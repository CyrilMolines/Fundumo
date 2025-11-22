import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/fundumo_repository.dart';
import '../domain/models/models.dart';
import '../services/auto_reminder_service.dart';
import '../services/sync_service.dart';

final fundumoControllerProvider =
    AsyncNotifierProvider<FundumoController, FundumoData>(
      FundumoController.new,
    );

class FundumoController extends AsyncNotifier<FundumoData> {
  FundumoController();

  final Uuid _uuid = const Uuid();

  @override
  Future<FundumoData> build() async {
    final repository = ref.read(fundumoRepositoryProvider);
    final data = await repository.load();
    // Schedule initial reminders after data is loaded
    unawaited(ref.read(autoReminderServiceProvider).checkAllReminders());
    return data;
  }

  Future<void> refresh() async {
    state = const AsyncLoading<FundumoData>();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fundumoRepositoryProvider);
      return repository.load();
    });
  }

  void addTransaction({
    required String envelopeId,
    required double amount,
    required DateTime timestamp,
    String notes = '',
  }) {
    _mutate((data) {
      final envelope = data.envelopes.firstWhere(
        (envelope) => envelope.id == envelopeId,
        orElse: () => throw ArgumentError('Unknown envelope $envelopeId'),
      );

      final updatedTransactions = List<TransactionEntry>.from(data.transactions)
        ..add(
          TransactionEntry(
            id: 'tx-${_uuid.v4()}',
            envelopeId: envelope.id,
            amount: amount,
            timestamp: timestamp,
            notes: notes,
          ),
        );

      return data.copyWith(transactions: updatedTransactions);
    });
    // Check for budget spike reminders after adding a transaction
    unawaited(
      ref
          .read(autoReminderServiceProvider)
          .checkAndScheduleBudgetSpikeReminders(),
    );
  }

  void createEnvelope({
    required String name,
    required double allocation,
    bool rollover = false,
    Color? color,
  }) {
    _mutate((data) {
      final newEnvelope = Envelope(
        id: 'env-${_uuid.v4()}',
        name: name,
        allocation: allocation,
        rollover: rollover,
        colorHex: _colorToHex(color) ?? '#005F73',
      );

      final updatedEnvelopes = List<Envelope>.from(data.envelopes)
        ..add(newEnvelope);

      return data.copyWith(envelopes: updatedEnvelopes);
    });
  }

  void updateEnvelopeAllocation({
    required String envelopeId,
    required double allocation,
  }) {
    _mutate((data) {
      final updated = data.envelopes
          .map(
            (envelope) => envelope.id == envelopeId
                ? envelope.copyWith(allocation: allocation)
                : envelope,
          )
          .toList();

      return data.copyWith(envelopes: updated);
    });
  }

  void addSavingContribution({
    required String goalId,
    required double amount,
    required DateTime date,
  }) {
    _mutate((data) {
      final updatedGoals = data.savingGoals
          .map(
            (goal) => goal.id == goalId
                ? goal.copyWith(
                    contributions: [
                      ...goal.contributions,
                      SavingContribution(date: date, amount: amount),
                    ],
                  )
                : goal,
          )
          .toList();
      return data.copyWith(savingGoals: updatedGoals);
    });
  }

  void addSideGigEntry({
    required String gigId,
    required double hours,
    required double income,
    required double expenses,
    required DateTime date,
  }) {
    _mutate((data) {
      final updatedGigs = data.sideGigs
          .map(
            (gig) => gig.id == gigId
                ? gig.copyWith(
                    entries: [
                      ...gig.entries,
                      SideGigEntry(
                        date: date,
                        hours: hours,
                        income: income,
                        expenses: expenses,
                      ),
                    ],
                  )
                : gig,
          )
          .toList();
      return data.copyWith(sideGigs: updatedGigs);
    });
  }

  void snoozeSubscription({
    required String subscriptionName,
    required Duration duration,
  }) {
    _mutate((data) {
      final updatedSubscriptions = data.subscriptions
          .map(
            (subscription) => subscription.name == subscriptionName
                ? subscription.copyWith(
                    nextRenewal: subscription.nextRenewal.add(duration),
                  )
                : subscription,
          )
          .toList();
      return data.copyWith(subscriptions: updatedSubscriptions);
    });
  }

  void addSharedExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    required DateTime date,
    SharedSplitMode mode = SharedSplitMode.equal,
  }) {
    _mutate((data) {
      final updatedGroups = data.sharedBills
          .map(
            (group) => group.id == groupId
                ? group.copyWith(
                    expenses: [
                      ...group.expenses,
                      SharedExpense(
                        id: 'sbe-${_uuid.v4()}',
                        title: title,
                        amount: amount,
                        paidBy: paidBy,
                        date: date,
                        mode: mode,
                      ),
                    ],
                  )
                : group,
          )
          .toList();
      return data.copyWith(sharedBills: updatedGroups);
    });
  }

  void addReceipt({
    required String title,
    required String category,
    required DateTime purchaseDate,
    required DateTime warrantyExpiry,
  }) {
    _mutate((data) {
      final newReceipt = Receipt(
        id: 'receipt-${_uuid.v4()}',
        title: title,
        category: category,
        purchaseDate: purchaseDate,
        warrantyExpiry: warrantyExpiry,
        imagePath: null,
      );
      return data.copyWith(receipts: [...data.receipts, newReceipt]);
    });
    // Check for warranty reminders after adding a receipt
    unawaited(
      ref.read(autoReminderServiceProvider).checkAndScheduleWarrantyReminders(),
    );
  }

  Future<void> replaceData(FundumoData data) async {
    final repository = ref.read(fundumoRepositoryProvider);
    await repository.save(data);
    state = AsyncData<FundumoData>(data);
  }

  Future<void> resetToSeed() async {
    final repository = ref.read(fundumoRepositoryProvider);
    final seed = await repository.loadSeed();
    await repository.save(seed);
    state = AsyncData<FundumoData>(seed);
  }

  void updateUserProfile({
    String? name,
    String? currencyCode,
    double? monthlyTakeHome,
    String? notificationEmail,
  }) {
    _mutate((data) {
      final updatedProfile = data.user.copyWith(
        name: name ?? data.user.name,
        currencyCode: currencyCode ?? data.user.currencyCode,
        monthlyTakeHome: monthlyTakeHome ?? data.user.monthlyTakeHome,
        notificationEmail: notificationEmail ?? data.user.notificationEmail,
      );
      return data.copyWith(user: updatedProfile);
    });
  }

  Future<void> importExternalData(String jsonString) async {
    final decoded = FundumoData.fromJson(
      Map<String, dynamic>.from(jsonDecode(jsonString) as Map),
    );
    await replaceData(decoded);
  }

  String? _colorToHex(Color? color) {
    if (color == null) return null;
    final r = ((color.r * 255.0).round() & 0xff)
        .toRadixString(16)
        .padLeft(2, '0');
    final g = ((color.g * 255.0).round() & 0xff)
        .toRadixString(16)
        .padLeft(2, '0');
    final b = ((color.b * 255.0).round() & 0xff)
        .toRadixString(16)
        .padLeft(2, '0');
    return '#${(r + g + b).toUpperCase()}';
  }

  void _mutate(FundumoData Function(FundumoData data) transform) {
    final current = state.value;
    if (current == null) {
      throw StateError('FundumoData is not yet loaded');
    }
    try {
      final updated = transform(current);
      state = AsyncData<FundumoData>(updated);
      unawaited(ref.read(fundumoRepositoryProvider).save(updated));
      // Sync to cloud if enabled
      unawaited(_syncToCloud(updated));
    } catch (error, stackTrace) {
      state = AsyncError<FundumoData>(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _syncToCloud(FundumoData data) async {
    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncToCloud(data);
    } catch (e) {
      // Log sync errors but don't block UI
      debugPrint('Sync failed: $e');
    }
  }

  /// Sync data from cloud
  Future<void> syncFromCloud() async {
    try {
      final syncService = ref.read(syncServiceProvider);
      final cloudData = await syncService.syncFromCloud();
      if (cloudData != null) {
        final current = state.value;
        if (current != null) {
          // Resolve conflicts
          final resolved = await syncService.resolveConflicts(
            current,
            cloudData,
          );
          await replaceData(resolved);
        } else {
          await replaceData(cloudData);
        }
      }
    } catch (e) {
      debugPrint('Sync from cloud failed: $e');
      rethrow;
    }
  }
}
