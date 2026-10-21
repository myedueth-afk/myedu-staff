import 'package:eschool_saas_staff/cubits/qrAttendance/qrAttendanceHistoryCubit.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceHistory.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceUtils.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrAttendanceHistoryRow.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrAttendanceSummaryCard.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrPunchLogBottomSheet.dart';
import 'package:eschool_saas_staff/ui/widgets/customAppbar.dart';
import 'package:eschool_saas_staff/ui/widgets/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/monthSelectorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/noDataContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The staff member's own finalized QR attendance, one month at a time.
///
/// This is the permanent record: raw scans are purged after a month, but the
/// finalized days stay, so this screen is what history questions are answered
/// from.
class QrAttendanceHistoryScreen extends StatefulWidget {
  const QrAttendanceHistoryScreen._();

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (_) => QrAttendanceHistoryCubit(),
      child: const QrAttendanceHistoryScreen._(),
    );
  }

  @override
  State<QrAttendanceHistoryScreen> createState() =>
      _QrAttendanceHistoryScreenState();
}

class _QrAttendanceHistoryScreenState extends State<QrAttendanceHistoryScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    Future.delayed(Duration.zero, _fetchHistory);
  }

  void _fetchHistory() {
    context.read<QrAttendanceHistoryCubit>().fetchMonth(_selectedMonth);
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
    _fetchHistory();
  }

  /// Future months hold nothing to show, so the forward arrow stops at the
  /// current one.
  bool get _isNextMonthDisabled {
    final now = DateTime.now();
    return _selectedMonth.year >= now.year && _selectedMonth.month >= now.month;
  }

  void _openScanLog(QrAttendanceHistoryRow row) {
    final date = QrAttendanceUtils.parseServerDateTime(row.date);
    if (date == null) return;
    QrPunchLogBottomSheet.show(context: context, date: date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(titleKey: attendanceHistoryKey),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              appContentHorizontalPadding,
              appContentHorizontalPadding,
              appContentHorizontalPadding,
              0,
            ),
            child: MonthSelectorWidget(
              selectedDate: _selectedMonth,
              onPreviousMonth: () => _changeMonth(-1),
              onNextMonth: () => _changeMonth(1),
              isPreviousMonthDisabled: false,
              isNextMonthDisabled: _isNextMonthDisabled,
            ),
          ),
          Expanded(
            child:
                BlocBuilder<QrAttendanceHistoryCubit, QrAttendanceHistoryState>(
              builder: (context, state) {
                if (state is QrAttendanceHistoryFetchInProgress ||
                    state is QrAttendanceHistoryInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is QrAttendanceHistoryFetchFailure) {
                  return ErrorContainer(
                    errorMessage: state.errorMessage,
                    onTapRetry: _fetchHistory,
                  );
                }

                return _buildHistory(
                    (state as QrAttendanceHistoryFetchSuccess).history);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The month's totals stay pinned under the month selector while only the
  /// days scroll: the summary answers "how did this month go", which is the
  /// question the screen exists for, and scrolling it away to read the days
  /// means losing the figures they add up to.
  Widget _buildHistory(QrAttendanceHistory history) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            appContentHorizontalPadding,
            appContentHorizontalPadding,
            appContentHorizontalPadding,
            15,
          ),
          child: QrAttendanceSummaryCard(summary: history.summary),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _fetchHistory(),
            child: ListView(
              // With the summary pinned above, a quiet month leaves too few
              // rows to fill the viewport — and a list that cannot overscroll
              // never fires the pull to refresh gesture.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                appContentHorizontalPadding,
                0,
                appContentHorizontalPadding,
                appContentHorizontalPadding,
              ),
              children: [
                if (history.rows.isEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: const noDataContainer(titleKey: noDataFoundKey),
                  )
                else
                  ...history.rows.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: QrAttendanceHistoryRowCard(
                        row: row,
                        onTap: () => _openScanLog(row),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
