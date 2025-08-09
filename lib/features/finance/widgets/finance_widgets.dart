import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../core/models/savingplan_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

import '../widgets/add_transaction_popup.dart';
import '../widgets/calculator_popup.dart';
import '../widgets/savingplan_popup.dart';
import '../pages/transaction_page.dart';
import '../pages/category_page.dart';

class FinancialChart extends StatelessWidget {
  // Terima List<PieChartSectionData> yang sudah jadi
  final List<PieChartSectionData> sections;

  const FinancialChart({
    super.key,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const Center(
        child: Text('There is no data for this period.'),
      );
    }

    // Widget ini sekarang hanya fokus pada tampilan chart
    return AspectRatio(
      aspectRatio: 1.5,
      child: PieChart(
        duration: Duration(milliseconds: 1500),
        curve: Curves.ease,
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: sections,
        ),
      ),
    );
  }
}

class BadgeWithLine extends StatelessWidget {
  final String label;
  final Color color;
  final bool placeOnTop;

  const BadgeWithLine({
    super.key, 
    required this.label,
    required this.color,
    this.placeOnTop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (placeOnTop) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
        ] else ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ]
      ],
    );
  }
}

class FinanceBalanceCard extends StatelessWidget {
  final String balance;
  final String income;
  final String expenses;

  const FinanceBalanceCard({super.key,required this.balance, required this.income, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return StyledCard(
      color: customYellow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children : [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Balance', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
                OutlineText(
                  overflow: TextOverflow.ellipsis,
                  strokeColor: Colors.black,
                  strokeWidth: 1.5,
                  child: Text(
                    balance,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, overflow: TextOverflow.ellipsis, color: Colors.white, letterSpacing: 1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text('Income' , style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
                OutlineText(
                  overflow: TextOverflow.ellipsis,
                  strokeColor: Colors.black,
                  strokeWidth: 1.5,
                  child: Text(
                    income,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: customGreen, fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: 1),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expenses' , style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black)),
                    OutlineText(
                      overflow: TextOverflow.ellipsis,
                      strokeColor: Colors.black,
                      strokeWidth: 1.5,
                      child: Text(
                        expenses,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: customRed, fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: 1),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          SizedBox(width: 8),
          Image.asset('images/illustration/Dollar_Illustration.png', scale: 3,),
        ]
      ),
    );
  }
}

class FinanceMenu extends StatelessWidget {
  const FinanceMenu({super.key});


  @override
  Widget build(BuildContext context) {

  void openCategory() {
    Navigator.of(context).pushNamed(CategoryPage.nameRoute);
  }

  void openHistory() {
    Navigator.of(context).pushNamed(HistoryPage.nameRoute);
  }

  void showCalculatorPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Calculator',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return const Center(child: CalculatorPopup());
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

  void showTransactionPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Transaction',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return const Center(child: AddTransactionPopup());
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

  void showSavingPlanPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Saving Plan',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return const Center(child: SavingplanPopup());
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

    return StyledCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButtonHelper(icon: Icons.book_outlined, label: 'Trans', ontap: openHistory),
          IconButtonHelper(icon: Icons.category_outlined, label: 'Cat', ontap: openCategory),
          IconButtonHelper(icon: Icons.cloud_outlined, label: 'Save', ontap: showSavingPlanPopup),
          IconButtonHelper(icon: Icons.calculate_outlined, label: 'Calc', ontap: showCalculatorPopup),
          IconButtonHelper(icon: Icons.add_outlined, label: 'Add', ontap: showTransactionPopup),
        ],
      ),
    );
  }
}

class SavingPlanEmptyCard extends StatelessWidget {
  const SavingPlanEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {

  void showSavingPlanPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Saving Plan',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return const Center(child: SavingplanPopup());
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

    return StyledCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('No Saving Plan Available'),
          const SizedBox(height: 8),
          PrimaryButton(
            padding: const EdgeInsets.all(18),
            text: 'Add Saving Plan',
            onPressed: showSavingPlanPopup, // Gunakan parameter onPressed di sini
          )
        ],
      ),
    );
  }
}

class SavingPlan extends StatelessWidget {

  final Savingplan savingplan;

  const SavingPlan({super.key, 
    required this.savingplan,
  });

  // Helper untuk mengubah enum menjadi string yang bisa dibaca
  String _getRangeTypeText(SavingRangeType rangeType) {
    switch (rangeType) {
      case SavingRangeType.daily:
        return '/ Days';
      case SavingRangeType.weekly:
        return '/ Weeks';
      case SavingRangeType.monthly:
        return '/ Month';
    }
  }

  @override
  Widget build(BuildContext context) {

    final transactionProvider = context.watch<TransactionProvider>();
    final locale = transactionProvider.currencyLocale;
    final symbol = transactionProvider.currencySymbol;
    final double collected = savingplan.transactions.fold(0.0, (sum, item) => sum + item.amount);

    // Format nilai mata uang
    final formattedTarget = formatCurrency(savingplan.target, locale, symbol);
    final formattedFilling = formatCurrency(savingplan.filling, locale, symbol);
    final formattedCollected = formatCurrency(collected, locale, symbol); 


    // 2. Hitung 'progressValue' secara dinamis dan aman (menghindari pembagian dengan nol)
    final double progressValue = (savingplan.target > 0)
        ? (collected / savingplan.target).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Judul dan Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                savingplan.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                formattedTarget,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          Container(
            decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(8)),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[300],
              color: customGreen,
              minHeight: 6,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Menampilkan jumlah yang sudah terkumpul
              Expanded(
                flex: 2,
                child: Text(
                  'Saved: \n$formattedCollected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                    overflow: TextOverflow.ellipsis
                  ),
                ),
              ),
              SizedBox(width: 32),
              Expanded(
                flex: 1,
                child: Text(
                  '$formattedFilling ${_getRangeTypeText(savingplan.rangeType)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FinanceCalendarSection extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;

  const FinanceCalendarSection({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  Map<String, double> _getDailySummary(DateTime day, List<Transaction> transactions) {
    double dailyIncome = 0;
    double dailyExpense = 0;

    for (var tx in transactions) {
      if (isSameDay(tx.date, day)) {
        if (tx.type == TransactionType.income) {
          dailyIncome += tx.amount;
        } else {
          dailyExpense += tx.amount;
        }
      }
    }
    return {'income': dailyIncome, 'expense': dailyExpense};
  }

  Widget _buildCellContent(DateTime day, Map<String, double> summary, String locale) {

    final compactFormatter = NumberFormat.compact(locale: locale);

    return ConstrainedBox(
      constraints: BoxConstraints.expand(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}', style: const TextStyle(fontSize: 14)), // Angka tanggal
          if (summary['income']! > 0 || summary['expense']! > 0)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (summary['income']! > 0)
                    Text(
                      compactFormatter.format(summary['income']),
                      style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  if (summary['income']! > 0 && summary['expense']! > 0)
                    const SizedBox(width: 2),
                  if (summary['expense']! > 0)
                    Text(
                      compactFormatter.format(summary['expense']),
                      style: const TextStyle(color: Color(0xFFC62828), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final transactions = transactionProvider.transactions;
    final locale = transactionProvider.currencyLocale;

    final dayBoxDecoration = BoxDecoration(
      shape: BoxShape.rectangle,
      border: Border.all(color: Colors.black, width: 1),
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
      ],
    );

    return StyledCard(
      child: TableCalendar(
        rowHeight: 70,
        focusedDay: focusedDay,
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          leftChevronPadding: EdgeInsets.zero,
          rightChevronPadding: EdgeInsets.zero,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final summary = _getDailySummary(day, transactions);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.all(4),
              decoration: dayBoxDecoration.copyWith(color: Colors.white),
              child: _buildCellContent(day, summary, locale),
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final summary = _getDailySummary(day, transactions);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.all(4),
              decoration: dayBoxDecoration.copyWith(color: const Color(0xfffef3c8)),
              child: _buildCellContent(day, summary, locale),
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            final summary = _getDailySummary(day, transactions);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.all(4),
              decoration: dayBoxDecoration.copyWith(color: const Color(0xFFFFD000)),
              child: _buildCellContent(day, summary, locale),
            );
          },
          holidayBuilder: (context, day, focusedDay) {
            final summary = _getDailySummary(day, transactions);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.all(4),
              decoration: dayBoxDecoration.copyWith(color: customRed),
              child: _buildCellContent(day, summary, locale),
            );
          },
          outsideBuilder: (context, day, focusedDay) {
            final summary = _getDailySummary(day, transactions);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.all(4),
              decoration: dayBoxDecoration.copyWith(color: Colors.grey[300]),
              child: Opacity(
                opacity: 0.6, // Redupkan konten tanggal di luar bulan
                child: _buildCellContent(day, summary, locale)
              ),
            );
          },
          // Kosongkan style di sini karena sudah di-handle oleh builder
        ),
      ),
    );
  }
}

class TransactionTopNavigationBar extends StatelessWidget {

  final String title;
  final VoidCallback? onEditPressed;
  final IconData? actionIcon;

  const TransactionTopNavigationBar({
    super.key, 
    required this.title,
    this.onEditPressed,
    this.actionIcon,
    });

  @override
  Widget build(BuildContext context) {
    return StyledCard(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (actionIcon != null && onEditPressed != null) 
            IconButton(
              icon: Icon(actionIcon),
              onPressed: onEditPressed,
            )
          else
            const SizedBox(width: 48,),
        ],
      ),
    );
  }
}

class HistoryPageBalance extends StatelessWidget {
  
  const HistoryPageBalance({
    super.key,
    required this.income,
    required this.expenses,
    required this.total,
  });

  final double income;
  final double expenses;
  final double total;

  @override
  Widget build(BuildContext context) {

    final transactionProvider = context.watch<TransactionProvider>();

    final locale = transactionProvider.currencyLocale;
    final symbol = transactionProvider.currencySymbol;

    final String formattedBalance = formatCurrency(total, locale, symbol);
    final String formattedIncome = formatCurrency(income, locale, symbol);
    final String formattedExpenses = formatCurrency(expenses, locale, symbol);

    final Color totalColor = total >= 0 ? customGreen : customRed;

    return StyledCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBalanceColumn('Income', formattedIncome, customGreen),
          _buildBalanceColumn('Expenses', formattedExpenses, customRed, crossAxisAlignment: CrossAxisAlignment.center),
          _buildBalanceColumn('Total', formattedBalance, totalColor, crossAxisAlignment: CrossAxisAlignment.end),
        ],
      )
    );
  }

  Widget _buildBalanceColumn(String title, String amount, Color color, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
            Text(
              title, 
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4,),
            OutlineText(
              strokeColor: Colors.black,
              strokeWidth: 2,
              overflow: TextOverflow.ellipsis,
              child: Text(
                amount,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, letterSpacing: 1,fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                ),
            )
        ],
      ),
    );
  }
}