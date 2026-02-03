class BudgetTransaction {
  final String id;
  final double amount;
  final DateTime date;
  final String payee;
  final String? categoryId;
  final String accountId;
  final String? memo;
  final bool isIncome;

  BudgetTransaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.payee,
    this.categoryId,
    required this.accountId,
    this.memo,
    this.isIncome = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'payee': payee,
      'category_id': categoryId,
      'account_id': accountId,
      'memo': memo,
      'is_income': isIncome ? 1 : 0,
    };
  }

  factory BudgetTransaction.fromMap(Map<String, dynamic> map) {
    return BudgetTransaction(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      payee: map['payee'],
      categoryId: map['category_id'],
      accountId: map['account_id'],
      memo: map['memo'],
      isIncome: map['is_income'] == 1,
    );
  }
}
