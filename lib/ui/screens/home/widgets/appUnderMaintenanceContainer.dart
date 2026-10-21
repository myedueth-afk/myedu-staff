import 'package:eschool_saas_staff/ui/widgets/appIcon.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/appIllustrations.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:flutter/material.dart';

class AppUnderMaintenanceContainer extends StatelessWidget {
  const AppUnderMaintenanceContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppIllustration(
            AppIllustrations.maintenance,
            fit: BoxFit.cover,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * (0.0125),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: CustomTextContainer(
              textKey: appUnderMaintenanceKey,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          )
        ],
      ),
    );
  }
}
