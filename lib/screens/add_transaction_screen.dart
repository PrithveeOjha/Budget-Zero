import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/widgets.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _amount = '';
  final _payeeController = TextEditingController();
  final _memoController = TextEditingController();

  String? _selectedAccountId;
  String? _selectedCategoryId;
  bool _isIncome = false;
  DateTime _selectedDate = DateTime.now();
  int _currentStep = 0; // 0: amount, 1: details

  @override
  void dispose() {
    _payeeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final theme = Theme.of(context);

    // Set default account if not set
    if (_selectedAccountId == null && provider.accounts.isNotEmpty) {
      _selectedAccountId = provider.accounts.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isIncome ? 'Add Income' : 'Add Expense'),
        actions: [
          if (_currentStep == 1)
            TextButton(
              onPressed: _saveTransaction,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _currentStep == 0
          ? _buildAmountStep(provider, theme)
          : _buildDetailsStep(provider, theme),
    );
  }

  Widget _buildAmountStep(BudgetProvider provider, ThemeData theme) {
    final currencySymbol = provider.currency == 'INR'
        ? '\u20B9'
        : provider.currency == 'EUR'
            ? '\u20AC'
            : provider.currency == 'GBP'
                ? '\u00A3'
                : '\$';

    return Column(
      children: [
        // Income/Expense Toggle
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Expense'),
                icon: Icon(Icons.arrow_upward),
              ),
              ButtonSegment(
                value: true,
                label: Text('Income'),
                icon: Icon(Icons.arrow_downward),
              ),
            ],
            selected: {_isIncome},
            onSelectionChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() {
                _isIncome = value.first;
                if (_isIncome) {
                  _selectedCategoryId = null;
                }
              });
            },
          ),
        ),

        // Numeric Keypad
        Expanded(
          child: NumericKeypad(
            value: _amount,
            currency: currencySymbol,
            onValueChanged: (value) {
              setState(() => _amount = value);
            },
            onDone: () {
              final amount = double.tryParse(_amount);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              setState(() => _currentStep = 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep(BudgetProvider provider, ThemeData theme) {
    final amount = double.tryParse(_amount) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount display (tappable to go back)
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _currentStep = 0);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isIncome
                    ? Colors.green.withValues(alpha: 0.1)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: _isIncome ? Colors.green : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_isIncome ? '+' : '-'}${provider.formatCurrency(amount)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isIncome ? Colors.green : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payee
          TextField(
            controller: _payeeController,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: InputDecoration(
              labelText: _isIncome ? 'Source' : 'Payee',
              hintText:
                  _isIncome ? 'e.g., Salary, Freelance' : 'e.g., Grocery Store',
              prefixIcon: const Icon(Icons.store),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Account
          DropdownButtonFormField<String>(
            value: _selectedAccountId,
            decoration: const InputDecoration(
              labelText: 'Account',
              prefixIcon: Icon(Icons.account_balance_wallet),
              border: OutlineInputBorder(),
            ),
            items: provider.accounts.map((account) {
              return DropdownMenuItem(
                value: account.id,
                child: Text(account.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedAccountId = value);
            },
          ),
          const SizedBox(height: 16),

          // Category (only for expenses)
          if (!_isIncome)
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Select Category'),
                ),
                ...provider.categoryGroups.expand((group) {
                  final categories = provider.getCategoriesForGroup(group.id);
                  return [
                    DropdownMenuItem(
                      enabled: false,
                      child: Text(
                        group.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    ...categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(cat.name),
                        ),
                      );
                    }),
                  ];
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedCategoryId = value);
              },
            ),
          if (!_isIncome) const SizedBox(height: 16),

          // Date
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: theme.colorScheme.outline),
            ),
            onTap: () async {
              HapticFeedback.selectionClick();
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
          const SizedBox(height: 16),

          // Memo
          TextField(
            controller: _memoController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Memo (optional)',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          FilledButton.icon(
            onPressed: _saveTransaction,
            icon: const Icon(Icons.check),
            label: const Text('Save Transaction'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _saveTransaction() {
    final provider = context.read<BudgetProvider>();

    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final payee = _payeeController.text.trim();
    if (payee.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a payee')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    if (!_isIncome && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    HapticFeedback.heavyImpact();

    provider.addTransaction(
      amount: amount,
      payee: payee,
      accountId: _selectedAccountId!,
      categoryId: _selectedCategoryId,
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      isIncome: _isIncome,
      date: _selectedDate,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_isIncome ? 'Income' : 'Expense'} added'),
      ),
    );
  }
}
