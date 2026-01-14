import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'transactions';

  Future<void> createTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      throw 'Lỗi khi tạo giao dịch: $e';
    }
  }

  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .toList());
  }

  Future<List<TransactionModel>> getTransactionsByMonth(
      String userId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
      
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      return transactions;
    } catch (e) {
      throw 'Lỗi khi lấy giao dịch: $e';
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      throw 'Lỗi khi cập nhật giao dịch: $e';
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection(_collection).doc(transactionId).delete();
    } catch (e) {
      throw 'Lỗi khi xóa giao dịch: $e';
    }
  }

  Future<double> getTotalIncome(String userId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'income')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp?)?.toDate();
        if (date != null &&
            date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
          total += (data['amount'] ?? 0).toDouble();
        }
      }
      return total;
    } catch (e) {
      throw 'Lỗi khi tính tổng thu nhập: $e';
    }
  }

  Future<double> getTotalExpense(String userId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'expense')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp?)?.toDate();
        if (date != null &&
            date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
          total += (data['amount'] ?? 0).toDouble();
        }
      }
      return total;
    } catch (e) {
      throw 'Lỗi khi tính tổng chi tiêu: $e';
    }
  }
}
