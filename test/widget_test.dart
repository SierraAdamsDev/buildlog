import 'package:buildlog/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BuildLog app loads homepage', (WidgetTester tester) async {
    await tester.pumpWidget(const BuildLogApp());
    expect(find.text('BuildLog'), findsWidgets);
  });
}