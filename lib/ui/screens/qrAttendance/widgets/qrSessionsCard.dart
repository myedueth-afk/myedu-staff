import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceToday.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrSessionRow.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextButton.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:flutter/material.dart';

/// Today's punch in -> punch out pairs, plus the session still open, if any.
///
/// Gaps between sessions are breaks and are excluded from the counted minutes
/// by the server, so only the sessions themselves are listed.
class QrSessionsCard extends StatelessWidget {
  final QrAttendanceToday today;
  final VoidCallback onTapScanLog;

  const QrSessionsCard({
    super.key,
    required this.today,
    required this.onTapScanLog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(appContentHorizontalPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.tertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextContainer(
                  textKey: todaysSessionsKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CustomTextButton(
                buttonTextKey: viewScanLogKey,
                textStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTapButton: onTapScanLog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!today.hasAnyActivity)
            _buildEmptyState(context)
          else
            ..._buildSessionRows(),
        ],
      ),
    );
  }

  List<Widget> _buildSessionRows() {
    final rows = <Widget>[];

    for (var index = 0; index < today.sessions.length; index++) {
      rows.add(QrSessionRow(
        index: index + 1,
        session: today.sessions[index],
        isLast: index == today.sessions.length - 1 && today.openSession == null,
      ));
    }

    if (today.openSession != null) {
      rows.add(QrSessionRow.open(
        index: today.sessions.length + 1,
        punchInTime: today.formattedOpenSessionTime,
      ));
    }

    return rows;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomTextContainer(
        textKey: noSessionsYetKey,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5,
          height: 18 / 12.5,
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
