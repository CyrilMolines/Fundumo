import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.budgetAlerts,
    required this.subscriptionAlerts,
    required this.warrantyAlerts,
  });

  final bool budgetAlerts;
  final bool subscriptionAlerts;
  final bool warrantyAlerts;

  NotificationPreferences copyWith({
    bool? budgetAlerts,
    bool? subscriptionAlerts,
    bool? warrantyAlerts,
  }) {
    return NotificationPreferences(
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      subscriptionAlerts: subscriptionAlerts ?? this.subscriptionAlerts,
      warrantyAlerts: warrantyAlerts ?? this.warrantyAlerts,
    );
  }
}

class NotificationPrefsService {
  NotificationPrefsService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _budgetKey = 'notif_budget';
  static const _subsKey = 'notif_subscriptions';
  static const _warrantyKey = 'notif_warranty';

  Future<SharedPreferences> _preferences() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<NotificationPreferences> load() async {
    final prefs = await _preferences();
    return NotificationPreferences(
      budgetAlerts: prefs.getBool(_budgetKey) ?? true,
      subscriptionAlerts: prefs.getBool(_subsKey) ?? true,
      warrantyAlerts: prefs.getBool(_warrantyKey) ?? true,
    );
  }

  Future<void> save(NotificationPreferences prefsModel) async {
    final prefs = await _preferences();
    await prefs.setBool(_budgetKey, prefsModel.budgetAlerts);
    await prefs.setBool(_subsKey, prefsModel.subscriptionAlerts);
    await prefs.setBool(_warrantyKey, prefsModel.warrantyAlerts);
  }
}

