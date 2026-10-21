import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:intl/intl.dart';

/// Formatting helpers shared by the QR attendance models and widgets.
///
/// Every timestamp the QR attendance API returns is already expressed in the
/// school's own timezone (`Y-m-d H:i:s`, no offset). They are parsed as
/// timezone-naive values and rendered as they arrived — converting them to the
/// device timezone would show a wrong punch time to anyone travelling or with a
/// misconfigured clock.
class QrAttendanceUtils {
  const QrAttendanceUtils._();

  /// Parses `2026-08-10 07:02:11` / `2026-08-10` without applying any timezone
  /// shift. Returns null for empty or malformed values.
  static DateTime? parseServerDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim().replaceFirst(' ', 'T'));
  }

  /// `2026-08-10 07:02:11` -> `7:02 AM`.
  static String formatTime(String? value) {
    final dateTime = parseServerDateTime(value);
    if (dateTime == null) return "";
    return DateFormat.jm().format(dateTime);
  }

  /// `2026-08-10` -> `10 Aug 2026`.
  static String formatDate(String? value) {
    final dateTime = parseServerDateTime(value);
    if (dateTime == null) return value ?? "";
    return Utils.formatDate(dateTime);
  }

  /// `07:00` / `07:00:00` -> `7:00 AM`. Falls back to the raw value when the
  /// server sends something unexpected.
  static String formatClockTime(String? value) {
    if (value == null || value.trim().isEmpty) return "";
    final parts = value.trim().split(":");
    if (parts.length < 2) return value;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return value;
    return DateFormat.jm().format(DateTime(2000, 1, 1, hour, minute));
  }

  /// Localized weekday name of [dateTime], reusing the app's weekday labels.
  static String weekDayLabelOf(DateTime dateTime) {
    return Utils.getTranslatedLabel(Utils.weekDays[dateTime.weekday - 1]);
  }

  /// Reads a `working_minutes` value off a response.
  ///
  /// The API sends this key in two shapes: a plain minute count on
  /// `/my-attendance`, and a `{ total, first_half, second_half }` breakdown on
  /// `/config`, `/today` and `/punch`, where `total` is the same number. Both
  /// are accepted here so a breakdown is not silently read as zero minutes.
  static int parseWorkingMinutes(dynamic value) {
    final raw = value is Map ? value['total'] : value;
    return int.tryParse((raw ?? "").toString()) ?? 0;
  }

  /// Metres in a kilometre — the point at which the displayed unit switches.
  static const int _metersInKilometer = 1000;

  /// Keeps a value and its unit on one line when the sentence around them
  /// wraps, so a notice never breaks as `13,129` / `km`.
  static const String _nonBreakingSpace = "\u00A0";

  /// Grouped whole numbers: `150`, `13,129`.
  static final NumberFormat _wholeNumberFormat = NumberFormat("#,##0");

  /// Kilometres near the threshold, where a decimal still says something.
  /// Drops it again once it does not: `1.2`, but `2` rather than `2.0`.
  static final NumberFormat _kilometerFormat = NumberFormat("#,##0.#");

  /// Metres as a distance a person can actually read: `150 m`, `1.2 km`,
  /// `13,129 km`.
  ///
  /// The API reports every distance in metres, which suits the radius of a
  /// school but stops being readable the moment the fix is wrong — a simulator
  /// default or a stale position turns into a seven digit number that tells the
  /// staff member nothing. From a kilometre up the value is therefore shown in
  /// kilometres; past ten of them the decimal is dropped, because the point is
  /// then "nowhere near the school", not the exact figure.
  static String formatDistance(int meters) {
    final int safeMeters = meters < 0 ? 0 : meters;

    if (safeMeters < _metersInKilometer) {
      return "${_wholeNumberFormat.format(safeMeters)}$_nonBreakingSpace"
          "${Utils.getTranslatedLabel(meterShortKey)}";
    }

    final double kilometers = safeMeters / _metersInKilometer;
    final String value = kilometers < 10
        ? _kilometerFormat.format(kilometers)
        : _wholeNumberFormat.format(kilometers.round());

    return "$value$_nonBreakingSpace"
        "${Utils.getTranslatedLabel(kilometerShortKey)}";
  }

  /// Minute counts as `2h 58m`, `45m`, `0m` — using the localized short units.
  static String formatDuration(int minutes) {
    final safeMinutes = minutes < 0 ? 0 : minutes;
    final hourLabel = Utils.getTranslatedLabel(hourShortKey);
    final minuteLabel = Utils.getTranslatedLabel(minuteShortKey);
    final hours = safeMinutes ~/ 60;
    final remainingMinutes = safeMinutes % 60;

    if (hours == 0) return "$remainingMinutes$minuteLabel";
    if (remainingMinutes == 0) return "$hours$hourLabel";
    return "$hours$hourLabel $remainingMinutes$minuteLabel";
  }
}
