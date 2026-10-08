import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mind_drji/app/data/models/target_app_model.dart';
import 'package:mind_drji/app/data/providers/doomscroll_native_provider.dart';
import 'package:mind_drji/app/modules/target_apps/controllers/target_apps_controller.dart';
import 'package:mind_drji/app/modules/target_apps/views/target_apps_view.dart';

class FakeDoomscrollProviderForTargetApps extends DoomscrollNativeProvider {
  List<TargetAppModel> installedAppsList = [];
  List<TargetAppModel> savedTargetApps = [];
  bool saveCalled = false;
  bool resetCalled = false;

  @override
  Future<List<TargetAppModel>> getInstalledApps() async => installedAppsList;

  @override
  Future<List<TargetAppModel>> getTargetPackages() async =>
      installedAppsList.where((a) => a.isMonitored).toList();

  @override
  Future<bool> saveTargetPackages(List<TargetAppModel> targetApps) async {
    saveCalled = true;
    savedTargetApps = List.from(targetApps);
    return true;
  }

  @override
  Future<List<TargetAppModel>> resetTargetPackagesToDefault() async {
    resetCalled = true;
    installedAppsList = List.from(TargetAppsController.fallbackDefaultApps);
    return installedAppsList;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TargetAppModel Unit Tests', () {
    test('Correctly maps from and to map', () {
      final map = {
        'packageName': 'com.ss.android.ugc.trill',
        'appName': 'TikTok',
        'isMonitored': true,
      };
      final model = TargetAppModel.fromMap(map);

      expect(model.packageName, 'com.ss.android.ugc.trill');
      expect(model.appName, 'TikTok');
      expect(model.isMonitored, isTrue);
      expect(model.isDefault, isTrue);

      final toMap = model.toMap();
      expect(toMap['packageName'], 'com.ss.android.ugc.trill');
      expect(toMap['appName'], 'TikTok');
      expect(toMap['isMonitored'], isTrue);
    });

    test('copyWith works properly', () {
      const model = TargetAppModel(
        packageName: 'com.example.app',
        appName: 'Example App',
        isMonitored: false,
      );

      final updated = model.copyWith(isMonitored: true);
      expect(updated.packageName, 'com.example.app');
      expect(updated.isMonitored, isTrue);
    });
  });

  group('TargetAppsController Unit Tests', () {
    late FakeDoomscrollProviderForTargetApps fakeProvider;
    late TargetAppsController controller;

    setUp(() {
      Get.reset();
      fakeProvider = FakeDoomscrollProviderForTargetApps();
      fakeProvider.installedAppsList = [
        const TargetAppModel(
          packageName: 'com.ss.android.ugc.trill',
          appName: 'TikTok',
          isMonitored: true,
          isDefault: true,
        ),
        const TargetAppModel(
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          isMonitored: false,
          isDefault: true,
        ),
        const TargetAppModel(
          packageName: 'com.shopee.id',
          appName: 'Shopee',
          isMonitored: false,
          isDefault: false,
        ),
      ];
      controller = TargetAppsController(provider: fakeProvider);
    });

    test('Initial loading loads installed apps from provider', () async {
      await controller.loadApps();
      expect(controller.installedApps.length, 3);
      expect(controller.monitoredCount, 1);
    });

    test('toggleApp updates monitored status in reactive list', () async {
      await controller.loadApps();
      final instagram = controller.installedApps
          .firstWhere((a) => a.packageName == 'com.instagram.android');

      controller.toggleApp(instagram, true);
      expect(controller.monitoredCount, 2);
    });

    test('filteredApps filters by search query and tabs', () async {
      await controller.loadApps();

      // Search
      controller.searchQuery.value = 'shopee';
      expect(controller.filteredApps.length, 1);
      expect(controller.filteredApps.first.appName, 'Shopee');

      controller.searchQuery.value = '';

      // Filter: Monitored
      controller.currentFilter.value = TargetAppFilter.monitored;
      expect(controller.filteredApps.length, 1);
      expect(controller.filteredApps.first.appName, 'TikTok');

      // Filter: Defaults
      controller.currentFilter.value = TargetAppFilter.defaults;
      expect(controller.filteredApps.length, 2);
    });

    test('saveTargetApps sends only monitored apps to provider', () async {
      await controller.loadApps();
      final success = await controller.saveTargetApps();

      expect(success, isTrue);
      expect(fakeProvider.saveCalled, isTrue);
      expect(fakeProvider.savedTargetApps.length, 1);
      expect(fakeProvider.savedTargetApps.first.packageName,
          'com.ss.android.ugc.trill');
    });

    test('resetToDefault triggers provider reset and reloads apps', () async {
      await controller.resetToDefault();
      expect(fakeProvider.resetCalled, isTrue);
      expect(controller.installedApps.isNotEmpty, isTrue);
    });
  });

  group('TargetAppsView Widget Tests', () {
    late FakeDoomscrollProviderForTargetApps fakeProvider;
    late TargetAppsController controller;

    setUp(() {
      Get.reset();
      fakeProvider = FakeDoomscrollProviderForTargetApps();
      fakeProvider.installedAppsList = [
        const TargetAppModel(
          packageName: 'com.ss.android.ugc.trill',
          appName: 'TikTok',
          isMonitored: true,
          isDefault: true,
        ),
        const TargetAppModel(
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          isMonitored: false,
          isDefault: true,
        ),
      ];
      controller = TargetAppsController(provider: fakeProvider);
      Get.put(controller);
    });

    testWidgets('Renders app title, search box, filter chips, and app list',
        (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: TargetAppsView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Target Doomscrolling'), findsOneWidget);
      expect(find.byKey(const Key('input_search_target_apps')), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Dipantau'), findsOneWidget);
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
    });

    testWidgets('Toggling switch updates state', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: TargetAppsView(),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder =
          find.byKey(const Key('switch_com.instagram.android'));
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(controller.monitoredCount, 2);
    });
  });
}
