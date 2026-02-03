import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildHeader(context, provider),
            Expanded(
              child: ListView.builder(
                itemCount: provider.categoryGroups.length,
                itemBuilder: (context, index) {
                  final group = provider.categoryGroups[index];
                  return _buildCategoryGroup(context, provider, group);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BudgetProvider provider) {
    final theme = Theme.of(context);
    final monthDate = DateFormat('yyyy-MM').parse(provider.currentMonth);
    final monthName = DateFormat('MMMM yyyy').format(monthDate);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.primaryContainer,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => provider.goToPreviousMonth(),
              ),
              Text(
                monthName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => provider.goToNextMonth(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: provider.toBeBudgeted >= 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'To Be Budgeted',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                Text(
                  provider.formatCurrency(provider.toBeBudgeted),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup(
    BuildContext context,
    BudgetProvider provider,
    CategoryGroup group,
  ) {
    final categories = provider.getCategoriesForGroup(group.id);
    final theme = Theme.of(context);

    double groupAssigned = 0;
    double groupAvailable = 0;
    for (var cat in categories) {
      final budget = provider.getBudgetForCategory(cat.id);
      if (budget != null) {
        groupAssigned += budget.assigned;
        groupAvailable += budget.available;
      }
    }

    return ExpansionTile(
      title: Text(
        group.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              'Assigned: ${provider.formatCurrency(groupAssigned)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(
            provider.formatCurrency(groupAvailable),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: groupAvailable >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      initiallyExpanded: true,
      children: categories.map((category) {
        return _buildCategoryTile(context, provider, category);
      }).toList(),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    BudgetProvider provider,
    BudgetCategory category,
  ) {
    final budget = provider.getBudgetForCategory(category.id);
    final theme = Theme.of(context);
    final available = budget?.available ?? 0;

    return Dismissible(
      key: Key('category_${category.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        _showMoveMoneySheet(context, category);
        return false; // Don't actually dismiss, just show the sheet
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.primaryContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.swap_horiz,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Move',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: ListTile(
        title: Text(category.name),
        subtitle: Text('Assigned: ${provider.formatCurrency(budget?.assigned ?? 0)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: available >= 0
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            provider.formatCurrency(available),
            style: theme.textTheme.titleMedium?.copyWith(
              color: available >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _showAssignDialog(context, provider, category),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showMoveMoneySheet(context, category);
        },
      ),
    );
  }

  void _showMoveMoneySheet(BuildContext context, BudgetCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MoveMoneySheet(fromCategory: category),
    );
  }

  void _showAssignDialog(
    BuildContext context,
    BudgetProvider provider,
    BudgetCategory category,
  ) {
    final controller = TextEditingController();
    final budget = provider.getBudgetForCategory(category.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
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
              Text(
                'Assign to ${category.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Available: ${provider.formatCurrency(budget?.available ?? 0)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'To Be Budgeted: ${provider.formatCurrency(provider.toBeBudgeted)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: provider.toBeBudgeted >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Amount to assign',
                  border: OutlineInputBorder(),
                  prefixText: '+ ',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final amount = double.tryParse(controller.text);
                        if (amount != null && amount > 0) {
                          HapticFeedback.mediumImpact();
                          provider.assignToBudget(category.id, -amount);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Remove'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final amount = double.tryParse(controller.text);
                        if (amount != null && amount > 0) {
                          HapticFeedback.mediumImpact();
                          provider.assignToBudget(category.id, amount);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Assign'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
