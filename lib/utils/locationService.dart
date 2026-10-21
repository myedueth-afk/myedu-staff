import 'dart:async';

import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Why a location read did not produce a fix.
enum LocationFailureReason {
  /// Location services are switched off on the device.
  serviceDisabled,

  /// The user declined the permission for now.
  permissionDenied,

  /// The permission is blocked and can only be granted from the settings app.
  permissionDeniedForever,

  /// Permission and services are fine, but no fix arrived in time.
  unavailable,
}

/// Outcome of a location read: either a [position], or a [failureReason] with
/// the label to show for it.
class LocationResult {
  final Position? position;
  final LocationFailureReason? failureReason;

  const LocationResult.success(Position this.position) : failureReason = null;

  const LocationResult.failure(LocationFailureReason this.failureReason)
      : position = null;

  bool get isSuccess => position != null;

  /// Radius in metres the fix could be off by. Used to keep the app side
  /// distance check from blocking someone the server would have accepted.
  double get accuracyInMeters => position?.accuracy ?? 0;

  /// Localization key describing [failureReason].
  String get messageKey {
    switch (failureReason) {
      case LocationFailureReason.serviceDisabled:
        return enableLocationServicesKey;
      case LocationFailureReason.permissionDenied:
        return allowLocationAccessKey;
      case LocationFailureReason.permissionDeniedForever:
        return locationPermissionDeniedForeverKey;
      case LocationFailureReason.unavailable:
      case null:
        return unableToDetermineLocationKey;
    }
  }

  /// Which settings page, if any, can resolve this failure.
  LocationSettingsTarget? get settingsTarget => failureReason?.settingsTarget;
}

extension LocationFailureSettings on LocationFailureReason {
  /// Which settings page, if any, can resolve this failure.
  ///
  /// A fix that never arrives is usually not a permission problem: it is GPS
  /// indoors while the device's network based location source is switched off.
  /// That switch lives in the device location settings, so they are offered
  /// here too rather than leaving the user at a dead end.
  LocationSettingsTarget? get settingsTarget {
    switch (this) {
      case LocationFailureReason.serviceDisabled:
      case LocationFailureReason.unavailable:
        return LocationSettingsTarget.deviceLocation;
      case LocationFailureReason.permissionDeniedForever:
        return LocationSettingsTarget.appPermissions;
      case LocationFailureReason.permissionDenied:
        return null;
    }
  }
}

/// Settings page that can resolve a location failure.
enum LocationSettingsTarget {
  /// The device's own location settings, holding both the master switch and
  /// the network based accuracy option.
  deviceLocation,

  /// This app's permission page, for a permanently denied permission.
  appPermissions,
}

/// Device location, and the permission plumbing every location feature needs.
///
/// [getCurrentPosition] serves the QR attendance flow: the position is read at
/// the moment of a scan, never cached from app start. A high accuracy fix is
/// asked for first, because a coarse network fix can be hundreds of metres out
/// and would be refused by the server — but a school entrance is exactly the
/// kind of place where a cold GPS fix is slow, so the read degrades in steps
/// instead of giving up on the first timeout.
///
/// [isServiceEnabled] and [ensurePermission] are the shared gate in front of
/// that read and of the trip tracking stream.
class LocationService {
  const LocationService._();

  /// How long to wait for the preferred high accuracy fix.
  static const Duration _highAccuracyTimeLimit = Duration(seconds: 20);

  /// How long to wait for the reduced accuracy retry.
  static const Duration _reducedAccuracyTimeLimit = Duration(seconds: 15);

  /// A cached platform fix is only trusted while it is this recent — long
  /// enough to cover a slow GPS lock, short enough that the staff member
  /// cannot have walked out of the school's radius since it was taken.
  static const Duration _maxLastKnownAge = Duration(minutes: 2);

  /// Reads a fresh position, requesting the permission and reporting every
  /// device state the caller has to explain to the user.
  static Future<LocationResult> getCurrentPosition() async {
    if (!await isServiceEnabled()) {
      return const LocationResult.failure(
          LocationFailureReason.serviceDisabled);
    }

    final permissionFailure = await ensurePermission();
    if (permissionFailure != null) {
      return LocationResult.failure(permissionFailure);
    }

    // 1. The fix the server wants: satellite grade, good to a few metres.
    final highAccuracyResult = await _tryFix(
      accuracy: LocationAccuracy.high,
      timeLimit: _highAccuracyTimeLimit,
    );
    if (highAccuracyResult != null) return highAccuracyResult;

    // 2. A fix the platform already had. Only used while it is recent enough
    //    that the device cannot have moved out of the radius since.
    final recentFix = await _recentLastKnownPosition();
    if (recentFix != null) return LocationResult.success(recentFix);

    // 3. Last resort. Coarser, so it may land outside the radius and be
    //    refused — but a refusal with a distance is far more useful to the
    //    staff member than "unable to determine your location".
    final reducedAccuracyResult = await _tryFix(
      accuracy: LocationAccuracy.medium,
      timeLimit: _reducedAccuracyTimeLimit,
    );
    if (reducedAccuracyResult != null) return reducedAccuracyResult;

    return const LocationResult.failure(LocationFailureReason.unavailable);
  }

  /// Whether the device's location master switch is on.
  static Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint("LocationService: service check failed ($e)");
      // Assume it is on and let the position read report the real reason.
      return true;
    }
  }

  /// Returns the failure to report, or null when the permission is good.
  ///
  /// [request] shows the system dialog for a permission that has not been
  /// decided yet. Pass false where no user gesture is behind the call — a
  /// trip that resumes tracking on its own must never make a dialog appear out
  /// of nowhere; it simply reports the missing permission instead.
  static Future<LocationFailureReason?> ensurePermission({
    bool request = true,
  }) async {
    try {
      var permission = await Geolocator.checkPermission();

      // `unableToDetermine` is not a refusal — the platform simply has no
      // answer yet, so asking is the right move. Without this the read fell
      // through and failed later as a generic "no fix".
      if (request &&
          (permission == LocationPermission.denied ||
              permission == LocationPermission.unableToDetermine)) {
        permission = await Geolocator.requestPermission();
      }

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return null;
        case LocationPermission.deniedForever:
          return LocationFailureReason.permissionDeniedForever;
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return LocationFailureReason.permissionDenied;
      }
    } catch (e) {
      debugPrint("LocationService: permission check failed ($e)");
      return LocationFailureReason.permissionDenied;
    }
  }

  /// One attempt at a fix. Returns null when it timed out — the caller then
  /// falls back — or a failure result when the device state changed under us
  /// and there is something specific to tell the user.
  static Future<LocationResult?> _tryFix({
    required LocationAccuracy accuracy,
    required Duration timeLimit,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
      return LocationResult.success(position);
    } on TimeoutException {
      // No fix settled in time. Not fatal on its own — the caller degrades.
      debugPrint(
          "LocationService: no $accuracy fix within ${timeLimit.inSeconds}s");
      return null;
    } on LocationServiceDisabledException {
      // Switched off between the check above and this read.
      return const LocationResult.failure(
          LocationFailureReason.serviceDisabled);
    } on PermissionDeniedException {
      // Revoked from the notification shade or the settings app mid flight.
      return const LocationResult.failure(
          LocationFailureReason.permissionDenied);
    } catch (e) {
      debugPrint("LocationService: $accuracy fix failed ($e)");
      return null;
    }
  }

  /// The platform's cached fix, but only while it is younger than
  /// [_maxLastKnownAge].
  static Future<Position?> _recentLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      final age = DateTime.now().difference(position.timestamp).abs();
      if (age > _maxLastKnownAge) {
        debugPrint(
            "LocationService: ignoring last known fix, ${age.inSeconds}s old");
        return null;
      }
      return position;
    } catch (e) {
      debugPrint("LocationService: last known position failed ($e)");
      return null;
    }
  }

  /// Distance in metres between two points, rounded the way the server reports
  /// it. Uses the same haversine maths the backend applies.
  static int distanceInMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ).round();
  }

  /// Opens the settings page that can resolve a failed read.
  static Future<void> openSettings(LocationSettingsTarget target) {
    switch (target) {
      case LocationSettingsTarget.deviceLocation:
        return Geolocator.openLocationSettings();
      case LocationSettingsTarget.appPermissions:
        return Geolocator.openAppSettings();
    }
  }
}
