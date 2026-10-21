import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:flutter/material.dart';

/// Coloured status pill of a finalized attendance day.
///
/// All six day types are handled: QR finalization only ever produces absent,
/// present, half day or holiday, but an administrator's correction can leave a
/// day marked as first or second half present.
class QrAttendanceDayTypePill extends StatelessWidget {
  final QrAttendanceDayType dayType;

  const QrAttendanceDayTypePill({super.key, required this.dayType});

  /// Amber, matching the "needs attention" tone used elsewhere in the app.
  static const Color _partialDayColor = Color(0xFFF89E1B);

  static Color colorOf(BuildContext context, QrAttendanceDayType dayType) {
    switch (dayType) {
      case QrAttendanceDayType.present:
        return Theme.of(context).extension<CustomColors>()?.successColor ??
            Theme.of(context).colorScheme.primary;
      case QrAttendanceDayType.absent:
        return Theme.of(context).colorScheme.error;
      case QrAttendanceDayType.halfDay:
      case QrAttendanceDayType.firstHalfPresent:
      case QrAttendanceDayType.secondHalfPresent:
        return _partialDayColor;
      case QrAttendanceDayType.holiday:
        return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.45);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = colorOf(context, dayType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomTextContainer(
        textKey: dayType.labelKey,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
