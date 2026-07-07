import 'package:intl/intl.dart';

class DateFormatter {
  static final _dateId    = DateFormat('dd MMM yyyy', 'id_ID');
  static final _datetimeId= DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _timeId    = DateFormat('HH:mm', 'id_ID');
  static final _monthId   = DateFormat('MMM yyyy', 'id_ID');

  static String date(dynamic dt) {
    final d = _parse(dt); return d != null ? _dateId.format(d) : '—';
  }
  static String datetime(dynamic dt) {
    final d = _parse(dt); return d != null ? _datetimeId.format(d) : '—';
  }
  static String time(dynamic dt) {
    final d = _parse(dt); return d != null ? _timeId.format(d) : '—';
  }
  static String month(dynamic dt) {
    final d = _parse(dt); return d != null ? _monthId.format(d) : '—';
  }
  static String timeAgo(dynamic dt) {
    final d = _parse(dt);
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds  < 60)  return '${diff.inSeconds} dtk lalu';
    if (diff.inMinutes  < 60)  return '${diff.inMinutes} mnt lalu';
    if (diff.inHours    < 24)  return '${diff.inHours} jam lalu';
    if (diff.inDays     < 7)   return '${diff.inDays} hari lalu';
    return date(d);
  }
  static String duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}j ${m}m ${s}d';
    if (m > 0) return '${m}m ${s}d';
    return '${s}d';
  }
  static DateTime? _parse(dynamic d) {
    if (d == null) return null;
    if (d is DateTime) return d;
    if (d is String && d.isNotEmpty) return DateTime.tryParse(d);
    return null;
  }
}
