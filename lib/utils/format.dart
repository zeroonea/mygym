import 'package:intl/intl.dart';

final _volumeFormat = NumberFormat.decimalPattern();

/// Formats a weight, dropping a trailing `.0` (e.g. `60`, `62.5`).
String formatWeight(double weight) {
  if (weight == weight.roundToDouble()) {
    return weight.toStringAsFixed(0);
  }
  return weight.toStringAsFixed(1);
}

/// Formats total volume with thousands separators (e.g. `12,450`).
String formatVolume(double volume) => _volumeFormat.format(volume.round());

String formatFullDate(DateTime date) =>
    DateFormat('EEEE, d MMM yyyy').format(date);

String formatShortDate(DateTime date) => DateFormat('d MMM yyyy').format(date);

String formatDayMonth(DateTime date) => DateFormat('d MMM').format(date);

/// A friendly relative label: "Today", "Yesterday", or a short date.
String relativeDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(date.year, date.month, date.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return '$diff days ago';
  return formatShortDate(date);
}
