import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/fundumo_controller.dart';
import '../../core/widgets/async_state_view.dart';
import '../../domain/models/models.dart';

class EnvelopesView extends ConsumerWidget {
  const EnvelopesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(fundumoControllerProvider);

    return dataAsync.when(
      data: (data) {
        final currency = data.user.currencyFormat;
        final envelopes = data.envelopes.map((envelope) {
          final spent = data.envelopeSpent(envelope.id);
          final remaining =
              (envelope.allocation - spent).clamp(0, double.infinity).toDouble();
          final utilization = envelope.allocation == 0
              ? 0.0
              : (spent / envelope.allocation).clamp(0.0, 1.5);
          return _EnvelopeOverview(
            envelope: envelope,
            spent: spent,
            remaining: remaining,
            utilization: utilization,
          );
        }).toList()
          ..sort((a, b) => a.envelope.name.compareTo(b.envelope.name));

        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Active envelopes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...envelopes.map(
              (overview) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(overview.envelope.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: overview.utilization.clamp(0, 1),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${currency.format(overview.spent)} spent • '
                        '${currency.format(overview.remaining)} remaining',
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(overview.utilization * 100).clamp(0, 150).toStringAsFixed(0)}% used',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      if (overview.envelope.rollover)
                        Text(
                          'Rollover',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (data.transactions.isNotEmpty)
              _RecentTransactionsSection(data: data),
          ],
        );
      },
      loading: () => const AsyncLoadingView(),
      error: (error, stackTrace) => AsyncErrorView(
        message: 'Unable to load envelopes',
        details: error.toString(),
        onRetry: () => ref.read(fundumoControllerProvider.notifier).refresh(),
      ),
    );
  }
}

class EnvelopesFab extends ConsumerWidget {
  const EnvelopesFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(fundumoControllerProvider);
    final data = dataAsync.valueOrNull;

    return FloatingActionButton.extended(
      onPressed: data == null
          ? null
          : () => _showEnvelopeActions(context, ref, data),
      icon: const Icon(Icons.add),
      label: const Text('Manage'),
    );
  }
}

Future<void> _showEnvelopeActions(
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
            leading: const Icon(Icons.receipt_long),
            title: const Text('Log transaction'),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await _showLogTransactionSheet(context, ref, data);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Create envelope'),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await _showCreateEnvelopeSheet(context, ref);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

Future<void> _showLogTransactionSheet(
  BuildContext context,
  WidgetRef ref,
  FundumoData data,
) async {
  if (data.envelopes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create an envelope before logging transactions.')),
    );
    return;
  }

  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  String selectedEnvelopeId = data.envelopes.first.id;
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
                'Log transaction',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedEnvelopeId,
                decoration: const InputDecoration(
                  labelText: 'Envelope',
                ),
                items: data.envelopes
                    .map(
                      (envelope) => DropdownMenuItem(
                        value: envelope.id,
                        child: Text(envelope.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedEnvelopeId = value;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    DateFormat.yMMMd().format(selectedDate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
                    final amount = double.parse(amountController.text);
                    ref.read(fundumoControllerProvider.notifier).addTransaction(
                          envelopeId: selectedEnvelopeId,
                          amount: amount,
                          timestamp: selectedDate,
                          notes: notesController.text.trim(),
                        );
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction logged')),
                    );
                  },
                  child: const Text('Save transaction'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showCreateEnvelopeSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final allocationController = TextEditingController();
  String selectedColor = _availableColors.entries.first.key;
  bool rollover = false;

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
                'Create envelope',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: allocationController,
                decoration: const InputDecoration(
                  labelText: 'Monthly allocation',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive allocation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedColor,
                decoration: const InputDecoration(labelText: 'Color'),
                items: _availableColors.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: entry.value,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            Text(entry.key),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedColor = value;
                  }
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: rollover,
                onChanged: (value) => rollover = value,
                title: const Text('Enable rollover'),
                subtitle: const Text('Unused funds move to next month'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    final allocation = double.parse(allocationController.text);
                    final color = _availableColors[selectedColor];
                    ref.read(fundumoControllerProvider.notifier).createEnvelope(
                          name: nameController.text.trim(),
                          allocation: allocation,
                          rollover: rollover,
                          color: color,
                        );
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Envelope created')),
                    );
                  },
                  child: const Text('Create envelope'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _EnvelopeOverview {
  _EnvelopeOverview({
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

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({required this.data});

  final FundumoData data;

  @override
  Widget build(BuildContext context) {
    final currency = data.user.currencyFormat;
    final recent = data.transactions
        .sorted((a, b) => b.timestamp.compareTo(a.timestamp))
        .take(8)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recent transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        ...recent.map(
          (transaction) {
            final envelope = data.envelopes.firstWhere(
              (env) => env.id == transaction.envelopeId,
              orElse: () => Envelope(
                id: transaction.envelopeId,
                name: transaction.envelopeId,
                allocation: 0,
                rollover: false,
                colorHex: '#005F73',
              ),
            );
            return ListTile(
              leading: const Icon(Icons.monetization_on),
              title: Text(envelope.name),
              subtitle: Text(DateFormat.yMMMd().format(transaction.timestamp)),
              trailing: Text(currency.format(transaction.amount)),
            );
          },
        ),
      ],
    );
  }
}

const Map<String, Color> _availableColors = {
  'Teal': Color(0xFF0A9396),
  'Amber': Color(0xFFFFB703),
  'Rose': Color(0xFFEE6C4D),
  'Indigo': Color(0xFF4F46E5),
  'Forest': Color(0xFF2F5D62),
};

