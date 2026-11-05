import 'package:flutter/widgets.dart';

import '../incidents/incident.dart';

/// Widget keys shared by the screens and the tests. Screens must attach
/// these keys to the widgets named here; tests find widgets only by them.
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
  static ValueKey<String> ribbonSegment(StatusGroup g) => ValueKey('ribbon.${g.name}');
  static ValueKey<String> categoryChip(IncidentCategory c) => ValueKey('chip.${c.name}');
  static ValueKey<String> ticket(String id) => ValueKey('ticket.$id');
  static ValueKey<String> ticketStamp(String id) => ValueKey('ticket.$id.stamp');

  // File a snag
  static ValueKey<String> categoryRow(IncidentCategory c) => ValueKey('file.category.${c.name}');
  static ValueKey<String> urgencyOption(Urgency u) => ValueKey('file.urgency.${u.name}');
  static ValueKey<String> locationOption(String name) => ValueKey('file.location.$name');
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
  static ValueKey<String> similarAffects(String id) => ValueKey('file.similar.$id.affects');
  static const fieldError = ValueKey('file.fieldError'); // category/location error text

  // Details
  static const detailStamp = ValueKey('detail.stamp');
  static const detailTrack = ValueKey('detail.track');
  static const detailPhoto = ValueKey('detail.photo');
  static ValueKey<String> moveTo(IncidentStatus s) => ValueKey('detail.moveTo.${s.name}');
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
}
