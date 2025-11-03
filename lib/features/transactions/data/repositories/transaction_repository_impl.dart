import 'package:hive_flutter/hive_flutter.dart';

// Domain (Logic) layer imports
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

// Data layer imports
import '../data_sources/transaction_local_data_source.dart';
import '../models/transaction_model.dart';

/// Implementation of the [TransactionRepository] interface.
class TransactionRepositoryImpl implements TransactionRepository {
  /// The local data source that provides raw transaction data.
  final TransactionLocalDataSource localDataSource;

  /// Creates an instance of [TransactionRepositoryImpl].
  TransactionRepositoryImpl({required this.localDataSource});

  @override
  Future<void> addTransaction(Transaction transaction) async {
    final transactionModel = TransactionModel(
      id: transaction.id,
      description: transaction.description,
      amount: transaction.amount,
      date: transaction.date,
    );
    try {
      await localDataSource.addTransaction(transactionModel);
    } on HiveError catch (e) {
      throw Exception('Failed to add transaction: $e');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
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
      final transactionModels = await localDataSource.getTransactions();
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

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    // <-- UPDATE
    final transactionModel = TransactionModel(
      id: transaction.id,
      description: transaction.description,
      amount: transaction.amount,
      date: transaction.date,
    );
    try {
      await localDataSource.updateTransaction(transactionModel);
    } on HiveError catch (e) {
      throw Exception('Failed to update transaction: $e');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
