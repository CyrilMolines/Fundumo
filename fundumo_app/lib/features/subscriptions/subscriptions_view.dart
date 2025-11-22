import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fundumo_controller.dart';
import '../../core/widgets/async_state_view.dart';
import '../../domain/models/models.dart';

class SubscriptionsView extends ConsumerWidget {
  const SubscriptionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(fundumoControllerProvider);

    return dataAsync.when(
      data: (data) {
        final currency = data.user.currencyFormat;
        final subscriptions = List<Subscription>.from(data.subscriptions)
          ..sort((a, b) => a.nextRenewal.compareTo(b.nextRenewal));

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Total monthly spend: ${currency.format(data.monthlySubscriptionSpend)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Annualized: ${currency.format(data.annualSubscriptionSpend)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            ...subscriptions.map(
              (subscription) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    subscription.requiresReminder
                        ? Icons.warning_amber
                        : Icons.subscriptions_outlined,
                    color: subscription.requiresReminder
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                  title: Text(subscription.name),
                  subtitle: Text(
                    '${subscription.category} • Renews ${DateFormat.yMMMd().format(subscription.nextRenewal)}',
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currency.format(subscription.monthlyValue)),
                      PopupMenuButton<_SnoozeOption>(
                        onSelected: (option) {
                          ref.read(fundumoControllerProvider.notifier).snoozeSubscription(
                                subscriptionName: subscription.name,
                                duration: option.duration,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Snoozed ${subscription.name} by ${option.label}.',
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
                        child: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const AsyncLoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        message: 'Unable to load subscriptions',
        details: error.toString(),
        onRetry: () => ref.read(fundumoControllerProvider.notifier).refresh(),
      ),
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

