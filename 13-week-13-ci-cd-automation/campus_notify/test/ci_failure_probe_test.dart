import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CI failure probe blocks release builds', () {
    expect(
      false,
      isTrue,
      reason: 'Controlled CI verification; removed after failure evidence is captured.',
    );
  });
}
