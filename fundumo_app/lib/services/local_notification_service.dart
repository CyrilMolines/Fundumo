import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  LocalNotificationService.disabled() : _plugin = null;

  final FlutterLocalNotificationsPlugin? _plugin;

  static const _channelId = 'fundumo_reminders';
  static const _channelName = 'Fundumo Reminders';

  Future<void> initialize() async {
    final plugin = _plugin;
    if (plugin == null) return;
    tz.initializeTimeZones();
    final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await plugin.initialize(settings);
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Budget and subscription reminders',
      importance: Importance.high,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final plugin = _plugin;
    if (plugin == null) return;
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    final target = tz.TZDateTime.from(scheduledTime, tz.local);
    await plugin.zonedSchedule(
      id,
      title,
      body,
      target,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => throw UnimplementedError('Notification service not initialized'),
);

