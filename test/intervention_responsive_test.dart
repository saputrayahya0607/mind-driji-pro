import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/local/app_database.dart';
import 'package:mind_drji/app/data/local/repositories/intervention_history_local_repository.dart';
import 'package:mind_drji/app/data/providers/intervention_native_provider.dart';
import 'package:mind_drji/app/data/services/intervention_service.dart';
import 'package:mind_drji/app/modules/intervention/controllers/intervention_controller.dart';
import 'package:mind_drji/app/modules/intervention/views/intervention_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late InterventionHistoryLocalRepository historyRepo;
  late InterventionService service;
  late InterventionController controller;

  setUp(() {
    Get.reset();
    db = AppDatabase(NativeDatabase.memory());
    historyRepo = InterventionHistoryLocalRepository(db: db);
    Get.put<AppDatabase>(db);
    Get.put<InterventionHistoryLocalRepository>(historyRepo);

    service = InterventionService(
      nativeProvider: InterventionNativeProvider(),
      historyRepository: historyRepo,
    );
    Get.put<InterventionService>(service);

    controller = InterventionController(interventionService: service);
    Get.put<InterventionController>(controller);
  });

  tearDown(() async {
    service.onClose();
    await db.close();
    Get.reset();
  });

  group('INTERVENTION VIEW MULTI-RESOLUTION & TEXT SCALING TESTS', () {
    final testSizes = [
      const Size(320, 600), // Narrow device
      const Size(360, 640), // Standard Android
      const Size(393, 852), // Modern Android (e.g. Pixel / Galaxy)
    ];

    final textScales = [1.0, 1.5];

    for (final size in testSizes) {
      for (final scale in textScales) {
        testWidgets(
            'Renders cleanly on ${size.width.toInt()}x${size.height.toInt()} with text scale $scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
              ),
              child: const GetMaterialApp(
                home: InterventionView(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(InterventionView), findsOneWidget);
          expect(find.text('Intervensi Digital'), findsOneWidget);
          expect(find.text('Atur Penggunaan Digital'), findsOneWidget);
          expect(find.text('Jeda Digital'), findsOneWidget);
          expect(find.text('Mode Fokus'), findsOneWidget);
          expect(find.text('Pomodoro Timer'), findsOneWidget);
          expect(find.text('Relaksasi Mata'), findsOneWidget);
          expect(find.text('Riwayat Sesi'), findsOneWidget);
        });
      }
    }
  });
}
