import 'package:eschool_saas_staff/data/models/appLanguage.dart';

/// Language the build is expected to ship an `assets/languages/<code>.json`
/// for. It is the last-resort source of labels only — the language the app
/// actually starts in is the panel default (`status: 1` in `get-languages`),
/// resolved by [AppLocalizationCubit].
const String bundledFallbackLanguageCode = "en";

//Add language code in this list
//visit this to find languageCode for your respective language
//https://developers.google.com/admin-sdk/directory/v1/languages
const List<AppLanguage> appLanguages = [
  //Please add language code here and language name
  AppLanguage(languageCode: "en", languageName: "English"),
  //
  //For example you are adding gujarati language
  //AppLanguage(languageCode: "gu", languageName: "ગુજરાતી - Gujarati"),
  //
];
