import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // For @immutable
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

// --- 1. State Definition ---

/// Represents the possible states for the transaction feature.
@immutable
sealed class TransactionState {
  const TransactionState();
}

/// Initial state, before any data is fetched.
final class TransactionInitial extends TransactionState {}

/// State indicating that data is currently being fetched.
final class TransactionLoading extends TransactionState {}

/// State indicating that data has been successfully loaded.
final class TransactionLoaded extends TransactionState {
  /// The list of transactions.
  final List<Transaction> transactions;

  /// (Optional) A computed property for the total balance.
  double get totalBalance =>
      transactions.fold(0.0, (sum, item) => sum + item.amount);

  const TransactionLoaded(this.transactions);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionLoaded &&
        listEquals(other.transactions, transactions);
  }

  @override
  int get hashCode => transactions.hashCode;
}

/// State indicating that an error occurred while fetching data.
final class TransactionError extends TransactionState {
  /// The error message.
  final String message;
  const TransactionError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

// --- 2. State Notifier Definition ---

/// Manages the state for transactions.
class TransactionNotifier extends StateNotifier<TransactionState> {
  /// The repository used to interact with data.
  final TransactionRepository _repository;

  /// Creates an instance of [TransactionNotifier].
  TransactionNotifier(this._repository) : super(TransactionInitial());

  /// Fetches the list of transactions from the repository.
  Future<void> loadTransactions() async {
    state = TransactionLoading();
    try {
      final transactions = await _repository.getTransactions();
      // Sort transactions by date (newest first)
      transactions.sort((a, b) => b.date.compareTo(a.date));
      state = TransactionLoaded(transactions);
    } catch (e) {
      state = TransactionError(e.toString());
    }
  }

  /// Adds a new transaction.
  Future<void> addTransaction(String description, double amount) async {
    try {
      final newTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: description,
        amount: amount,
        date: DateTime.now(),
      );
      await _repository.addTransaction(newTransaction);
      await loadTransactions(); // Refresh the list
    } catch (e) {
      state = TransactionError('Failed to add transaction: $e');
    }
  }

  /// Deletes a transaction by its [id].
  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadTransactions(); // Refresh the list
    } catch (e) {
      state = TransactionError('Failed to delete transaction: $e');
    }
  }

  /// Updates an existing transaction.
  Future<void> updateTransaction(Transaction transaction) async {
    // <-- UPDATE
    try {
      await _repository.updateTransaction(transaction);
      await loadTransactions(); // Refresh the list
    } catch (e) {
      state = TransactionError('Failed to update transaction: $e');
    }
  }
}
