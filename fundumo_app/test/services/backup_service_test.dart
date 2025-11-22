import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fundumo_app/data/fundumo_repository.dart';
import 'package:fundumo_app/data/local_fundumo_store.dart';
import 'package:fundumo_app/domain/models/models.dart';
import 'package:fundumo_app/services/backup_service.dart';

class _MemoryStore extends LocalFundumoStore {
  Map<String, dynamic>? _data;

  void seed(FundumoData data) {
    _data = data.toJson();
  }

  @override
  Future<Map<String, dynamic>?> read() async => _data;

  @override
  Future<void> write(Map<String, dynamic> data) async {
    _data = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  }
}

FundumoData _makeSampleData() {
  final now = DateTime(2025, 11, 14);
  return FundumoData(
    user: UserProfile(
      name: 'Test User',
      currencyCode: 'USD',
      monthlyTakeHome: 4000,
      notificationEmail: 'user@example.com',
    ),
    fixedExpenses: [
      ExpenseTemplate(
        name: 'Rent',
        amount: 1500,
        frequency: ExpenseFrequency.monthly,
        nextDue: now,
      ),
    ],
    subscriptions: [
      Subscription(
        name: 'Music',
        monthlyCost: 10,
        renewalCycle: ExpenseFrequency.monthly,
        nextRenewal: now,
        category: 'Entertainment',
      ),
    ],
    envelopes: [
      Envelope(
        id: 'env-1',
        name: 'Food',
        allocation: 500,
        rollover: false,
        colorHex: '#FF0000',
      ),
    ],
    transactions: [
      TransactionEntry(
        id: 'tx-1',
        envelopeId: 'env-1',
        amount: 20,
        timestamp: now,
        notes: 'Lunch',
      ),
    ],
    sideGigs: [
      SideGig(
        id: 'gig-1',
        name: 'Design',
        hourlyRate: 50,
        taxRate: 0.25,
        entries: [
          SideGigEntry(
            date: now,
            hours: 2,
            income: 100,
            expenses: 10,
          ),
        ],
      ),
    ],
    savingGoals: [
      SavingGoal(
        id: 'goal-1',
        name: 'Vacation',
        targetAmount: 2000,
        targetDate: now.add(const Duration(days: 200)),
        theme: 'travel',
        contributions: [
          SavingContribution(date: now, amount: 150),
        ],
      ),
    ],
    sharedBills: [
      SharedBillGroup(
        id: 'group-1',
        name: 'Roommates',
        participants: [
          SharedBillParticipant(id: 'u1', name: 'A', weight: 1),
          SharedBillParticipant(id: 'u2', name: 'B', weight: 1),
        ],
        expenses: [
          SharedExpense(
            id: 'exp-1',
            title: 'Utilities',
            amount: 100,
            paidBy: 'u1',
            date: now,
            mode: SharedSplitMode.equal,
          ),
        ],
        settlements: const [],
      ),
    ],
    receipts: [
      Receipt(
        id: 'rec-1',
        title: 'Laptop',
        category: 'Work',
        purchaseDate: now,
        warrantyExpiry: now.add(const Duration(days: 365)),
        imagePath: null,
      ),
    ],
  );
}

void main() {
  group('BackupService', () {
    late _MemoryStore store;
    late FundumoRepository repository;
    late Directory tempDir;
    late BackupService service;
    late FundumoData sample;

    setUp(() async {
      store = _MemoryStore();
      sample = _makeSampleData();
      store.seed(sample);
      repository = FundumoRepository(store: store);
      tempDir = await Directory.systemTemp.createTemp('fundumo_backup_test');
      service = BackupService(
        repository,
        directoryResolver: () async => tempDir,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('exportBackup writes file to directory', () async {
      final file = await service.exportBackup();
      expect(await file.exists(), isTrue);
      final contents = await file.readAsString();
      final decoded = jsonDecode(contents) as Map<String, dynamic>;
      expect(decoded['userProfile']['name'], equals('Test User'));
    });

    test('importBackup restores data and saves to repository', () async {
      final file = await service.exportBackup();
      final modified = sample.copyWith(
        user: sample.user.copyWith(name: 'Restored User'),
      );
      await file.writeAsString(jsonEncode(modified.toJson()));

      final restored = await service.importBackup();
      expect(restored.user.name, equals('Restored User'));
      final cached = await store.read();
      expect(cached?['userProfile']['name'], equals('Restored User'));
    });
  });
}

