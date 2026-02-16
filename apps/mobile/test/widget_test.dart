import 'package:flutter_test/flutter_test.dart';
import 'package:ileotoktok_mobile/app.dart';

void main() {
  testWidgets('app boot smoke test', (tester) async {
    await tester.pumpWidget(const IleoTokTokApp());

    expect(find.byType(IleoTokTokApp), findsOneWidget);
  });
}
