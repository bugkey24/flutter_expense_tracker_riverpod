import 'package:hive_flutter/hive_flutter.dart';

// Domain (Logic) layer imports
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

// Data layer imports
import '../data_sources/transaction_local_data_source.dart';
import '../models/transaction_model.dart';

/// Implementation of the [TransactionRepository] interface.
///
/// This class orchestrates data flow from the local data source
/// and handles data mapping between [TransactionModel] (data layer)
/// and [Transaction] (domain layer).
class TransactionRepositoryImpl implements TransactionRepository {
  /// The local data source that provides raw transaction data.
  final TransactionLocalDataSource localDataSource;

  /// Creates an instance of [TransactionRepositoryImpl].
  ///
  /// Requires a [TransactionLocalDataSource] to be injected.
  TransactionRepositoryImpl({required this.localDataSource});

  @override
  Future<void> addTransaction(Transaction transaction) async {
    // 1. Map Entity (Domain) to Model (Data)
    final transactionModel = TransactionModel(
      id: transaction.id,
      description: transaction.description,
      amount: transaction.amount,
      date: transaction.date,
    );

    // 2. Perform operation & Handle Errors
    try {
      await localDataSource.addTransaction(transactionModel);
    } on HiveError catch (e) {
      // Catch the specific HiveError and re-throw a generic Exception.
      // This stops data-layer-specific errors from leaking to the UI.
      throw Exception('Failed to add transaction: $e');
    } catch (e) {
      // Catch any other unexpected errors.
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // 2. Perform operation & Handle Errors
    try {
      await localDataSource.deleteTransaction(id);
    } on HiveError catch (e) {
      throw Exception('Failed to delete transaction: $e');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    try {
      // 1. Get raw models from the data source
      final transactionModels = await localDataSource.getTransactions();

      // 2. Map Models (Data) to Entities (Domain)
      final transactions = transactionModels
          .map((model) => Transaction(
                id: model.id,
                description: model.description,
                amount: model.amount,
                date: model.date,
              ))
          .toList();

      return transactions;
    } on HiveError catch (e) {
      throw Exception('Failed to get transactions: $e');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
