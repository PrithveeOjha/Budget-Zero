import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/models.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first transaction',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: provider.transactions.length,
          itemBuilder: (context, index) {
            final transaction = provider.transactions[index];
            return _buildTransactionTile(context, provider, transaction);
          },
        );
      },
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    BudgetProvider provider,
    BudgetTransaction transaction,
  ) {
    final theme = Theme.of(context);
    final account = provider.getAccountById(transaction.accountId);
    final category = provider.getCategoryById(transaction.categoryId);
    final dateFormat = DateFormat('MMM d');

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Transaction?'),
              content: const Text('This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        provider.deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isIncome
              ? Colors.green.withValues(alpha: 0.1)
              : theme.colorScheme.primaryContainer,
          child: Icon(
            transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: transaction.isIncome ? Colors.green : theme.colorScheme.primary,
          ),
        ),
        title: Text(transaction.payee),
        subtitle: Text(
          '${account?.name ?? 'Unknown'} • ${category?.name ?? (transaction.isIncome ? 'Income' : 'Uncategorized')}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.isIncome ? '+' : '-'}${provider.formatCurrency(transaction.amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: transaction.isIncome ? Colors.green : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              dateFormat.format(transaction.date),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
