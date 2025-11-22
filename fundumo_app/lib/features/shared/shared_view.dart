import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fundumo_controller.dart';
import '../../core/utils/color_extensions.dart';
import '../../core/widgets/async_state_view.dart';
import '../../domain/models/models.dart';

class SharedFinancesView extends ConsumerWidget {
  const SharedFinancesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(fundumoControllerProvider);

    return dataAsync.when(
      data: (data) {
        final currency = data.user.currencyFormat;
        final groups = data.sharedBills.sorted(
          (a, b) => a.name.compareTo(b.name),
        );
        final receipts = data.receipts.sorted(
          (a, b) => a.warrantyExpiry.compareTo(b.warrantyExpiry),
        );

        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Shared ledgers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...groups.map(
              (group) {
                final balances = group.buildBalances();
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ExpansionTile(
                    title: Text(group.name),
                    subtitle: Text('${group.expenses.length} expenses logged'),
                    childrenPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Participant balances',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...group.participants.map((participant) {
                        final balance = balances[participant.id] ?? 0;
                        final colorScheme = Theme.of(context).colorScheme;
                        Color color;
                        IconData icon;
                        if (balance > 0) {
                          color = colorScheme.tertiary;
                          icon = Icons.arrow_downward;
                        } else if (balance < 0) {
                          color = colorScheme.error;
                          icon = Icons.arrow_upward;
                        } else {
                          color = colorScheme.onSurfaceVariant;
                          icon = Icons.remove;
                        }
                        return ListTile(
                          dense: true,
                          leading: Icon(icon, color: color),
                          title: Text(participant.name),
                          trailing: Text(
                            currency.format(balance),
                            style: TextStyle(color: color),
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent expenses',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ...group.expenses
                          .sorted((a, b) => b.date.compareTo(a.date))
                          .take(5)
                          .map(
                            (expense) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.receipt),
                              title: Text(expense.title),
                              subtitle: Text(
                                '${DateFormat.yMMMd().format(expense.date)} • Paid by ${group.participants.firstWhere((p) => p.id == expense.paidBy).name}',
                              ),
                              trailing: Text(currency.format(expense.amount)),
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Receipt vault',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...receipts.map(
              (receipt) {
                final daysRemaining = receipt.warrantyExpiry.difference(DateTime.now()).inDays;
                final colorScheme = Theme.of(context).colorScheme;
                Color color;
                if (daysRemaining < 0) {
                  color = colorScheme.error;
                } else if (daysRemaining <= 30) {
                  color = colorScheme.tertiary;
                } else {
                  color = colorScheme.onSurfaceVariant;
                }
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacityFactor(0.12),
                    child: Icon(Icons.archive, color: color),
                  ),
                  title: Text(receipt.title),
                  subtitle: Text(
                    'Purchased ${DateFormat.yMMMd().format(receipt.purchaseDate)} • Warranty ${DateFormat.yMMMd().format(receipt.warrantyExpiry)}',
                  ),
                  trailing: Text(
                    daysRemaining >= 0 ? '$daysRemaining days left' : 'Expired ${daysRemaining.abs()} d',
                    style: TextStyle(color: color),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const AsyncLoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        message: 'Unable to load shared finances',
        details: error.toString(),
        onRetry: () => ref.read(fundumoControllerProvider.notifier).refresh(),
      ),
    );
  }
}

class SharedFinancesFab extends ConsumerWidget {
  const SharedFinancesFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(fundumoControllerProvider).valueOrNull;
    return FloatingActionButton.extended(
      onPressed:
          data == null ? null : () => _showSharedActions(context, ref, data),
      icon: const Icon(Icons.group_add),
      label: const Text('Add record'),
    );
  }
}

Future<void> _showSharedActions(
  BuildContext context,
  WidgetRef ref,
  FundumoData data,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.groups),
            title: const Text('Add shared expense'),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await _showAddSharedExpenseForm(context, ref, data);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Add receipt'),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await _showAddReceiptForm(context, ref);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

Future<void> _showAddSharedExpenseForm(
  BuildContext context,
  WidgetRef ref,
  FundumoData data,
) async {
  if (data.sharedBills.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create a shared group first.')),
    );
    return;
  }

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final group = ValueNotifier<SharedBillGroup>(data.sharedBills.first);
  final paidBy = ValueNotifier<String>(data.sharedBills.first.participants.first.id);
  SharedSplitMode splitMode = SharedSplitMode.equal;
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
          child: ValueListenableBuilder<SharedBillGroup>(
            valueListenable: group,
            builder: (context, currentGroup, _) {
              final participants = currentGroup.participants;
              if (!participants.any((p) => p.id == paidBy.value)) {
                paidBy.value = participants.first.id;
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add shared expense',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SharedBillGroup>(
                    initialValue: currentGroup,
                    decoration: const InputDecoration(labelText: 'Group'),
                    items: data.sharedBills
                        .map(
                          (group) => DropdownMenuItem(
                            value: group,
                            child: Text(group.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        group.value = value;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
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
                  DropdownButtonFormField<String>(
                    initialValue: paidBy.value,
                    decoration: const InputDecoration(labelText: 'Paid by'),
                    items: participants
                        .map(
                          (participant) => DropdownMenuItem(
                            value: participant.id,
                            child: Text(participant.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) paidBy.value = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SharedSplitMode>(
                    initialValue: splitMode,
                    decoration: const InputDecoration(labelText: 'Split mode'),
                    items: SharedSplitMode.values
                        .map(
                          (mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(mode == SharedSplitMode.equal ? 'Equal parts' : 'Weighted'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) splitMode = value;
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
                        if (!formKey.currentState!.validate()) return;
                        ref.read(fundumoControllerProvider.notifier).addSharedExpense(
                              groupId: currentGroup.id,
                              title: titleController.text.trim(),
                              amount: double.parse(amountController.text),
                              paidBy: paidBy.value,
                              date: selectedDate,
                              mode: splitMode,
                            );
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shared expense recorded')),
                        );
                      },
                      child: const Text('Save expense'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

Future<void> _showAddReceiptForm(
  BuildContext context,
  WidgetRef ref,
) async {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final categoryController = TextEditingController();
  DateTime purchaseDate = DateTime.now();
  DateTime warrantyExpiry = DateTime.now().add(const Duration(days: 365));

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
                'Add receipt',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Purchase date', style: Theme.of(context).textTheme.labelMedium),
                        Text(DateFormat.yMMMd().format(purchaseDate)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: purchaseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) purchaseDate = picked;
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Warranty expiry', style: Theme.of(context).textTheme.labelMedium),
                        Text(DateFormat.yMMMd().format(warrantyExpiry)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: warrantyExpiry,
                        firstDate: purchaseDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) warrantyExpiry = picked;
                    },
                    child: const Text('Change'),
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
                    ref.read(fundumoControllerProvider.notifier).addReceipt(
                          title: titleController.text.trim(),
                          category: categoryController.text.trim().isEmpty
                              ? 'General'
                              : categoryController.text.trim(),
                          purchaseDate: purchaseDate,
                          warrantyExpiry: warrantyExpiry,
                        );
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receipt saved')),
                    );
                  },
                  child: const Text('Save receipt'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

