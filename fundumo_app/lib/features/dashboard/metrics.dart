import 'package:collection/collection.dart';

import '../../domain/models/models.dart';

class ExpenseSnapshotMetrics {
  ExpenseSnapshotMetrics({
    required this.totalFixedMonthly,
    required this.estimatedDiscretionaryMonthly,
    required this.dailyBudgetRemaining,
    required this.todayVariance,
    required this.daysRemaining,
  });

  final double totalFixedMonthly;
  final double estimatedDiscretionaryMonthly;
  final double dailyBudgetRemaining;
  final double todayVariance;
  final int daysRemaining;
}

class SubscriptionSummary {
  SubscriptionSummary({
    required this.monthlyTotal,
    required this.annualTotal,
    required this.upcomingRenewals,
  });

  final double monthlyTotal;
  final double annualTotal;
  final List<Subscription> upcomingRenewals;
}

class EnvelopeProgress {
  EnvelopeProgress({
    required this.envelope,
    required this.spent,
    required this.remaining,
    required this.utilization,
  });

  final Envelope envelope;
  final double spent;
  final double remaining;
  final double utilization;
}

class SideGigSummary {
  SideGigSummary({
    required this.gig,
    required this.totalHours,
    required this.grossIncome,
    required this.expenses,
    required this.taxProvision,
    required this.netProfit,
  });

  final SideGig gig;
  final double totalHours;
  final double grossIncome;
  final double expenses;
  final double taxProvision;
  final double netProfit;
}

class SavingGoalSummary {
  SavingGoalSummary({
    required this.goal,
    required this.totalSaved,
    required this.progress,
    required this.daysRemaining,
  });

  final SavingGoal goal;
  final double totalSaved;
  final double progress;
  final int daysRemaining;
}

class SharedBillSummary {
  SharedBillSummary({
    required this.group,
    required this.balances,
  });

  final SharedBillGroup group;
  final Map<SharedBillParticipant, double> balances;
}

class ReceiptReminder {
  ReceiptReminder({
    required this.receipt,
    required this.daysUntilExpiry,
  });

  final Receipt receipt;
  final int daysUntilExpiry;
}

class DashboardSnapshot {
  DashboardSnapshot({
    required this.data,
    required this.expenseSnapshot,
    required this.subscriptionSummary,
    required this.envelopeProgress,
    required this.sideGigSummaries,
    required this.savingGoalSummaries,
    required this.sharedBillSummaries,
    required this.receiptReminders,
    required this.insights,
    required this.recentActivity,
  });

  final FundumoData data;
  final ExpenseSnapshotMetrics expenseSnapshot;
  final SubscriptionSummary subscriptionSummary;
  final List<EnvelopeProgress> envelopeProgress;
  final List<SideGigSummary> sideGigSummaries;
  final List<SavingGoalSummary> savingGoalSummaries;
  final List<SharedBillSummary> sharedBillSummaries;
  final List<ReceiptReminder> receiptReminders;
  final List<DashboardInsight> insights;
  final List<DashboardActivityItem> recentActivity;

  double get totalEnvelopeRemaining => envelopeProgress.fold<double>(
        0,
        (value, progress) => value + progress.remaining,
      );

  double get totalEnvelopeUtilization => envelopeProgress.isEmpty
      ? 0
      : envelopeProgress
              .map((e) => e.utilization)
              .average;
}

enum InsightType { warning, info, success }

class DashboardInsight {
  DashboardInsight({
    required this.title,
    required this.message,
    required this.type,
  });

  final String title;
  final String message;
  final InsightType type;
}

enum ActivityType { transaction, sideGig, saving }

class DashboardActivityItem {
  DashboardActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.timestamp,
  });

  final ActivityType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime timestamp;
}

