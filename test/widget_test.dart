import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_unit/core/utils/validators.dart';

void main() {
  test('phone validator accepts common formats', () {
    expect(Validators.phone('+923001234567'), isNull);
    expect(Validators.phone('0300 1234567'), isNull);
    expect(Validators.phone('abc'), isNotNull);
  });

  test('confirm password must match', () {
    final check = Validators.confirmPassword(() => 'secret1');
    expect(check('secret1'), isNull);
    expect(check('other'), isNotNull);
  });
}
