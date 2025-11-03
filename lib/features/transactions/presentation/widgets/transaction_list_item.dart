import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../notifiers/transaction_notifier.dart';
import '../providers/transaction_providers.dart';

/// A widget that represents a single transaction item in the list.
///
/// This widget is responsible for displaying the transaction data
/// and handling user interactions like tapping (for update)
/// and swiping (for delete).
///
/// It is a [ConsumerWidget] to allow it to call the
/// [transactionNotifierProvider] directly for deletion.
class TransactionListItem extends ConsumerWidget {
  /// Creates a [TransactionListItem].
  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onItemTap,
  });

  /// The transaction data to display.
  final Transaction transaction;

  /// Callback function to execute when the item is tapped (for Update).
  final void Function(Transaction) onItemTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Formatters ---
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('d MMM yyyy', 'id_ID');

    final bool isExpense = transaction.amount < 0;

    // --- Dismissible for Swipe-to-Delete ---
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,

      // --- Delete Confirmation Dialog ---
      confirmDismiss: (DismissDirection direction) async {
        final bool? result = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text(
                  'Are you sure you want to delete "${transaction.description}"?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    // Close the dialog and return 'false' (do not dismiss)
                    Navigator.of(dialogContext).pop(false);
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                  onPressed: () {
                    // Close the dialog and return 'true' (dismiss)
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        );
        // Return the dialog's result (or false if dialog was dismissed)
        return result ?? false;
      },

      // --- Action after Confirmation ---
      onDismissed: (direction) {
        // Call the notifier to delete the transaction
        ref
            .read(transactionNotifierProvider.notifier)
            .deleteTransaction(transaction.id);

        // Show a confirmation snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${transaction.description}" deleted.'),
          ),
        );
      },

      // --- Background shown during swipe ---
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete_sweep, color: Colors.white),
      ),

      // --- The actual item content (ListTile) ---
      child: ListTile(
        onTap: () => onItemTap(transaction), // Callback for 'Update'
        leading: CircleAvatar(
          backgroundColor:
              isExpense ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: isExpense ? Colors.red.shade700 : Colors.green.shade800,
            size: 20,
          ),
        ),
        title: Text(transaction.description,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(dateFormatter.format(transaction.date)),
        trailing: Text(
          currencyFormatter.format(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isExpense ? Colors.red.shade700 : Colors.green.shade800,
          ),
        ),
      ),
    );
  }
}
