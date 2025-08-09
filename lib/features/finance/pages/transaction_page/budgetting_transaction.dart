import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/budget_model.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/budget_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../shared/widgets/common_widgets.dart';
import 'budgetting_setting_page.dart';

class HistorypageBudget extends StatelessWidget {
  const HistorypageBudget({super.key});

  @override
  Widget build(BuildContext context) {
    // --- PERBAIKAN UTAMA: GUNAKAN CONSUMER WIDGET ---
    // Consumer secara eksplisit akan mendengarkan BudgetProvider dan
    // membangun ulang UI di dalam 'builder' setiap kali ada notifyListeners().
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        
        // Semua logika yang sebelumnya ada di 'build' dipindahkan ke sini.
        // Sekarang logika ini akan selalu berjalan dengan data 'budgetProvider' terbaru.
        final Map<BudgetPeriod, List<BudgetSummary>> recurringBudgets = {};
        for (var period in BudgetPeriod.values) {
          final summaries = budgetProvider.getBudgetSummariesForPeriod(period);
          if (summaries.isNotEmpty) {
            recurringBudgets[period] = summaries;
          }
        }

        final specificBudgets = budgetProvider.specificMonthBudgetSummaries;

        if (recurringBudgets.isEmpty && specificBudgets.isEmpty) {
          return SingleChildScrollView(child: _BudgetEmptyCard());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Render semua budget berulang
              ...recurringBudgets.entries.map((entry) {
                final period = entry.key;
                final summaries = entry.value;

                final double totalBudget = summaries.fold(0.0, (sum, item) => sum + item.budgeted);
                final double totalSpent = summaries.fold(0.0, (sum, item) => sum + item.spent);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _BudgetSummaryCard(
                    title: '${period.displayName} Budgets',
                    totalBudget: totalBudget,
                    totalSpent: totalSpent,
                    budgets: summaries,
                  ),
                );
              }),

              // Render budget bulan spesifik jika ada
              if (specificBudgets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _BudgetSummaryCard(
                    title: 'Specific Budgets',
                    totalBudget: specificBudgets.fold(0.0, (sum, item) => sum + item.budgeted),
                    totalSpent: specificBudgets.fold(0.0, (sum, item) => sum + item.spent),
                    budgets: specificBudgets,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BudgetEmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StyledCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('No budgeting Available'),
          const SizedBox(height: 8,),
          PrimaryButton(
            padding: const EdgeInsets.all(18),
            text: 'Add Budgetting', 
            onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetSettingsPage()),
                );
              },
            )
        ],
      )
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.title,
    required this.totalBudget,
    required this.totalSpent,
    required this.budgets,
  });

  final List<BudgetSummary> budgets;
  final String title;
  final double totalBudget;
  final double totalSpent;

  void _navigateToTransactionDetails(BuildContext context, BudgetSummary budget) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TransactionDetailPage(budget: budget)),
    );
  }

  Widget _buildSummaryRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor, letterSpacing: 1))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final locale = transactionProvider.currencyLocale;
    final symbol = transactionProvider.currencySymbol;

    final double totalRemaining = totalBudget - totalSpent;

    final String formattedBudget = formatCurrency(totalBudget, locale, symbol);
    final String formattedTotalExpenses = formatCurrency(totalSpent, locale, symbol);
    final String formattedTotalRemaining = formatCurrency(totalRemaining, locale, symbol);
    
    final Color remainingColor = totalRemaining >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336); // customGreen & customRed
    
    return StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BudgetSettingsPage())),
                icon: const Icon(Icons.settings),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(customPink), // customPink
                  iconColor: WidgetStateProperty.all(Colors.black),
                  shape: WidgetStateProperty.all(const RoundedRectangleBorder(side: BorderSide(width: 1), borderRadius: BorderRadius.all(Radius.circular(8)))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Total Budget:', formattedBudget, valueColor: const Color(0xFF4CAF50)),
          _buildSummaryRow('Total Expenses:', formattedTotalExpenses, valueColor: const Color(0xFFF44336)),
          const Divider(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () => _navigateToTransactionDetails(context, budget),
                  child: _BudgetCategoryList(budget: budget),
                ),
              );
            },
          ),
          const Divider(height: 12),
          _buildSummaryRow('Budget Remaining:', formattedTotalRemaining, valueColor: remainingColor),
        ],
      ),
    );
  }
}

class _BudgetCategoryList extends StatelessWidget {
  const _BudgetCategoryList({required this.budget});

  final BudgetSummary budget;

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final locale = transactionProvider.currencyLocale;
    final symbol = transactionProvider.currencySymbol;

    final double remaining = budget.budgeted - budget.spent;
    final String formattedBudgetSpent = formatCurrency(budget.spent, locale, symbol);
    final String formattedBudgetBudgeted = formatCurrency(budget.budgeted, locale, symbol);
    final String formattedRemaining = formatCurrency(remaining.abs(), locale, symbol);

    final double progress = (budget.budgeted > 0) ? (budget.spent / budget.budgeted).clamp(0.0, 1.0) : 0.0;
    
    final Color progressColor;
    if (progress > 0.9) { progressColor = const Color(0xFFF44336); } else if (progress > 0.6) { progressColor = const Color(0xFFFFC107); } else { progressColor = const Color(0xFF4CAF50); }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(budget.icon, size: 20, color: Colors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(budget.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (budget.targetMonth != null)
                    Text(
                      DateFormat('MMMM yyyy').format(budget.targetMonth!),
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                ],
              ),
            ),
            Text(
              '$formattedBudgetSpent / $formattedBudgetBudgeted',
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12), 
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(width: 1), 
              borderRadius: const BorderRadius.all(Radius.circular(8))
            ), 
            child: LinearProgressIndicator(
              borderRadius: const BorderRadius.all(Radius.circular(8)), 
              value: progress, 
              minHeight: 8, 
              backgroundColor: Colors.grey[300], 
              color: progressColor,
            ),
          ),
        ), 
        const SizedBox(height: 8), 
        Align(
          alignment: Alignment.centerRight, 
          child: Text(remaining >= 0 ? 'Remaining: $formattedRemaining' : 'Over: $formattedRemaining', 
            style: TextStyle(
              letterSpacing: 1, 
              fontSize: 12, 
              fontWeight: FontWeight.w600, 
              color: remaining >= 0 ? progressColor : const Color(0xFFC62828),
            ),
          ),
        ), 
        const SizedBox(height: 4), 
        const Divider(height: 2),
      ],
    );
  }
}

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key, required this.budget});

  final BudgetSummary budget;

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final locale = Provider.of<TransactionProvider>(context, listen: false).currencyLocale;
    final symbol = Provider.of<TransactionProvider>(context, listen: false).currencySymbol;

    final List<Transaction> categoryTransactions =
        transactionProvider.getTransactionsForCategory(
            categoryName: budget.name,
            periodicity: budget.periodicity,
            targetMonth: budget.targetMonth);

    final currencyFormatter = NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: 0); 
    final double progress = (budget.budgeted > 0) ? (budget.spent / budget.budgeted).clamp(0.0, 1.0) : 0.0; 
    final double remaining = budget.budgeted - budget.spent; 
    final Color progressColor; 
    if (progress > 0.9) { progressColor = customRed; } else if (progress > 0.6) { progressColor = customYellow; } else { progressColor = customGreen; } 
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);

    String historyTitle;
    if (budget.targetMonth != null) {
      historyTitle = 'History for ${DateFormat('MMMM yyyy').format(budget.targetMonth!)}';
    } else {
      historyTitle = 'History for This ${budget.periodicity.displayName.replaceAll('ly', '')}';
    }

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
                        const TopNavigationBar(title: 'Transaction Detail'),
                        const SizedBox(height: 12),
                        StyledCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Detail', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DetailRow(detailname: 'Category', input: budget.name),
                              DetailRow(
                                detailname: 'Period', 
                                input: budget.targetMonth != null 
                                    ? DateFormat('MMMM yyyy').format(budget.targetMonth!) 
                                    : budget.periodicity.displayName
                              ),
                              DetailRow(detailname: 'Expenses', input: '${(progress * 100).toStringAsFixed(0)}%'),
                              DetailRow(detailname: 'Remaining', input: currencyFormatter.format(remaining)),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(borderRadius: const BorderRadius.all(Radius.circular(8)), value: progress, minHeight: 8, backgroundColor: Colors.grey[300], color: progressColor),
                              const SizedBox(height: 4),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${currencyFormatter.format(budget.spent)} / ${currencyFormatter.format(budget.budgeted)}', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),),]),
                              const Divider(height: 12),
                              Text(historyTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              categoryTransactions.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text(
                                          'No transactions recorded for this period.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.black54),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: categoryTransactions.length,
                                      itemBuilder: (context, index) {
                                        return _TransactionItem(transaction: categoryTransactions[index]);
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {

    final locale = Provider.of<TransactionProvider>(context, listen: false).currencyLocale;
    final symbol = Provider.of<TransactionProvider>(context, listen: false).currencySymbol; 

    final currencyFormatter =
        NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: 0);
    final dateFormatter = DateFormat('d MMMM yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(transaction.categoryIcon, size: 28, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note.isEmpty ? transaction.category : transaction.note,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateFormatter.format(transaction.date),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            currencyFormatter.format(transaction.amount),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFFF44336), // customRed
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.input,
    required this.detailname,
  });

  final String detailname;
  final String input;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            detailname,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            ' : $input',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
