import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/app/schoolBuildConfig.dart';
import 'package:eschool_saas_staff/cubits/appConfigurationCubit.dart';
import 'package:eschool_saas_staff/cubits/appLocalizationCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/homeScreenDataCubit.dart';
import 'package:eschool_saas_staff/cubits/task/homeTasksCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/teacherMyTimetableCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/errorContainer.dart';
import 'package:eschool_saas_staff/utils/systemModulesAndPermissions.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();

  static Widget getRouteInstance() => const SplashScreen();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Prevents double-navigation if the app-config listener fires more than once.
  bool _navigationStarted = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        // Refresh panel-managed languages/labels in the background; the app
        // keeps running on bundled/cached labels if this fails (e.g. offline).
        context.read<AppLocalizationCubit>().syncRemoteLocalization();
        context.read<AppConfigurationCubit>().fetchAppConfiguration();
      }
    });
  }

  // ─── Navigation flow ────────────────────────────────────────────────────────

  /// Entry point after app config succeeds.
  ///
  /// Order of operations:
  ///   1. Unauthenticated → login. No home data needed.
  ///   2. Authenticated → wait for permissions (required before reading module
  ///      flags for home data).
  ///   3. Fire home data + tasks + timetable in parallel (all global cubits).
  ///   4. Navigate to home — data arrives during transition, zero in-screen load.
  Future<void> _prefetchAndNavigate() async {
    if (_navigationStarted) return;
    _navigationStarted = true;

    if (!mounted) return;

    final authCubit = context.read<AuthCubit>();
    if (authCubit.state is Unauthenticated) {
      Get.offNamed(Routes.loginScreen);
      return;
    }

    final permCubit = context.read<StaffAllowedPermissionsAndModulesCubit>();
    await _ensurePermissionsLoaded(permCubit);

    if (!mounted) return;

    _fireHomePreloads(permCubit, authCubit);

    Get.offNamed(Routes.homeScreen);
  }

  /// Waits for permissions to reach a terminal state (success or failure).
  ///
  /// Uses the cubit stream — no polling, no arbitrary delays.
  /// If permissions are already in memory (idempotency guard skipped the
  /// fetch), the stream won't emit again so we check state first.
  Future<void> _ensurePermissionsLoaded(
    StaffAllowedPermissionsAndModulesCubit permCubit,
  ) async {
    if (permCubit.state is StaffAllowedPermissionsAndModulesFetchSuccess) {
      return;
    }

    permCubit.getPermissionAndAllowedModules();

    await permCubit.stream.firstWhere(
      (s) =>
          s is StaffAllowedPermissionsAndModulesFetchSuccess ||
          s is StaffAllowedPermissionsAndModulesFetchFailure,
    );
  }

  /// Fires all home-screen prefetches in parallel.
  ///
  /// All cubits are global so their state survives to the home screen render.
  /// Idempotency guards on each cubit make repeated calls safe (e.g. if the
  /// permission listener on homeContainer fires after we already loaded data).
  void _fireHomePreloads(
    StaffAllowedPermissionsAndModulesCubit permCubit,
    AuthCubit authCubit,
  ) {
    final isTeacher = authCubit.isTeacher();

    // Re-sync the stored user details with the server so profile changes made
    // from the admin panel show up without a re-login.
    authCubit.refreshProfile();

    context.read<HomeScreenDataCubit>().getHomeScreenData(
          isTeacher: isTeacher,
          holidayModuleEnabled: permCubit.isModuleEnabled(
              moduleId: holidayManagementModuleId.toString()),
          staffLeaveModuleEnabled: permCubit.isModuleEnabled(
              moduleId: staffLeaveManagementModuleId.toString()),
          listTeacherTimetablePermission: permCubit.isPermissionGiven(
              permission: viewTeachersPermissionKey),
        );

    context.read<HomeTasksCubit>().getTasks(type: 'my_tasks');

    // Timetable is teacher-only and module-gated.
    if (isTeacher &&
        permCubit.isModuleEnabled(
            moduleId: timetableManagementModuleId.toString())) {
      context
          .read<TeacherMyTimetableCubit>()
          .getTeacherMyTimetable(isRefresh: true);
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolBuildConfig.hasSplashLogo
          ? const Color(SchoolBuildConfig.splashBackgroundValue)
          : Theme.of(context).colorScheme.primary,
      body: BlocConsumer<AppConfigurationCubit, AppConfigurationState>(
        listener: (context, state) {
          if (state is AppConfigurationFetchSuccess) {
            _prefetchAndNavigate();
          }
        },
        builder: (context, state) {
          if (state is AppConfigurationFetchFailure) {
            return Center(
              child: ErrorContainer(
                errorMessage: state.errorMessage,
                onTapRetry: () {
                  // Reset guard so user can retry the full flow.
                  _navigationStarted = false;
                  context.read<AppLocalizationCubit>().syncRemoteLocalization();
                  context.read<AppConfigurationCubit>().fetchAppConfiguration();
                },
                retryButtonTextColor: Theme.of(context).colorScheme.onSurface,
              ),
            );
          }
          return Center(
            child: SchoolBuildConfig.hasSplashLogo
                ? Image.asset(
                    SchoolBuildConfig.splashLogoAsset,
                    width: SchoolBuildConfig.splashLogoWidth.toDouble(),
                  )
                : Image.asset(Utils.getImagePath("splash_logo.png")),
          );
        },
      ),
    );
  }
}
