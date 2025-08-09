import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../../../shared/widgets/common_widgets.dart';

class HistorypageDaily extends StatelessWidget {
  // PERUBAHAN: Hapus parameter 'transactions' dari constructor.
  // Widget ini tidak lagi menerima data dari luar, tapi akan mengambilnya sendiri.
  const HistorypageDaily({super.key});

  @override
  Widget build(BuildContext context) {
    // PERUBAHAN: Gunakan Consumer untuk mendengarkan perubahan pada TransactionProvider.
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        // Ambil daftar transaksi terbaru langsung dari provider.
        final transactions = transactionProvider.transactions;

        if (transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No transactions yet.',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
          );
        }

        // Logika untuk mengelompokkan dan mengurutkan data tetap sama.
        final groupedTransactions = groupBy(
          transactions,
          (Transaction tx) => DateFormat('yyyy-MM-dd').format(tx.date),
        );

        final sortedDates = groupedTransactions.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          shrinkWrap: true,
          // Gunakan NeverScrollableScrollPhysics jika widget ini berada di dalam SingleChildScrollView lain.
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedDates.length,
          itemBuilder: (ctx, index) {
            final dateKey = sortedDates[index];
            final dailyTransactions = groupedTransactions[dateKey]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: DailyHistoryCard(
                date: DateTime.parse(dateKey),
                transactions: dailyTransactions,
              ),
            );
          },
        );
      },
    );
  }
}

class DailyHistoryCard extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;

  const DailyHistoryCard({
    super.key,
    required this.date,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final double dailyIncome = transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double dailyExpense = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    // Format tanggal
    final String dayDate = DateFormat('dd').format(date);
    final String monthDate = DateFormat('MM').format(date);
    final String yearDate = DateFormat('yyyy').format(date);
    final String weekdayName = DateFormat('E').format(date);

    final double dailyTotal = dailyIncome - dailyExpense;
    final Color totalColor = dailyTotal >= 0 ? customGreen : customRed;
    
    final transactionProvider = context.watch<TransactionProvider>();

    final locale = transactionProvider.currencyLocale;
    final symbol = transactionProvider.currencySymbol;

    final String formattedBalance = formatCurrency(dailyTotal, locale, symbol);
    final String formattedIncome = formatCurrency(dailyIncome, locale, symbol);
    final String formattedExpenses = formatCurrency(dailyExpense, locale, symbol);

    return StyledCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dayDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('/$monthDate/$yearDate', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: customYellow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Text(weekdayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Income', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    OutlineText(
                      strokeColor: Colors.black,
                      strokeWidth: 2,
                      overflow: TextOverflow.ellipsis,
                      child: Text(
                        formattedIncome,
                        style: TextStyle(color: customGreen, fontWeight: FontWeight.bold,fontSize: 12, letterSpacing: 1),
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
                    const Text('Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    OutlineText(
                      strokeColor: Colors.black,
                      strokeWidth: 2,
                      overflow: TextOverflow.ellipsis,
                      child: Text(
                        formattedExpenses,
                        style: TextStyle(color: customRed, fontWeight: FontWeight.bold, letterSpacing: 1),
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return InkWell(
                child: _TransactionRow(transaction: transactions[index]),
                // onTap: () {},
                );
            },
            separatorBuilder: (context, index) => Divider(color: Colors.grey[300]),
          ),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(height: 8,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                  'Total :',
                  style: TextStyle(
                    fontWeight: FontWeight.w600
                  ),
                  ),
                ]
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                        color: totalColor,
                        letterSpacing: 1),
                    )
                  ),
                ]
              )
            ],
          )
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == TransactionType.income;
    final Color amountColor = isIncome ? customGreen : customRed;
    final String amountPrefix = isIncome ? '+' : '-';

    final transactionProvider = context.watch<TransactionProvider>();

    final locale = transactionProvider.currencyLocale;
    final symbol = transactionProvider.currencySymbol;

    final String formattedBalance = formatCurrency(transaction.amount, locale, symbol);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: customPink,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(transaction.categoryIcon, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          transaction.category, 
                          style: const TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.w700), 
                            overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              transaction.note.isEmpty ? '-' : transaction.note,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlineText(
                strokeColor: Colors.black,
                strokeWidth: 2,
                overflow: TextOverflow.ellipsis,
                child: Text(
                  '$amountPrefix $formattedBalance',
                  style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
