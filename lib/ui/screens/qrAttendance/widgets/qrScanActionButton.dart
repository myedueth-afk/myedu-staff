import 'dart:async';

import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';

/// Primary call to action of the QR attendance screen.
///
/// Its label follows the server's `next_action` — the app never guesses whether
/// the next scan is an in or an out. After a successful punch the button counts
/// down [cooldownUntil] so the staff member cannot hit the server's cooldown
/// window by accident.
class QrScanActionButton extends StatefulWidget {
  final QrPunchType nextAction;

  /// Set while the location is being read or a punch is in flight.
  final bool isBusy;

  /// Label shown instead of the title while [isBusy] is set.
  final String? busyLabelKey;

  /// Moment the cooldown expires. Null once scanning is allowed again.
  final DateTime? cooldownUntil;

  final VoidCallback onTap;

  const QrScanActionButton({
    super.key,
    required this.nextAction,
    required this.onTap,
    this.isBusy = false,
    this.busyLabelKey,
    this.cooldownUntil,
  });

  @override
  State<QrScanActionButton> createState() => _QrScanActionButtonState();
}

class _QrScanActionButtonState extends State<QrScanActionButton> {
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _syncCooldownTimer();
  }

  @override
  void didUpdateWidget(covariant QrScanActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cooldownUntil != widget.cooldownUntil) {
      _syncCooldownTimer();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Runs a one second tick only while a cooldown is actually pending.
  void _syncCooldownTimer() {
    _cooldownTimer?.cancel();
    if (_remainingCooldownSeconds == 0) return;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingCooldownSeconds == 0) {
        timer.cancel();
      }
      setState(() {});
    });
  }

  int get _remainingCooldownSeconds {
    final cooldownUntil = widget.cooldownUntil;
    if (cooldownUntil == null) return 0;
    final remaining = cooldownUntil.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  bool get _isDisabled => widget.isBusy || _remainingCooldownSeconds > 0;

  String get _label {
    if (widget.isBusy) {
      return Utils.getTranslatedLabel(widget.busyLabelKey ?? recordingPunchKey);
    }
    final remaining = _remainingCooldownSeconds;
    if (remaining > 0) {
      return Utils.getTranslatedLabel(waitBeforeNextScanKey)
          .replaceAll('@seconds', remaining.toString());
    }
    return Utils.getTranslatedLabel(
      widget.nextAction.isPunchIn ? scanToPunchInKey : scanToPunchOutKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color backgroundColor =
        _isDisabled ? primaryColor.withValues(alpha: 0.4) : primaryColor;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isDisabled ? null : widget.onTap,
        child: Container(
          height: 52,
          width: double.maxFinite,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isBusy)
                const CustomCircularProgressIndicator(widthAndHeight: 18)
              else
                const Icon(Icons.qr_code_scanner,
                    size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(
                child: CustomTextContainer(
                  textKey: _label,
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
        ),
      ),
    );
  }
}
