class CategoryGroup {
  final String id;
  final String name;
  final int sortOrder;

  CategoryGroup({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sort_order': sortOrder,
    };
  }

  factory CategoryGroup.fromMap(Map<String, dynamic> map) {
    return CategoryGroup(
      id: map['id'],
      name: map['name'],
      sortOrder: map['sort_order'] ?? 0,
    );
  }
}

class BudgetCategory {
  final String id;
  final String groupId;
  final String name;
  final double? targetAmount;
  final int sortOrder;

  BudgetCategory({
    required this.id,
    required this.groupId,
    required this.name,
    this.targetAmount,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'target_amount': targetAmount,
      'sort_order': sortOrder,
    };
  }

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      id: map['id'],
      groupId: map['group_id'],
      name: map['name'],
      targetAmount: map['target_amount'],
      sortOrder: map['sort_order'] ?? 0,
    );
  }
}
