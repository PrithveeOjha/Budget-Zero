import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../models/models.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              const _SectionHeader(title: 'General'),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Currency'),
                subtitle: Text(provider.currency),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCurrencyPicker(context, provider),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Theme'),
                subtitle: Text(_getThemeModeName(provider.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemePicker(context, provider),
              ),
              const Divider(),
              const _SectionHeader(title: 'Categories'),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Category Group'),
                onTap: () => _showAddGroupDialog(context, provider),
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Add Category'),
                onTap: () => _showAddCategoryDialog(context, provider),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete Category'),
                onTap: () => _showDeleteCategoryDialog(context, provider),
              ),
              ListTile(
                leading: const Icon(Icons.folder_delete_outlined),
                title: const Text('Delete Category Group'),
                onTap: () => _showDeleteGroupDialog(context, provider),
              ),
              const Divider(),
              const _SectionHeader(title: 'Accounts'),
              ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('Add Account'),
                onTap: () => _showAddAccountDialog(context, provider),
              ),
              const Divider(),
              const _SectionHeader(title: 'About'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('BudgetZero'),
                subtitle: Text('Version 1.0.0\nDeveloped by prithV33'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemePicker(BuildContext context, BudgetProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Theme'),
          children: ThemeMode.values.map((mode) {
            return SimpleDialogOption(
              onPressed: () {
                provider.setThemeMode(mode);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Radio<ThemeMode>(
                    value: mode,
                    groupValue: provider.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        provider.setThemeMode(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Icon(
                    mode == ThemeMode.dark
                        ? Icons.dark_mode
                        : mode == ThemeMode.light
                            ? Icons.light_mode
                            : Icons.settings_suggest,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(_getThemeModeName(mode)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showCurrencyPicker(BuildContext context, BudgetProvider provider) {
    final currencies = ['USD', 'INR', 'EUR', 'GBP'];

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Currency'),
          children: currencies.map((currency) {
            return SimpleDialogOption(
              onPressed: () {
                provider.setCurrency(currency);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Radio<String>(
                    value: currency,
                    groupValue: provider.currency,
                    onChanged: (value) {
                      if (value != null) {
                        provider.setCurrency(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Text(currency),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showAddGroupDialog(BuildContext context, BudgetProvider provider) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category Group'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              hintText: 'e.g., Monthly Bills',
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
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  provider.addCategoryGroup(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, BudgetProvider provider) {
    final controller = TextEditingController();
    String? selectedGroupId = provider.categoryGroups.isNotEmpty
        ? provider.categoryGroups.first.id
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Group',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.categoryGroups.map((group) {
                      return DropdownMenuItem(
                        value: group.id,
                        child: Text(group.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedGroupId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g., Subscriptions',
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
                    final name = controller.text.trim();
                    if (name.isNotEmpty && selectedGroupId != null) {
                      provider.addCategory(name, selectedGroupId!);
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
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Account Name',
                      hintText: 'e.g., Main Checking',
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

  void _showDeleteCategoryDialog(BuildContext context, BudgetProvider provider) {
    if (provider.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No categories to delete')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.categoryGroups.length,
              itemBuilder: (context, groupIndex) {
                final group = provider.categoryGroups[groupIndex];
                final categoriesInGroup = provider.getCategoriesForGroup(group.id);

                if (categoriesInGroup.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        group.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    ...categoriesInGroup.map((category) {
                      return ListTile(
                        dense: true,
                        title: Text(category.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmDeleteCategory(context, provider, category);
                          },
                        ),
                      );
                    }),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, BudgetProvider provider, BudgetCategory category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete "${category.name}"?\n\n'
            'Transactions in this category will become uncategorized.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                provider.deleteCategory(category.id);
                Navigator.pop(context); // Close confirm dialog
                Navigator.pop(context); // Close list dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${category.name}"')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteGroupDialog(BuildContext context, BudgetProvider provider) {
    if (provider.categoryGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No category groups to delete')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category Group'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.categoryGroups.length,
              itemBuilder: (context, index) {
                final group = provider.categoryGroups[index];
                final categoryCount = provider.getCategoriesForGroup(group.id).length;

                return ListTile(
                  title: Text(group.name),
                  subtitle: Text('$categoryCount categories'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmDeleteGroup(context, provider, group);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteGroup(BuildContext context, BudgetProvider provider, CategoryGroup group) {
    final categoryCount = provider.getCategoriesForGroup(group.id).length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete "${group.name}"?\n\n'
            'This will also delete $categoryCount categories in this group. '
            'Transactions in these categories will become uncategorized.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                provider.deleteCategoryGroup(group.id);
                Navigator.pop(context); // Close confirm dialog
                Navigator.pop(context); // Close list dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${group.name}" and its categories')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
