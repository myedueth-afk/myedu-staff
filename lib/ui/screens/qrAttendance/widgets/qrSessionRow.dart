import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceToday.dart';
import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:flutter/material.dart';

/// One row of the sessions timeline: a numbered marker, the in -> out times and
/// how long the session lasted.
///
/// The [QrSessionRow.open] variant renders a session that has a punch in but no
/// punch out yet — the server never invents the missing punch, so the row stays
/// open until the staff member scans again.
class QrSessionRow extends StatelessWidget {
  final int index;
  final QrAttendanceSession? session;
  final String? openPunchInTime;
  final bool isLast;

  const QrSessionRow({
    super.key,
    required this.index,
    required QrAttendanceSession this.session,
    this.isLast = false,
  }) : openPunchInTime = null;

  const QrSessionRow.open({
    super.key,
    required this.index,
    required String punchInTime,
  })  : session = null,
        openPunchInTime = punchInTime,
        isLast = true;

  bool get _isOpen => session == null;

  @override
  Widget build(BuildContext context) {
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color accentColor = _isOpen
        ? (Theme.of(context).extension<CustomColors>()?.successColor ??
            Theme.of(context).colorScheme.primary)
        : Theme.of(context).colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineMarker(context, accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTimes(context, secondaryColor)),
                      const SizedBox(width: 8),
                      _buildDurationChip(context, accentColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMarker(BuildContext context, Color accentColor) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            index.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              width: 1.5,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
      ],
    );
  }

  Widget _buildTimes(BuildContext context, Color secondaryColor) {
    final TextStyle timeStyle = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: secondaryColor,
    );

    if (_isOpen) {
      return Row(
        children: [
          Text(openPunchInTime ?? "", style: timeStyle),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward,
              size: 14, color: secondaryColor.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          Text(
            "--:--",
            style: timeStyle.copyWith(
              color: secondaryColor.withValues(alpha: 0.4),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(session!.formattedPunchInTime, style: timeStyle),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward,
            size: 14, color: secondaryColor.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        Text(session!.formattedPunchOutTime, style: timeStyle),
      ],
    );
  }

  Widget _buildDurationChip(BuildContext context, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: _isOpen
          ? CustomTextContainer(
              textKey: sessionInProgressKey,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: accentColor,
              ),
            )
          : Text(
              session!.formattedDuration,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: accentColor,
              ),
            ),
    );
  }
}
