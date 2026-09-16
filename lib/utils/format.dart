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

/// Clock time, e.g. `10:32 am`.
String formatClock(DateTime date) => DateFormat('h:mm a').format(date);

/// A compact rest/elapsed label, e.g. `45s`, `2m 10s`, `1h 5m`.
String formatDuration(Duration d) {
  if (d.isNegative) return '0s';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return s > 0 ? '${m}m ${s}s' : '${m}m';
  return '${s}s';
}

/// Formats a measurement/number, dropping a trailing `.0` (e.g. `80`, `80.5`).
String formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

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
