import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/fundumo_controller.dart';
import '../../core/utils/color_extensions.dart';
import '../../core/widgets/async_state_view.dart';
import '../../domain/models/models.dart';
import '../../services/auto_reminder_service.dart';
import '../../services/local_notification_service.dart';
import 'dashboard_providers.dart';
import 'metrics.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);

    return snapshotAsync.when(
      data: (snapshot) => RefreshIndicator(
        onRefresh: () async {
          await ref.read(fundumoControllerProvider.notifier).refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _UserSummaryCard(
                user: snapshot.data.user,
                expenseSnapshot: snapshot.expenseSnapshot,
                totalEnvelopeRemaining: snapshot.totalEnvelopeRemaining,
                upcomingRenewals:
                    snapshot.subscriptionSummary.upcomingRenewals.length,
              ),
            ),
            _Section(
              title: 'Expense Snapshot',
              child: _ExpenseSnapshotCard(
                metrics: snapshot.expenseSnapshot,
                currency: snapshot.data.user.currencyFormat,
              ),
            ),
            _Section(
              title: 'Subscription Watchdog',
              child: _SubscriptionWatchdogCard(
                summary: snapshot.subscriptionSummary,
                currency: snapshot.data.user.currencyFormat,
                ref: ref,
              ),
            ),
            _Section(
              title: 'Cash Envelope Assistant',
              child: _EnvelopeAssistantCard(
                envelopes: snapshot.envelopeProgress,
                currency: snapshot.data.user.currencyFormat,
              ),
            ),
            _Section(
              title: 'Side-Gig Tracker',
              child: _SideGigTrackerCard(
                summaries: snapshot.sideGigSummaries,
                currency: snapshot.data.user.currencyFormat,
              ),
            ),
            _Section(
              title: 'Goal-Based Saving Jars',
              child: _SavingGoalsCard(
                summaries: snapshot.savingGoalSummaries,
                currency: snapshot.data.user.currencyFormat,
              ),
            ),
            _Section(
              title: 'Bill Splitting Friendlier',
              child: _BillSplittingCard(
                summaries: snapshot.sharedBillSummaries,
                currency: snapshot.data.user.currencyFormat,
              ),
            ),
            _Section(
              title: 'Receipt Vault',
              child: _ReceiptVaultCard(
                reminders: snapshot.receiptReminders,
                currency: snapshot.data.user.currencyFormat,
              ),
            ),
            if (snapshot.insights.isNotEmpty)
              _Section(
                title: 'Insights',
                child: _InsightsCard(
                  insights: snapshot.insights,
                  ref: ref,
                ),
              ),
            if (snapshot.recentActivity.isNotEmpty)
              _Section(
                title: 'Recent Activity',
                child: _RecentActivityCard(
                  items: snapshot.recentActivity,
                  currency: snapshot.data.user.currencyFormat,
                ),
              ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _exportSnapshot(context, snapshot),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export JSON'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _exportTransactionsCsv(context, snapshot),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Export CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _importSnapshot(context, ref),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Import JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _checkReminders(context, ref),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Check Reminders'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      loading: () => const AsyncLoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        message: 'Failed to load dashboard',
        details: error.toString(),
        onRetry: () =>
            ref.read(fundumoControllerProvider.notifier).refresh(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ExpenseSnapshotCard extends StatelessWidget {
  const _ExpenseSnapshotCard({
    required this.metrics,
    required this.currency,
  });

  final ExpenseSnapshotMetrics metrics;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remaining daily budget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(metrics.dailyBudgetRemaining),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(width: 12),
                _VarianceChip(
                  label: 'Variance today',
                  value: metrics.todayVariance,
                  currency: currency,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _KeyValueRow(
              label: 'Fixed monthly obligations',
              value: currency.format(metrics.totalFixedMonthly),
            ),
            _KeyValueRow(
              label: 'Discretionary budget this month',
              value: currency.format(metrics.estimatedDiscretionaryMonthly),
            ),
            _KeyValueRow(
              label: 'Days remaining',
              value: '${metrics.daysRemaining}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionWatchdogCard extends StatelessWidget {
  const _SubscriptionWatchdogCard({
    required this.summary,
    required this.currency,
    required this.ref,
  });

  final SubscriptionSummary summary;
  final NumberFormat currency;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _KeyValueRow(
                    label: 'Monthly total',
                    value: currency.format(summary.monthlyTotal),
                  ),
                ),
                Expanded(
                  child: _KeyValueRow(
                    label: 'Annualized',
                    value: currency.format(summary.annualTotal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Upcoming renewals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...summary.upcomingRenewals.map(
              (subscription) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.name,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${subscription.category} • ${subscription.nextRenewal.formatShort()}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    _SubscriptionActions(
                      subscription: subscription,
                      currency: currency,
                      ref: ref,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvelopeAssistantCard extends StatelessWidget {
  const _EnvelopeAssistantCard({
    required this.envelopes,
    required this.currency,
  });

  final List<EnvelopeProgress> envelopes;
  final NumberFormat currency;

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: envelopes.map((progress) {
          final color = _hexToColor(progress.envelope.colorHex);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacityFactor(0.2),
              child: Icon(Icons.account_balance_wallet, color: color),
            ),
            title: Text(progress.envelope.name),
            subtitle: LinearProgressIndicator(
              value: progress.utilization.clamp(0, 1),
              color: color,
              backgroundColor: color.withOpacityFactor(0.15),
              minHeight: 6,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${currency.format(progress.remaining)} left'),
                Text(
                  '${(progress.utilization * 100).clamp(0, 150).toStringAsFixed(0)}% used',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SideGigTrackerCard extends StatelessWidget {
  const _SideGigTrackerCard({
    required this.summaries,
    required this.currency,
  });

  final List<SideGigSummary> summaries;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: summaries.map((summary) {
          return ExpansionTile(
            title: Text(summary.gig.name),
            subtitle: Text(
              '${summary.totalHours.toStringAsFixed(1)} h logged • '
              'Net ${currency.format(summary.netProfit)}',
            ),
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            children: [
              _KeyValueRow(
                label: 'Gross income',
                value: currency.format(summary.grossIncome),
              ),
              _KeyValueRow(
                label: 'Expenses',
                value: currency.format(summary.expenses),
              ),
              _KeyValueRow(
                label: 'Tax provision (${(summary.gig.taxRate * 100).toStringAsFixed(0)}%)',
                value: currency.format(summary.taxProvision),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent sessions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              ...summary.gig.entries.sorted(
                (a, b) => b.date.compareTo(a.date),
              ).take(5).map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.date.formatShort()),
                  trailing: Text(
                    '${entry.hours.toStringAsFixed(1)} h • ${currency.format(entry.income - entry.expenses)}',
                  ),
                  subtitle: Text(
                    'Income: ${currency.format(entry.income)}  •  Expenses: ${currency.format(entry.expenses)}',
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SavingGoalsCard extends StatelessWidget {
  const _SavingGoalsCard({
    required this.summaries,
    required this.currency,
  });

  final List<SavingGoalSummary> summaries;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: summaries.map((summary) {
          final percentage = (summary.progress * 100).clamp(0, 100);
          return ListTile(
            title: Text(summary.goal.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: summary.progress,
                  minHeight: 6,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 6),
                Text(
                  '${currency.format(summary.totalSaved)} of ${currency.format(summary.goal.targetAmount)} '
                  '• ${summary.daysRemaining} days left',
                ),
              ],
            ),
            trailing: Chip(
              label: Text('${percentage.toStringAsFixed(0)}%'),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BillSplittingCard extends StatelessWidget {
  const _BillSplittingCard({
    required this.summaries,
    required this.currency,
  });

  final List<SharedBillSummary> summaries;
  final NumberFormat currency;

  Color _trendColor(double value, ColorScheme scheme) {
    if (value > 0) return scheme.tertiary;
    if (value < 0) return scheme.error;
    return scheme.onSurface.withOpacityFactor(0.7);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: summaries.map((summary) {
          return ExpansionTile(
            title: Text(summary.group.name),
            subtitle: Text(
              '${summary.group.expenses.length} shared expenses',
            ),
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            children: summary.balances.entries.map((entry) {
              final amount = entry.value;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  amount >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
                  color: _trendColor(amount, scheme),
                ),
                title: Text(entry.key.name),
                trailing: Text(
                  currency.format(amount),
                  style: TextStyle(color: _trendColor(amount, scheme)),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _ReceiptVaultCard extends StatelessWidget {
  const _ReceiptVaultCard({
    required this.reminders,
    required this.currency,
  });

  final List<ReceiptReminder> reminders;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: reminders.take(5).map((reminder) {
          final days = reminder.daysUntilExpiry;
          final scheme = Theme.of(context).colorScheme;
          final color = days <= 7
              ? scheme.error
              : days <= 30
                  ? scheme.tertiary
                  : scheme.onSurfaceVariant;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacityFactor(0.15),
              child: Icon(Icons.receipt_long, color: color),
            ),
            title: Text(reminder.receipt.title),
            subtitle: Text(
              'Purchased ${reminder.receipt.purchaseDate.formatShort()} • Warranty until ${reminder.receipt.warrantyExpiry.formatShort()}',
            ),
            trailing: Chip(
              label: Text(
                days >= 0 ? '$days days left' : 'Expired ${days.abs()} d',
              ),
              backgroundColor: color.withOpacityFactor(0.1),
              labelStyle: TextStyle(color: color),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UserSummaryCard extends StatelessWidget {
  const _UserSummaryCard({
    required this.user,
    required this.expenseSnapshot,
    required this.totalEnvelopeRemaining,
    required this.upcomingRenewals,
  });

  final UserProfile user;
  final ExpenseSnapshotMetrics expenseSnapshot;
  final double totalEnvelopeRemaining;
  final int upcomingRenewals;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final currency = user.currencyFormat;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          color: Theme.of(context).colorScheme
                              .onPrimaryContainer,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_greeting, ${user.name}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Monthly take-home ${currency.format(user.monthlyTakeHome)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Daily budget',
                    value: currency.format(
                      expenseSnapshot.dailyBudgetRemaining,
                    ),
                  ),
                ),
                Expanded(
                  child: _SummaryTile(
                    label: 'Envelope cushion',
                    value: currency.format(totalEnvelopeRemaining),
                  ),
                ),
                Expanded(
                  child: _SummaryTile(
                    label: 'Upcoming renewals',
                    value: '$upcomingRenewals',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({
    required this.insights,
    required this.ref,
  });

  final List<DashboardInsight> insights;
  final WidgetRef ref;

  Color _colorForType(InsightType type, ColorScheme scheme) {
    switch (type) {
      case InsightType.warning:
        return scheme.error;
      case InsightType.info:
        return scheme.tertiary;
      case InsightType.success:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: insights.map((insight) {
          final color = _colorForType(insight.type, scheme);
          return ListTile(
            leading: Icon(
              insight.type == InsightType.success
                  ? Icons.check_circle_outline
                  : insight.type == InsightType.warning
                      ? Icons.warning_amber_outlined
                      : Icons.insights_outlined,
              color: color,
            ),
            title: Text(insight.title),
            subtitle: Text(insight.message),
            trailing: insight.type != InsightType.success
                ? IconButton(
                    tooltip: 'Schedule reminder',
                    icon: const Icon(Icons.alarm_add_outlined),
                    onPressed: () {
                      _scheduleInsightReminder(
                        context,
                        ref,
                        insight,
                      );
                    },
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.items,
    required this.currency,
  });

  final List<DashboardActivityItem> items;
  final NumberFormat currency;

  IconData _iconForType(ActivityType type) {
    switch (type) {
      case ActivityType.transaction:
        return Icons.shopping_bag_outlined;
      case ActivityType.sideGig:
        return Icons.timer_outlined;
      case ActivityType.saving:
        return Icons.savings_outlined;
    }
  }

  Color _colorForType(ActivityType type, ColorScheme scheme) {
    switch (type) {
      case ActivityType.transaction:
        return scheme.primary;
      case ActivityType.sideGig:
        return scheme.tertiary;
      case ActivityType.saving:
        return scheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: items.map((item) {
          final color = _colorForType(item.type, scheme);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacityFactor(0.15),
              child: Icon(
                _iconForType(item.type),
                color: color,
              ),
            ),
            title: Text(item.title),
            subtitle: Text(
              '${item.subtitle} • ${DateFormat.MMMd().format(item.timestamp)}',
            ),
            trailing: Text(currency.format(item.amount)),
          );
        }).toList(),
      ),
    );
  }
}

Future<void> _exportSnapshot(
  BuildContext context,
  DashboardSnapshot snapshot,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/fundumo_export.json');
    await file.writeAsString(
      jsonEncode(snapshot.data.toJson()),
    );
    await Share.shareXFiles([XFile(file.path)], text: 'Fundumo export');
    messenger.showSnackBar(
      SnackBar(content: Text('Exported to ${file.path}')),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Export failed: $error')),
    );
  }
}

Future<void> _importSnapshot(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/fundumo_import.json');
    if (!await file.exists()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Place fundumo_import.json in documents first'),
        ),
      );
      return;
    }
    final contents = await file.readAsString();
    await ref
        .read(fundumoControllerProvider.notifier)
        .importExternalData(contents);
    messenger.showSnackBar(
      const SnackBar(content: Text('Import complete')),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Import failed: $error')),
    );
  }
}

Future<void> _exportTransactionsCsv(
  BuildContext context,
  DashboardSnapshot snapshot,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final buffer = StringBuffer();
    buffer.writeln('timestamp,envelope,amount,notes');
    final envelopeLookup = {
      for (final envelope in snapshot.data.envelopes) envelope.id: envelope.name
    };
    final transactions = [...snapshot.data.transactions]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    for (final transaction in transactions) {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(
        transaction.timestamp.toLocal(),
      );
      final envelopeName =
          envelopeLookup[transaction.envelopeId] ?? transaction.envelopeId;
      final escapedNotes =
          transaction.notes.replaceAll('"', '""');
      buffer.writeln(
        '"$timestamp","$envelopeName",${transaction.amount.toStringAsFixed(2)},"$escapedNotes"',
      );
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/fundumo_transactions.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Fundumo transactions export',
    );
    messenger.showSnackBar(
      SnackBar(content: Text('CSV exported to ${file.path}')),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('CSV export failed: $error')),
    );
  }
}

Future<void> _scheduleSubscriptionReminder(
  BuildContext context,
  WidgetRef ref,
  Subscription subscription,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final service = ref.read(localNotificationServiceProvider);
    final scheduledTime = DateTime.now().add(const Duration(hours: 24));
    await service.scheduleNotification(
      id: subscription.name.hashCode & 0x7fffffff,
      title: '${subscription.name} renews soon',
      body:
          'Renewal on ${DateFormat.yMMMd().format(subscription.nextRenewal)}',
      scheduledTime: scheduledTime,
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Reminder scheduled')),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Reminder failed: $error')),
    );
  }
}

Future<void> _scheduleInsightReminder(
  BuildContext context,
  WidgetRef ref,
  DashboardInsight insight,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final service = ref.read(localNotificationServiceProvider);
    final scheduledTime = DateTime.now().add(const Duration(hours: 24));
    await service.scheduleNotification(
      id: insight.hashCode & 0x7fffffff,
      title: insight.title,
      body: insight.message,
      scheduledTime: scheduledTime,
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Reminder scheduled')),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Reminder failed: $error')),
    );
  }
}

Future<void> _checkReminders(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(autoReminderServiceProvider).checkAllReminders();
    messenger.showSnackBar(
      const SnackBar(content: Text('Reminder check complete')),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Reminder check failed: $error')),
    );
  }
}

class _VarianceChip extends StatelessWidget {
  const _VarianceChip({
    required this.label,
    required this.value,
    required this.currency,
  });

  final String label;
  final double value;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPositive = value >= 0;
    final color = isPositive ? scheme.tertiary : scheme.error;
    return Chip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onTertiaryContainer),
          ),
          Text(
            currency.format(value),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      backgroundColor: color.withOpacityFactor(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ReminderBadge extends StatelessWidget {
  const _ReminderBadge({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    if (!subscription.requiresReminder) {
      return const SizedBox.shrink();
    }
    final days = subscription.nextRenewal.difference(DateTime.now()).inDays;
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      backgroundColor: scheme.error.withOpacityFactor(0.1),
      labelStyle: TextStyle(color: scheme.error),
      label: Text('Due in ${days.clamp(0, 90)} d'),
    );
  }
}

class _SubscriptionActions extends StatelessWidget {
  const _SubscriptionActions({
    required this.subscription,
    required this.currency,
    required this.ref,
  });

  final Subscription subscription;
  final NumberFormat currency;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(currency.format(subscription.monthlyValue)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReminderBadge(subscription: subscription),
            PopupMenuButton<_SnoozeOption>(
              tooltip: 'Adjust reminder',
              onSelected: (option) {
                ref
                    .read(fundumoControllerProvider.notifier)
                    .snoozeSubscription(
                      subscriptionName: subscription.name,
                      duration: option.duration,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Snoozed ${subscription.name} by ${option.label}',
                    ),
                  ),
                );
              },
              itemBuilder: (context) => _SnoozeOption.values
                  .map(
                    (option) => PopupMenuItem(
                      value: option,
                      child: Text('Snooze ${option.label}'),
                    ),
                  )
                  .toList(),
              icon: Icon(
                Icons.more_vert,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => _scheduleSubscriptionReminder(
            context,
            ref,
            subscription,
          ),
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Remind in 24h'),
        ),
      ],
    );
  }
}

enum _SnoozeOption {
  week(Duration(days: 7), '1 week'),
  month(Duration(days: 30), '1 month');

  const _SnoozeOption(this.duration, this.label);

  final Duration duration;
  final String label;
}
