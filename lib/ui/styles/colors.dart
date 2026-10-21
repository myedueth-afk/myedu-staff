import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:flutter/material.dart';

//Replace these colors accoridng to ui
//Brand palette, overridable per school by the School Builder addon. Every
//default is the stock value, so a plain `flutter run` is unchanged, and these
//stay assignable exactly as before — only where the first value comes from moved.
Color primaryColor = const Color(
  int.fromEnvironment('SCHOOL_COLOR_PRIMARY', defaultValue: 0xff29638A),
);
Color secondaryColor = const Color(
  int.fromEnvironment('SCHOOL_COLOR_SECONDARY', defaultValue: 0xff1A1C1D),
);
Color pageBackgroundColor = const Color(
  int.fromEnvironment('SCHOOL_COLOR_PAGE_BACKGROUND', defaultValue: 0xffF7F9FF),
);
Color backgroundColor = const Color(
  int.fromEnvironment('SCHOOL_COLOR_BACKGROUND', defaultValue: 0xffFFFFFF),
);
Color errorColor = const Color(
  int.fromEnvironment('SCHOOL_COLOR_ERROR', defaultValue: 0xffBA1A1A),
);
Color tertiaryColor = const Color(
  int.fromEnvironment('SCHOOL_COLOR_TERTIARY', defaultValue: 0xffEBEEF3),
); //Border color define in design style

Color tripTimelineGreenColor = const Color(0xff57CC99);

//muted label grey used for secondary lines on the student leave cards
const Color labelColor = Color(0xff6D6E6F);

//caption grey used for field labels on the student leave cards
const Color captionColor = Color(0xff9F9F9F);

//student leave status chips. Each status pairs a tinted container with the
//matching solid text color, per the Message/* tokens in the design.
const Color leavePendingColor = Color(0xffF89E1B);
const Color leavePendingContainerColor = Color(0xffFEEED7);
const Color leaveApprovedColor = Color(0xff56B35A);
const Color leaveApprovedContainerColor = Color(0xffDFF6E2);
const Color leaveRejectedColor = Color(0xffBA1A1A);
const Color leaveRejectedContainerColor = Color(0xffF9D2D2);

//attachment row on the student leave details screen
const Color attachmentContainerColor = Color(0xffE0F5EC);

CustomColors customColorsExtension = const CustomColors(
  redColor: Color(0xffBA1A1A),
  successColor: Color(0xff56B35A),
  leaveRequestOverviewBackgroundColor: Color(0xff6D76CA),
  totalStaffOverviewBackgroundColor: Color(0xff6dca95),
  totalStudentOverviewBackgroundColor: Color(0xffED7483),
  totalTeacherOverviewBackgroundColor: Color(0xff518EF4),
);
