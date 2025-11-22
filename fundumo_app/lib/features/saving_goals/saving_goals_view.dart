import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fundumo_controller.dart';
import '../../core/widgets/async_state_view.dart';
import '../../domain/models/models.dart';

class SavingGoalsView extends ConsumerWidget {
  const SavingGoalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(fundumoControllerProvider);

    return dataAsync.when(
      data: (data) {
        if (data.savingGoals.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No savings goals defined yet'),
            ),
          );
        }

        final currency = data.user.currencyFormat;

        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: data.savingGoals.map((goal) {
            final progressPercent = (goal.progress * 100).clamp(0, 100);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currency.format(goal.totalSaved)} of ${currency.format(goal.targetAmount)} saved',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${goal.daysRemaining} days remaining • Target ${DateFormat.yMMMd().format(goal.targetDate)}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: goal.contributions
                          .map(
                            (contribution) => Chip(
                              label: Text(
                                '${DateFormat.MMMd().format(contribution.date)} • ${currency.format(contribution.amount)}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Progress: ${progressPercent.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const AsyncLoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        message: 'Unable to load saving goals',
        details: error.toString(),
        onRetry: () => ref.read(fundumoControllerProvider.notifier).refresh(),
      ),
    );
  }
}

class SavingGoalsFab extends ConsumerWidget {
  const SavingGoalsFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(fundumoControllerProvider).valueOrNull;
    return FloatingActionButton.extended(
      onPressed:
          data == null ? null : () => _showContributionSheet(context, ref, data),
      icon: const Icon(Icons.savings),
      label: const Text('Add contribution'),
    );
  }
}

Future<void> _showContributionSheet(
  BuildContext context,
  WidgetRef ref,
  FundumoData data,
) async {
  if (data.savingGoals.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create a savings goal first.')),
    );
    return;
  }

  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  String selectedGoalId = data.savingGoals.first.id;
  DateTime selectedDate = DateTime.now();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add contribution',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedGoalId,
                decoration: const InputDecoration(labelText: 'Goal'),
                items: data.savingGoals
                    .map(
                      (goal) => DropdownMenuItem(
                        value: goal.id,
                        child: Text(goal.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) selectedGoalId = value;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(DateFormat.yMMMd().format(selectedDate)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) selectedDate = picked;
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Change date'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    ref.read(fundumoControllerProvider.notifier).addSavingContribution(
                          goalId: selectedGoalId,
                          amount: double.parse(amountController.text),
                          date: selectedDate,
                        );
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contribution added')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

