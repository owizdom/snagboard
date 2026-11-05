/// '5 Nov 2026, 14:07'
String formatDateTime(DateTime t) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.day} ${months[t.month - 1]} ${t.year}, ${two(t.hour)}:${two(t.minute)}';
}

/// 'just now', '12m ago', '3h ago', '2d ago', then the date.
String timeAgo(DateTime t, DateTime now) {
  final d = now.difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return formatDateTime(t).split(',').first;
}
