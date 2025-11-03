import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // For @immutable
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

// --- 1. State Definition ---

/// Represents the possible states for the transaction feature.
///
/// Using a sealed class (or abstract class with private constructor)
/// allows us to handle all possible states (like Initial, Loading,
/// Loaded, Error) in the UI layer explicitly.
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
  /// This logic lives here, close to the state.
  double get totalBalance =>
      transactions.fold(0.0, (sum, item) => sum + item.amount);

  const TransactionLoaded(this.transactions);

  // Override equals and hashCode for proper state comparison.
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
///
/// This notifier contains all the business logic required
/// to fetch, add, and delete transactions. It interacts
/// with the [TransactionRepository] to perform data operations.
class TransactionNotifier extends StateNotifier<TransactionState> {
  /// The repository used to interact with data.
  final TransactionRepository _repository;

  /// Creates an instance of [TransactionNotifier].
  ///
  /// Requires a [TransactionRepository] and initializes
  /// the state to [TransactionInitial].
  TransactionNotifier(this._repository) : super(TransactionInitial());

  /// Fetches the list of transactions from the repository.
  ///
  /// Sets the state to [TransactionLoading] while fetching,
  /// then to [TransactionLoaded] on success, or
  /// [TransactionError] on failure.
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
  ///
  /// Creates a [Transaction] entity and passes it to the
  /// repository. After successfully adding, it reloads all
  /// transactions to ensure the state is in sync.
  Future<void> addTransaction(String description, double amount) async {
    try {
      final newTransaction = Transaction(
        // Using timestamp for a simple, unique ID
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: description,
        amount: amount,
        date: DateTime.now(),
      );

      await _repository.addTransaction(newTransaction);
      await loadTransactions(); // Refresh the list
    } catch (e) {
      // If adding fails, set state to Error.
      // A more complex app might show a temporary error (e.g., a SnackBar)
      // without wiping out the existing 'Loaded' state.
      state = TransactionError('Failed to add transaction: $e');
    }
  }

  /// Deletes a transaction by its [id].
  ///
  /// After successfully deleting, it reloads all
  /// transactions to ensure the state is in sync.
  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadTransactions(); // Refresh the list
    } catch (e) {
      state = TransactionError('Failed to delete transaction: $e');
    }
  }
}
