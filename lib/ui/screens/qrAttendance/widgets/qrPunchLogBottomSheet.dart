import 'package:eschool_saas_staff/cubits/qrAttendance/qrPunchLogCubit.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrPunchLog.dart';
import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:eschool_saas_staff/ui/widgets/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/errorContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Raw scan log of a single date — every punch as it was recorded, with the
/// distance the server measured.
///
/// Punch rows are purged one month after the attendance date, so an older date
/// legitimately comes back empty; that is shown as an empty state with the
/// retention note, never as an error.
class QrPunchLogBottomSheet extends StatelessWidget {
  final DateTime date;

  const QrPunchLogBottomSheet({super.key, required this.date});

  /// Opens the sheet for [date], with its own cubit scoped to the sheet.
  static Future<void> show({
    required BuildContext context,
    required DateTime date,
  }) {
    return Utils.showBottomSheet(
      context: context,
      child: BlocProvider(
        create: (_) => QrPunchLogCubit()..fetchPunches(date: date),
        child: QrPunchLogBottomSheet(date: date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
      titleLabelKey: scanLogKey,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: appContentHorizontalPadding,
          vertical: 15,
        ),
        child: BlocBuilder<QrPunchLogCubit, QrPunchLogState>(
          builder: (context, state) {
            if (state is QrPunchLogFetchInProgress ||
                state is QrPunchLogInitial) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is QrPunchLogFetchFailure) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ErrorContainer(
                  errorMessage: state.errorMessage,
                  showErrorImage: false,
                  onTapRetry: () =>
                      context.read<QrPunchLogCubit>().fetchPunches(date: date),
                ),
              );
            }

            final punchLog = (state as QrPunchLogFetchSuccess).punchLog;
            return _buildLog(context, punchLog);
          },
        ),
      ),
    );
  }

  Widget _buildLog(BuildContext context, QrPunchLog punchLog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextContainer(
          textKey: punchLog.formattedDate,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
        if (punchLog.isEmpty)
          _buildEmptyState(context)
        else
          ...punchLog.punches.map(
            (punch) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PunchEntryRow(punch: punch),
            ),
          ),
        const SizedBox(height: 5),
        CustomTextContainer(
          textKey: punchLogRetentionNoteKey,
          style: TextStyle(
            fontSize: 11.5,
            height: 16 / 11.5,
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomTextContainer(
        textKey: noPunchesForThisDateKey,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// A single recorded scan: direction, time and measured distance.
class _PunchEntryRow extends StatelessWidget {
  final QrPunchEntry punch;

  const _PunchEntryRow({required this.punch});

  @override
  Widget build(BuildContext context) {
    final bool isPunchIn = punch.type.isPunchIn;
    final Color accentColor = isPunchIn
        ? (Theme.of(context).extension<CustomColors>()?.successColor ??
            Theme.of(context).colorScheme.primary)
        : Theme.of(context).colorScheme.primary;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPunchIn ? Icons.login : Icons.logout,
              size: 14,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomTextContainer(
              textKey: isPunchIn ? punchInKey : punchOutKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: secondaryColor,
              ),
            ),
          ),
          Text(
            punch.formattedTime,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 13,
                color: secondaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 2),
              Text(
                punch.formattedDistance,
                style: TextStyle(
                  fontSize: 11.5,
                  color: secondaryColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
