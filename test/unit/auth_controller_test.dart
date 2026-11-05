import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/auth/auth_controller.dart';

import '../fakes/fakes.dart';

void main() {
  late TestHarness h;
  late ProviderContainer c;
  late AuthController a;

  setUp(() {
    h = TestHarness();
    c = h.container();
    addTearDown(c.dispose);
    c.listen(authControllerProvider, (_, _) {});
    a = c.read(authControllerProvider.notifier);
  });

  test('signIn delegates to the repository', () async {
    await a.signIn('amani@alustudent.com', 'Passw0rdOK');
    expect(h.auth.calls, ['signIn:amani@alustudent.com']);
    expect(c.read(authControllerProvider).hasError, isFalse);
  });
}
