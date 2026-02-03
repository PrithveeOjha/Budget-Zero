import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/models.dart';

class MoveMoneySheet extends StatefulWidget {
  final BudgetCategory fromCategory;

  const MoveMoneySheet({super.key, required this.fromCategory});

  @override
  State<MoveMoneySheet> createState() => _MoveMoneySheetState();
}

class _MoveMoneySheetState extends State<MoveMoneySheet> {
  final _amountController = TextEditingController();
  String? _toCategoryId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final theme = Theme.of(context);
    final fromBudget = provider.getBudgetForCategory(widget.fromCategory.id);

    // Get all categories except the current one
    final availableCategories = provider.categories
        .where((c) => c.id != widget.fromCategory.id)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Move Money',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // From category info
          Card(
            child: ListTile(
              title: const Text('From'),
              subtitle: Text(widget.fromCategory.name),
              trailing: Text(
                'Available: ${provider.formatCurrency(fromBudget?.available ?? 0)}',
                style: TextStyle(
                  color: (fromBudget?.available ?? 0) >= 0
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // To category dropdown
          DropdownButtonFormField<String>(
            value: _toCategoryId,
            decoration: const InputDecoration(
              labelText: 'To Category',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.arrow_forward),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Select category'),
              ),
              ...provider.categoryGroups.expand((group) {
                final categories = availableCategories
                    .where((c) => c.groupId == group.id)
                    .toList();
                if (categories.isEmpty) return <DropdownMenuItem<String>>[];
                return [
                  DropdownMenuItem<String>(
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
                    final budget = provider.getBudgetForCategory(cat.id);
                    return DropdownMenuItem<String>(
                      value: cat.id,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(cat.name),
                          ),
                          Text(
                            provider.formatCurrency(budget?.available ?? 0),
                            style: TextStyle(
                              color: (budget?.available ?? 0) >= 0
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ];
              }),
            ],
            onChanged: (value) {
              setState(() => _toCategoryId = value);
            },
          ),
          const SizedBox(height: 16),

          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 8),

          // Quick amount buttons
          Wrap(
            spacing: 8,
            children: [
              _QuickAmountChip(
                label: 'All Available',
                onTap: () {
                  HapticFeedback.selectionClick();
                  _amountController.text =
                      (fromBudget?.available ?? 0).abs().toStringAsFixed(2);
                },
              ),
              _QuickAmountChip(
                label: 'Half',
                onTap: () {
                  HapticFeedback.selectionClick();
                  _amountController.text =
                      ((fromBudget?.available ?? 0).abs() / 2)
                          .toStringAsFixed(2);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Move button
          FilledButton.icon(
            onPressed: _moveMoney,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Move Money'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _moveMoney() {
    final provider = context.read<BudgetProvider>();

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_toCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination category')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    // Remove from source category
    provider.assignToBudget(widget.fromCategory.id, -amount);
    // Add to destination category
    provider.assignToBudget(_toCategoryId!, amount);

    Navigator.pop(context);

    final toCategory = provider.getCategoryById(_toCategoryId!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved ${provider.formatCurrency(amount)} to ${toCategory?.name}',
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
