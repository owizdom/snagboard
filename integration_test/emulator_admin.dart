/// Talks to the Firebase emulators over REST so the end-to-end test can do
/// what a person would do outside the app: verify an inbox, grant a role,
/// inspect Storage. All calls use the emulators' `Bearer owner` bypass.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

const projectId = 'snagboard-alu';
const storageBucket = 'snagboard-alu.firebasestorage.app';
const _owner = {'Authorization': 'Bearer owner'};
const _json = {
  'Authorization': 'Bearer owner',
  'Content-Type': 'application/json',
};

const _auth = 'http://localhost:9099';
const _firestore = 'http://localhost:8080';
const _storage = 'http://localhost:9199';

Never _fail(String what, http.Response r) =>
    throw StateError('$what failed: ${r.statusCode} ${r.body}');

/// Auth emulator uid for [email].
Future<String> lookupUid(String email) async {
  final r = await http.post(
    Uri.parse(
      '$_auth/identitytoolkit.googleapis.com/v1/projects/$projectId/accounts:lookup',
    ),
    headers: _json,
    body: jsonEncode({
      'email': [email.toLowerCase()],
    }),
  );
  if (r.statusCode != 200) _fail('lookup $email', r);
  final users = (jsonDecode(r.body)['users'] as List?) ?? const [];
  if (users.isEmpty) throw StateError('no emulator account for $email');
  return users.first['localId'] as String;
}

/// Marks the account verified, as if the inbox link was clicked.
Future<String> markEmailVerified(String email) async {
  final uid = await lookupUid(email);
  final r = await http.post(
    Uri.parse(
      '$_auth/identitytoolkit.googleapis.com/v1/projects/$projectId/accounts:update',
    ),
    headers: _json,
    body: jsonEncode({'localId': uid, 'emailVerified': true}),
  );
  if (r.statusCode != 200) _fail('verify $email', r);
  return uid;
}

String _doc(String path) =>
    '$_firestore/v1/projects/$projectId/databases/(default)/documents/$path';

/// Waits for users/{uid} (the app writes it after sign-up) so a role patch
/// cannot race the app's own write.
Future<void> waitForUserDoc(
  String uid, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    final r = await http.get(Uri.parse(_doc('users/$uid')), headers: _owner);
    if (r.statusCode == 200) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  throw StateError('users/$uid never appeared');
}

/// Sets users/{uid}.role.
Future<void> setRole(String uid, String role) async {
  final r = await http.patch(
    Uri.parse('${_doc('users/$uid')}?updateMask.fieldPaths=role'),
    headers: _json,
    body: jsonEncode({
      'fields': {
        'role': {'stringValue': role},
      },
    }),
  );
  if (r.statusCode != 200) _fail('set role', r);
}

/// Document id of the incident whose title is [title], or null.
Future<String?> incidentIdByTitle(String title) async {
  final r = await http.get(
    Uri.parse('${_doc('incidents')}?pageSize=300'),
    headers: _owner,
  );
  if (r.statusCode != 200) _fail('list incidents', r);
  final docs = (jsonDecode(r.body)['documents'] as List?) ?? const [];
  for (final d in docs) {
    final fields = d['fields'] as Map<String, dynamic>;
    if (fields['title']?['stringValue'] == title) {
      return (d['name'] as String).split('/').last;
    }
  }
  return null;
}

/// Object names under [prefix] in the Storage emulator.
Future<List<String>> storageObjects(String prefix) async {
  final r = await http.get(
    Uri.parse(
      '$_storage/v0/b/$storageBucket/o?prefix=${Uri.encodeQueryComponent(prefix)}',
    ),
    headers: _owner,
  );
  if (r.statusCode != 200) _fail('list storage', r);
  final items = (jsonDecode(r.body)['items'] as List?) ?? const [];
  return [for (final i in items) i['name'] as String];
}
