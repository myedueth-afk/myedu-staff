import 'package:flutter/material.dart';

/// Darkens the camera preview everywhere except a square window, and draws the
/// corner brackets that tell the user where to hold the code.
class QrScannerOverlay extends StatelessWidget {
  /// The transparent window the camera shows through, in global coordinates.
  final Rect scanWindow;

  final Color borderColor;

  const QrScannerOverlay({
    super.key,
    required this.scanWindow,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _QrScannerOverlayPainter(
            scanWindow: scanWindow,
            borderColor: borderColor,
          ),
        ),
      ),
    );
  }
}

class _QrScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color borderColor;

  static const double _cornerRadius = 20;
  static const double _cornerLength = 32;
  static const double _borderWidth = 4;

  const _QrScannerOverlayPainter({
    required this.scanWindow,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final windowRect = RRect.fromRectAndRadius(
        scanWindow, const Radius.circular(_cornerRadius));

    // Everything outside the window is dimmed.
    final backgroundPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(windowRect),
    );
    canvas.drawPath(
      backgroundPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _borderWidth;

    // Four corner brackets rather than a full frame, so the code stays readable.
    canvas.drawPath(_cornerPath(), borderPaint);
  }

  Path _cornerPath() {
    final path = Path();
    final rect = scanWindow;

    // Top left
    path
      ..moveTo(rect.left, rect.top + _cornerLength)
      ..lineTo(rect.left, rect.top + _cornerRadius)
      ..arcToPoint(
        Offset(rect.left + _cornerRadius, rect.top),
        radius: const Radius.circular(_cornerRadius),
      )
      ..lineTo(rect.left + _cornerLength, rect.top);

    // Top right
    path
      ..moveTo(rect.right - _cornerLength, rect.top)
      ..lineTo(rect.right - _cornerRadius, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + _cornerRadius),
        radius: const Radius.circular(_cornerRadius),
      )
      ..lineTo(rect.right, rect.top + _cornerLength);

    // Bottom right
    path
      ..moveTo(rect.right, rect.bottom - _cornerLength)
      ..lineTo(rect.right, rect.bottom - _cornerRadius)
      ..arcToPoint(
        Offset(rect.right - _cornerRadius, rect.bottom),
        radius: const Radius.circular(_cornerRadius),
      )
      ..lineTo(rect.right - _cornerLength, rect.bottom);

    // Bottom left
    path
      ..moveTo(rect.left + _cornerLength, rect.bottom)
      ..lineTo(rect.left + _cornerRadius, rect.bottom)
      ..arcToPoint(
        Offset(rect.left, rect.bottom - _cornerRadius),
        radius: const Radius.circular(_cornerRadius),
      )
      ..lineTo(rect.left, rect.bottom - _cornerLength);

    return path;
  }

  @override
  bool shouldRepaint(covariant _QrScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow ||
        oldDelegate.borderColor != borderColor;
  }
}
