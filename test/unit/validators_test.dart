import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/core/validators.dart';

String rep(int n) => List.filled(n, 'a').join();

void main() {
  group('validateAluEmail', () {
    for (final ok in [
      'a@alustudent.com',
      'a+staff@alustudent.com',
      'a@alueducation.com',
      'w.okechukwu+staff@alustudent.com',
      'A@ALUSTUDENT.COM',
    ]) {
      test('accepts $ok', () => expect(validateAluEmail(ok), isNull));
    }
    for (final bad in [
      'a@gmail.com',
      'a@alustudent.com.evil.io',
      'alustudent.com',
      '',
      '@alustudent.com',
      'a@xalustudent.com',
      'a@evil.io/alustudent.com',
    ]) {
      test('rejects "$bad"', () => expect(validateAluEmail(bad), isNotNull));
    }
    test('rejects null', () => expect(validateAluEmail(null), isNotNull));
  });

  group('validatePassword', () {
    test(
      '7 chars refused',
      () => expect(validatePassword('abcdef1'), isNotNull),
    );
    test(
      '8 chars with letter and digit accepted',
      () => expect(validatePassword('abcdefg1'), isNull),
    );
    test(
      'no digit refused',
      () => expect(validatePassword('abcdefgh'), isNotNull),
    );
    test(
      'no letter refused',
      () => expect(validatePassword('12345678'), isNotNull),
    );
    test('empty and null refused', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword(null), isNotNull);
    });
  });

  group('validateConfirm', () {
    test(
      'equal accepted',
      () => expect(validateConfirm('Passw0rdOK', 'Passw0rdOK'), isNull),
    );
    test(
      'different refused',
      () => expect(validateConfirm('Passw0rdNO', 'Passw0rdOK'), isNotNull),
    );
    test(
      'empty vs non-empty refused',
      () => expect(validateConfirm('', 'Passw0rdOK'), isNotNull),
    );
    test(
      'null refused',
      () => expect(validateConfirm(null, 'Passw0rdOK'), isNotNull),
    );
  });

  group('validateName 2-60', () {
    test('1 refused', () => expect(validateName('A'), isNotNull));
    test('2 accepted', () => expect(validateName('Al'), isNull));
    test('60 accepted', () => expect(validateName(rep(60)), isNull));
    test('61 refused', () => expect(validateName(rep(61)), isNotNull));
    test(
      'trimmed before counting',
      () => expect(validateName('  A  '), isNotNull),
    );
    test('null refused', () => expect(validateName(null), isNotNull));
  });

  group('validateTitle 5-80', () {
    test('4 refused', () => expect(validateTitle(rep(4)), isNotNull));
    test('5 accepted', () => expect(validateTitle(rep(5)), isNull));
    test('80 accepted', () => expect(validateTitle(rep(80)), isNull));
    test('81 refused', () => expect(validateTitle(rep(81)), isNotNull));
    test(
      '4 after trim refused',
      () => expect(validateTitle('  ${rep(4)}  '), isNotNull),
    );
    test(
      '5 after trim accepted',
      () => expect(validateTitle('  ${rep(5)}  '), isNull),
    );
    test('null refused', () => expect(validateTitle(null), isNotNull));
  });

  group('validateDescription 15-1000', () {
    test('14 refused', () => expect(validateDescription(rep(14)), isNotNull));
    test('15 accepted', () => expect(validateDescription(rep(15)), isNull));
    test('1000 accepted', () => expect(validateDescription(rep(1000)), isNull));
    test(
      '1001 refused',
      () => expect(validateDescription(rep(1001)), isNotNull),
    );
    test(
      '14 after trim refused',
      () => expect(validateDescription('  ${rep(14)}  '), isNotNull),
    );
    test('null refused', () => expect(validateDescription(null), isNotNull));
  });

  group('validateNote 3-280', () {
    test('2 refused', () => expect(validateNote(rep(2)), isNotNull));
    test('3 accepted', () => expect(validateNote(rep(3)), isNull));
    test('280 accepted', () => expect(validateNote(rep(280)), isNull));
    test('281 refused', () => expect(validateNote(rep(281)), isNotNull));
    test(
      '2 after trim refused',
      () => expect(validateNote('  ${rep(2)}  '), isNotNull),
    );
    test('null refused', () => expect(validateNote(null), isNotNull));
  });
}
