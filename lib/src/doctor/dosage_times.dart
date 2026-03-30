/// Utilities for storing and displaying prescription dosage times.
///
/// Storage format (DB): "m+a+n" where each part is 0 or 1:
/// - m = morning (সকাল)
/// - a = afternoon/noon (দুপুর)
/// - n = night (রাত)
///
/// Example: "1+0+1" means সকাল + রাত.
/// Special format:
/// - "1+1+1+1" means special "4 times" (UI shows only "4")

bool isDosageFourTimes(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) return false;
  final parts = normalized.split('+').map((s) => s.trim()).toList();
  return parts.length == 4 && parts.every((p) => p == '1');
}

Map<String, bool> decodeDosageTimesToBanglaMap(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return const {'সকাল': false, 'দুপুর': false, 'রাত': false};
  }

  // Numeric pattern: 1+0+1 (allow spaces)
  final parts = normalized.split('+').map((s) => s.trim()).toList();
  if (parts.length == 3 && parts.every((p) => p == '0' || p == '1')) {
    return {
      'সকাল': parts[0] == '1',
      'দুপুর': parts[1] == '1',
      'রাত': parts[2] == '1',
    };
  }

  // Fallback: text patterns (Bangla/English)
  final lower = normalized.toLowerCase();
  return {
    'সকাল': lower.contains('সকাল') || lower.contains('morning'),
    'দুপুর': lower.contains('দুপুর') || lower.contains('noon'),
    'রাত': lower.contains('রাত') || lower.contains('night'),
  };
}

String encodeDosageTimesFromBanglaMap(Map<String, bool> times) {
  bool t(String key) => (times[key] ?? false) == true;
  final m = t('সকাল') ? '1' : '0';
  final a = t('দুপুর') ? '1' : '0';
  final n = t('রাত') ? '1' : '0';
  return '$m+$a+$n';
}

String encodeDosageTimes({
  required Map<String, bool> times,
  required bool four,
}) {
  if (four) return '1+1+1+1';
  return encodeDosageTimesFromBanglaMap(times);
}

/// Converts stored dosage string into a Bangla label string for UI/PDF.
/// - "1+0+1" -> "সকাল, রাত"
/// - If nothing selected, returns empty string.
String dosageTimesDisplayBangla(String raw) {
  final rawTrim = raw.trim();
  if (isDosageFourTimes(rawTrim)) return '4';
  final map = decodeDosageTimesToBanglaMap(rawTrim);
  final selected = <String>[];
  if (map['সকাল'] == true) selected.add('সকাল');
  if (map['দুপুর'] == true) selected.add('দুপুর');
  if (map['রাত'] == true) selected.add('রাত');

  if (selected.isNotEmpty) return selected.join(', ');

  final parts = rawTrim.split('+').map((s) => s.trim()).toList();
  final looksNumeric =
      parts.length == 3 && parts.every((p) => p == '0' || p == '1');

  // For numeric patterns like 0+0+0, prefer blank (caller can show '-')
  if (looksNumeric) return '';

  // For any other unrecognized format (e.g., '3 times daily'), keep raw.
  return rawTrim;
}

/// Returns how many times per day based on decoded morning/noon/night flags.
/// - "1+0+1" -> 2
/// - "সকাল, রাত" -> 2
int dosageTimesPerDay(String raw) {
  final rawTrim = raw.trim();
  if (isDosageFourTimes(rawTrim)) return 4;
  final map = decodeDosageTimesToBanglaMap(rawTrim);
  var count = 0;
  if (map['সকাল'] == true) count++;
  if (map['দুপুর'] == true) count++;
  if (map['রাত'] == true) count++;

  if (count > 0) return count;

  // Fallback: numeric string like '3 times daily'
  final m = RegExp(r'\d+').firstMatch(rawTrim);
  if (m != null) return int.tryParse(m.group(0)!) ?? 0;

  return 0;
}
