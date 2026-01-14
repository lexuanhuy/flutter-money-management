import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/transactions/add_transaction_screen.dart';
import '../../models/transaction.dart';
import '../../widgets/transaction_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();
  User? _currentUser;
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = true;
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final income = await _transactionService.getTotalIncome(
          _currentUser!.uid, _currentMonth);
      final expense = await _transactionService.getTotalExpense(
          _currentUser!.uid, _currentMonth);

      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  double get _balance => _totalIncome - _totalExpense;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    final monthFormat = DateFormat('MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _authService.signOut();
              if (mounted) {
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Month selector
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: () {
                              setState(() {
                                _currentMonth = DateTime(
                                    _currentMonth.year, _currentMonth.month - 1);
                              });
                              _loadDashboardData();
                            },
                          ),
                          Text(
                            monthFormat.format(_currentMonth),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () {
                              final now = DateTime.now();
                              if (_currentMonth.month < now.month ||
                                  _currentMonth.year < now.year) {
                                setState(() {
                                  _currentMonth = DateTime(_currentMonth.year,
                                      _currentMonth.month + 1);
                                });
                                _loadDashboardData();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    // Balance Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.blue.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Số Dư Hiện Tại',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${currencyFormat.format(_balance)} đ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Income and Expense Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Thu Nhập',
                            _totalIncome,
                            Colors.green,
                            Icons.trending_up,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Chi Tiêu',
                            _totalExpense,
                            Colors.red,
                            Icons.trending_down,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Transactions List Section
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giao Dịch Gần Đây',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<TransactionModel>>(
                            stream: _transactionService.getTransactions(_currentUser!.uid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Text('Lỗi: ${snapshot.error}'),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text('Chưa có giao dịch nào'),
                                  ),
                                );
                              }

                              // Filter transactions by current month
                              var transactions = snapshot.data!
                                  .where((t) {
                                    final tDate = t.date;
                                    return tDate.year == _currentMonth.year &&
                                        tDate.month == _currentMonth.month;
                                  })
                                  .toList();

                              // Limit to 10 most recent
                              transactions = transactions.take(10).toList();

                              if (transactions.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text('Chưa có giao dịch nào trong tháng này'),
                                  ),
                                );
                              }

                              return Column(
                                children: transactions.map((transaction) {
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
                                          .then((_) => _loadDashboardData());
                                    },
                                    onDelete: () async {
                                      try {
                                        await _transactionService.deleteTransaction(transaction.id);
                                        _loadDashboardData();
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
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "btn_add_transaction_1",
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(),
                ),
              )
              .then((_) => _loadDashboardData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm Giao Dịch'),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, double amount,
      Color color, IconData icon) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currencyFormat.format(amount)} đ',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
