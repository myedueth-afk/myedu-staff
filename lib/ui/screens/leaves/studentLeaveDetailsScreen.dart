import 'package:eschool_saas_staff/cubits/leave/updateStudentLeaveStatusCubit.dart';
import 'package:eschool_saas_staff/data/models/studentLeave.dart';
import 'package:eschool_saas_staff/data/models/studyMaterial.dart';
import 'package:eschool_saas_staff/ui/styles/colors.dart';
import 'package:eschool_saas_staff/ui/widgets/customAppbar.dart';
import 'package:eschool_saas_staff/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/customRoundedButton.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/rejectionReasonBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/studentLeaveRequestCard.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class StudentLeaveDetailsScreenArguments {
  final StudentLeave leave;

  StudentLeaveDetailsScreenArguments({required this.leave});
}

/// Full breakdown of one student leave with the approve/reject actions. Pops
/// with `true` once a decision was saved so the list can refresh.
class StudentLeaveDetailsScreen extends StatefulWidget {
  final StudentLeave leave;

  const StudentLeaveDetailsScreen({super.key, required this.leave});

  static Widget getRouteInstance() {
    final arguments = Get.arguments as StudentLeaveDetailsScreenArguments;

    return BlocProvider(
      create: (context) => UpdateStudentLeaveStatusCubit(),
      child: StudentLeaveDetailsScreen(leave: arguments.leave),
    );
  }

  static StudentLeaveDetailsScreenArguments buildArguments({
    required StudentLeave leave,
  }) {
    return StudentLeaveDetailsScreenArguments(leave: leave);
  }

  @override
  State<StudentLeaveDetailsScreen> createState() =>
      _StudentLeaveDetailsScreenState();
}

class _StudentLeaveDetailsScreenState extends State<StudentLeaveDetailsScreen> {
  /// Breathing room between the appbar and the first card.
  static const double _appbarToCardGap = 16.0;

  StudentLeave get _leave => widget.leave;

  static const TextStyle _valueTextStyle = TextStyle(
    color: Color(0xff212121),
    fontSize: 14.0,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
  );

  void _approve() {
    context.read<UpdateStudentLeaveStatusCubit>().updateStudentLeaveStatus(
          leaveId: _leave.id ?? 0,
          approveLeave: true,
        );
  }

  Future<void> _reject() async {
    final reason = await Utils.showBottomSheet(
      context: context,
      child: const RejectionReasonBottomsheet(),
    );

    if (reason is! String || reason.trim().isEmpty || !mounted) {
      return;
    }

    if (!context.mounted) return;
    context.read<UpdateStudentLeaveStatusCubit>().updateStudentLeaveStatus(
          leaveId: _leave.id ?? 0,
          approveLeave: false,
          note: reason,
        );
  }

  /// "09 July 2025 By Teacher" — the day the decision was taken and who took
  /// it. Either half can be missing, so the line adapts to what is there.
  String _actionOnValue() {
    final date = Utils.formatApiDate(_leave.actionDate);
    final name = (_leave.actionByName ?? "").trim();

    if (date.isEmpty && name.isEmpty) {
      return "-";
    }
    if (name.isEmpty) {
      return date;
    }
    if (date.isEmpty) {
      return name;
    }

    return "$date ${Utils.getTranslatedLabel(byKey)} $name";
  }

  Widget _buildRejectedReason() {
    return Container(
      width: double.maxFinite,
      margin: const EdgeInsets.only(top: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: leaveRejectedContainerColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentLeaveFieldLabel(labelKey: rejectedReasonKey),
          const SizedBox(height: 4.0),
          CustomTextContainer(
            textKey: _leave.note!.trim(),
            style: _valueTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final hasActionLine = !_leave.isPending;
    final hasRejectionNote =
        _leave.isRejected && (_leave.note ?? "").trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentLeaveHeader(leave: _leave),
          Divider(
            height: 25.0,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          if (hasActionLine) ...[
            CustomTextContainer(
              textKey:
                  "${Utils.getTranslatedLabel(_leave.isApproved ? approvedOnKey : rejectedOnKey)} : ${_actionOnValue()}",
              style: const TextStyle(
                color: labelColor,
                fontSize: 12.0,
                height: 16 / 12,
              ),
            ),
            const SizedBox(height: 12.0),
          ],
          if (hasRejectionNote) ...[
            _buildRejectedReason(),
            const SizedBox(height: 12.0),
          ],
          StudentLeaveDurationBox(leave: _leave),
          const SizedBox(height: 12.0),
          StudentLeaveFieldLabel(labelKey: reasonKey),
          const SizedBox(height: 4.0),
          CustomTextContainer(
            textKey: (_leave.reason ?? "").trim().isEmpty
                ? "-"
                : _leave.reason!.trim(),
            style: _valueTextStyle,
          ),
          const SizedBox(height: 12.0),
          CustomTextContainer(
            textKey:
                "${Utils.getTranslatedLabel(submittedOnKey)} : ${Utils.formatApiDate(_leave.createdAt).isEmpty ? "-" : Utils.formatApiDate(_leave.createdAt)}",
            style: const TextStyle(
              color: labelColor,
              fontSize: 12.0,
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(StudyMaterial attachment) {
    return Container(
      margin: const EdgeInsets.only(top: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: attachmentContainerColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomTextContainer(
              textKey: attachment.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _valueTextStyle,
            ),
          ),
          const SizedBox(width: 8.0),
          GestureDetector(
            onTap: () => Utils.openDownloadBottomsheet(
              context: context,
              studyMaterial: attachment,
            ),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 32.0,
              width: 32.0,
              decoration: BoxDecoration(
                color: tripTimelineGreenColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_rounded,
                size: 18.0,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextContainer(
            textKey: attachmentKey,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 14.0,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          ..._leave.attachments.map(_buildAttachmentRow),
        ],
      ),
    );
  }

  /// Only a pending request offers a decision. Once approved or rejected the
  /// screen is read-only here; changing a decision is done from the panel.
  Widget _buildActionButtons() {
    return BlocBuilder<UpdateStudentLeaveStatusCubit,
        UpdateStudentLeaveStatusState>(
      builder: (context, state) {
        final inProgress = state is UpdateStudentLeaveStatusInProgress;

        return Container(
          padding: EdgeInsets.only(
            left: appContentHorizontalPadding,
            right: appContentHorizontalPadding,
            top: 12.0,
            bottom: MediaQuery.of(context).padding.bottom + 12.0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.tertiary),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, boxConstraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: boxConstraints.maxWidth * (0.48),
                    child: CustomRoundedButton(
                      onTap: inProgress ? null : _reject,
                      height: 48.0,
                      widthPercentage: 1.0,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      buttonTitle: rejectKey,
                      titleColor: Theme.of(context).colorScheme.error,
                      borderColor: Theme.of(context).colorScheme.error,
                      showBorder: true,
                      radius: 8.0,
                    ),
                  ),
                  SizedBox(
                    width: boxConstraints.maxWidth * (0.48),
                    child: CustomRoundedButton(
                      onTap: inProgress ? null : _approve,
                      height: 48.0,
                      widthPercentage: 1.0,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      buttonTitle: approveKey,
                      showBorder: false,
                      radius: 8.0,
                      child: inProgress
                          ? const CustomCircularProgressIndicator()
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _leave.isPending ? _buildActionButtons() : null,
      body: BlocListener<UpdateStudentLeaveStatusCubit,
          UpdateStudentLeaveStatusState>(
        listener: (context, state) {
          if (state is UpdateStudentLeaveStatusSuccess) {
            Utils.showSnackBar(
              context: context,
              message: Utils.getTranslatedLabel(
                state.updatedStatus == StudentLeaveStatus.approved
                    ? leaveApprovedSuccessfullyKey
                    : leaveRejectedSuccessfullyKey,
              ),
            );
            //the snackbar is hosted by the app-level ScaffoldMessenger, so it
            //stays visible after this screen pops
            Get.back(result: true);
          }

          if (state is UpdateStudentLeaveStatusFailure) {
            Utils.showSnackBar(
              context: context,
              message: state.errorMessage,
            );
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                left: appContentHorizontalPadding,
                right: appContentHorizontalPadding,
                bottom: 25.0,
                //keeps the first card off the appbar's bottom edge
                top: Utils.appContentTopScrollPadding(context: context) +
                    _appbarToCardGap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailsCard(),
                  if (_leave.attachments.isNotEmpty) _buildAttachmentsCard(),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.topCenter,
              child: CustomAppbar(titleKey: leaveDetailsKey),
            ),
          ],
        ),
      ),
    );
  }
}
