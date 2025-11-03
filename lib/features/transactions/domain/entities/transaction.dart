import 'package:flutter/foundation.dart';

/// A plain Dart object representing a single transaction.
///
/// This is the 'Entity' that the Presentation (UI) and
/// Domain (Logic) layers will interact with. It is completely
/// decoupled from any data source implementation (like Hive).
@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
  });

  final String id;
  final String description;
  final double amount;
  final DateTime date;

  // You can add helper methods here if needed, e.g.:
  // bool get isExpense => amount < 0;
  // bool get isIncome => amount > 0;
}
