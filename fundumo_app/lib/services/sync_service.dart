import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../domain/models/models.dart';
import 'auth_service.dart';

/// Service for syncing data between local storage and Supabase
class SyncService {
  SyncService({
    required this.supabase,
    required this.authService,
    required this.ref,
  });

  final SupabaseClient supabase;
  final AuthService authService;
  final Ref ref;

  /// Sync all data to cloud
  Future<void> syncToCloud(FundumoData data) async {
    if (!AppConfig.enableCloudSync) return;
    if (!authService.isAuthenticated) return;

    final userId = authService.currentUser?.id;
    if (userId == null) return;

    try {
      // Sync user profile
      await _syncUserProfile(userId, data.user);

      // Sync fixed expenses
      await _syncFixedExpenses(userId, data.fixedExpenses);

      // Sync subscriptions
      await _syncSubscriptions(userId, data.subscriptions);

      // Sync envelopes
      await _syncEnvelopes(userId, data.envelopes);

      // Sync transactions
      await _syncTransactions(userId, data.transactions);

      // Sync side gigs
      await _syncSideGigs(userId, data.sideGigs);

      // Sync saving goals
      await _syncSavingGoals(userId, data.savingGoals);

      // Sync shared bills
      await _syncSharedBills(userId, data.sharedBills);

      // Sync receipts
      await _syncReceipts(userId, data.receipts);

      // Update last sync timestamp
      await supabase.from('user_sync_metadata').upsert({
        'user_id': userId,
        'last_sync_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw SyncException('Failed to sync to cloud: $e');
    }
  }

  /// Sync data from cloud
  Future<FundumoData?> syncFromCloud() async {
    if (!AppConfig.enableCloudSync) return null;
    if (!authService.isAuthenticated) return null;

    final userId = authService.currentUser?.id;
    if (userId == null) return null;

    try {
      // Fetch all data from Supabase
      final userProfile = await _fetchUserProfile(userId);
      final fixedExpenses = await _fetchFixedExpenses(userId);
      final subscriptions = await _fetchSubscriptions(userId);
      final envelopes = await _fetchEnvelopes(userId);
      final transactions = await _fetchTransactions(userId);
      final sideGigs = await _fetchSideGigs(userId);
      final savingGoals = await _fetchSavingGoals(userId);
      final sharedBills = await _fetchSharedBills(userId);
      final receipts = await _fetchReceipts(userId);

      if (userProfile == null) return null;

      return FundumoData(
        user: userProfile,
        fixedExpenses: fixedExpenses,
        subscriptions: subscriptions,
        envelopes: envelopes,
        transactions: transactions,
        sideGigs: sideGigs,
        savingGoals: savingGoals,
        sharedBills: sharedBills,
        receipts: receipts,
      );
    } catch (e) {
      throw SyncException('Failed to sync from cloud: $e');
    }
  }

  /// Resolve conflicts using last-write-wins strategy
  Future<FundumoData> resolveConflicts(
    FundumoData localData,
    FundumoData cloudData,
  ) async {
    // Simple last-write-wins: prefer cloud data for now
    // In production, implement more sophisticated conflict resolution
    return cloudData;
  }

  // Private sync methods
  Future<void> _syncUserProfile(String userId, UserProfile profile) async {
    await supabase.from('user_profiles').upsert({
      'user_id': userId,
      'name': profile.name,
      'currency_code': profile.currencyCode,
      'monthly_take_home': profile.monthlyTakeHome,
      'notification_email': profile.notificationEmail,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<UserProfile?> _fetchUserProfile(String userId) async {
    final response = await supabase
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return UserProfile(
      name: response['name'] as String? ?? '',
      currencyCode: response['currency_code'] as String? ?? 'USD',
      monthlyTakeHome: (response['monthly_take_home'] as num?)?.toDouble() ?? 0,
      notificationEmail: response['notification_email'] as String? ?? '',
    );
  }

  Future<void> _syncFixedExpenses(
    String userId,
    List<ExpenseTemplate> expenses,
  ) async {
    await supabase
        .from('fixed_expenses')
        .upsert(
          expenses
              .map(
                (e) => {
                  'user_id': userId,
                  'name': e.name,
                  'amount': e.amount,
                  'frequency': e.frequency.name,
                  'next_due': e.nextDue.toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
        );
  }

  Future<List<ExpenseTemplate>> _fetchFixedExpenses(String userId) async {
    final response = await supabase
        .from('fixed_expenses')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((e) => ExpenseTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _syncSubscriptions(
    String userId,
    List<Subscription> subscriptions,
  ) async {
    await supabase
        .from('subscriptions')
        .upsert(
          subscriptions
              .map(
                (s) => {
                  'user_id': userId,
                  'name': s.name,
                  'monthly_cost': s.monthlyCost,
                  'renewal_cycle': s.renewalCycle.name,
                  'next_renewal': s.nextRenewal.toIso8601String(),
                  'category': s.category,
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
        );
  }

  Future<List<Subscription>> _fetchSubscriptions(String userId) async {
    final response = await supabase
        .from('subscriptions')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((s) => Subscription.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<void> _syncEnvelopes(String userId, List<Envelope> envelopes) async {
    await supabase
        .from('envelopes')
        .upsert(
          envelopes
              .map(
                (e) => {
                  'user_id': userId,
                  'id': e.id,
                  'name': e.name,
                  'allocation': e.allocation,
                  'rollover': e.rollover,
                  'color_hex': e.colorHex,
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
        );
  }

  Future<List<Envelope>> _fetchEnvelopes(String userId) async {
    final response = await supabase
        .from('envelopes')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((e) => Envelope.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _syncTransactions(
    String userId,
    List<TransactionEntry> transactions,
  ) async {
    await supabase
        .from('transactions')
        .upsert(
          transactions
              .map(
                (t) => {
                  'user_id': userId,
                  'id': t.id,
                  'envelope_id': t.envelopeId,
                  'amount': t.amount,
                  'timestamp': t.timestamp.toIso8601String(),
                  'notes': t.notes,
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
        );
  }

  Future<List<TransactionEntry>> _fetchTransactions(String userId) async {
    final response = await supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);

    return (response as List)
        .map((t) => TransactionEntry.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<void> _syncSideGigs(String userId, List<SideGig> sideGigs) async {
    await supabase
        .from('side_gigs')
        .upsert(
          sideGigs
              .map(
                (g) => {
                  'user_id': userId,
                  'id': g.id,
                  'name': g.name,
                  'hourly_rate': g.hourlyRate,
                  'tax_rate': g.taxRate,
                  'entries': g.entries.map((e) => e.toJson()).toList(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
        );
  }

  Future<List<SideGig>> _fetchSideGigs(String userId) async {
    final response = await supabase
        .from('side_gigs')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((g) => SideGig.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<void> _syncSavingGoals(
    String userId,
    List<SavingGoal> savingGoals,
  ) async {
    await supabase
        .from('saving_goals')
        .upsert(
          savingGoals
              .map(
                (g) => {
                  'user_id': userId,
                  'id': g.id,
                  'name': g.name,
                  'target_amount': g.targetAmount,
                  'target_date': g.targetDate.toIso8601String(),
                  'theme': g.theme,
                  'contributions': g.contributions
                      .map((c) => c.toJson())
                      .toList(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
        );
  }

  Future<List<SavingGoal>> _fetchSavingGoals(String userId) async {
    final response = await supabase
        .from('saving_goals')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((g) => SavingGoal.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<void> _syncSharedBills(
    String userId,
    List<SharedBillGroup> sharedBills,
  ) async {
    await supabase
        .from('shared_bill_groups')
        .upsert(
          sharedBills
              .map(
                (g) => {
                  'user_id': userId,
                  'id': g.id,
                  'name': g.name,
                  'participants': g.participants
                      .map((p) => p.toJson())
                      .toList(),
                  'expenses': g.expenses.map((e) => e.toJson()).toList(),
                  'settlements': g.settlements.map((s) => s.toJson()).toList(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
        );
  }

  Future<List<SharedBillGroup>> _fetchSharedBills(String userId) async {
    final response = await supabase
        .from('shared_bill_groups')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((g) => SharedBillGroup.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<void> _syncReceipts(String userId, List<Receipt> receipts) async {
    await supabase
        .from('receipts')
        .upsert(
          receipts
              .map(
                (r) => {
                  'user_id': userId,
                  'id': r.id,
                  'title': r.title,
                  'category': r.category,
                  'purchase_date': r.purchaseDate.toIso8601String(),
                  'warranty_expiry': r.warrantyExpiry.toIso8601String(),
                  'image_path': r.imagePath,
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
        );
  }

  Future<List<Receipt>> _fetchReceipts(String userId) async {
    final response = await supabase
        .from('receipts')
        .select()
        .eq('user_id', userId)
        .order('purchase_date', ascending: false);

    return (response as List)
        .map((r) => Receipt.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}

class SyncException implements Exception {
  SyncException(this.message);
  final String message;
  @override
  String toString() => 'SyncException: $message';
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final authService = ref.watch(authServiceProvider);
  return SyncService(supabase: supabase, authService: authService, ref: ref);
});
