import 'package:intl/intl.dart';

/// Frontend-only Date/Time helpers.
///
/// Goals:
/// - Display instants (createdAt/timestamp/etc.) in local time.
/// - Display date-only fields (shiftDate/reportDate/etc.) without timezone drift.
/// - When sending date ranges to backend, always send UTC instants.
class AppDateTime {
  const AppDateTime._();

  static DateTime _asLocal(DateTime d) => d.toLocal();

  /// Interprets [d] as a local calendar day and returns local midnight.
  static DateTime startOfLocalDay(DateTime d) {
    final local = _asLocal(d);
    return DateTime(local.year, local.month, local.day);
  }

  /// Start of the next local day (exclusive end bound).
  static DateTime startOfNextLocalDay(DateTime d) {
    return startOfLocalDay(d).add(const Duration(days: 1));
  }

  /// Formats an instant in the user's local time.
  static String formatLocal(DateTime d, {String pattern = 'yyyy-MM-dd'}) {
    return DateFormat(pattern).format(_asLocal(d));
  }

  /// Formats an instant in the user's local time with a default date+time pattern.
  static String formatLocalDateTime(
    DateTime d, {
    String pattern = 'yyyy-MM-dd HH:mm',
  }) {
    return DateFormat(pattern).format(_asLocal(d));
  }

  /// Formats a date-only value without timezone drift.
  ///
  /// Many APIs model dates as DateTime at midnight. Converting such values to
  /// local can shift the calendar date in negative timezones. This helper keeps
  /// the calendar date stable by using the UTC year/month/day components.
  static String formatDateOnly(DateTime d, {String pattern = 'yyyy-MM-dd'}) {
    final u = d.toUtc();
    final stable = DateTime(u.year, u.month, u.day);
    return DateFormat(pattern).format(stable);
  }

  /// Converts a date-only value to a UTC midnight DateTime.
  ///
  /// Useful when sending date-only fields (DOB/shiftDate) to backend.
  static DateTime utcDateOnly(DateTime d) {
    final u = d.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  /// UTC ISO8601 string (includes trailing 'Z').
  static String utcIso(DateTime d) => d.toUtc().toIso8601String();

  static bool _isMidnightLocal(DateTime d) {
    final l = d.toLocal();
    return l.hour == 0 &&
        l.minute == 0 &&
        l.second == 0 &&
        l.millisecond == 0 &&
        l.microsecond == 0;
  }

  static String _ymdLocal(DateTime d) {
    final l = d.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}';
  }

  /// Formats values like `2026-01-17T00:00:00.000..2026-01-18T00:00:00.000`.
  ///
  /// If both sides are ISO datetimes at local midnight, the time portion is
  /// removed and returned as `yyyy-MM-dd - yyyy-MM-dd`.
  static String formatMaybeIsoRange(String raw, {String separator = ' - '}) {
    final input = raw.trim();
    final parts = input.split('..');
    if (parts.length != 2) return raw;

    final leftRaw = parts[0].trim();
    final rightRaw = parts[1].trim();

    final left = DateTime.tryParse(leftRaw);
    final right = DateTime.tryParse(rightRaw);
    if (left == null || right == null) return raw;

    // Common case: date-range boundaries represented as local midnight.
    if (_isMidnightLocal(left) && _isMidnightLocal(right)) {
      return '${_ymdLocal(left)}$separator${_ymdLocal(right)}';
    }

    // Fallback: keep it readable as local date+time.
    return '${formatLocalDateTime(left)}$separator${formatLocalDateTime(right)}';
  }
}
