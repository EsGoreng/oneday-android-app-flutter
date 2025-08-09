// budgetting_setting_page.dart

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/budget_model.dart';
import '../../../../core/models/transaction_category_model.dart';
import '../../../../core/providers/budget_provider.dart';
import '../../../../core/providers/category_provider.dart';
import '../../../../core/providers/transaction_provider.dart';

import '../../../../shared/widgets/common_widgets.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class BudgetSettingsPage extends StatelessWidget {
  const BudgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        return Scaffold(
          backgroundColor: customCream, // customCream
          body: Stack(
            children: [
              const GridBackground(gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            const TopNavigationBar(title: 'Add Budgeting'),
                            const SizedBox(height: 12),
                            _BudgetsList(provider: budgetProvider),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showAddEditBudgetDialog(context);
            },
            backgroundColor: customPink, // customPink
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _BudgetsList extends StatelessWidget {
  final BudgetProvider provider;

  const _BudgetsList({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    // Gunakan budgets dari provider yang sudah real-time
    final budgets = provider.budgets;

    if (budgets.isEmpty) {
      return StyledCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No budget data. Add one to start!'),
        ),
      );
    }

    return StyledCard(
      padding: const EdgeInsets.all(0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: budgets.length,
        itemBuilder: (context, index) {
          final budget = budgets[index];
          final transactionProvider = context.watch<TransactionProvider>();
          final locale = transactionProvider.currencyLocale;
          final symbol = transactionProvider.currencySymbol;
          final String formattedBalance = formatCurrency(budget.budgetedAmount, locale, symbol);

          return ListTile(
            dense: true,
            leading: Icon(budget.categoryIcon, size: 30),
            title: Text(budget.categoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('$formattedBalance / ${budget.periodicity.displayName}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.black),
                  onPressed: () {
                    _showAddEditBudgetDialog(context, existingBudget: budget);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_outlined, color: customRed),
                  onPressed: () {
                    _showDeleteConfirmationDialog(context, budget);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Helper di luar class agar bisa dipanggil dari mana saja di file ini
void _showAddEditBudgetDialog(BuildContext context, {Budget? existingBudget}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add/Edit Budget',
    barrierColor: Colors.black.withValues(alpha : 0.2),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) {
      return _AddEditBudgetPopup(
        existingBudget: existingBudget,
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      );
    },
  );
}

void _showDeleteConfirmationDialog(BuildContext context, Budget budget) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Delete Confirmation',
    barrierColor: Colors.black.withValues(alpha : 0.2),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) {
      return _DeleteConfirmationPopup(
        budget: budget,
      );
    },
     transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      );
    },
  );
}

class _AddEditBudgetPopup extends StatefulWidget {
  final Budget? existingBudget;

  const _AddEditBudgetPopup({
    this.existingBudget,
  });

  @override
  State<_AddEditBudgetPopup> createState() => _AddEditBudgetPopupState();
}

enum _BudgetType { recurring, specificMonth }

class _AddEditBudgetPopupState extends State<_AddEditBudgetPopup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  CategoryInfo? _selectedCategory;
  
  _BudgetType _budgetType = _BudgetType.recurring;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  DateTime? _selectedMonth;
  bool _isSaving = false; // State untuk loading

  @override
  void initState() {
    super.initState();
    // ✅ PERUBAHAN: Ambil hanya kategori expense dari provider
    final expenseCategories = context.read<CategoryProvider>().allExpenseCategories;

    if (widget.existingBudget != null) {
      final budget = widget.existingBudget!;
      
      // ✅ PERUBAHAN: Cari kategori yang ada HANYA dari daftar expense
      _selectedCategory = expenseCategories.firstWhere(
        (cat) => cat.name == budget.categoryName,
        // Fallback jika kategori tidak ditemukan (seharusnya tidak terjadi)
        orElse: () => CategoryInfo(id: '',name: 'Unknown', icon: Icons.help, type: CategoryType.expense)
      );

      _amountController = TextEditingController(
        text: budget.budgetedAmount.toStringAsFixed(0)
      );
      
      if (budget.targetMonth != null) {
        _budgetType = _BudgetType.specificMonth;
        _selectedMonth = budget.targetMonth;
        _selectedPeriod = BudgetPeriod.monthly;
      } else {
        _budgetType = _BudgetType.recurring;
        _selectedPeriod = budget.periodicity;
      }
    } else {
      _amountController = TextEditingController();
      _budgetType = _BudgetType.recurring;
      _selectedPeriod = BudgetPeriod.monthly;
      _selectedMonth = DateTime.now();
      
      // ✅ PERUBAHAN: Inisialisasi kategori yang dipilih dengan item expense pertama
      if (expenseCategories.isNotEmpty) {
        _selectedCategory = expenseCategories.first;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      final category = _selectedCategory;
      if (category == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category.')),
        );
        return;
      }

      final cleanString = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.tryParse(cleanString);
      
      if (amount == null) return;

      setState(() {
        _isSaving = true;
      });

      try {
        await context.read<BudgetProvider>().addOrUpdateBudget(
          categoryName: category.name,
          icon: category.icon,
          amount: amount,
          periodicity: _selectedPeriod,
          targetMonth: _budgetType == _BudgetType.specificMonth ? _selectedMonth : null,
        );
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        debugPrint("Failed to save budget: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save budget: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }
  
  void _pickMonth() {
    showMonthPicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    ).then((date) {
      if (date != null) {
        setState(() {
          _selectedMonth = date;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.existingBudget != null;
    final categoryProvider = context.watch<CategoryProvider>();
    final symbol = context.watch<TransactionProvider>().currencySymbol;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StyledCard(
            width: 320,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditMode ? 'Edit Budget' : 'Add Budget',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<CategoryInfo>(
                    value: _selectedCategory,
                    hint: const Text('Select Category'),
                    // ✅ PERUBAHAN: Gunakan allExpenseCategories untuk mengisi item dropdown
                    items: categoryProvider.allExpenseCategories.map((CategoryInfo category) {
                      return DropdownMenuItem<CategoryInfo>(
                        value: category,
                        child: Row(children: [Icon(category.icon, size: 20), const SizedBox(width: 8), Text(category.name)]),
                      );
                    }).toList(),
                    onChanged: isEditMode ? null : (value) => setState(() => _selectedCategory = value),
                    validator: (value) => value == null ? 'Category is required' : null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: isEditMode,
                      fillColor: isEditMode ? Colors.grey[200] : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Budget Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<_BudgetType>(
                    value: _budgetType,
                    items: const [
                      DropdownMenuItem(value: _BudgetType.recurring, child: Text('Recurring Budget')),
                      DropdownMenuItem(value: _BudgetType.specificMonth, child: Text('Specific Month Budget')),
                    ],
                    onChanged: isEditMode ? null : (value) {
                      if (value != null) {
                        setState(() => _budgetType = value);
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: isEditMode,
                      fillColor: isEditMode ? Colors.grey[200] : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  if (_budgetType == _BudgetType.recurring)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text('Period', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<BudgetPeriod>(
                          value: _selectedPeriod,
                          items: BudgetPeriod.values.map((BudgetPeriod period) {
                            return DropdownMenuItem<BudgetPeriod>(value: period, child: Text(period.displayName));
                          }).toList(),
                          onChanged: isEditMode ? null : (value) => setState(() => _selectedPeriod = value!),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: isEditMode,
                            fillColor: isEditMode ? Colors.grey[200] : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text('Select Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        PrimaryButton(
                          padding: const EdgeInsets.all(12),
                          text: DateFormat('MMMM yyyy').format(_selectedMonth ?? DateTime.now()),
                          onPressed: isEditMode ? null : _pickMonth,
                          color: const Color(0xFFE88B8B), // customPink
                          textColor: Colors.black,
                        )
                      ],
                    ),
                  const SizedBox(height: 16),
                  const Text('Budget Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _amountController,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixText: '$symbol ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Amount is required';
                      final cleanString = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (double.tryParse(cleanString) == null) return 'Please enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: PrimaryButton(
                      text: _isSaving ? 'Saving...' : 'Save Budget', 
                      onPressed: _isSaving ? null : _submitForm
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteConfirmationPopup extends StatefulWidget {
  final Budget budget;

  const _DeleteConfirmationPopup({
    required this.budget,
  });

  @override
  State<_DeleteConfirmationPopup> createState() => _DeleteConfirmationPopupState();
}

class _DeleteConfirmationPopupState extends State<_DeleteConfirmationPopup> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    setState(() { _isDeleting = true; });

    try {
      await context.read<BudgetProvider>().deleteBudget(
        categoryName: widget.budget.categoryName,
        periodicity: widget.budget.periodicity,
        targetMonth: widget.budget.targetMonth,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Failed to delete budget: $e");
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete budget: $e")),
          );
          setState(() { _isDeleting = false; });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: StyledCard(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Delete Budget', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete the budget for "${widget.budget.categoryName}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(side: const BorderSide(color: Colors.black), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: PrimaryButton(
                        text: _isDeleting ? 'Deleting...' : 'Delete',
                        onPressed: _isDeleting ? null : _handleDelete,
                        color: customRed, // customRed
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}