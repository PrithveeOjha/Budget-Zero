enum AccountType { cash, credit, savings }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'balance': balance,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: AccountType.values[map['type']],
      balance: (map['balance'] as num).toDouble(),
    );
  }

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }
}
