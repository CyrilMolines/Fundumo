import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

enum ExpenseFrequency {
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly;

  static ExpenseFrequency fromString(String value) {
    switch (value.toLowerCase()) {
      case 'weekly':
        return ExpenseFrequency.weekly;
      case 'biweekly':
        return ExpenseFrequency.biweekly;
      case 'monthly':
        return ExpenseFrequency.monthly;
      case 'quarterly':
        return ExpenseFrequency.quarterly;
      case 'yearly':
        return ExpenseFrequency.yearly;
      default:
        throw ArgumentError('Unsupported expense frequency: $value');
    }
  }

  double monthlyEquivalent(double amount) {
    switch (this) {
      case ExpenseFrequency.weekly:
        return amount * 52 / 12;
      case ExpenseFrequency.biweekly:
        return amount * 26 / 12;
      case ExpenseFrequency.monthly:
        return amount;
      case ExpenseFrequency.quarterly:
        return amount / 3;
      case ExpenseFrequency.yearly:
        return amount / 12;
    }
  }
}

class ExpenseTemplate {
  ExpenseTemplate({
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextDue,
  });

  final String name;
  final double amount;
  final ExpenseFrequency frequency;
  final DateTime nextDue;

  factory ExpenseTemplate.fromJson(Map<String, dynamic> json) {
    return ExpenseTemplate(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      frequency: ExpenseFrequency.fromString(json['frequency'] as String),
      nextDue: DateTime.parse(json['nextDue'] as String),
    );
  }

  double get normalizedMonthlyValue => frequency.monthlyEquivalent(amount);

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'frequency': frequency.name,
        'nextDue': nextDue.toIso8601String(),
      };
}

class Subscription {
  Subscription({
    required this.name,
    required this.monthlyCost,
    required this.renewalCycle,
    required this.nextRenewal,
    required this.category,
  });

  final String name;
  final double monthlyCost;
  final ExpenseFrequency renewalCycle;
  final DateTime nextRenewal;
  final String category;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      name: json['name'] as String,
      monthlyCost: (json['amount'] as num).toDouble(),
      renewalCycle: ExpenseFrequency.fromString(json['frequency'] as String),
      nextRenewal: DateTime.parse(json['nextRenewal'] as String),
      category: json['category'] as String,
    );
  }

  double get monthlyValue => renewalCycle.monthlyEquivalent(monthlyCost);
  double get annualValue => monthlyValue * 12;

  Duration get timeUntilRenewal =>
      nextRenewal.difference(DateTime.now()).abs();

  bool get requiresReminder {
    final days = nextRenewal.difference(DateTime.now()).inDays;
    return days <= 7;
  }

  Subscription copyWith({
    String? name,
    double? monthlyCost,
    ExpenseFrequency? renewalCycle,
    DateTime? nextRenewal,
    String? category,
  }) {
    return Subscription(
      name: name ?? this.name,
      monthlyCost: monthlyCost ?? this.monthlyCost,
      renewalCycle: renewalCycle ?? this.renewalCycle,
      nextRenewal: nextRenewal ?? this.nextRenewal,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': monthlyCost,
        'frequency': renewalCycle.name,
        'nextRenewal': nextRenewal.toIso8601String(),
        'category': category,
      };
}

class Envelope {
  Envelope({
    required this.id,
    required this.name,
    required this.allocation,
    required this.rollover,
    required this.colorHex,
  });

  final String id;
  final String name;
  final double allocation;
  final bool rollover;
  final String colorHex;

  factory Envelope.fromJson(Map<String, dynamic> json) {
    return Envelope(
      id: json['id'] as String,
      name: json['name'] as String,
      allocation: (json['allocation'] as num).toDouble(),
      rollover: json['rollover'] as bool? ?? false,
      colorHex: json['color'] as String? ?? '#005F73',
    );
  }

  Envelope copyWith({
    String? id,
    String? name,
    double? allocation,
    bool? rollover,
    String? colorHex,
  }) {
    return Envelope(
      id: id ?? this.id,
      name: name ?? this.name,
      allocation: allocation ?? this.allocation,
      rollover: rollover ?? this.rollover,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'allocation': allocation,
        'rollover': rollover,
        'color': colorHex,
      };
}

class TransactionEntry {
  TransactionEntry({
    required this.id,
    required this.envelopeId,
    required this.amount,
    required this.timestamp,
    required this.notes,
  });

  final String id;
  final String envelopeId;
  final double amount;
  final DateTime timestamp;
  final String notes;

  factory TransactionEntry.fromJson(Map<String, dynamic> json) {
    return TransactionEntry(
      id: json['id'] as String,
      envelopeId: json['envelopeId'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'envelopeId': envelopeId,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
      };
}

class SideGigEntry {
  SideGigEntry({
    required this.date,
    required this.hours,
    required this.income,
    required this.expenses,
  });

  final DateTime date;
  final double hours;
  final double income;
  final double expenses;

  factory SideGigEntry.fromJson(Map<String, dynamic> json) {
    return SideGigEntry(
      date: DateTime.parse(json['date'] as String),
      hours: (json['hours'] as num).toDouble(),
      income: (json['income'] as num).toDouble(),
      expenses: (json['expenses'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'hours': hours,
        'income': income,
        'expenses': expenses,
      };
}

class SideGig {
  SideGig({
    required this.id,
    required this.name,
    required this.hourlyRate,
    required this.taxRate,
    required this.entries,
  });

  final String id;
  final String name;
  final double hourlyRate;
  final double taxRate;
  final List<SideGigEntry> entries;

  factory SideGig.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List<dynamic>? ?? [];
    return SideGig(
      id: json['id'] as String,
      name: json['name'] as String,
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      taxRate: (json['taxRate'] as num).toDouble(),
      entries: entriesJson
          .map((dynamic e) => SideGigEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get totalHours =>
      entries.fold<double>(0, (value, entry) => value + entry.hours);

  double get grossIncome =>
      entries.fold<double>(0, (value, entry) => value + entry.income);

  double get totalExpenses =>
      entries.fold<double>(0, (value, entry) => value + entry.expenses);

  double get taxProvision => grossIncome * taxRate;

  double get netProfit => grossIncome - totalExpenses - taxProvision;

  SideGig copyWith({
    String? id,
    String? name,
    double? hourlyRate,
    double? taxRate,
    List<SideGigEntry>? entries,
  }) {
    return SideGig(
      id: id ?? this.id,
      name: name ?? this.name,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      taxRate: taxRate ?? this.taxRate,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hourlyRate': hourlyRate,
        'taxRate': taxRate,
        'entries': entries.map((entry) => entry.toJson()).toList(),
      };
}

class SavingContribution {
  SavingContribution({
    required this.date,
    required this.amount,
  });

  final DateTime date;
  final double amount;

  factory SavingContribution.fromJson(Map<String, dynamic> json) {
    return SavingContribution(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amount': amount,
      };
}

class SavingGoal {
  SavingGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.targetDate,
    required this.theme,
    required this.contributions,
  });

  final String id;
  final String name;
  final double targetAmount;
  final DateTime targetDate;
  final String theme;
  final List<SavingContribution> contributions;

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    final contributionsJson = json['contributions'] as List<dynamic>? ?? [];
    return SavingGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      targetDate: DateTime.parse(json['targetDate'] as String),
      theme: json['theme'] as String? ?? 'default',
      contributions: contributionsJson
          .map(
            (dynamic e) => SavingContribution.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  double get totalSaved =>
      contributions.fold<double>(0, (value, contribution) => value + contribution.amount);

  double get progress => targetAmount == 0 ? 0 : (totalSaved / targetAmount).clamp(0.0, 1.0);

  int get daysRemaining =>
      targetDate.difference(DateTime.now()).inDays;

  SavingGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    DateTime? targetDate,
    String? theme,
    List<SavingContribution>? contributions,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      theme: theme ?? this.theme,
      contributions: contributions ?? this.contributions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'targetDate': targetDate.toIso8601String(),
        'theme': theme,
        'contributions':
            contributions.map((contribution) => contribution.toJson()).toList(),
      };
}

class SharedBillParticipant {
  SharedBillParticipant({
    required this.id,
    required this.name,
    required this.weight,
  });

  final String id;
  final String name;
  final double weight;

  factory SharedBillParticipant.fromJson(Map<String, dynamic> json) {
    return SharedBillParticipant(
      id: json['id'] as String,
      name: json['name'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weight': weight,
      };
}

enum SharedSplitMode { equal, weighted }

class SharedExpense {
  SharedExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.date,
    required this.mode,
  });

  final String id;
  final String title;
  final double amount;
  final String paidBy;
  final DateTime date;
  final SharedSplitMode mode;

  factory SharedExpense.fromJson(Map<String, dynamic> json) {
    return SharedExpense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paidBy'] as String,
      date: DateTime.parse(json['date'] as String),
      mode: (json['split'] as String).toLowerCase() == 'weighted'
          ? SharedSplitMode.weighted
          : SharedSplitMode.equal,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'paidBy': paidBy,
        'date': date.toIso8601String(),
        'split': mode == SharedSplitMode.weighted ? 'weighted' : 'equal',
      };
}

class SharedSettlement {
  SharedSettlement({
    required this.from,
    required this.to,
    required this.amount,
    required this.date,
  });

  final String from;
  final String to;
  final double amount;
  final DateTime date;

  factory SharedSettlement.fromJson(Map<String, dynamic> json) {
    return SharedSettlement(
      from: json['from'] as String,
      to: json['to'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'amount': amount,
        'date': date.toIso8601String(),
      };
}

class SharedBillGroup {
  SharedBillGroup({
    required this.id,
    required this.name,
    required this.participants,
    required this.expenses,
    required this.settlements,
  });

  final String id;
  final String name;
  final List<SharedBillParticipant> participants;
  final List<SharedExpense> expenses;
  final List<SharedSettlement> settlements;

  factory SharedBillGroup.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'] as List<dynamic>? ?? [];
    final expensesJson = json['expenses'] as List<dynamic>? ?? [];
    final settlementsJson = json['settlements'] as List<dynamic>? ?? [];
    return SharedBillGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      participants: participantsJson
          .map(
            (dynamic e) => SharedBillParticipant.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      expenses: expensesJson
          .map(
            (dynamic e) => SharedExpense.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      settlements: settlementsJson
          .map(
            (dynamic e) => SharedSettlement.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, double> buildBalances() {
    final totals = <String, double>{};
    for (final participant in participants) {
      totals[participant.id] = 0;
    }
    final totalWeight =
        participants.fold<double>(0, (value, p) => value + p.weight);

    for (final expense in expenses) {
      if (!totals.containsKey(expense.paidBy)) {
        totals[expense.paidBy] = 0;
      }
      totals[expense.paidBy] = totals[expense.paidBy]! + expense.amount;

      switch (expense.mode) {
        case SharedSplitMode.equal:
          final share = expense.amount / participants.length;
          for (final participant in participants) {
            totals[participant.id] = totals[participant.id]! - share;
          }
          break;
        case SharedSplitMode.weighted:
          for (final participant in participants) {
            final share = expense.amount * (participant.weight / totalWeight);
            totals[participant.id] = totals[participant.id]! - share;
          }
          break;
      }
    }

    for (final settlement in settlements) {
      totals[settlement.from] = (totals[settlement.from] ?? 0) + settlement.amount;
      totals[settlement.to] = (totals[settlement.to] ?? 0) - settlement.amount;
    }

    return totals;
  }

  SharedBillGroup copyWith({
    String? id,
    String? name,
    List<SharedBillParticipant>? participants,
    List<SharedExpense>? expenses,
    List<SharedSettlement>? settlements,
  }) {
    return SharedBillGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      participants: participants ?? this.participants,
      expenses: expenses ?? this.expenses,
      settlements: settlements ?? this.settlements,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'participants':
            participants.map((participant) => participant.toJson()).toList(),
        'expenses': expenses.map((expense) => expense.toJson()).toList(),
        'settlements':
            settlements.map((settlement) => settlement.toJson()).toList(),
      };
}

class Receipt {
  Receipt({
    required this.id,
    required this.title,
    required this.category,
    required this.purchaseDate,
    required this.warrantyExpiry,
    required this.imagePath,
  });

  final String id;
  final String title;
  final String category;
  final DateTime purchaseDate;
  final DateTime warrantyExpiry;
  final String? imagePath;

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      warrantyExpiry: DateTime.parse(json['warrantyExpiry'] as String),
      imagePath: json['image'] as String?,
    );
  }

  bool get isExpiringSoon =>
      warrantyExpiry.difference(DateTime.now()).inDays <= 30;

  Receipt copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? purchaseDate,
    DateTime? warrantyExpiry,
    String? imagePath,
  }) {
    return Receipt(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'purchaseDate': purchaseDate.toIso8601String(),
        'warrantyExpiry': warrantyExpiry.toIso8601String(),
        'image': imagePath,
      };
}

class UserProfile {
  UserProfile({
    required this.name,
    required this.currencyCode,
    required this.monthlyTakeHome,
    required this.notificationEmail,
  });

  final String name;
  final String currencyCode;
  final double monthlyTakeHome;
  final String notificationEmail;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      currencyCode: json['currency'] as String,
      monthlyTakeHome: (json['monthlyTakeHome'] as num).toDouble(),
      notificationEmail: json['notificationEmail'] as String,
    );
  }

  NumberFormat get currencyFormat => NumberFormat.simpleCurrency(
        name: currencyCode,
      );

  UserProfile copyWith({
    String? name,
    String? currencyCode,
    double? monthlyTakeHome,
    String? notificationEmail,
  }) {
    return UserProfile(
      name: name ?? this.name,
      currencyCode: currencyCode ?? this.currencyCode,
      monthlyTakeHome: monthlyTakeHome ?? this.monthlyTakeHome,
      notificationEmail: notificationEmail ?? this.notificationEmail,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'currency': currencyCode,
        'monthlyTakeHome': monthlyTakeHome,
        'notificationEmail': notificationEmail,
      };
}

class FundumoData {
  FundumoData({
    required this.user,
    required this.fixedExpenses,
    required this.subscriptions,
    required this.envelopes,
    required this.transactions,
    required this.sideGigs,
    required this.savingGoals,
    required this.sharedBills,
    required this.receipts,
  });

  final UserProfile user;
  final List<ExpenseTemplate> fixedExpenses;
  final List<Subscription> subscriptions;
  final List<Envelope> envelopes;
  final List<TransactionEntry> transactions;
  final List<SideGig> sideGigs;
  final List<SavingGoal> savingGoals;
  final List<SharedBillGroup> sharedBills;
  final List<Receipt> receipts;

  factory FundumoData.fromJson(Map<String, dynamic> json) {
    return FundumoData(
      user: UserProfile.fromJson(json['userProfile'] as Map<String, dynamic>),
      fixedExpenses: (json['fixedExpenses'] as List<dynamic>)
          .map((dynamic e) => ExpenseTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
      subscriptions: (json['subscriptions'] as List<dynamic>)
          .map((dynamic e) => Subscription.fromJson(e as Map<String, dynamic>))
          .toList(),
      envelopes: (json['envelopes'] as List<dynamic>)
          .map((dynamic e) => Envelope.fromJson(e as Map<String, dynamic>))
          .toList(),
      transactions: (json['transactions'] as List<dynamic>)
          .map((dynamic e) => TransactionEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      sideGigs: (json['sideGigs'] as List<dynamic>)
          .map((dynamic e) => SideGig.fromJson(e as Map<String, dynamic>))
          .toList(),
      savingGoals: (json['savingGoals'] as List<dynamic>)
          .map((dynamic e) => SavingGoal.fromJson(e as Map<String, dynamic>))
          .toList(),
      sharedBills: (json['sharedBills'] as List<dynamic>)
          .map((dynamic e) => SharedBillGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      receipts: (json['receipts'] as List<dynamic>)
          .map((dynamic e) => Receipt.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get totalFixedMonthly =>
      fixedExpenses.fold<double>(0, (v, e) => v + e.normalizedMonthlyValue);

  double get monthlySubscriptionSpend =>
      subscriptions.fold<double>(0, (v, s) => v + s.monthlyValue);

  double get annualSubscriptionSpend =>
      subscriptions.fold<double>(0, (v, s) => v + s.annualValue);

  double get totalEnvelopeAllocation =>
      envelopes.fold<double>(0, (v, e) => v + e.allocation);

  double envelopeSpent(String envelopeId) {
    return transactions
        .where((t) => t.envelopeId == envelopeId)
        .fold<double>(0, (value, t) => value + t.amount);
  }

  double get totalDiscretionarySpending {
    final now = DateTime.now();
    return transactions
        .where((t) => t.timestamp.year == now.year && t.timestamp.month == now.month)
        .fold<double>(0, (value, t) => value + t.amount);
  }

  static Future<FundumoData> fromAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return FundumoData.fromJson(decoded);
  }

  FundumoData copyWith({
    UserProfile? user,
    List<ExpenseTemplate>? fixedExpenses,
    List<Subscription>? subscriptions,
    List<Envelope>? envelopes,
    List<TransactionEntry>? transactions,
    List<SideGig>? sideGigs,
    List<SavingGoal>? savingGoals,
    List<SharedBillGroup>? sharedBills,
    List<Receipt>? receipts,
  }) {
    return FundumoData(
      user: user ?? this.user,
      fixedExpenses: fixedExpenses ?? this.fixedExpenses,
      subscriptions: subscriptions ?? this.subscriptions,
      envelopes: envelopes ?? this.envelopes,
      transactions: transactions ?? this.transactions,
      sideGigs: sideGigs ?? this.sideGigs,
      savingGoals: savingGoals ?? this.savingGoals,
      sharedBills: sharedBills ?? this.sharedBills,
      receipts: receipts ?? this.receipts,
    );
  }

  Map<String, dynamic> toJson() => {
        'userProfile': user.toJson(),
        'fixedExpenses':
            fixedExpenses.map((expense) => expense.toJson()).toList(),
        'subscriptions':
            subscriptions.map((subscription) => subscription.toJson()).toList(),
        'envelopes': envelopes.map((envelope) => envelope.toJson()).toList(),
        'transactions':
            transactions.map((transaction) => transaction.toJson()).toList(),
        'sideGigs': sideGigs.map((gig) => gig.toJson()).toList(),
        'savingGoals': savingGoals.map((goal) => goal.toJson()).toList(),
        'sharedBills': sharedBills.map((group) => group.toJson()).toList(),
        'receipts': receipts.map((receipt) => receipt.toJson()).toList(),
      };
}

