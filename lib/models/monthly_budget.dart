class MonthlyBudget {
  final String id;
  final String categoryId;
  final String month; // Format: "2024-01"
  final double assigned;
  final double activity;

  MonthlyBudget({
    required this.id,
    required this.categoryId,
    required this.month,
    this.assigned = 0,
    this.activity = 0,
  });

  double get available => assigned + activity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'month': month,
      'assigned': assigned,
      'activity': activity,
    };
  }

  factory MonthlyBudget.fromMap(Map<String, dynamic> map) {
    return MonthlyBudget(
      id: map['id'],
      categoryId: map['category_id'],
      month: map['month'],
      assigned: (map['assigned'] as num?)?.toDouble() ?? 0,
      activity: (map['activity'] as num?)?.toDouble() ?? 0,
    );
  }

  MonthlyBudget copyWith({
    String? id,
    String? categoryId,
    String? month,
    double? assigned,
    double? activity,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      assigned: assigned ?? this.assigned,
      activity: activity ?? this.activity,
    );
  }
}
