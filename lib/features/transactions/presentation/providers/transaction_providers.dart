import 'package:flutter_riverpod/flutter_riverpod.dart';

// Data Layer
import '../../data/data_sources/transaction_local_data_source.dart';
import '../../data/repositories/transaction_repository_impl.dart';

// Domain Layer
import '../../domain/repositories/transaction_repository.dart';

// Presentation Layer
import '../notifiers/transaction_notifier.dart';

// --- 1. Data Layer Providers ---

/// Provider for the [TransactionLocalDataSource].
final transactionLocalDataSourceProvider =
    Provider<TransactionLocalDataSource>((ref) {
  return TransactionLocalDataSourceImpl();
});

// --- 2. Domain Layer Providers (Repository) ---

/// Provider for the [TransactionRepository].
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final localDataSource = ref.watch(transactionLocalDataSourceProvider);
  return TransactionRepositoryImpl(localDataSource: localDataSource);
});

// --- 3. Presentation Layer Providers (StateNotifier) ---

/// Provider for the [TransactionNotifier].
final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  // Create the notifier, inject the repository, and call the initial load.
  return TransactionNotifier(repository)..loadTransactions();
});
