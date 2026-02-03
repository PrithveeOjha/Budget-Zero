import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/models.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final cashAccounts = provider.accounts
            .where((a) => a.type == AccountType.cash || a.type == AccountType.savings)
            .toList();
        final creditAccounts = provider.accounts
            .where((a) => a.type == AccountType.credit)
            .toList();

        final totalCash = cashAccounts.fold<double>(0, (sum, a) => sum + a.balance);
        final totalCredit = creditAccounts.fold<double>(0, (sum, a) => sum + a.balance);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(context, provider, totalCash, totalCredit),
            const SizedBox(height: 24),
            if (cashAccounts.isNotEmpty) ...[
              _buildSectionHeader(context, 'Cash & Savings'),
              ...cashAccounts.map((a) => _buildAccountTile(context, provider, a)),
            ],
            if (creditAccounts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Credit Cards'),
              ...creditAccounts.map((a) => _buildAccountTile(context, provider, a)),
            ],
            if (provider.accounts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No accounts yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first account to start budgeting',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _showAddAccountDialog(context, provider),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Account'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    BudgetProvider provider,
    double totalCash,
    double totalCredit,
  ) {
    final theme = Theme.of(context);
    final netWorth = totalCash - totalCredit;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Net Worth',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              provider.formatCurrency(netWorth),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: netWorth >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Cash', style: theme.textTheme.bodySmall),
                    Text(
                      provider.formatCurrency(totalCash),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Credit', style: theme.textTheme.bodySmall),
                    Text(
                      provider.formatCurrency(totalCredit),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    BudgetProvider provider,
    Account account,
  ) {
    final theme = Theme.of(context);
    final isCredit = account.type == AccountType.credit;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primaryContainer,
          child: Icon(
            isCredit ? Icons.credit_card : Icons.account_balance,
            color: isCredit
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
        ),
        title: Text(account.name),
        subtitle: Text(account.type.name.toUpperCase()),
        trailing: Text(
          provider.formatCurrency(account.balance),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isCredit ? Colors.red : null,
          ),
        ),
        onTap: () => _showAccountOptions(context, provider, account),
      ),
    );
  }

  void _showAccountOptions(
    BuildContext context,
    BudgetProvider provider,
    Account account,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Balance'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditBalanceDialog(context, provider, account);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, provider, account);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditBalanceDialog(
    BuildContext context,
    BudgetProvider provider,
    Account account,
  ) {
    final controller = TextEditingController(text: account.balance.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${account.name}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Balance',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final balance = double.tryParse(controller.text);
                if (balance != null) {
                  provider.updateAccountBalance(account.id, balance);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    BudgetProvider provider,
    Account account,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: Text('Are you sure you want to delete "${account.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                provider.deleteAccount(account.id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddAccountDialog(BuildContext context, BudgetProvider provider) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    AccountType selectedType = AccountType.cash;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Account Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AccountType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: AccountType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Starting Balance',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final balance = double.tryParse(balanceController.text) ?? 0;
                    if (name.isNotEmpty) {
                      provider.addAccount(name, selectedType, balance);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
