import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction.dart';
import '../../services/category_service.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();
  final CategoryService _categoryService = CategoryService();
  User? _currentUser;
  DateTime _currentMonth = DateTime.now();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _transactionService.getTransactionsByMonth(
          _currentUser!.uid, _currentMonth);

      setState(() {
        // Lưu tất cả giao dịch của tháng, phân loại sau theo type
        _transactions = transactions;
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

  Map<String, double> _getAmountsByCategory(String type) {
    final Map<String, double> categoryTotals = {};

    for (var transaction in _transactions.where((t) => t.type == type)) {
      final categoryName = transaction.categoryName;
      categoryTotals[categoryName] =
          (categoryTotals[categoryName] ?? 0) + transaction.amount;
    }

    return categoryTotals;
  }

  List<PieChartSectionData> _getPieChartSections(
      Map<String, double> amountsByCategory) {
    final total =
        amountsByCategory.values.fold(0.0, (sum, amount) => sum + amount);

    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'Không có dữ liệu',
          color: Colors.grey,
          radius: 100,
        ),
      ];
    }

    final List<Color> colors = [
      Colors.orange,
      Colors.blue,
      Colors.pink,
      Colors.red,
      Colors.purple,
      Colors.green,
      Colors.indigo,
      Colors.teal,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.lightBlue,
    ];

    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    // Sắp xếp theo số tiền giảm dần
    final sortedEntries = amountsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedEntries) {
      final percentage = (entry.value / total * 100);
      final category = _categoryService.getCategoryByName(entry.key);
      
      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: percentage > 5 
              ? '${percentage.toStringAsFixed(1)}%' 
              : '',
          color: category?.color ?? colors[colorIndex % colors.length],
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    }

    return sections;
  }

  List<Widget> _buildCategoryList(
      Map<String, double> expensesByCategory,
      double totalExpense,
      NumberFormat currencyFormat) {
    final sortedEntries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      final category = _categoryService.getCategoryByName(entry.key);
      final percentage = (entry.value / totalExpense * 100);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (category?.color ?? Colors.grey).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (category?.color ?? Colors.grey).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category?.icon ?? Icons.category,
                color: category?.color ?? Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${currencyFormat.format(entry.value)} đ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: category?.color ?? Colors.grey,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, double> amounts, double total) {
    final entries = amounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: entries.map((entry) {
        final category = _categoryService.getCategoryByName(entry.key);
        final color = category?.color ?? Colors.grey;
        final percent = total == 0 ? 0 : (entry.value / total * 100);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${entry.key} (${percent.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    final monthFormat = DateFormat('MM/yyyy');

    final incomeByCategory = _getAmountsByCategory('income');
    final expenseByCategory = _getAmountsByCategory('expense');

    final totalIncome =
        incomeByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    final totalExpense =
        expenseByCategory.values.fold(0.0, (sum, amount) => sum + amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân Tích Chi Tiêu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChartData,
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
                              _loadChartData();
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
                                _loadChartData();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    // Income Pie Chart
                    if (totalIncome > 0)
                      SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            sections: _getPieChartSections(incomeByCategory),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {},
                            ),
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Chưa có dữ liệu thu nhập trong tháng này',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Tổng Thu Nhập: ${currencyFormat.format(totalIncome)} đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (totalIncome > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildLegend(incomeByCategory, totalIncome),
                      ),
                    const SizedBox(height: 16),
                    // Expense Pie Chart
                    if (totalExpense > 0)
                      SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            sections: _getPieChartSections(expenseByCategory),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                            ),
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Chưa có dữ liệu chi tiêu trong tháng này',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Tổng Chi Tiêu: ${currencyFormat.format(totalExpense)} đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (totalExpense > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildLegend(expenseByCategory, totalExpense),
                      ),
                    const SizedBox(height: 8),
                    // Expense Category list
                    if (totalExpense > 0) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Chi Tiết Theo Danh Mục',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ..._buildCategoryList(
                          expenseByCategory, totalExpense, currencyFormat),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
