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
///
/// This creates an instance of the Hive-based implementation.
final transactionLocalDataSourceProvider =
    Provider<TransactionLocalDataSource>((ref) {
  return TransactionLocalDataSourceImpl();
});

// --- 2. Domain Layer Providers (Repository) ---

/// Provider for the [TransactionRepository].
///
/// This provider "injects" the [TransactionLocalDataSource]
/// into the [TransactionRepositoryImpl].
///
/// The UI/Notifier layer will depend on this provider,
/// not the concrete implementation.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  // Watch the data source provider
  final localDataSource = ref.watch(transactionLocalDataSourceProvider);
  return TransactionRepositoryImpl(localDataSource: localDataSource);
});

// --- 3. Presentation Layer Providers (StateNotifier) ---

/// Provider for the [TransactionNotifier].
///
/// This is the main provider that the UI will interact with.
/// It "injects" the [TransactionRepository] into the [TransactionNotifier]
/// and immediately calls `loadTransactions()` to fetch initial data.
final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  // Watch the repository provider
  final repository = ref.watch(transactionRepositoryProvider);

  // Create the notifier, inject the repository, and call the initial load.
  // The cascade operator '..' allows us to call a method on the
  // object right after it's instantiated.
  return TransactionNotifier(repository)..loadTransactions();
});
