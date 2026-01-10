import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/transactions/transactions_screen.dart';
import '../../screens/transactions/add_transaction_screen.dart';

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
        title: const Text('Quản Lý Chi Tiêu'),
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
                    // Transactions List Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TransactionsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list),
                        label: const Text('Xem Tất Cả Giao Dịch'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
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
