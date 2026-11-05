import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/core/validators.dart';

void main() {
  test('email: an ALU address is accepted', () {
    expect(validateAluEmail('amani@alustudent.com'), isNull);
  });

  test('email: a non-ALU address is refused', () {
    expect(validateAluEmail('amani@gmail.com'), isNotNull);
  });

  test('password: 8+ characters with a letter and a digit is accepted', () {
    expect(validatePassword('abcdefg1'), isNull);
  });

  test('password: too short or without a digit is refused', () {
    expect(validatePassword('abc1'), isNotNull);
    expect(validatePassword('abcdefgh'), isNotNull);
  });

  test('title: 5 to 80 characters is accepted', () {
    expect(validateTitle('Leaking tap'), isNull);
  });

  test('title: too short is refused', () {
    expect(validateTitle('Tap'), isNotNull);
  });
}
