// add_transaction_popup.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/transaction_category_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class AddTransactionPopup extends StatefulWidget {
  const AddTransactionPopup({super.key});

  @override
  State<AddTransactionPopup> createState() => _AddTransactionPopupState();
}

class _AddTransactionPopupState extends State<AddTransactionPopup> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();

  // State untuk data form
  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  CategoryInfo? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd MMMM yyyy').format(DateTime.now());

    // ✅ PERUBAHAN: Inisialisasi awal sekarang menggunakan daftar kategori expense
    // karena tipe default yang dipilih adalah "Expense".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      // Atur kategori expense pertama sebagai pilihan default.
      if (mounted && categoryProvider.allExpenseCategories.isNotEmpty) {
        setState(() {
          _selectedCategory = categoryProvider.allExpenseCategories.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      // Izinkan memilih tanggal di masa depan jika diperlukan
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('dd MMMM yyyy').format(_selectedDate);
      });
    }
  }

  void _onCategorySelected(CategoryInfo category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _submitData() {
    final cleanAmountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final enteredAmount = double.tryParse(cleanAmountText);

    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    // ✅ PERUBAHAN: Pastikan tipe kategori yang disimpan konsisten dengan tipe transaksi
    if (_selectedCategory!.type.name != _selectedType.name) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category type does not match transaction type. Please re-select.')),
      );
      return;
    }

    final newTransaction = Transaction(
      id: '', // ID akan dibuat oleh Firestore
      amount: enteredAmount,
      type: _selectedType,
      category: _selectedCategory!.name,
      categoryIcon: _selectedCategory!.icon,
      note: _noteController.text,
      date: _selectedDate,
    );

    Provider.of<TransactionProvider>(context, listen: false)
        .addTransaction(newTransaction);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final currencySymbol = '${transactionProvider.currencySymbol} ';
    final categoryProvider = context.watch<CategoryProvider>();

    // ✅ PERUBAHAN: Tentukan daftar kategori yang akan ditampilkan berdasarkan _selectedType
    final List<CategoryInfo> categoriesToShow = _selectedType == TransactionType.income
        ? categoryProvider.allIncomeCategories
        : categoryProvider.allExpenseCategories;

    // Logika untuk memastikan kategori yang dipilih selalu valid
    CategoryInfo? currentValidCategory = _selectedCategory;
    
    // Jika kategori yang dipilih saat ini tidak ada di dalam daftar yang seharusnya ditampilkan
    // (misal: beralih dari Expense ke Income), maka reset pilihan.
    if (currentValidCategory != null && !categoriesToShow.contains(currentValidCategory)) {
      currentValidCategory = categoriesToShow.isNotEmpty ? categoriesToShow.first : null;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) {
          setState(() {
            _selectedCategory = currentValidCategory;
          });
        }
      });
    }
    // Juga tangani kasus inisialisasi jika daftar kategori kosong pada awalnya
    else if (currentValidCategory == null && categoriesToShow.isNotEmpty) {
      currentValidCategory = categoriesToShow.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) {
          setState(() {
            _selectedCategory = currentValidCategory;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 42),
              child: StyledCard(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Text('Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    CustomTextField(
                      controller: _amountController,
                      hintText: 'Input Amount',
                      keyboardType: TextInputType.number,
                      prefix: currencySymbol,
                      inputFormatters: [CurrencyInputFormatter()],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 42,
                          width: 90,
                          child: PrimaryButton(
                            text: 'Income',
                            onPressed: () => setState(() => _selectedType = TransactionType.income),
                            color: _selectedType == TransactionType.income ? customGreen : Colors.grey,
                            textColor: _selectedType == TransactionType.income ? Colors.black : Colors.black,
                            isSelected: _selectedType == TransactionType.income,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 42,
                          width: 90,
                          child: PrimaryButton(
                            text: 'Expense',
                            onPressed: () => setState(() => _selectedType = TransactionType.expense),
                            color: _selectedType == TransactionType.expense ? customRed : Colors.grey,
                            textColor: _selectedType == TransactionType.expense ? Colors.white : Colors.black,
                            isSelected: _selectedType == TransactionType.expense,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: categoriesToShow.map((category) {
                        final bool isSelected = currentValidCategory == category;
                        return GestureDetector(
                          onTap: () => _onCategorySelected(category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? customPink : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(category.icon, size: 16, color: isSelected ? Colors.white : Colors.black),
                                const SizedBox(width: 6),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (categoriesToShow.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        alignment: Alignment.center,
                        child: Text(
                          "No categories found for this type.\nPlease add one in the Category page.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text('Note or Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    CustomTextField(controller: _noteController, hintText: 'Enter a note... (optional)'),
                    const SizedBox(height: 12),
                    const Text('Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: _dateController,
                          hintText: 'Select a date...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: PrimaryButton(text: 'Submit', onPressed: _submitData),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}