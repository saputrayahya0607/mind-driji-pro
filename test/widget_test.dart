import 'package:flutter_test/flutter_test.dart';
import 'package:mind_drji/app/core/constants/app_strings.dart';
import 'package:mind_drji/main.dart';

void main() {
  testWidgets('App smoke test initializes MindDrjiApp', (WidgetTester tester) async {
    await tester.pumpWidget(const MindDrjiApp());

    // Memverifikasi nama aplikasi muncul di splash
    expect(find.text(AppStrings.appName), findsOneWidget);
  });
}
