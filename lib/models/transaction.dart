import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final double amount;
  final String description;
  final DateTime date;
  final String type; // 'income' or 'expense'

  TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'type': type,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] ?? 'expense',
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    double? amount,
    String? description,
    DateTime? date,
    String? type,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }
}
