import '../entities/transaction.dart';

/// Abstract interface for the transaction repository.
abstract class TransactionRepository {
  /// Fetches all [Transaction] entities.
  Future<List<Transaction>> getTransactions();

  /// Saves a new [Transaction].
  Future<void> addTransaction(Transaction transaction);

  /// Updates an existing [Transaction].
  Future<void> updateTransaction(Transaction transaction); // <-- UPDATE

  /// Deletes a [Transaction] using its [id].
  Future<void> deleteTransaction(String id);
}
