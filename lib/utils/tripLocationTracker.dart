import 'dart:async';
import 'dart:io';

import 'package:eschool_saas_staff/data/repositories/transportRepository.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/locationService.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

/// Past this age a fix stops meaning "the bus is here" and starts meaning "we
/// lost it a while ago" — a tunnel, a parking basement, location switched off.
///
/// It serves as both halves of that thought: a fix this old is not worth
/// reporting, and a stream silent this long is presumed dead rather than
/// merely parked.
final Duration _maxPositionAge = tripLocationUpdateInterval * 5;

bool _isTooOld(Position position) =>
    DateTime.now().difference(position.timestamp).abs() > _maxPositionAge;

/// Reports where the vehicle is while a driver's trip is in progress.
///
/// A singleton on purpose: tracking belongs to the trip, not to the screen the
/// driver happens to be looking at. It keeps running when the trip details
/// screen is closed, when the app is put in the background, and when the phone
/// is locked in a cradle for the whole route.
///
/// The work splits in two. This class owns the *trip*: which one is being
/// tracked, how often its position may be posted, and what to do when the
/// server answers. [_PositionFeed] owns the *device*: getting fixes out of it
/// and keeping that stream alive across everything Android and iOS do to a
/// backgrounded app. Neither needs to know much about the other — the feed
/// says "here is a fresh fix", this class decides whether it is time to report
/// one.
///
/// What it costs: one location stream and one request per
/// [tripLocationUpdateInterval], and nothing at all outside a trip.
///
/// The one case it cannot cover is the process being killed — no Dart code
/// runs then. Recovery does not need persistence either: `TripsCubit` tells
/// the tracker what the server says about the driver's trips on every refresh,
/// so a trip that is still in progress resumes tracking the next time the app
/// is opened, and one that was finished elsewhere stops being tracked here.
class TripLocationTracker with WidgetsBindingObserver {
  TripLocationTracker._();

  static final TripLocationTracker instance = TripLocationTracker._();

  final TransportRepository _transportRepository = TransportRepository();

  /// The device side of the job. Every fix it receives is offered back through
  /// [_sendUpdate], which is free to ignore it until the interval is up.
  late final _PositionFeed _positions = _PositionFeed(onFix: _sendUpdate);

  /// One update gets less time than the gap to the next one, so a request left
  /// hanging on a dying connection can never block the interval after it.
  static final Duration _requestTimeout = tripLocationUpdateInterval ~/ 2;

  /// Timer ticks, location events and lifecycle resumes all lead to the same
  /// send; a little slack keeps a tick that lands a moment "too early" from
  /// being dropped and silently halving the cadence.
  static const Duration _cadenceTolerance = Duration(seconds: 2);

  /// The trip being tracked. Null means tracking is off, and it is the flag
  /// every other path checks.
  int? _tripId;
  Timer? _timer;

  /// When the last update was *attempted*, not when it came back. Recording it
  /// up front is what keeps a slow or failed request from stacking retries.
  DateTime? _lastAttemptAt;

  /// The trip whose update is in flight, so one trip's slow request cannot
  /// hold up the first update of the trip that follows it.
  int? _sendingTripId;

  bool get isTracking => _tripId != null;

  int? get trackedTripId => _tripId;

  /// Settles the location permission, showing the system dialog.
  ///
  /// Meant for the moment the driver starts a trip: the dialog then arrives on
  /// the back of their own tap, and the trip waits for the answer. Returns null
  /// when tracking can run, or the reason to put in front of the driver.
  ///
  /// A granted permission is always enough to say yes here — see
  /// [_checkPreconditions] for why the device's location switch is left to the
  /// offer Play Services makes inside the app.
  Future<LocationFailureReason?> ensureTrackingReady() =>
      _checkPreconditions(requestPermission: true);

  /// Starts reporting the position for [tripId].
  ///
  /// Safe to call repeatedly: a second call for the trip already being tracked
  /// does nothing, which is what keeps a screen refresh from opening a second
  /// stream or firing a second update. Starting a different trip replaces the
  /// current one — a driver only drives one bus at a time.
  ///
  /// [requestPermission] stays false for automatic starts, so the OS dialog
  /// only ever appears where a driver asked for something.
  Future<void> start({
    required int tripId,
    bool requestPermission = false,
  }) async {
    if (_tripId == tripId) return;
    if (_tripId != null) await stop();

    // Claimed before the first await: the trip start response and the refresh
    // that follows it arrive together, and only one of them may open a stream.
    _tripId = tripId;

    final failure =
        await _checkPreconditions(requestPermission: requestPermission);
    if (_tripId != tripId) return; // stopped or replaced while we were asking
    if (failure != null) {
      _tripId = null;
      debugPrint("TripLocationTracker: trip $tripId not tracked ($failure)");
      return;
    }

    _lastAttemptAt = null;
    WidgetsBinding.instance.addObserver(this);
    _positions.start();
    _timer = Timer.periodic(tripLocationUpdateInterval, (_) => _onTick());
    debugPrint("TripLocationTracker: tracking trip $tripId");

    unawaited(_positions.seedFromLastKnownFix());
  }

  /// Stops reporting and releases the location stream — which is also what
  /// takes down the Android foreground service and its notification.
  ///
  /// [tripId] scopes the stop to one trip, so the details screen of the trip
  /// that just finished cannot switch off the tracking of a trip started after
  /// it. Pass nothing to stop unconditionally (sign out, force logout).
  Future<void> stop({int? tripId}) async {
    if (_tripId == null) return;
    if (tripId != null && tripId != _tripId) return;

    debugPrint("TripLocationTracker: stopped tracking trip $_tripId");
    _tripId = null;
    _lastAttemptAt = null;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    await _positions.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !isTracking) return;

    // Back on screen is the only safe moment to repair a stream that died
    // while the app was away — and the moment a process the OS had frozen can
    // report again. An iPhone locked with "while in use" permission, or an
    // Android device in deep doze, freezes the timer along with everything
    // else; the cadence guard inside [_sendUpdate] keeps this from doubling up
    // with the missed tick that fires at the same time.
    _onTick();
  }

  /// Whether the device may be asked for fixes, and can produce them.
  ///
  /// Only the permission is settled here, and on Android that is deliberate:
  /// opening the position stream makes Play Services offer to switch location
  /// on from *inside* the app — one tap, updates start on the spot — and a
  /// pre-flight check here would pre-empt that offer with a far worse answer,
  /// sending a driver whose permission is perfectly fine out to the settings
  /// app. iOS has no such offer, so there the switch is checked up front.
  Future<LocationFailureReason?> _checkPreconditions({
    required bool requestPermission,
  }) async {
    final permissionFailure =
        await LocationService.ensurePermission(request: requestPermission);
    if (permissionFailure != null) return permissionFailure;

    if (Platform.isIOS && !await LocationService.isServiceEnabled()) {
      return LocationFailureReason.serviceDisabled;
    }
    return null;
  }

  void _onTick() {
    _positions.keepAlive();
    _sendUpdate();
  }

  /// The single path every update takes, whatever triggered it.
  Future<void> _sendUpdate() async {
    final tripId = _tripId;
    if (tripId == null) return;

    // Never two updates in flight for the same trip, and never two inside one
    // interval: this is what a stream that fires every few seconds is
    // throttled by.
    if (_sendingTripId == tripId || !_isDueForUpdate) return;

    final position = _positions.lastPosition;
    if (position == null) return;
    if (_isTooOld(position)) {
      final age = DateTime.now().difference(position.timestamp).abs();
      debugPrint("TripLocationTracker: skipped, fix is ${age.inSeconds}s old");
      return;
    }

    _sendingTripId = tripId;
    _lastAttemptAt = DateTime.now();
    try {
      await _transportRepository
          .updateTripLocation(
            tripId: tripId,
            latitude: position.latitude,
            longitude: position.longitude,
          )
          .timeout(_requestTimeout);
    } on TripLocationException catch (e) {
      // The server refusing the trip itself — finished, or never this
      // driver's — is final. Anything else is the network, and the next
      // interval simply tries again with a fresher position.
      if (e.isRetryable) {
        debugPrint("TripLocationTracker: update failed, will retry ($e)");
      } else {
        debugPrint("TripLocationTracker: update refused for trip $tripId ($e)");
        await stop(tripId: tripId);
      }
    } on TimeoutException {
      debugPrint("TripLocationTracker: update timed out, will retry");
    } catch (e) {
      debugPrint("TripLocationTracker: update failed, will retry ($e)");
    } finally {
      if (_sendingTripId == tripId) _sendingTripId = null;
    }
  }

  bool get _isDueForUpdate =>
      _lastAttemptAt == null ||
      DateTime.now().difference(_lastAttemptAt!) >=
          tripLocationUpdateInterval - _cadenceTolerance;
}

/// The device's position stream for one trip: opening it, keeping it healthy,
/// closing it again, and holding on to the latest fix.
///
/// Everything the two platforms demand of a stream that has to survive the app
/// being backgrounded lives here — the foreground-service rule, the platform
/// settings, the wait after a failure — so that [TripLocationTracker] can be
/// about the trip.
class _PositionFeed {
  _PositionFeed({required this.onFix});

  /// Called whenever a fresh fix lands. Fixes drive the updates and the
  /// tracker's timer is only a backstop, which is what matters in the
  /// background: a location event is what wakes the app, so reporting from
  /// here keeps the cadence honest while every timer in the isolate stands
  /// still.
  final void Function() onFix;

  /// Fixes are asked for twice as often as they are posted, so what goes out
  /// on each interval is a recent position rather than a minute-old one.
  static final Duration _fixInterval = tripLocationUpdateInterval ~/ 2;

  /// Metres the vehicle has to move on iOS before a new fix is delivered.
  ///
  /// iOS offers no interval to slow updates down, so this is the only thing
  /// keeping a bus waiting at a stop from waking the app for every jitter of
  /// the GPS. Android has [_fixInterval] for that and therefore takes no
  /// distance filter at all — a bus standing still there keeps reporting
  /// rather than going quiet and looking lost.
  static const int _iosDistanceFilterInMeters = 10;

  /// How long a failed stream is left alone before another attempt.
  ///
  /// A stream fails for reasons the next minute rarely changes, and on Android
  /// the retry is not free: with location switched off it puts Play Services'
  /// "turn on location?" dialog in front of the driver again. Backing off
  /// keeps a driver who answered "no thanks" from being asked once a minute
  /// for the rest of the route.
  static final Duration _retryBackoff = tripLocationUpdateInterval * 3;

  bool _isRunning = false;
  StreamSubscription<Position>? _subscription;
  Position? _lastPosition;

  /// When a fix last arrived, whatever it said. Separate from the position's
  /// own timestamp because this measures the *stream's* health: a stream that
  /// stops delivering without ever reporting an error looks exactly like a
  /// parked bus, and only this tells them apart.
  DateTime? _lastFixAt;

  /// When the stream may be opened again after a failure.
  DateTime? _retryAfter;

  /// The latest fix, or null while none has arrived — including after a stream
  /// failure, where the last one is no longer worth trusting.
  Position? get lastPosition => _lastPosition;

  void start() {
    _isRunning = true;
    _lastPosition = null;
    _lastFixAt = DateTime.now();
    _retryAfter = null; // a new trip waits on nothing the last one ran into
    keepAlive();
  }

  Future<void> stop() async {
    _isRunning = false;
    _lastFixAt = null;
    _retryAfter = null;
    await _drop();
  }

  /// Opens the stream, or replaces one that has gone quiet.
  ///
  /// Every caller — the trip starting, each tick, the app coming back on
  /// screen — goes through here, so they all get the same rules applied in the
  /// same order.
  void keepAlive() {
    if (!_isRunning) return;

    // Replacing a stream is a foreground-only move, so out of sight it must
    // not even be attempted: [_open] could not follow through there, and
    // dropping a quiet-but-working stream would trade a bus that is merely
    // parked for one that has gone silent for the rest of the trip.
    if (_isInForeground && _isStale) {
      debugPrint("TripLocationTracker: no fix in a while, reopening stream");
      unawaited(_restart());
      return;
    }

    _open();
  }

  /// Reports the platform's cached fix while the first live one is still being
  /// acquired.
  ///
  /// A cold GPS lock takes up to a minute in a depot or under a roof, and the
  /// school would see nothing at all in the meantime. The cached fix is only
  /// used while it is recent, and the stream replaces it the moment it has
  /// something better.
  Future<void> seedFromLastKnownFix() async {
    if (_lastPosition != null) return; // the stream was quicker

    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null || _lastPosition != null || !_isRunning) return;
      if (_isTooOld(position)) return;

      _lastPosition = position;
      onFix();
    } catch (e) {
      debugPrint("TripLocationTracker: no cached fix to start from ($e)");
    }
  }

  /// The one place a stream is opened, and so the one place that has to hold
  /// the line on Android's rule: starting a location foreground service from
  /// the background throws, and the plugin lets that exception through and
  /// crashes the app. A stream lost out of sight is repaired on the driver's
  /// return, not before.
  void _open() {
    if (!_isRunning || _subscription != null) return;
    if (!_isInForeground) {
      debugPrint("TripLocationTracker: stream repair waits for the foreground");
      return;
    }
    if (_retryAfter != null && DateTime.now().isBefore(_retryAfter!)) return;

    try {
      _subscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings(),
      ).listen(_onPosition, onError: _onError);
      _lastFixAt = DateTime.now();
      _retryAfter = null;
    } catch (e) {
      // Opening the stream is the one step that can fail outright — a
      // foreground service the OS refused to start, for instance. A trip must
      // not go down with it; the next tick tries again.
      debugPrint("TripLocationTracker: could not open position stream ($e)");
      _subscription = null;
    }
  }

  void _onPosition(Position position) {
    _lastPosition = position;
    _lastFixAt = DateTime.now();
    onFix();
  }

  void _onError(Object error) {
    // Location switched off mid-trip, a declined "turn on location?" offer, or
    // the platform simply dropping the stream. Tracking stays on and the
    // stream is reopened later — soon enough that a driver who fixes it need
    // do nothing else, far enough apart not to badger one who did not.
    debugPrint("TripLocationTracker: position stream failed ($error)");
    _retryAfter = DateTime.now().add(_retryBackoff);
    unawaited(_drop());
  }

  Future<void> _drop() async {
    final subscription = _subscription;
    _subscription = null;
    _lastPosition = null;
    await subscription?.cancel();
  }

  /// The cancel is awaited before reopening: geolocator hands back the very
  /// same stream object until the old subscription has finished tearing down,
  /// so reopening too early would "succeed" onto a dead stream and leave the
  /// trip reporting nothing at all.
  Future<void> _restart() async {
    await _drop();
    _open();
  }

  /// A subscription that is still open but has gone quiet for several
  /// intervals. The platform can drop a stream without ever reporting an
  /// error, and from the outside that is indistinguishable from a parked bus —
  /// so it is only treated as dead after [_maxPositionAge] of silence.
  bool get _isStale =>
      _subscription != null &&
      _lastFixAt != null &&
      DateTime.now().difference(_lastFixAt!) > _maxPositionAge;

  /// Whether the app is on screen.
  ///
  /// Read from the binding every time instead of being remembered, because the
  /// tracker only observes lifecycle changes while a trip runs: a value left
  /// over from the last trip would be wrong by the time the next one starts,
  /// and a stale `false` would keep that trip from ever opening its stream.
  /// Null is the state before the first transition is reported, which only
  /// happens while the app is running in front of the user.
  bool get _isInForeground {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    return lifecycleState == null ||
        lifecycleState == AppLifecycleState.resumed;
  }

  /// Platform settings that keep the stream alive while the app is not on
  /// screen. Both branches are what make the background part of this work at
  /// all; the shared defaults would stop delivering the moment the driver
  /// switches apps.
  LocationSettings _locationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        // No distance filter: [_fixInterval] already caps how often a fix
        // arrives, and a filter on top of it would silence a bus that is
        // simply waiting at a stop.
        distanceFilter: 0,
        intervalDuration: _fixInterval,
        // The notification is not decoration: it is the foreground service
        // Android requires before it will hand location to a backgrounded app,
        // and it is also the disclosure that tells the driver sharing is on.
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: Utils.getTranslatedLabel(tripInProgressKey),
          notificationText:
              Utils.getTranslatedLabel(tripLocationSharingActiveKey),
          notificationChannelName:
              Utils.getTranslatedLabel(tripLocationUpdatesKey),
          notificationIcon: const AndroidResource(
            name: 'ic_notification',
            defType: 'drawable',
          ),
          // The trip is the driver's whole shift and the phone is usually in a
          // cradle: keeping the CPU awake is what makes updates arrive on time
          // with the screen off, instead of in a burst hours later.
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _iosDistanceFilterInMeters,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        // Never let iOS pause updates: it decides the vehicle has stopped and
        // stays quiet until it sees significant movement, which would leave a
        // bus waiting in traffic looking like a bus that vanished.
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _iosDistanceFilterInMeters,
    );
  }
}
