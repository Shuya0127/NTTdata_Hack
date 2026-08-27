import 'package:flutter_test/flutter_test.dart';

import 'package:newsapp/main.dart';

void main() {
  testWidgets('Shows the account creation screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('アカウント作成'), findsOneWidget);
    expect(find.text('ユーザーID'), findsOneWidget);
    expect(find.text('ユーザー名'), findsOneWidget);
  });
}
