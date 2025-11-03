import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date and currency formatting

import '../../domain/entities/transaction.dart';
import '../notifiers/transaction_notifier.dart';
import '../providers/transaction_providers.dart';

/// The main screen of the application.
///
/// It consumes [transactionNotifierProvider] to display the UI based
/// on the current [TransactionState]. It handles loading, error, and
/// loaded states, and provides actions to add or delete transactions.
class HomeScreen extends ConsumerWidget {
  /// Creates the [HomeScreen] widget.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the provider to get the current state.
    // The UI will automatically rebuild when this state changes.
    final transactionState = ref.watch(transactionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // 2. Use Dart 3's switch expression for clean state handling.
      // This pattern matching is exhaustive and ensures we handle
      // all possible states from our TransactionState sealed class.
      body: switch (transactionState) {
        // --- Loading and Initial States ---
        TransactionInitial() ||
        TransactionLoading() =>
          const Center(child: CircularProgressIndicator()),

        // --- Error State ---
        TransactionError(:final message) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Call the notifier method to try fetching data again.
                    ref
                        .read(transactionNotifierProvider.notifier)
                        .loadTransactions();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),

        // --- Loaded State ---
        TransactionLoaded(:final transactions, :final totalBalance) => Column(
            children: [
              // 3. Header Card for Total Balance
              _TotalBalanceCard(totalBalance: totalBalance),

              // 4. List of Transactions
              // A simple header for the list
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              // Use Expanded to make the list fill the remaining space
              Expanded(
                child: _TransactionList(
                  transactions: transactions,
                ),
              ),
            ],
          ),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 5. Show the modal bottom sheet to add a new transaction.
          _showAddTransactionModal(context, ref);
        },
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Displays a modal bottom sheet with a form to add a new transaction.
  void _showAddTransactionModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      // Ensure the modal resizes when the keyboard appears
      isScrollControlled: true,
      // Use a rounded shape
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (modalContext) {
        // We wrap the form in a Padding to respect the keyboard's view insets
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          // We pass the 'ref' down to the form widget
          child: _AddTransactionForm(ref: ref),
        );
      },
    );
  }
}

// --- Helper Widget: Total Balance Card ---

/// A card widget to display the user's total balance.
class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({required this.totalBalance});

  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    // Use Intl package to format currency
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID', // Indonesian locale
      symbol: 'Rp ',
      decimalDigits: 0, // No decimal digits for Rupiah
    );

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Text(
                'TOTAL BALANCE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 8.0),
              Text(
                currencyFormatter.format(totalBalance),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: totalBalance < 0
                          ? Colors.red.shade700
                          : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Helper Widget: Transaction List ---

/// A list widget to display all transactions.
class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use Intl package for currency and date formatting
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter =
        DateFormat('d MMM yyyy', 'id_ID'); // e.g., "3 Nov 2025"

    // Handle the empty state
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions yet.\nTap the \'+\' button to add one!',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Use ListView.builder for efficient scrolling
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isExpense = tx.amount < 0;

        // Use Dismissible to enable swipe-to-delete
        return Dismissible(
          // Key must be unique for each item
          key: ValueKey(tx.id),
          direction: DismissDirection.endToStart,
          // Callback when dismissed
          onDismissed: (direction) {
            // Call the notifier method to delete the transaction
            ref
                .read(transactionNotifierProvider.notifier)
                .deleteTransaction(tx.id);

            // Show a SnackBar to confirm deletion (and offer undo)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${tx.description}" deleted.'),
                // TODO: Add an 'Undo' button that re-adds the transaction
              ),
            );
          },
          // Background shown during the swipe
          background: Container(
            color: Colors.red.shade700,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete_sweep, color: Colors.white),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isExpense ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                color: isExpense ? Colors.red.shade700 : Colors.green.shade800,
                size: 20,
              ),
            ),
            title: Text(tx.description,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(dateFormatter.format(tx.date)),
            trailing: Text(
              currencyFormatter.format(tx.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red.shade700 : Colors.green.shade800,
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Helper Widget: Add Transaction Form ---

/// A stateful form widget for adding a new transaction.
///
/// This widget manages its own state (form controllers, toggle buttons)
/// and calls the [TransactionNotifier] to add the new data.
class _AddTransactionForm extends StatefulWidget {
  /// We pass the [WidgetRef] down from the [HomeScreen]
  /// so this widget can call the notifier.
  const _AddTransactionForm({required this.ref});
  final WidgetRef ref;

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  // Local state for the form's toggle button
  // 0 = Expense, 1 = Income
  final _selectedType = [true, false]; // Default to Expense

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Submits the form data to the [TransactionNotifier].
  void _submitForm() {
    // 1. Validate the form
    if (_formKey.currentState?.validate() ?? false) {
      // 2. Get the raw values
      final description = _descriptionController.text;
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final isExpense = _selectedType[0]; // Check if 'Expense' is selected

      if (amount == 0.0) return; // Don't submit if amount is zero

      // 3. Call the notifier to add the transaction
      // We use 'widget.ref' to access the ref passed from the parent.
      widget.ref.read(transactionNotifierProvider.notifier).addTransaction(
            description,
            isExpense
                ? -amount
                : amount, // Make amount negative if it's an expense
          );

      // 4. Close the modal bottom sheet
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Make the modal fit its content
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add New Transaction',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),

            // --- Toggle Button: Expense / Income ---
            ToggleButtons(
              isSelected: _selectedType,
              onPressed: (index) {
                setState(() {
                  _selectedType[0] = index == 0;
                  _selectedType[1] = index == 1;
                });
              },
              borderRadius: BorderRadius.circular(8.0),
              fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              selectedColor: Theme.of(context).colorScheme.primary,
              children: [
                _buildToggleChild(Icons.arrow_downward, 'Expense'),
                _buildToggleChild(Icons.arrow_upward, 'Income'),
              ],
            ),
            const SizedBox(height: 16.0),

            // --- Form Field: Description ---
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Coffee, Salary, etc.',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // --- Form Field: Amount ---
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (Rp)',
                hintText: 'e.g., 20000',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount.';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number.';
                }
                if (double.parse(value) <= 0) {
                  return 'Please enter an amount greater than zero.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),

            // --- Submit Button ---
            FilledButton(
              onPressed: _submitForm,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('SAVE TRANSACTION'),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build a child for the [ToggleButtons].
  Widget _buildToggleChild(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8.0),
          Text(label),
        ],
      ),
    );
  }
}
