import 'package:flutter/material.dart';
import 'package:snagboard/data/models.dart';

/// Snagboard design tokens: warm paper, ink, one signal colour. Flat, no
/// gradients, no shadows, 2 px outlines, 4 px corners.
abstract final class Snag {
  static const paper = Color(0xFFF3EFE6);
  static const paperDeep = Color(0xFFE8E2D4);
  static const ink = Color(0xFF16130F);
  static const inkSoft = Color(0xFF4A443C);
  static const flare = Color(0xFFFF4F1A);
  static const onFlare = Color(0xFF16130F);
  static const danger = Color(0xFF9B1C1C);

  static const outline = 2.0;
  static const radius = 4.0;
  static const gap = 16.0;

  static const sans = 'SpaceGrotesk';
  static const mono = 'JetBrainsMono';

  static Color statusColor(IncidentStatus s) => switch (s) {
    IncidentStatus.submitted => const Color(0xFF6B6359),
    IncidentStatus.acknowledged => const Color(0xFF2457D6),
    IncidentStatus.inProgress => const Color(0xFF9A5B00),
    IncidentStatus.resolved => const Color(0xFF1F7A4D),
    IncidentStatus.declined => const Color(0xFF9B1C1C),
  };

  /// Mono caps label style used for codes, tabs and stamps.
  static TextStyle label({double size = 12, Color color = ink}) => TextStyle(
    fontFamily: mono,
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: color,
  );

  static const border = BorderSide(color: ink, width: outline);
  static final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: border,
  );
}

ThemeData buildSnagTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: Snag.sans,
    scaffoldBackgroundColor: Snag.paper,
    colorScheme: const ColorScheme.light(
      primary: Snag.ink,
      onPrimary: Snag.paper,
      secondary: Snag.flare,
      onSecondary: Snag.onFlare,
      surface: Snag.paper,
      onSurface: Snag.ink,
      error: Snag.danger,
      outline: Snag.ink,
    ),
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Snag.radius),
    borderSide: Snag.border,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Snag.paper,
      foregroundColor: Snag.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.6),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: Snag.flare, width: 2.5),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: Snag.danger, width: 2),
      ),
      labelStyle: Snag.label(size: 12, color: Snag.inkSoft),
      floatingLabelStyle: Snag.label(size: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Snag.ink,
        foregroundColor: Snag.paper,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Snag.radius),
        ),
        textStyle: Snag.label(size: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Snag.ink,
        minimumSize: const Size(48, 48),
        side: Snag.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Snag.radius),
        ),
        textStyle: Snag.label(size: 13),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Snag.ink,
        minimumSize: const Size(48, 48),
        textStyle: Snag.label(size: 12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Snag.ink,
      contentTextStyle: const TextStyle(
        fontFamily: Snag.sans,
        color: Snag.paper,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Snag.radius),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Snag.ink, thickness: 1),
  );
}

/// '5 Nov 2026, 14:07'
String formatDateTime(DateTime t) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
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

/// Stable keys on the main widgets, so each one can be found by name.
abstract final class K {
  // Sign in
  static const signInEmail = ValueKey('signIn.email');
  static const signInPassword = ValueKey('signIn.password');
  static const signInSubmit = ValueKey('signIn.submit');
  static const signInToSignUp = ValueKey('signIn.toSignUp');
  static const signInForgot = ValueKey('signIn.forgot');

  // Sign up
  static const signUpName = ValueKey('signUp.name');
  static const signUpEmail = ValueKey('signUp.email');
  static const signUpPassword = ValueKey('signUp.password');
  static const signUpConfirm = ValueKey('signUp.confirm');
  static const signUpSubmit = ValueKey('signUp.submit');
  static const signUpToSignIn = ValueKey('signUp.toSignIn');

  // Verify email
  static const verifyCheck = ValueKey('verify.check'); // "I've verified"
  static const verifyResend = ValueKey('verify.resend');
  static const verifyUseAnother = ValueKey('verify.useAnother');

  // Auth gate states
  static const gateLoading = ValueKey('gate.loading');
  static const gateError = ValueKey('gate.error');
  static const gateRetry = ValueKey('gate.retry');
  static const gateSignOut = ValueKey('gate.signOut');

  // Shell tabs (student: board, mine, me; staff: queue, board, me)
  static const tabBoard = ValueKey('tab.board');
  static const tabMine = ValueKey('tab.mine');
  static const tabMe = ValueKey('tab.me');
  static const tabQueue = ValueKey('tab.queue');

  // Lists (board, mine, queue)
  static const fileSnag = ValueKey('board.fileSnag');
  static const search = ValueKey('board.search');
  static const listLoading = ValueKey('list.loading');
  static const listError = ValueKey('list.error');
  static const listRetry = ValueKey('list.retry');
  static const listEmpty = ValueKey('list.empty');
  static ValueKey<String> ribbonSegment(StatusGroup g) =>
      ValueKey('ribbon.${g.name}');
  static ValueKey<String> categoryChip(IncidentCategory c) =>
      ValueKey('chip.${c.name}');
  static ValueKey<String> ticket(String id) => ValueKey('ticket.$id');
  static ValueKey<String> ticketStamp(String id) =>
      ValueKey('ticket.$id.stamp');

  // File a snag
  static ValueKey<String> categoryRow(IncidentCategory c) =>
      ValueKey('file.category.${c.name}');
  static ValueKey<String> urgencyOption(Urgency u) =>
      ValueKey('file.urgency.${u.name}');
  static ValueKey<String> locationOption(String name) =>
      ValueKey('file.location.$name');
  static const spot = ValueKey('file.spot');
  static const title = ValueKey('file.title');
  static const description = ValueKey('file.description');
  static const addPhoto = ValueKey('file.addPhoto');
  static const removePhoto = ValueKey('file.removePhoto');
  static const anonymous = ValueKey('file.anonymous');
  static const next = ValueKey('file.next');
  static const back = ValueKey('file.back');
  static const submit = ValueKey('file.submit');
  static const submitRetry = ValueKey('file.retry');
  static const submitProgress = ValueKey('file.progress');
  static const safetyNotice = ValueKey('file.safetyNotice');
  static const similarList = ValueKey('file.similar');
  static ValueKey<String> similarAffects(String id) =>
      ValueKey('file.similar.$id.affects');
  static const fieldError = ValueKey(
    'file.fieldError',
  ); // category/location error text

  // Details
  static const detailStamp = ValueKey('detail.stamp');
  static const detailTrack = ValueKey('detail.track');
  static const detailPhoto = ValueKey('detail.photo');
  static ValueKey<String> moveTo(IncidentStatus s) =>
      ValueKey('detail.moveTo.${s.name}');
  static const statusNote = ValueKey('detail.note');
  static const confirmMove = ValueKey('detail.confirmMove');
  static const affectsToggle = ValueKey('detail.affects');
  static const edit = ValueKey('detail.edit');
  static const withdraw = ValueKey('detail.withdraw');
  static const staffDelete = ValueKey('detail.staffDelete');
  static const confirmDelete = ValueKey('detail.confirmDelete');

  // Profile
  static const signOut = ValueKey('me.signOut');
  static const roleStamp = ValueKey('me.role');
  static const avatar = ValueKey('me.avatar');
  static const programme = ValueKey('me.programme');
  static const editProfile = ValueKey('me.edit');
  static ValueKey<String> summary(String name) =>
      ValueKey('me.summary.$name'); // total, open, active, resolved
  static const recentList = ValueKey('me.recent');
  static const editName = ValueKey('edit.name');
  static const editProgramme = ValueKey('edit.programme'); // dropdown
  static ValueKey<String> programmeOption(String name) =>
      ValueKey('edit.programme.$name');
  static const editPhoto = ValueKey('edit.photo');
  static const editSave = ValueKey('edit.save');
}
