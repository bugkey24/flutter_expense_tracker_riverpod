// All code in English as requested.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date and currency formatting

import '../../domain/entities/transaction.dart';
import '../notifiers/transaction_notifier.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_list_item.dart';

/// The main screen of the application.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the provider to get the current state.
    final transactionState = ref.watch(transactionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // 2. Use Dart 3's switch expression for clean state handling.
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: _TransactionList(
                  transactions: transactions,
                  // Pass the callback to the list
                  onItemTap: (tx) {
                    // Call modal in "Update" mode
                    _showAddTransactionModal(context, ref,
                        existingTransaction: tx);
                  },
                ),
              ),
            ],
          ),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Call modal in "Create" mode (existingTransaction = null)
          _showAddTransactionModal(context, ref);
        },
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Displays a modal bottom sheet with a form to add/update a transaction.
  void _showAddTransactionModal(BuildContext context, WidgetRef ref,
      {Transaction? existingTransaction}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: _AddTransactionForm(
            ref: ref,
            existingTransaction: existingTransaction,
          ),
        );
      },
    );
  }
}

// --- Helper Widget: Total Balance Card ---

/// Displays the total calculated balance.
class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({required this.totalBalance});

  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
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

/// Displays the list of transactions using [ListView.builder].
/// This widget is now much cleaner after the refactor.
class _TransactionList extends ConsumerWidget {
  const _TransactionList({
    required this.transactions,
    required this.onItemTap,
  });

  final List<Transaction> transactions;
  final void Function(Transaction) onItemTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions yet.\nTap the \'+\' button to add one!',
          textAlign: TextAlign.center,
        ),
      );
    }

    // ListView.builder now only delegates the item building
    // to our new [TransactionListItem] widget.
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];

        // Delegate the rendering of each item to the new widget
        return TransactionListItem(
          key: ValueKey(tx.id), // Key is still important here
          transaction: tx,
          onItemTap: onItemTap,
        );
      },
    );
  }
}

// --- Helper Widget: Add/Update Transaction Form ---

/// A stateful form widget for adding or updating a transaction.
class _AddTransactionForm extends StatefulWidget {
  const _AddTransactionForm({
    required this.ref,
    this.existingTransaction,
  });
  final WidgetRef ref;
  final Transaction? existingTransaction;

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  final _selectedType = [true, false]; // 0 = Expense, 1 = Income

  @override
  void initState() {
    super.initState();
    // Pre-fill the form if in 'Update' mode
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _descriptionController.text = tx.description;
      _amountController.text = tx.amount.abs().toStringAsFixed(0);
      if (tx.amount < 0) {
        _selectedType[0] = true;
        _selectedType[1] = false;
      } else {
        _selectedType[0] = false;
        _selectedType[1] = true;
      }
    }
  }

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
      // Sanitize input to remove '.' or ','
      final sanitizedAmount =
          _amountController.text.replaceAll('.', '').replaceAll(',', '');
      final amount = double.tryParse(sanitizedAmount) ?? 0.0;
      final isExpense = _selectedType[0];

      if (amount == 0.0) return; // Don't submit if amount is zero

      // 3. Store the ScaffoldMessenger and message BEFORE popping the modal
      final messenger = ScaffoldMessenger.of(context);
      final bool isUpdating = widget.existingTransaction != null;
      final String message = isUpdating
          ? 'Transaction updated successfully!'
          : 'Transaction added successfully!';

      // 4. Perform Create or Update logic
      if (isUpdating) {
        // --- UPDATE LOGIC ---
        final updatedTransaction = Transaction(
          id: widget.existingTransaction!.id, // Must use the existing ID
          description: description,
          amount: isExpense ? -amount : amount,
          date: widget.existingTransaction!.date, // Must use the existing date
        );
        widget.ref
            .read(transactionNotifierProvider.notifier)
            .updateTransaction(updatedTransaction);
      } else {
        // --- ADD LOGIC ---
        widget.ref.read(transactionNotifierProvider.notifier).addTransaction(
              description,
              isExpense ? -amount : amount,
            );
      }

      // 5. Close the modal bottom sheet
      Navigator.of(context).pop();

      // 6. Show the confirmation SnackBar using the stored messenger
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.shade700,
        ),
      );
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
            // --- Dynamic Title ---
            Text(
              widget.existingTransaction == null
                  ? 'Add New Transaction'
                  : 'Update Transaction',
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
                // Validate the sanitized value
                final sanitizedValue =
                    value.replaceAll('.', '').replaceAll(',', '');
                if (double.tryParse(sanitizedValue) == null) {
                  return 'Please enter a valid number.';
                }
                if (double.parse(sanitizedValue) <= 0) {
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
