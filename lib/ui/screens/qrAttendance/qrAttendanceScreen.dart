import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/qrAttendance/qrAttendanceConfigCubit.dart';
import 'package:eschool_saas_staff/cubits/qrAttendance/qrPunchCubit.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceConfig.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceUtils.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrAttendanceMessageContainer.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrPunchLogBottomSheet.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrPunchResultBottomSheet.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrScanActionButton.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrSessionsCard.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrTodayStatusCard.dart';
import 'package:eschool_saas_staff/ui/widgets/customAppbar.dart';
import 'package:eschool_saas_staff/ui/widgets/errorContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/locationService.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

/// Home of the QR attendance flow.
///
/// It owns the sequence the API expects — read the configuration, confirm the
/// device is at the school, scan, punch — and never decides whether a scan is a
/// punch in or a punch out: `next_action` and `punch_type` always come from the
/// server, so a second device or an administrator's correction can never leave
/// this screen out of step.
class QrAttendanceScreen extends StatefulWidget {
  const QrAttendanceScreen._();

  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => QrAttendanceConfigCubit()),
        BlocProvider(create: (_) => QrPunchCubit()),
      ],
      child: const QrAttendanceScreen._(),
    );
  }

  @override
  State<QrAttendanceScreen> createState() => _QrAttendanceScreenState();
}

class _QrAttendanceScreenState extends State<QrAttendanceScreen> {
  /// Set while the location is read or the punch is in flight, so the action
  /// button cannot be tapped twice.
  bool _isPreparingScan = false;
  String? _busyLabelKey;

  /// Moment the local cooldown expires, mirroring the server's own window.
  DateTime? _cooldownUntil;

  /// The single notice shown above the action button: an unavailable location,
  /// a refused punch, a blocked feature.
  _QrAttendanceNotice? _notice;

  /// A refusal that makes scanning pointless until an administrator acts.
  QrAttendanceErrorCode? _blockingErrorCode;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _fetchConfig);
  }

  void _fetchConfig() {
    setState(() {
      _notice = null;
      _blockingErrorCode = null;
    });
    context.read<QrAttendanceConfigCubit>().fetchConfig();
  }

  Future<void> _onRefresh() async {
    final cubit = context.read<QrAttendanceConfigCubit>();
    if (cubit.config == null) {
      _fetchConfig();
      return;
    }
    await cubit.refreshToday();
  }

  void _setNotice(_QrAttendanceNotice? notice) {
    if (!mounted) return;
    setState(() => _notice = notice);
  }

  void _setBusy({required bool isBusy, String? labelKey}) {
    if (!mounted) return;
    setState(() {
      _isPreparingScan = isBusy;
      _busyLabelKey = isBusy ? labelKey : null;
    });
  }

  // ---------------------------------------------------------------------------
  // Scan flow
  // ---------------------------------------------------------------------------

  /// Location first, camera second: a staff member who is too far away learns
  /// it before the camera ever opens, and the coordinates that get posted are
  /// the ones read for this scan.
  Future<void> _onTapScan(QrAttendanceConfig config) async {
    if (_isPreparingScan) return;

    _setNotice(null);
    _setBusy(isBusy: true, labelKey: checkingYourLocationKey);

    final locationResult = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (!locationResult.isSuccess) {
      _setBusy(isBusy: false);
      final settingsTarget = locationResult.settingsTarget;
      _setNotice(_QrAttendanceNotice(
        message: Utils.getTranslatedLabel(locationResult.messageKey),
        icon: Icons.location_off_outlined,
        actionTitleKey: settingsTarget == null ? null : openSettingsKey,
        onTapAction: settingsTarget == null
            ? null
            : () => LocationService.openSettings(settingsTarget),
      ));
      return;
    }

    final position = locationResult.position!;

    // The server checks this again and is the authority; doing it here only
    // saves the user a pointless trip to the camera.
    if (config.hasSchoolLocation) {
      final distance = LocationService.distanceInMeters(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: config.latitude!,
        endLongitude: config.longitude!,
      );

      // The fix is only good to within its own margin of error, so the check
      // refuses only when the device is outside the radius by more than that
      // margin. Anything inside it is sent on and left to the server, which
      // must never be pre-empted into refusing someone it would have accepted.
      final int certainDistance =
          (distance - locationResult.accuracyInMeters).round();

      // A device exactly on the boundary is accepted, matching the server.
      if (certainDistance > config.radius!) {
        _setBusy(isBusy: false);
        _setNotice(_QrAttendanceNotice(
          message: Utils.getTranslatedLabel(youAreAwayFromSchoolKey)
              .replaceAll(
                  '@distance', QrAttendanceUtils.formatDistance(distance))
              .replaceAll('@radius', config.formattedRadius),
          icon: Icons.wrong_location_outlined,
        ));
        return;
      }
    }

    final qrToken = await Get.toNamed(Routes.qrScannerScreen);
    if (!mounted) return;

    // The user backed out of the scanner.
    if (qrToken is! String || qrToken.isEmpty) {
      _setBusy(isBusy: false);
      return;
    }

    _setBusy(isBusy: true, labelKey: recordingPunchKey);
    await context.read<QrPunchCubit>().punch(
          qrToken: qrToken,
          latitude: position.latitude,
          longitude: position.longitude,
        );
  }

  void _onPunchStateChanged(BuildContext context, QrPunchState state) {
    if (state is QrPunchInProgress) return;

    _setBusy(isBusy: false);

    if (state is QrPunchSuccess) {
      final config = context.read<QrAttendanceConfigCubit>().config;
      setState(() {
        _notice = null;
        // Keep the button out of reach for as long as the school's cooldown
        // lasts, so the user cannot walk into a `cooldown` refusal.
        _cooldownUntil = DateTime.now().add(Duration(
          seconds: config?.cooldownSeconds ??
              QrAttendanceConfig.defaultCooldownSeconds,
        ));
      });

      QrPunchResultBottomSheet.show(context: context, result: state.result);
      // The punch response already carries the fresh figures, but today's
      // block is what the screen renders, so it is re-read.
      context.read<QrAttendanceConfigCubit>().refreshToday();
      return;
    }

    if (state is QrPunchFailure) {
      _handlePunchFailure(state);
    }
  }

  void _handlePunchFailure(QrPunchFailure failure) {
    final errorCode = failure.errorCode;

    // Nothing reached the server, or the answer was lost on the way back.
    // Re-sending carries the same request UUID, so at most one punch is ever
    // recorded no matter how many times this is tapped.
    if (failure.isRetryableRequest) {
      _setNotice(_QrAttendanceNotice(
        message: failure.errorMessage,
        icon: Icons.wifi_off_outlined,
        actionTitleKey: retryKey,
        onTapAction: () {
          _setNotice(null);
          _setBusy(isBusy: true, labelKey: recordingPunchKey);
          context.read<QrPunchCubit>().retryLastPunch();
        },
      ));
      return;
    }

    setState(() {
      _blockingErrorCode =
          (errorCode?.blocksScanning ?? false) ? errorCode : null;
      // The server refused because two scans were too close together. The
      // remaining wait is never longer than the configured window, so holding
      // the button for that long keeps the user from hitting it again.
      if (errorCode == QrAttendanceErrorCode.cooldown) {
        _cooldownUntil = DateTime.now().add(Duration(
          seconds:
              context.read<QrAttendanceConfigCubit>().config?.cooldownSeconds ??
                  QrAttendanceConfig.defaultCooldownSeconds,
        ));
      }
      _notice = _QrAttendanceNotice(
        message: failure.errorMessage,
        icon: _iconForErrorCode(errorCode),
        isBlocking: errorCode?.blocksScanning ?? false,
        // "Contact administration" is the only useful next step when the
        // school has not finished the setup.
        actionTitleKey: errorCode == QrAttendanceErrorCode.notConfigured
            ? contactAdministrationKey
            : null,
        onTapAction: errorCode == QrAttendanceErrorCode.notConfigured
            ? () => Get.toNamed(Routes.contactUsScreen)
            : null,
      );
    });

    // A refusal that hides the feature is a state change on the server side;
    // re-reading the configuration keeps the whole screen consistent.
    if (errorCode?.blocksScanning ?? false) {
      context.read<QrAttendanceConfigCubit>().fetchConfig();
    }
  }

  IconData _iconForErrorCode(QrAttendanceErrorCode? errorCode) {
    switch (errorCode) {
      case QrAttendanceErrorCode.outsideRadius:
        return Icons.wrong_location_outlined;
      case QrAttendanceErrorCode.locationUnavailable:
        return Icons.location_off_outlined;
      case QrAttendanceErrorCode.cooldown:
        return Icons.timer_outlined;
      case QrAttendanceErrorCode.qrInvalid:
      case QrAttendanceErrorCode.qrExpired:
      case QrAttendanceErrorCode.qrInactive:
        return Icons.qr_code_scanner;
      case QrAttendanceErrorCode.dayClosed:
        return Icons.event_busy_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<QrPunchCubit, QrPunchState>(
      listener: _onPunchStateChanged,
      child: Scaffold(
        appBar: CustomAppbar(
          titleKey: qrAttendanceKey,
          trailingWidget: IconButton(
            tooltip: Utils.getTranslatedLabel(attendanceHistoryKey),
            icon: const Icon(Icons.history),
            onPressed: () => Get.toNamed(Routes.qrAttendanceHistoryScreen),
          ),
        ),
        body: BlocBuilder<QrAttendanceConfigCubit, QrAttendanceConfigState>(
          builder: (context, state) {
            if (state is QrAttendanceConfigFetchInProgress ||
                state is QrAttendanceConfigInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is QrAttendanceConfigFetchFailure) {
              return _buildConfigFailure(state);
            }

            return _buildContent(
                (state as QrAttendanceConfigFetchSuccess).config);
          },
        ),
        bottomNavigationBar: _buildBottomAction(),
      ),
    );
  }

  /// A configuration that could not be read. A business refusal has nothing to
  /// retry — it needs an administrator — so only transport failures get a retry
  /// button.
  Widget _buildConfigFailure(QrAttendanceConfigFetchFailure state) {
    final bool isBlocked = state.errorCode?.blocksScanning ?? false;

    if (isBlocked) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(appContentHorizontalPadding),
        child: QrAttendanceMessageContainer(
          icon: Icons.qr_code_scanner,
          message: state.errorMessage,
          isBlocking: true,
          actionTitleKey: contactAdministrationKey,
          onTapAction: () => Get.toNamed(Routes.contactUsScreen),
        ),
      );
    }

    return ErrorContainer(
      errorMessage: state.errorMessage,
      onTapRetry: _fetchConfig,
    );
  }

  Widget _buildContent(QrAttendanceConfig config) {
    // A disabled feature is a successful response carrying only `enabled` and
    // an explanation — it is shown as a notice, not as an error.
    if (!config.enabled) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(appContentHorizontalPadding),
        child: QrAttendanceMessageContainer(
          icon: Icons.qr_code_2_outlined,
          message: config.message.isEmpty
              ? Utils.getTranslatedLabel(qrAttendanceUnavailableKey)
              : config.message,
          isBlocking: true,
          actionTitleKey: contactAdministrationKey,
          onTapAction: () => Get.toNamed(Routes.contactUsScreen),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: EdgeInsets.all(appContentHorizontalPadding),
        children: [
          QrTodayStatusCard(config: config),
          const SizedBox(height: 15),
          if (config.today != null)
            QrSessionsCard(
              today: config.today!,
              onTapScanLog: () => QrPunchLogBottomSheet.show(
                context: context,
                date: DateTime.now(),
              ),
            ),
          if (!(config.today?.hasShift ?? false)) ...[
            const SizedBox(height: 15),
            QrAttendanceMessageContainer(
              icon: Icons.event_busy_outlined,
              message: Utils.getTranslatedLabel(noShiftAssignedKey),
              isBlocking: true,
            ),
          ],
          if (!config.hasSchoolLocation) ...[
            const SizedBox(height: 15),
            QrAttendanceMessageContainer(
              icon: Icons.location_off_outlined,
              message: Utils.getTranslatedLabel(qrAttendanceUnavailableKey),
              isBlocking: true,
              actionTitleKey: contactAdministrationKey,
              onTapAction: () => Get.toNamed(Routes.contactUsScreen),
            ),
          ],
        ],
      ),
    );
  }

  /// The action bar is only built when a scan can actually succeed, so the
  /// button is never shown next to a message explaining it would fail.
  Widget? _buildBottomAction() {
    final state = context.watch<QrAttendanceConfigCubit>().state;
    if (state is! QrAttendanceConfigFetchSuccess) return null;

    final config = state.config;
    // A switched off feature is already explained in full by the body.
    if (!config.enabled) return null;

    final bool canScan = config.canScan && _blockingErrorCode == null;
    if (!canScan && _notice == null) return null;

    return Container(
      padding: EdgeInsets.all(appContentHorizontalPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.tertiary),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_notice != null) ...[
            QrAttendanceMessageContainer(
              icon: _notice!.icon,
              message: _notice!.message,
              isBlocking: _notice!.isBlocking,
              actionTitleKey: _notice!.actionTitleKey,
              onTapAction: _notice!.onTapAction,
            ),
            if (canScan) const SizedBox(height: 12),
          ],
          if (canScan)
            QrScanActionButton(
              nextAction: config.today?.nextAction ?? QrPunchType.punchIn,
              isBusy: _isPreparingScan,
              busyLabelKey: _busyLabelKey,
              cooldownUntil: _cooldownUntil,
              onTap: () => _onTapScan(config),
            ),
        ],
      ),
    );
  }
}

/// The single notice rendered above the action button.
class _QrAttendanceNotice {
  final String message;
  final IconData icon;
  final bool isBlocking;
  final String? actionTitleKey;
  final VoidCallback? onTapAction;

  const _QrAttendanceNotice({
    required this.message,
    required this.icon,
    this.isBlocking = false,
    this.actionTitleKey,
    this.onTapAction,
  });
}
