import 'package:flutter_test/flutter_test.dart';
import 'package:snagboard/data/models.dart';
import 'package:snagboard/state/report_form.dart';

void main() {
  test('only ALU email addresses can sign up', () {
    expect(validateAluEmail('amani@alustudent.com'), isNull);
    expect(validateAluEmail('staff@alueducation.com'), isNull);
    expect(validateAluEmail('amani@gmail.com'), isNotNull);
  });

  test('a password needs 8+ characters with a letter and a digit', () {
    expect(validatePassword('abcdefg1'), isNull);
    expect(validatePassword('abc1'), isNotNull);
    expect(validatePassword('abcdefgh'), isNotNull);
  });

  test('a snag title must be 5 to 80 characters', () {
    expect(validateTitle('Leaking tap'), isNull);
    expect(validateTitle('Tap'), isNotNull);
  });

  test('staff can only move a snag to the next allowed status', () {
    expect(
      canTransition(IncidentStatus.submitted, IncidentStatus.acknowledged),
      isTrue,
    );
    expect(
      canTransition(IncidentStatus.submitted, IncidentStatus.resolved),
      isFalse,
    );
    expect(nextStatuses(IncidentStatus.inProgress), [IncidentStatus.resolved]);
  });
}
