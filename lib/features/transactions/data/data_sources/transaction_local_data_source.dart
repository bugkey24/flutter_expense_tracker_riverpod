import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';
import '../models/transaction_model.dart';

// --- 1. The Interface (Contract) ---

/// Abstract interface for local transaction data operations.
///
/// Defines the contract for data source classes that handle
/// CRUD (Create, Read, Update, Delete) operations for [TransactionModel]s locally.
abstract class TransactionLocalDataSource {
  /// Fetches all [TransactionModel]s from local storage.
  ///
  /// Throws a [HiveError] if any error occurs during the read operation.
  Future<List<TransactionModel>> getTransactions();

  /// Saves a new [TransactionModel] to local storage.
  ///
  /// The [TransactionModel.id] is used as the key.
  /// Throws a [HiveError] if any error occurs during the write operation.
  Future<void> addTransaction(TransactionModel transaction);

  /// Deletes a [TransactionModel] from local storage using its [id].
  ///
  /// Throws a [HiveError] if any error occurs during the delete operation.
  Future<void> deleteTransaction(String id);
}

// --- 2. The Implementation (Concrete Class) ---

/// Hive-based implementation of the [TransactionLocalDataSource].
///
/// This class interacts directly with the Hive box defined by
/// [kTransactionBoxName] to store and retrieve [TransactionModel] data.
class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  /// The Hive box for storing transactions.
  ///
  /// We lazily get the box using Hive.box(). This assumes
  /// the box has already been opened in main.dart.
  final Box<TransactionModel> _transactionBox =
      Hive.box<TransactionModel>(kTransactionBoxName);

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    // We use the transaction's 'id' as the key in the Hive box.
    // This makes it easy to find and delete later.
    await _transactionBox.put(transaction.id, transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // Hive's delete method uses the key we provided earlier.
    await _transactionBox.delete(id);
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    // Hive's `values` getter returns all items in the box.
    // We convert the resulting Iterable to a List.
    // This is a synchronous operation, but we return a Future
    // to adhere to the interface contract.
    return _transactionBox.values.toList();
  }
}