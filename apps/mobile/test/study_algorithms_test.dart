import 'package:flutter_test/flutter_test.dart';
import 'package:ileotoktok_mobile/domain/usecases/study_algorithms.dart';

void main() {
  group('nextIntervalDays', () {
    test('again returns 1 day', () {
      expect(nextIntervalDays(currentInterval: 8, good: false), 1);
    });

    test('good returns at least 2 days', () {
      expect(nextIntervalDays(currentInterval: 1, good: true), 2);
    });

    test('good doubles interval after 2 days', () {
      expect(nextIntervalDays(currentInterval: 4, good: true), 8);
    });
  });
}
