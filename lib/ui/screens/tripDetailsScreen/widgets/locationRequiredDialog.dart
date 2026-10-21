import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/locationService.dart';
import 'package:flutter/material.dart';

/// Explains what is keeping a trip from being tracked, and offers the one
/// action that can resolve it.
///
/// [show] answers whether the caller should check again straight away. That is
/// only true for a permission the system will still prompt for: where the fix
/// lives in the settings app the driver has to leave, and no answer can arrive
/// while they are gone.
class LocationRequiredDialog extends StatelessWidget {
  const LocationRequiredDialog({super.key, required this.reason});

  final LocationFailureReason reason;

  static Future<bool> show(
    BuildContext context,
    LocationFailureReason reason,
  ) async {
    final shouldRetry = await showDialog<bool>(
      context: context,
      builder: (_) => LocationRequiredDialog(reason: reason),
    );
    // Dismissing the dialog by tapping outside it means the same as cancelling.
    return shouldRetry ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final settingsTarget = reason.settingsTarget;

    return AlertDialog(
      title: const CustomTextContainer(
        textKey: locationRequiredKey,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: CustomTextContainer(
        textKey: _messageKey,
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const CustomTextContainer(textKey: cancelKey),
        ),
        TextButton(
          onPressed: () {
            if (settingsTarget == null) {
              Navigator.of(context).pop(true);
              return;
            }
            LocationService.openSettings(settingsTarget);
            Navigator.of(context).pop(false);
          },
          child: CustomTextContainer(
            textKey: settingsTarget == null ? allowKey : openSettingsKey,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Trip wording for a location problem.
  ///
  /// The QR attendance flow has its own messages for the very same reasons,
  /// but they talk about scanning at school and would read as nonsense to a
  /// driver about to pull away — hence a second, deliberate set.
  String get _messageKey {
    switch (reason) {
      case LocationFailureReason.serviceDisabled:
        return enableLocationServicesForTripKey;
      case LocationFailureReason.permissionDeniedForever:
        return locationPermissionBlockedForTripKey;
      case LocationFailureReason.permissionDenied:
      case LocationFailureReason.unavailable:
        return allowLocationAccessForTripKey;
    }
  }
}
