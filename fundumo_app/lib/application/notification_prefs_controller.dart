import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_prefs_service.dart';

final notificationPrefsServiceProvider =
    Provider<NotificationPrefsService>((ref) {
  return NotificationPrefsService();
});

final notificationPrefsControllerProvider = AsyncNotifierProvider<
    NotificationPrefsController, NotificationPreferences>(
  NotificationPrefsController.new,
);

class NotificationPrefsController
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final service = ref.read(notificationPrefsServiceProvider);
    return service.load();
  }

  Future<void> setPrefs(NotificationPreferences prefs) async {
    state = AsyncData(prefs);
    final service = ref.read(notificationPrefsServiceProvider);
    await service.save(prefs);
  }
}

