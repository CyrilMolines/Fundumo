import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/fundumo_controller.dart';
import '../domain/models/models.dart';
import 'local_notification_service.dart';

/// Service that automatically schedules reminders for warranties and budget alerts
class AutoReminderService {
  AutoReminderService({
    required this.notificationService,
    required this.ref,
  });

  final LocalNotificationService notificationService;
  final Ref ref;

  /// Check and schedule reminders for warranties expiring soon
  Future<void> checkAndScheduleWarrantyReminders() async {
    final dataAsync = ref.read(fundumoControllerProvider);
    final data = dataAsync.valueOrNull;
    if (data == null) return;

    final now = DateTime.now();
    final receipts = data.receipts;

    // Schedule reminders for warranties expiring within 30 days
    for (final receipt in receipts) {
      final daysUntilExpiry = receipt.warrantyExpiry.difference(now).inDays;

      // Skip if already expired (more than 0 days ago) or more than 30 days away
      if (daysUntilExpiry < 0 || daysUntilExpiry > 30) continue;

      // Determine which reminder milestone to schedule
      int reminderDays;
      DateTime scheduledTime;

      if (daysUntilExpiry == 0) {
        // Expiring today - schedule for today
        reminderDays = 0;
        scheduledTime = receipt.warrantyExpiry;
      } else if (daysUntilExpiry <= 7) {
        // Within 7 days - schedule reminder for tomorrow
        reminderDays = daysUntilExpiry;
        scheduledTime = now.add(const Duration(days: 1));
      } else if (daysUntilExpiry <= 14) {
        // Within 14 days - schedule reminder for 7 days before expiry
        reminderDays = 7;
        scheduledTime = receipt.warrantyExpiry.subtract(const Duration(days: 7));
      } else if (daysUntilExpiry <= 30) {
        // Within 30 days - schedule reminder for 14 days before expiry
        reminderDays = 14;
        scheduledTime = receipt.warrantyExpiry.subtract(const Duration(days: 14));
      } else {
        continue;
      }

      // Only schedule if the scheduled time is in the future
      if (scheduledTime.isAfter(now)) {
        await _scheduleWarrantyReminder(
          receipt: receipt,
          daysUntilExpiry: reminderDays,
          scheduledTime: scheduledTime,
        );
      }
    }
  }

  Future<void> _scheduleWarrantyReminder({
    required Receipt receipt,
    required int daysUntilExpiry,
    required DateTime scheduledTime,
  }) async {
    final id = 'warranty-${receipt.id}-$daysUntilExpiry'.hashCode & 0x7fffffff;
    final title = daysUntilExpiry == 0
        ? 'Warranty expired: ${receipt.title}'
        : 'Warranty expiring soon: ${receipt.title}';
    final body = daysUntilExpiry == 0
        ? 'The warranty for ${receipt.title} expired today. Schedule repairs or extend coverage if needed.'
        : 'The warranty for ${receipt.title} expires in $daysUntilExpiry days (${DateFormat.yMMMd().format(receipt.warrantyExpiry)}). Schedule repairs or extend coverage if needed.';

    await notificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
  }

  /// Check and schedule reminders for budget spikes
  Future<void> checkAndScheduleBudgetSpikeReminders() async {
    final dataAsync = ref.read(fundumoControllerProvider);
    final data = dataAsync.valueOrNull;
    if (data == null) return;

    final now = DateTime.now();
    final transactionsThisWeek = data.transactions.where((transaction) {
      return now.difference(transaction.timestamp).inDays <= 7;
    }).toList();

    final weeklyBudget = data.user.monthlyTakeHome / 4;
    final weeklySpent = transactionsThisWeek.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );

    // Schedule reminder if weekly spend exceeds 80% of weekly budget
    const thresholdRatio = 0.8;
    if (weeklySpent >= weeklyBudget * thresholdRatio) {
      final weeklyRemaining = weeklyBudget - weeklySpent;
      final id = 'budget-spike-${now.year}-${now.month}-${now.day}'.hashCode &
          0x7fffffff;
      final title = 'Weekly budget alert';
      final body = weeklyRemaining <= 0
          ? 'You\'ve exceeded your weekly budget by ${(-weeklyRemaining).toStringAsFixed(0)}. Focus on essentials until it resets.'
          : 'You\'ve used ${(thresholdRatio * 100).toStringAsFixed(0)}% of your weekly budget. Only ${weeklyRemaining.toStringAsFixed(0)} remaining. Focus on essentials until it resets.';

      // Schedule for tomorrow morning at 9 AM
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 0);
      await notificationService.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: tomorrow,
      );
    }
  }

  /// Run all automatic reminder checks
  Future<void> checkAllReminders() async {
    await checkAndScheduleWarrantyReminders();
    await checkAndScheduleBudgetSpikeReminders();
  }
}

final autoReminderServiceProvider = Provider<AutoReminderService>((ref) {
  final notificationService = ref.watch(localNotificationServiceProvider);
  return AutoReminderService(
    notificationService: notificationService,
    ref: ref,
  );
});

