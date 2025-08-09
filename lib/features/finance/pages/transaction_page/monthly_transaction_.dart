import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../shared/widgets/common_widgets.dart';

class HistorypageMonthly extends StatelessWidget {
  final List<Transaction> transactions;

  const HistorypageMonthly({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Mengelompokkan transaksi berdasarkan tahun-bulan (misal: '2025-07')
    final groupedTransactions = groupBy(
      transactions,
      (Transaction tx) => DateFormat('yyyy-MM').format(tx.date),
    );

    // Mengurutkan kunci bulan agar bulan terbaru ada di atas
    final sortedMonthKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return transactions.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No transactions yet.'),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedMonthKeys.length,
            itemBuilder: (ctx, index) {
              final monthKey = sortedMonthKeys[index];
              final monthlyTransactions = groupedTransactions[monthKey]!;
              final monthDate = DateTime.parse('$monthKey-01');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonthlyTransactionsDetailPage(
                          monthDate: monthDate,
                          transactions: monthlyTransactions,
                        ),
                      ),
                    );
                  },
                  child: MonthlyHistoryCard(
                    date: monthDate,
                    transactions: monthlyTransactions,
                  ),
                ),
              );
            },
          );
  }
}

class MonthlyHistoryCard extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;

  const MonthlyHistoryCard({
    super.key,
    required this.date,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final double monthlyIncome = transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double monthlyExpense = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    final String monthDateStr = DateFormat('MM').format(date);
    final String yearDateStr = DateFormat('yyyy').format(date);
    final String monthName = DateFormat('MMMM').format(date);

    final double monthlyTotal = monthlyIncome - monthlyExpense;
    final Color totalColor = monthlyTotal >= 0 ? customGreen : customRed;

    final transactionProvider = context.watch<TransactionProvider>();

    final locale = transactionProvider.currencyLocale;
    final symbol = transactionProvider.currencySymbol;

    final String formattedBalance = formatCurrency(monthlyTotal, locale, symbol);
    final String formattedIncome = formatCurrency(monthlyIncome, locale, symbol);
    final String formattedExpenses = formatCurrency(monthlyExpense, locale, symbol);
    
    return StyledCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(monthName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: customYellow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text('$monthDateStr/$yearDateStr', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Income', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    OutlineText(
                      strokeColor: Colors.black,
                      strokeWidth: 2,
                      overflow: TextOverflow.ellipsis,
                      child: Text(
                        formattedIncome,
                        style: TextStyle(color: customGreen, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Expense', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    OutlineText(
                      strokeColor: Colors.black,
                      strokeWidth: 2,
                      overflow: TextOverflow.ellipsis,
                      child: Text(
                        formattedExpenses,
                        style: TextStyle(color: customRed, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Total :',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlineText(
                    overflow: TextOverflow.ellipsis,
                    strokeWidth: 2,
                    child: Text(
                      formattedBalance,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                        color: totalColor,
                        letterSpacing: 1
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class MonthlyTransactionsDetailPage extends StatelessWidget {
  final DateTime monthDate;
  final List<Transaction> transactions;

  const MonthlyTransactionsDetailPage({
    super.key,
    required this.monthDate,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    // Mengurutkan transaksi agar yang terbaru di atas
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final String pageTitle = DateFormat('MMMM yyyy').format(monthDate);
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);

    return Scaffold(
      backgroundColor: customCream,
      body: Stack(
        children: [
          const GridBackground(
              gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      spacing: 12,
                      children: [
                        TopNavigationBar(title: pageTitle),
                        StyledCard(
                          child: sortedTransactions.isEmpty
                              ? const Center(child: Text('No transactions for this month.'))
                              : ListView.separated(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                  itemCount: sortedTransactions.length,
                                  itemBuilder: (context, index) {
                                    return _TransactionListItem(
                                        transaction: sortedTransactions[index]);
                                  },
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                ),
                        ),
                        SizedBox(height: 12,)
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

class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionListItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    
    final transactionProvider = context.watch<TransactionProvider>();

    final locale = transactionProvider.currencyLocale;
    final symbol = transactionProvider.currencySymbol;

    final String formattedBalance = formatCurrency(transaction.amount, locale, symbol);

    final dateFormatter = DateFormat('d MMMM yyyy');

    final bool isExpense = transaction.type == TransactionType.expense;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(transaction.categoryIcon, size: 32, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note.isEmpty
                      ? transaction.category
                      : transaction.note,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormatter.format(transaction.date),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          OutlineText(
            overflow: TextOverflow.ellipsis,
            child: Text(
              '${isExpense ? '-' : '+'} $formattedBalance',
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.bold,
                color: isExpense ? customRed : customGreen,
                fontSize: 14,
                letterSpacing: 1
              ),
            ),
          ),
        ],
      ),
    );
  }
}