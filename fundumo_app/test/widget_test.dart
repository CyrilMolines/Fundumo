// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fundumo_app/app.dart';
import 'package:fundumo_app/application/fundumo_controller.dart';
import 'package:fundumo_app/data/fundumo_repository.dart';
import 'package:fundumo_app/data/local_fundumo_store.dart';
import 'package:fundumo_app/services/local_notification_service.dart';

class InMemoryFundumoStore extends LocalFundumoStore {
  Map<String, dynamic>? _cache;

  @override
  Future<Map<String, dynamic>?> read() async => _cache;

  @override
  Future<void> write(Map<String, dynamic> data) async {
    _cache = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  }
}

void main() {
  testWidgets('Dashboard loads core modules', (WidgetTester tester) async {
    final store = InMemoryFundumoStore();
    SharedPreferences.setMockInitialValues({});
    final notificationService = LocalNotificationService.disabled();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localFundumoStoreProvider.overrideWithValue(store),
          localNotificationServiceProvider.overrideWithValue(
            notificationService,
          ),
        ],
        child: const FundumoApp(),
      ),
    );

    await tester.pump();
    final context = tester.element(find.byType(FundumoApp));
    final container = ProviderScope.containerOf(context, listen: false);
    await tester.runAsync(() async {
      await container.read(fundumoControllerProvider.future);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Fundumo Overview'), findsWidgets);
    expect(find.text('Expense Snapshot'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Subscription Watchdog'),
      300,
    );
    expect(find.text('Subscription Watchdog'), findsOneWidget);
  });
}
