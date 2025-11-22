import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fundumo_controller.dart';
import '../../core/widgets/async_state_view.dart';
import '../../domain/models/models.dart';

class SideGigsView extends ConsumerWidget {
  const SideGigsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(fundumoControllerProvider);

    return dataAsync.when(
      data: (data) {
        final gigs = data.sideGigs.sorted(
          (a, b) => b.netProfit.compareTo(a.netProfit),
        );
        final currency = data.user.currencyFormat;

        if (gigs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No side gigs logged yet'),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: gigs.map((gig) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ExpansionTile(
                title: Text(gig.name),
                subtitle: Text(
                  '${gig.totalHours.toStringAsFixed(1)} h • Net ${currency.format(gig.netProfit)}',
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  _KeyMetricRow(
                    label: 'Gross income',
                    value: currency.format(gig.grossIncome),
                  ),
                  _KeyMetricRow(
                    label: 'Expenses',
                    value: currency.format(gig.totalExpenses),
                  ),
                  _KeyMetricRow(
                    label: 'Tax provision (${(gig.taxRate * 100).toStringAsFixed(0)}%)',
                    value: currency.format(gig.taxProvision),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent sessions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...gig.entries.sorted((a, b) => b.date.compareTo(a.date)).map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(DateFormat.yMMMd().format(entry.date)),
                      subtitle: Text(
                        '${entry.hours.toStringAsFixed(1)} h • Income ${currency.format(entry.income)} • Expenses ${currency.format(entry.expenses)}',
                      ),
                      trailing: Text(
                        currency.format(entry.income - entry.expenses),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const AsyncLoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        message: 'Unable to load side gigs',
        details: error.toString(),
        onRetry: () => ref.read(fundumoControllerProvider.notifier).refresh(),
      ),
    );
  }
}

class SideGigsFab extends ConsumerWidget {
  const SideGigsFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(fundumoControllerProvider).valueOrNull;
    return FloatingActionButton.extended(
      onPressed:
          data == null ? null : () => _showAddEntrySheet(context, ref, data),
      icon: const Icon(Icons.timer),
      label: const Text('Log hours'),
    );
  }
}

Future<void> _showAddEntrySheet(
  BuildContext context,
  WidgetRef ref,
  FundumoData data,
) async {
  if (data.sideGigs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create a side gig profile before logging time.'),
      ),
    );
    return;
  }

  final formKey = GlobalKey<FormState>();
  final hoursController = TextEditingController();
  final incomeController = TextEditingController();
  final expensesController = TextEditingController(text: '0');
  String selectedGigId = data.sideGigs.first.id;
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
                'Log side gig hours',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedGigId,
                decoration: const InputDecoration(labelText: 'Gig'),
                items: data.sideGigs
                    .map(
                      (gig) => DropdownMenuItem(
                        value: gig.id,
                        child: Text(gig.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedGigId = value;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: hoursController,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter the hours worked';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: incomeController,
                decoration: const InputDecoration(
                  labelText: 'Income',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid income';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: expensesController,
                decoration: const InputDecoration(
                  labelText: 'Expenses',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Expenses cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                      if (picked != null) {
                        selectedDate = picked;
                      }
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
                    ref.read(fundumoControllerProvider.notifier).addSideGigEntry(
                          gigId: selectedGigId,
                          hours: double.parse(hoursController.text),
                          income: double.parse(incomeController.text),
                          expenses: double.parse(expensesController.text),
                          date: selectedDate,
                        );
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Side gig entry added')),
                    );
                  },
                  child: const Text('Save entry'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _KeyMetricRow extends StatelessWidget {
  const _KeyMetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

