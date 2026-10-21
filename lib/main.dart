import 'package:eschool_saas_staff/app/app.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:get_it/get_it.dart';

// Addon version: [1.0.0]
// App code version: [V.1.12.0]

void main() async {
  GetIt.instance.registerSingleton<FacebookAppEvents>(FacebookAppEvents());

  await initializeApp();
}

