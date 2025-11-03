import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';
import '../models/transaction_model.dart';

// --- 1. The Interface (Contract) ---

/// Abstract interface for local transaction data operations.
abstract class TransactionLocalDataSource {
  /// Fetches all [TransactionModel]s from local storage.
  Future<List<TransactionModel>> getTransactions();

  /// Saves a new [TransactionModel] to local storage.
  Future<void> addTransaction(TransactionModel transaction);

  /// Updates an existing [TransactionModel] in local storage.
  Future<void> updateTransaction(TransactionModel transaction); // <-- UPDATE

  /// Deletes a [TransactionModel] from local storage using its [id].
  Future<void> deleteTransaction(String id);
}

// --- 2. The Implementation (Concrete Class) ---

/// Hive-based implementation of the [TransactionLocalDataSource].
class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  /// The Hive box for storing transactions.
  final Box<TransactionModel> _transactionBox =
      Hive.box<TransactionModel>(kTransactionBoxName);

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    // We use the transaction's 'id' as the key in the Hive box.
    await _transactionBox.put(transaction.id, transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    return _transactionBox.values.toList();
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    // <-- UPDATE
    // Hive's put() method automatically overwrites (updates)
    // the entry with the same key.
    await _transactionBox.put(transaction.id, transaction);
  }
}
