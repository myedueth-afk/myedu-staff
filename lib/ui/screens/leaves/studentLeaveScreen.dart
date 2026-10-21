import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/leave/studentLeavesCubit.dart';
import 'package:eschool_saas_staff/data/models/classSection.dart';
import 'package:eschool_saas_staff/data/models/studentLeave.dart';
import 'package:eschool_saas_staff/ui/screens/leaves/studentLeaveDetailsScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/appbarFilterBackgroundContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/customAppbar.dart';
import 'package:eschool_saas_staff/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/filterButton.dart';
import 'package:eschool_saas_staff/ui/widgets/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/noDataContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/searchContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/studentLeaveRequestCard.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

/// Review queue for student leave requests. The backend scopes the list to what
/// the signed-in user may act on, so this screen serves both a class teacher
/// (their own classes) and an admin/principal (the whole school).
class StudentLeaveScreen extends StatefulWidget {
  const StudentLeaveScreen({super.key});

  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => StudentLeavesCubit()),
        BlocProvider(create: (context) => ClassesCubit()),
      ],
      child: const StudentLeaveScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<StudentLeaveScreen> createState() => _StudentLeaveScreenState();
}

class _StudentLeaveScreenState extends State<StudentLeaveScreen> {
  static const double _filterRowHeight = 40.0;

  /// SearchContainer is 50 tall and sits inside a 1px border on each side.
  static const double _searchFieldHeight = 52.0;

  static const double _filterRowToSearchGap = 16.0;

  /// Breathing room between the pinned header and the first card, so the card
  /// does not sit flush against the header's bottom border.
  static const double _headerToListGap = 16.0;

  /// AppbarFilterBackgroundContainer draws a 1px border on its top and bottom
  /// edges, and those eat into the height it is given.
  static const double _headerBorderHeight = 2.0;

  /// Derived from the header's actual contents rather than hard coded, so the
  /// list padding below stays in step with any change to the rows above.
  double get _headerHeight =>
      (appContentHorizontalPadding * 2) +
      _headerBorderHeight +
      _filterRowHeight +
      _filterRowToSearchGap +
      _searchFieldHeight;

  final TextEditingController _searchTextEditingController =
      TextEditingController();

  /// null means "All Status" / "All Classes".
  StudentLeaveStatus? _selectedStatus;
  ClassSection? _selectedClassSection;

  @override
  void initState() {
    super.initState();
    //SearchContainer only reports the clear button, so the query is watched
    //here to re-filter as the reviewer types
    _searchTextEditingController.addListener(_onSearchQueryChanged);
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<StudentLeavesCubit>().getStudentLeaves();
        context.read<ClassesCubit>().getClasses();
      }
    });
  }

  @override
  void dispose() {
    _searchTextEditingController.removeListener(_onSearchQueryChanged);
    _searchTextEditingController.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _fetchLeaves() {
    context.read<StudentLeavesCubit>().getStudentLeaves(
          classSectionId: _selectedClassSection?.id,
        );
  }

  /// Status and search are applied on the loaded list so switching them feels
  /// instant. The class filter round-trips instead, since the backend owns
  /// which classes the user may see.
  List<StudentLeave> _visibleLeaves(List<StudentLeave> leaves) {
    return leaves
        .where((leave) =>
            (_selectedStatus == null || leave.leaveStatus == _selectedStatus) &&
            leave.matchesSearchQuery(_searchTextEditingController.text))
        .toList();
  }

  String _statusLabel(StudentLeaveStatus? status) {
    switch (status) {
      case StudentLeaveStatus.pending:
        return Utils.getTranslatedLabel(pendingKey);
      case StudentLeaveStatus.approved:
        return Utils.getTranslatedLabel(approvedKey);
      case StudentLeaveStatus.rejected:
        return Utils.getTranslatedLabel(rejectedKey);
      case null:
        return Utils.getTranslatedLabel(allStatusKey);
    }
  }

  void _showStatusFilter() {
    const statuses = <StudentLeaveStatus?>[
      null,
      StudentLeaveStatus.pending,
      StudentLeaveStatus.approved,
      StudentLeaveStatus.rejected,
    ];
    final labels = statuses.map(_statusLabel).toList();

    Utils.showBottomSheet(
      context: context,
      child: FilterSelectionBottomsheet<String>(
        titleKey: statusKey,
        values: labels,
        selectedValue: _statusLabel(_selectedStatus),
        onSelection: (value) {
          Get.back();
          final index = labels.indexOf(value ?? "");
          if (index != -1) {
            setState(() => _selectedStatus = statuses[index]);
          }
        },
      ),
    );
  }

  /// Classes the signed-in user may filter by. A teacher only reviews the
  /// classes they are class teacher of, which is what `primaryClasses` holds —
  /// the same source the add attendance screen uses. Other staff
  /// (admin/principal) review every class in the school.
  List<ClassSection> get _selectableClasses {
    final classesCubit = context.read<ClassesCubit>();

    if (classesCubit.state is! ClassesFetchSuccess) {
      return [];
    }

    return context.read<AuthCubit>().isTeacher()
        ? (classesCubit.state as ClassesFetchSuccess).primaryClasses
        : classesCubit.getAllClasses();
  }

  void _showClassFilter() {
    final classes = _selectableClasses;
    if (classes.isEmpty) {
      return;
    }

    //a null entry stands for "All Classes" and clears the class filter
    final values = <ClassSection?>[null, ...classes];

    Utils.showBottomSheet(
      context: context,
      child: FilterSelectionBottomsheet<String>(
        titleKey: classKey,
        values: values
            .map((value) =>
                value?.fullName ?? Utils.getTranslatedLabel(allClassesKey))
            .toList(),
        selectedValue: _selectedClassSection?.fullName ??
            Utils.getTranslatedLabel(allClassesKey),
        onSelection: (value) {
          Get.back();
          final index = values
              .map((element) =>
                  element?.fullName ?? Utils.getTranslatedLabel(allClassesKey))
              .toList()
              .indexOf(value ?? "");
          if (index != -1) {
            setState(() => _selectedClassSection = values[index]);
            _fetchLeaves();
          }
        },
      ),
    );
  }

  Widget _buildFiltersAndSearch() {
    return AppbarFilterBackgroundContainer(
      height: _headerHeight,
      child: Column(
        children: [
          //FilterButton sizes itself to the full height it is given, so the row
          //needs an explicit one inside this Column
          SizedBox(
            height: _filterRowHeight,
            child: LayoutBuilder(
              builder: (context, boxConstraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilterButton(
                      onTap: _showStatusFilter,
                      titleKey: _statusLabel(_selectedStatus),
                      width: boxConstraints.maxWidth * (0.48),
                    ),
                    FilterButton(
                      onTap: _showClassFilter,
                      titleKey:
                          _selectedClassSection?.fullName ?? allClassesKey,
                      width: boxConstraints.maxWidth * (0.48),
                    ),
                  ],
                );
              },
            ),
          ),
          //the header and the search field are both white, so the field needs
          //its own border to stay visible against it
          Container(
            margin: const EdgeInsets.only(top: 16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.tertiary),
              borderRadius: BorderRadius.circular(8.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: SearchContainer(
              textEditingController: _searchTextEditingController,
              margin: EdgeInsets.zero,
              additionalCallback: _onSearchQueryChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLeaveDetails(StudentLeave leave) async {
    final didUpdate = await Get.toNamed(
      Routes.studentLeaveDetailsScreen,
      arguments: StudentLeaveDetailsScreen.buildArguments(leave: leave),
    );

    //the details screen returns true once a decision was saved
    if (didUpdate == true && mounted) {
      _fetchLeaves();
    }
  }

  Widget _buildLeaves() {
    return BlocBuilder<StudentLeavesCubit, StudentLeavesState>(
      builder: (context, state) {
        if (state is StudentLeavesFetchSuccess) {
          final leaves = _visibleLeaves(state.leaves);

          if (leaves.isEmpty) {
            return Center(
              child: noDataContainer(titleKey: noStudentLeavesFoundKey),
            );
          }

          return ListView.builder(
            itemCount: leaves.length,
            padding: EdgeInsets.only(
              left: appContentHorizontalPadding,
              right: appContentHorizontalPadding,
              bottom: 25.0,
              top: Utils.appContentTopScrollPadding(context: context) +
                  _headerHeight +
                  _headerToListGap,
            ),
            itemBuilder: (context, index) => StudentLeaveRequestCard(
              leave: leaves[index],
              onTap: () => _openLeaveDetails(leaves[index]),
            ),
          );
        }

        if (state is StudentLeavesFetchFailure) {
          return Center(
            child: ErrorContainer(
              errorMessage: state.errorMessage,
              onTapRetry: _fetchLeaves,
            ),
          );
        }

        return Center(
          child: CustomCircularProgressIndicator(
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildLeaves(),
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                const CustomAppbar(titleKey: studentLeaveKey),
                _buildFiltersAndSearch(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
