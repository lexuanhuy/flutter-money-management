import 'package:flutter/material.dart';

enum TransactionType {
  income,
  expense,
}

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  // Danh sách categories mặc định
  static List<Category> getDefaultCategories() {
    return [
      // Chi tiêu
      Category(
        id: 'food',
        name: 'Ăn uống',
        icon: Icons.restaurant,
        color: Colors.orange,
        type: TransactionType.expense,
      ),
      Category(
        id: 'transport',
        name: 'Di chuyển',
        icon: Icons.directions_car,
        color: Colors.blue,
        type: TransactionType.expense,
      ),
      Category(
        id: 'shopping',
        name: 'Mua sắm',
        icon: Icons.shopping_bag,
        color: Colors.pink,
        type: TransactionType.expense,
      ),
      Category(
        id: 'bills',
        name: 'Hóa đơn',
        icon: Icons.receipt,
        color: Colors.red,
        type: TransactionType.expense,
      ),
      Category(
        id: 'entertainment',
        name: 'Giải trí',
        icon: Icons.movie,
        color: Colors.purple,
        type: TransactionType.expense,
      ),
      Category(
        id: 'health',
        name: 'Sức khỏe',
        icon: Icons.medical_services,
        color: Colors.green,
        type: TransactionType.expense,
      ),
      Category(
        id: 'education',
        name: 'Giáo dục',
        icon: Icons.school,
        color: Colors.indigo,
        type: TransactionType.expense,
      ),
      Category(
        id: 'other_expense',
        name: 'Khác',
        icon: Icons.more_horiz,
        color: Colors.grey,
        type: TransactionType.expense,
      ),
      // Thu nhập
      Category(
        id: 'salary',
        name: 'Lương',
        icon: Icons.account_balance_wallet,
        color: Colors.green,
        type: TransactionType.income,
      ),
      Category(
        id: 'bonus',
        name: 'Thưởng',
        icon: Icons.card_giftcard,
        color: Colors.amber,
        type: TransactionType.income,
      ),
      Category(
        id: 'investment',
        name: 'Đầu tư',
        icon: Icons.trending_up,
        color: Colors.teal,
        type: TransactionType.income,
      ),
      Category(
        id: 'other_income',
        name: 'Khác',
        icon: Icons.more_horiz,
        color: Colors.grey,
        type: TransactionType.income,
      ),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'type': type.name,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: IconData(map['iconCodePoint'] ?? Icons.category.codePoint,
          fontFamily: 'MaterialIcons'),
      color: Color(map['colorValue'] ?? Colors.grey.value),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
    );
  }
}
