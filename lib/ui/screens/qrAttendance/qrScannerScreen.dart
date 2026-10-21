import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrScannerOverlay.dart';
import 'package:eschool_saas_staff/ui/widgets/customRoundedButton.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera screen that reads the attendance QR code.
///
/// It only decodes: it pops with the scanned token and lets the caller decide
/// what to do with it. Keeping the punch out of here means the camera is
/// released before the network call starts, and the same scanner can be reused
/// without dragging the attendance rules along.
///
/// Pops with the token as a [String], or with null when the user backs out.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen._();

  static Widget getRouteInstance() => const QrScannerScreen._();

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    // Only QR codes are of interest, so other symbologies are never decoded.
    formats: const [BarcodeFormat.qrCode],
    // `noDuplicates` reports a given value once and then suppresses it. If that
    // single emission arrives while the screen is still settling it is lost and
    // the same code is never offered again, which reads as a scanner that does
    // nothing. `normal` keeps emitting and [_hasHandledDetection] takes the
    // first one.
    detectionSpeed: DetectionSpeed.normal,
    // Pulls a small or distant code into range instead of asking the user to
    // find the exact spot.
    autoZoom: true,
  );

  /// Null while the permission is still being resolved.
  bool? _hasCameraPermission;

  /// A QR code can be decoded many times a second; the first valid read wins
  /// and everything after it is ignored.
  bool _hasHandledDetection = false;

  /// Shown over the preview when a scan could not be used, so a failed read is
  /// never silent.
  String? _scanErrorMessage;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final isGranted = await Utils.hasCameraPermissionGiven();
    if (!mounted) return;
    setState(() => _hasCameraPermission = isGranted);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasHandledDetection) return;

    debugPrint("QrScanner: detected ${capture.barcodes.length} barcode(s): "
        "${capture.barcodes.map((b) => b.rawValue).toList()}");

    final token = capture.barcodes
        .map((barcode) => barcode.rawValue ?? "")
        .firstWhere((rawValue) => rawValue.trim().isNotEmpty, orElse: () => "");

    // A QR that carries no text — decoded, but nothing usable in it. Say so
    // instead of leaving the user staring at a camera that seems dead.
    if (token.isEmpty) {
      _showScanError(emptyQrCodeKey);
      return;
    }

    _hasHandledDetection = true;
    // Stop before popping so the torch is switched off and the camera is
    // released even on devices that are slow to tear the preview down.
    _scannerController.stop();
    Get.back<String>(result: token.trim());
  }

  /// The decoder itself failed on a frame. Surfaced rather than swallowed.
  void _onDetectError(Object error, StackTrace stackTrace) {
    debugPrint("QrScanner: decode error ($error)");
    _showScanError(unableToReadQrCodeKey);
  }

  /// Shows [messageKey] over the preview and clears it again so the user can
  /// simply keep pointing at the code.
  void _showScanError(String messageKey) {
    if (!mounted || _scanErrorMessage == messageKey) return;
    setState(() => _scanErrorMessage = messageKey);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _scanErrorMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBody()),
            _buildTopBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasCameraPermission == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_hasCameraPermission == false) {
      return _buildPermissionDenied();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final Size layoutSize = constraints.biggest;
        // A square window, wide enough to frame a wall mounted code from a
        // comfortable distance, lifted slightly above centre to leave room for
        // the hint underneath.
        final double windowSide =
            (layoutSize.shortestSide * 0.68).clamp(180.0, 320.0);
        final Rect scanWindow = Rect.fromCenter(
          center: Offset(layoutSize.width / 2, layoutSize.height / 2 - 30),
          width: windowSide,
          height: windowSide,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _scannerController,
                // Deliberately no `scanWindow`: it filters out every code that
                // does not intersect the rectangle, and that rectangle is
                // measured against the preview widget rather than the camera
                // frame. With BoxFit.cover the two do not line up, so a code
                // held in the visible frame can still be discarded — a scanner
                // that looks alive and never reads anything. The brackets below
                // stay purely as an aiming guide.
                onDetect: _onDetect,
                onDetectError: _onDetectError,
                // Dense codes at close range need a manual focus nudge.
                tapToFocus: true,
                errorBuilder: (context, error) => _buildScannerError(error),
              ),
            ),
            Positioned.fill(
              child: QrScannerOverlay(
                scanWindow: scanWindow,
                borderColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            Positioned(
              left: appContentHorizontalPadding,
              right: appContentHorizontalPadding,
              top: scanWindow.bottom + 24,
              child: _buildHint(),
            ),
            if (_scanErrorMessage != null)
              Positioned(
                left: appContentHorizontalPadding,
                right: appContentHorizontalPadding,
                bottom: 100,
                child: _buildScanErrorBanner(),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Center(child: _buildTorchButton()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      left: 5,
      right: 5,
      top: 5,
      child: Row(
        children: [
          _CircularOverlayButton(
            icon: Icons.close,
            onTap: () => Get.back<String>(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomTextContainer(
              textKey: scanQrCodeKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Error shown over the camera preview, so a scan that could not be used is
  /// visible on screen instead of only in the logs.
  Widget _buildScanErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: CustomTextContainer(
              textKey: _scanErrorMessage!,
              style: const TextStyle(
                fontSize: 13,
                height: 18 / 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return CustomTextContainer(
      textKey: alignQrWithinFrameKey,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 13.5,
        height: 20 / 13.5,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTorchButton() {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: _scannerController,
      builder: (context, state, child) {
        final bool isTorchOn = state.torchState == TorchState.on;
        return _CircularOverlayButton(
          icon: isTorchOn ? Icons.flash_on : Icons.flash_off,
          size: 52,
          onTap: () => _scannerController.toggleTorch(),
        );
      },
    );
  }

  Widget _buildScannerError(MobileScannerException error) {
    // The camera itself refused to start — a permission revoked while the
    // screen was open, or hardware already in use by another app.
    final bool isPermissionError =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return _buildFullScreenMessage(
      icon: isPermissionError
          ? Icons.no_photography_outlined
          : Icons.error_outline,
      messageKey: isPermissionError
          ? allowCameraPermissionToScanKey
          : defaultErrorMessageKey,
      actionTitleKey: isPermissionError ? openSettingsKey : retryKey,
      onTapAction: isPermissionError
          ? openAppSettings
          : () {
              setState(() => _hasCameraPermission = null);
              _requestCameraPermission();
            },
    );
  }

  Widget _buildPermissionDenied() {
    return _buildFullScreenMessage(
      icon: Icons.no_photography_outlined,
      messageKey: allowCameraPermissionToScanKey,
      actionTitleKey: openSettingsKey,
      onTapAction: openAppSettings,
    );
  }

  Widget _buildFullScreenMessage({
    required IconData icon,
    required String messageKey,
    required String actionTitleKey,
    required VoidCallback onTapAction,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: appContentHorizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white70),
            const SizedBox(height: 20),
            CustomTextContainer(
              textKey: messageKey,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                height: 21 / 14.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 25),
            CustomRoundedButton(
              widthPercentage: 0.6,
              backgroundColor: Theme.of(context).colorScheme.primary,
              buttonTitle: actionTitleKey,
              titleColor: Colors.white,
              textSize: 15,
              height: 46,
              showBorder: false,
              onTap: onTapAction,
            ),
          ],
        ),
      ),
    );
  }
}

/// Translucent circular button used over the camera preview.
class _CircularOverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircularOverlayButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}
