import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/app/schoolBuildConfig.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/sendPasswordResetEmailCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/signInCubit.dart';
import 'package:eschool_saas_staff/ui/screens/login/widgets/forgotPasswordBottomsheet.dart';

import 'package:eschool_saas_staff/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/customRoundedButton.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextButton.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextFieldContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/schoolCodeFieldContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/showHidePasswordButton.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:eschool_saas_staff/utils/unauthenticatedAccessManager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static Widget getRouteInstance() => BlocProvider(
        create: (context) => SignInCubit(),
        child: const LoginScreen(),
      );

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const MethodChannel _autofillChannel = MethodChannel('et.myedu/autofill');

  late bool _hidePassword = true;
  var canPop = false;

  late final _schoolCodeController = TextEditingController(
      text: SchoolBuildConfig.hasFixedSchoolCode
          ? SchoolBuildConfig.schoolCode
          : (showDefaultCredentials ? defaultSchoolCode : ''));

  late final TextEditingController _emailTextEditingController =
      TextEditingController(text: showDefaultCredentials ? defaultEmail : '');

  late final TextEditingController _passwordTextEditingController =
      TextEditingController(
          text: showDefaultCredentials ? defaultPassword : '');

  @override
  void initState() {
    super.initState();
    _checkAutofill();
    _autofillChannel.setMethodCallHandler(_handleAutofillCall);
  }

  Future<dynamic> _handleAutofillCall(MethodCall call) async {
    if (call.method == 'onAutofillReceived') {
      final data = call.arguments;
      if (data is Map) {
        _applyAutofill(Map<String, dynamic>.from(data));
      }
    }
  }

  Future<void> _checkAutofill() async {
    try {
      final res = await _autofillChannel.invokeMethod('getAutofillCredentials');
      if (res != null && res is Map) {
        _applyAutofill(Map<String, dynamic>.from(res));
      }
    } catch (_) {}
  }

  void _applyAutofill(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      if (data['school_code'] != null && data['school_code'].toString().isNotEmpty) {
        _schoolCodeController.text = data['school_code'].toString();
      }
      if (data['username'] != null && data['username'].toString().isNotEmpty) {
        _emailTextEditingController.text = data['username'].toString();
      }
      if (data['password'] != null && data['password'].toString().isNotEmpty) {
        _passwordTextEditingController.text = data['password'].toString();
      }
    });
  }

  @override
  void dispose() {
    _schoolCodeController.dispose();
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    super.dispose();
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SafeArea(
        child: CustomTextButton(
            textStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary, fontSize: 16.0),
            buttonTextKey: forgotPasswordKey,
            onTapButton: () {
              if (context.read<SignInCubit>().state is SignInInProgress) {
                return;
              }
              Utils.showBottomSheet(
                  child: BlocProvider(
                    create: (context) => SendPasswordResetEmailCubit(),
                    child: const ForgotPasswordBottomsheet(),
                  ),
                  context: context);
            }),
      ),
    );
  }

  Widget _buildTermsConditionAndPrivacyPolicyContainer() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomTextContainer(
            textKey: bySignInYouAgreeToOurKey,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextButton(
                onTapButton: () {
                  if (context.read<SignInCubit>().state is SignInInProgress) {
                    return;
                  }
                  Get.toNamed(Routes.termsAndConditionScreen);
                },
                buttonTextKey: termsAndConditionKey,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                child: CustomTextContainer(textKey: andKey),
              ),
              CustomTextButton(
                onTapButton: () {
                  if (context.read<SignInCubit>().state is SignInInProgress) {
                    return;
                  }

                  Get.toNamed(Routes.privacyPolicyScreen);
                },
                buttonTextKey: privacyPolicyKey,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  void _onWillPop() {
    setState(() {
      canPop = true;
    });
    Utils.showSnackBar(
      message: pressbackagaintoexitKey,
      context: context,
    ); // Do not exit the app
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        canPop = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                    left: appContentHorizontalPadding,
                    right: appContentHorizontalPadding,
                    top: MediaQuery.of(context).padding.top),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 75),
                    const CustomTextContainer(
                      textKey: letSignInKey,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    const CustomTextContainer(
                      textKey: signInScreenSubTitleKey,
                      style: TextStyle(fontSize: 16.0, height: 1.1),
                    ),
                    const SizedBox(height: 20),
                    /// School code field — hidden on a single-school build
                    SchoolCodeFieldContainer(
                      textEditingController: _schoolCodeController,
                    ),
                    CustomTextFieldContainer(
                      prefixWidget: Icon(
                        Icons.email_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      textEditingController: _emailTextEditingController,
                      hintTextKey: emailKey,
                    ),
                    CustomTextFieldContainer(
                      prefixWidget: Icon(
                        Icons.lock_outline,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      textEditingController: _passwordTextEditingController,
                      hintTextKey: passwordKey,
                      hideText: _hidePassword,
                      suffixWidget: ShowHidePasswordButton(
                          hidePassword: _hidePassword,
                          onTapButton: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          }),
                    ),
                    SafeArea(child: _buildForgotPasswordButton()),
                    const SizedBox(height: 25),
                    BlocConsumer<SignInCubit, SignInState>(
                      listener: (context, state) {
                        if (state is SignInSuccess) {
                          context.read<AuthCubit>().authenticateUser(
                                authToken: state.authToken,
                                schoolCode: state.schoolCode,
                                userDetails: state.userDetails,
                              );
                          // Unblock API calls after successful re-login
                          UnauthenticatedAccessManager()
                              .onUserAuthenticated();
                          Get.offNamed(Routes.onbordingScreen);
                        } else if (state is SignInFailure) {
                          Utils.showSnackBar(
                              message: state.errorMessage, context: context);
                        }
                      },
                      builder: (context, state) {
                        return PopScope(
                          canPop: state is! SignInInProgress,
                          child: CustomRoundedButton(
                            widthPercentage: 1.0,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            buttonTitle: signInKey,
                            showBorder: false,
                            child: state is SignInInProgress
                                ? const CustomCircularProgressIndicator()
                                : null,
                            onTap: () {
                              if (state is SignInInProgress) {
                                return;
                              }

                              final schoolCode =
                                  SchoolBuildConfig.resolveSchoolCode(
                                      _schoolCodeController.text);

                              if (schoolCode.isEmpty) {
                                Utils.showSnackBar(
                                  message: pleaseEnterSchoolCodeKey,
                                  context: context,
                                );
                                return;
                              }

                              if (_emailTextEditingController.text
                                  .trim()
                                  .isEmpty) {
                                Utils.showSnackBar(
                                    message: pleaseEnterEmailKey,
                                    context: context);
                                return;
                              }
                              if (_passwordTextEditingController.text
                                  .trim()
                                  .isEmpty) {
                                Utils.showSnackBar(
                                    message: pleaseEnterPasswordKey,
                                    context: context);
                                return;
                              }

                              context.read<SignInCubit>().signInUser(
                                    email:
                                        _emailTextEditingController.text.trim(),
                                    password: _passwordTextEditingController
                                        .text
                                        .trim(),
                                    schoolCode: schoolCode,
                                  );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SafeArea(child: _buildTermsConditionAndPrivacyPolicyContainer()),
            ],
          )),
    );
  }
}
