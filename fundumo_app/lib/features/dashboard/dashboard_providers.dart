import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fundumo_controller.dart';
import '../../domain/models/models.dart';
import 'metrics.dart';

final dashboardSnapshotProvider =
    Provider<AsyncValue<DashboardSnapshot>>((ref) {
  final dataAsync = ref.watch(fundumoControllerProvider);
  return dataAsync.whenData(_buildSnapshot);
});

DashboardSnapshot _buildSnapshot(FundumoData data) {
  final now = DateTime.now();
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  final daysRemaining =
      max(1, endOfMonth.difference(now).inDays + 1); // inclusive of today

  final transactionsThisMonth = data.transactions
      .where((t) =>
          t.timestamp.year == now.year && t.timestamp.month == now.month)
      .toList();

  final todaySpend = transactionsThisMonth
      .where((t) => t.timestamp.day == now.day)
      .fold<double>(0, (value, t) => value + t.amount);

  final discretionaryBudgetMonthly = data.user.monthlyTakeHome -
      data.totalFixedMonthly -
      data.monthlySubscriptionSpend;

  final spentToDate = transactionsThisMonth.fold<double>(
    0,
    (value, t) => value + t.amount,
  );

  final remainingThisMonth =
      max(0.0, discretionaryBudgetMonthly - spentToDate).toDouble();
  final dailyBudgetRemaining =
      remainingThisMonth / max(1, daysRemaining).toDouble();

  final expectedDailySpend =
      discretionaryBudgetMonthly / max(1, endOfMonth.day).toDouble();
  final todayVariance =
      dailyBudgetRemaining - max(0.0, todaySpend - expectedDailySpend);

  final expenseSnapshot = ExpenseSnapshotMetrics(
    totalFixedMonthly: data.totalFixedMonthly,
    estimatedDiscretionaryMonthly: discretionaryBudgetMonthly,
    dailyBudgetRemaining: dailyBudgetRemaining,
    todayVariance: todayVariance,
    daysRemaining: daysRemaining,
  );

  final upcomingRenewals = data.subscriptions.sorted(
    (a, b) => a.nextRenewal.compareTo(b.nextRenewal),
  );

  final subscriptionSummary = SubscriptionSummary(
    monthlyTotal: data.monthlySubscriptionSpend,
    annualTotal: data.annualSubscriptionSpend,
    upcomingRenewals: upcomingRenewals.take(5).toList(),
  );

  final envelopeProgress = data.envelopes.map((envelope) {
    final spent = data.envelopeSpent(envelope.id);
    final remaining =
        max(0.0, envelope.allocation - spent).toDouble();
    final utilization = envelope.allocation == 0
        ? 0.0
        : (spent / envelope.allocation).clamp(0.0, 1.5).toDouble();
    return EnvelopeProgress(
      envelope: envelope,
      spent: spent,
      remaining: remaining,
      utilization: utilization,
    );
  }).toList()
    ..sortBy((element) => element.utilization);

  final sideGigSummaries = data.sideGigs.map((gig) {
    return SideGigSummary(
      gig: gig,
      totalHours: gig.totalHours,
      grossIncome: gig.grossIncome,
      expenses: gig.totalExpenses,
      taxProvision: gig.taxProvision,
      netProfit: gig.netProfit,
    );
  }).toList();

  final savingGoalSummaries = data.savingGoals.map((goal) {
    return SavingGoalSummary(
      goal: goal,
      totalSaved: goal.totalSaved,
      progress: goal.progress,
      daysRemaining: goal.daysRemaining,
    );
  }).toList();

  final sharedBillSummaries = data.sharedBills.map((group) {
    final balances = group.buildBalances();
    final resolved = <SharedBillParticipant, double>{};
    for (final participant in group.participants) {
      resolved[participant] = balances[participant.id] ?? 0;
    }
    return SharedBillSummary(
      group: group,
      balances: resolved,
    );
  }).toList();

  final receiptReminders = data.receipts.map((receipt) {
    final daysUntilExpiry =
        receipt.warrantyExpiry.difference(now).inDays;
    return ReceiptReminder(
      receipt: receipt,
      daysUntilExpiry: daysUntilExpiry,
    );
  }).sorted((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));

  return DashboardSnapshot(
    data: data,
    expenseSnapshot: expenseSnapshot,
    subscriptionSummary: subscriptionSummary,
    envelopeProgress: envelopeProgress,
    sideGigSummaries: sideGigSummaries,
    savingGoalSummaries: savingGoalSummaries,
    sharedBillSummaries: sharedBillSummaries,
    receiptReminders: receiptReminders,
    insights: _buildInsights(
      data: data,
      envelopeProgress: envelopeProgress,
      subscriptionSummary: subscriptionSummary,
      savingGoalSummaries: savingGoalSummaries,
    ),
    recentActivity: _buildRecentActivity(data),
  );
}

extension DateTimeFormatting on DateTime {
  String formatShort() => DateFormat('MMM d').format(this);
}

List<DashboardInsight> _buildInsights({
  required FundumoData data,
  required List<EnvelopeProgress> envelopeProgress,
  required SubscriptionSummary subscriptionSummary,
  required List<SavingGoalSummary> savingGoalSummaries,
}) {
  final insights = <DashboardInsight>[];
  final now = DateTime.now();

  final overspent = envelopeProgress
      .where((e) => e.utilization > 1)
      .toList()
    ..sortBy((e) => e.utilization);
  if (overspent.isNotEmpty) {
    final envelopeNames =
        overspent.map((e) => e.envelope.name).take(3).join(', ');
    insights.add(
      DashboardInsight(
        title: 'Check envelopes',
        message:
            '$envelopeNames exceeded their allocation. Consider rebalancing or moving funds.',
        type: InsightType.warning,
      ),
    );
  }

  final renewalsSoon = subscriptionSummary.upcomingRenewals
      .where(
        (sub) => sub.nextRenewal.difference(now).inDays <= 3,
      )
      .toList();
  if (renewalsSoon.isNotEmpty) {
    final subNames = renewalsSoon.map((s) => s.name).take(3).join(', ');
    insights.add(
      DashboardInsight(
        title: 'Renewals coming up',
        message:
            '$subNames renew soon. Double-check if you still need them before they charge again.',
        type: InsightType.info,
      ),
    );
  }

  final laggingGoals = savingGoalSummaries.where((goal) {
    if (goal.goal.contributions.isEmpty) {
      return false;
    }
    final startDate = goal.goal.contributions
        .map((c) => c.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final totalDuration =
        goal.goal.targetDate.difference(startDate).inDays;
    if (totalDuration <= 0) {
      return false;
    }
    final elapsed = now.difference(startDate).inDays;
    final expectedProgress =
        (elapsed / totalDuration).clamp(0.0, 1.0);
    return goal.progress + 0.1 < expectedProgress;
  }).toList();
  if (laggingGoals.isNotEmpty) {
    insights.add(
      DashboardInsight(
        title: 'Boost savings',
        message:
            '${laggingGoals.first.goal.name} is falling behind schedule. Nudging another contribution keeps it on track.',
        type: InsightType.info,
      ),
    );
  }

  final transactionsThisWeek = data.transactions.where((transaction) {
    return now.difference(transaction.timestamp).inDays <= 7;
  }).toList();
  final weeklyBudget = data.user.monthlyTakeHome / 4;
  final weeklySpent =
      transactionsThisWeek.fold<double>(0, (sum, transaction) => sum + transaction.amount);
  final weeklyRemaining = weeklyBudget - weeklySpent;

  const weeklyThresholdRatio = 0.3; // 30% of the weekly budget remains
  if (weeklyRemaining <= weeklyBudget * weeklyThresholdRatio) {
    insights.add(
      DashboardInsight(
        title: 'Weekly budget low',
        message:
            'Only ${weeklyRemaining.toStringAsFixed(0)} left in this week\'s plan. Focus on essentials until it resets.',
        type: InsightType.warning,
      ),
    );
  }

  final expiringReceipts = data.receipts.where((receipt) {
    final daysUntilExpiry =
        receipt.warrantyExpiry.difference(now).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 14;
  }).toList();
  if (expiringReceipts.isNotEmpty) {
    final titles = expiringReceipts.map((r) => r.title).take(3).join(', ');
    insights.add(
      DashboardInsight(
        title: 'Warranty expiring soon',
        message:
            '$titles warranty ends soon. Schedule repairs or extend coverage if needed.',
        type: InsightType.info,
      ),
    );
  }

  if (insights.isEmpty) {
    insights.add(
      DashboardInsight(
        title: 'All caught up',
        message: 'Budgets, subscriptions, and goals look healthy today.',
        type: InsightType.success,
      ),
    );
  }

  return insights;
}

List<DashboardActivityItem> _buildRecentActivity(FundumoData data) {
  final activities = <DashboardActivityItem>[];
  for (final transaction in data.transactions) {
    final envelope = data.envelopes
        .firstWhereOrNull((env) => env.id == transaction.envelopeId);
    activities.add(
      DashboardActivityItem(
        type: ActivityType.transaction,
        title: envelope?.name ?? 'Transaction',
        subtitle: transaction.notes.isNotEmpty
            ? transaction.notes
            : 'Envelope spend',
        amount: transaction.amount,
        timestamp: transaction.timestamp,
      ),
    );
  }

  for (final gig in data.sideGigs) {
    for (final entry in gig.entries) {
      activities.add(
        DashboardActivityItem(
          type: ActivityType.sideGig,
          title: gig.name,
          subtitle:
              '${entry.hours.toStringAsFixed(1)} h logged • Income ${entry.income.toStringAsFixed(0)}',
          amount: entry.income - entry.expenses,
          timestamp: entry.date,
        ),
      );
    }
  }

  for (final goal in data.savingGoals) {
    for (final contribution in goal.contributions) {
      activities.add(
        DashboardActivityItem(
          type: ActivityType.saving,
          title: goal.name,
          subtitle: 'Contribution',
          amount: contribution.amount,
          timestamp: contribution.date,
        ),
      );
    }
  }

  activities.sort(
    (a, b) => b.timestamp.compareTo(a.timestamp),
  );
  return activities.take(10).toList();
}

