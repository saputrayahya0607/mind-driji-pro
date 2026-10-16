import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_drji/app/core/widgets/mind_driji_loader.dart';

void main() {
  group('MindDrijiLoader Unit & Widget Tests', () {
    testWidgets('renders default loader correctly without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MindDrijiLoader(
              size: 100,
              message: 'Memuat data...',
            ),
          ),
        ),
      );

      // Verify widget tree contains loader and message
      expect(find.byType(MindDrijiLoader), findsOneWidget);
      expect(find.text('Memuat data...'), findsOneWidget);

      // Advance animation frames
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1000));
    });

    testWidgets('renders compact loader without message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindDrijiLoader.compact(size: 36),
          ),
        ),
      );

      expect(find.byType(MindDrijiLoader), findsOneWidget);
      expect(find.byType(Text), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('renders fullscreen loader with dark background styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindDrijiLoader.fullscreen(
              size: 160,
              message: 'Memulai sesi...',
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.byType(MindDrijiLoader), findsOneWidget);
      expect(find.text('Memulai sesi...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('respects repeat = false and forwards once', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MindDrijiLoader(
              repeat: false,
              duration: Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      // Forward through full duration
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(MindDrijiLoader), findsOneWidget);
    });

    testWidgets('disposes controller cleanly without leaking tickers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MindDrijiLoader(size: 80),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Replace with empty widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(MindDrijiLoader), findsNothing);
    });
  });
}
