import '../entities/transaction.dart';

/// Abstract interface for the transaction repository.
///
/// Defines the contract for repository classes that handle
/// data operations for [Transaction] entities.
///
/// This layer decouples the application's core logic (domain)
/// from the data layer's implementation details.
abstract class TransactionRepository {
  /// Fetches all [Transaction] entities.
  ///
  /// Returns a list of [Transaction]s.
  /// Throws an [Exception] if any error occurs.
  Future<List<Transaction>> getTransactions();

  /// Saves a new [Transaction].
  ///
  /// Takes a [Transaction] entity as input.
  /// Throws an [Exception] if any error occurs.
  Future<void> addTransaction(Transaction transaction);

  /// Deletes a [Transaction] using its [id].
  ///
  /// Throws an [Exception] if any error occurs.
  Future<void> deleteTransaction(String id);
}
