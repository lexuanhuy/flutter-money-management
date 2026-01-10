import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../widgets/category_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _transactionService = TransactionService();
  final _authService = AuthService();
  final _categoryService = CategoryService();

  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _loadTransactionData();
    }
  }

  void _loadTransactionData() {
    final transaction = widget.transaction!;
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description;
    _selectedDate = transaction.date;
    _selectedType =
        transaction.type == 'income' ? TransactionType.income : TransactionType.expense;
    _selectedCategory = _categoryService.getCategoryById(transaction.categoryId);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final transaction = TransactionModel(
        id: widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        date: _selectedDate,
        type: _selectedType == TransactionType.income ? 'income' : 'expense',
      );

      if (widget.transaction != null) {
        await _transactionService.updateTransaction(transaction);
      } else {
        await _transactionService.createTransaction(transaction);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transaction != null
                ? 'Đã cập nhật giao dịch'
                : 'Đã thêm giao dịch'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoryService.getCategoriesByType(_selectedType);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Sửa Giao Dịch' : 'Thêm Giao Dịch'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction type selector
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Chi Tiêu'),
                    icon: Icon(Icons.trending_down),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Thu Nhập'),
                    icon: Icon(Icons.trending_up),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedCategory = null;
                  });
                },
              ),
              const SizedBox(height: 24),
              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Số Tiền',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô Tả (Tùy chọn)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Date picker
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 24),
              // Category selector
              const Text(
                'Chọn Danh Mục',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CategorySelector(
                categories: categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
              const SizedBox(height: 32),
              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.transaction != null ? 'Cập Nhật' : 'Lưu',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
