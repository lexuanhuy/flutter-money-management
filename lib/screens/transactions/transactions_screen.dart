import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../models/transaction.dart';
import '../../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();
  User? _currentUser;
  String _filterType = 'all'; // 'all', 'income', 'expense'

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác Nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa giao dịch này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _transactionService.deleteTransaction(transaction.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa giao dịch')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao Dịch'),
      ),
      body: Column(
        children: [
          // Filter buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Tất Cả'),
                    selected: _filterType == 'all',
                    onSelected: (selected) {
                      setState(() {
                        _filterType = 'all';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Thu Nhập'),
                    selected: _filterType == 'income',
                    onSelected: (selected) {
                      setState(() {
                        _filterType = 'income';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Chi Tiêu'),
                    selected: _filterType == 'expense',
                    onSelected: (selected) {
                      setState(() {
                        _filterType = 'expense';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Transactions list
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _transactionService.getTransactions(_currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Chưa có giao dịch nào'),
                  );
                }

                var transactions = snapshot.data!;
                if (_filterType != 'all') {
                  transactions = transactions
                      .where((t) => t.type == _filterType)
                      .toList();
                }

                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('Không có giao dịch nào'),
                  );
                }

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionCard(
                      transaction: transaction,
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => AddTransactionScreen(
                                  transaction: transaction,
                                ),
                              ),
                            )
                            .then((_) => setState(() {}));
                      },
                      onDelete: () => _deleteTransaction(transaction),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn_add_transaction_2",
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(),
                ),
              )
              .then((_) => setState(() {}));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
