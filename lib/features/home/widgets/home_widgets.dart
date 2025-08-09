import 'dart:convert';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:oneday/core/providers/profile_provider.dart';
import 'package:oneday/features/home/pages/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/models/mood_models.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../core/providers/savingplan_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../finance/pages/category_page.dart';
import '../../finance/pages/transaction_page.dart';
import '../../finance/widgets/add_transaction_popup.dart';
import '../../finance/widgets/calculator_popup.dart';
import '../../finance/widgets/savingplan_popup.dart';
import '../../habit/pages/habit_notes_page.dart';
import '../../habit/pages/timer_page.dart';
import '../../mood/pages/mood_calendar_page.dart';
import '../../mood/pages/mood_notes_page.dart';

class BalanceCard extends StatelessWidget {
  final String balance;
  final String savingsRate;

  const BalanceCard({super.key, required this.balance, required this.savingsRate});

  @override
  Widget build(BuildContext context) {
    return StyledCard(
      height: 144,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text('Your Balance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(
                  balance,
                  style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20, overflow: TextOverflow.ellipsis),
                  maxLines: 1,
                ),
                const Text('Your Saving', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                OutlineText(
                  strokeColor: Colors.black,
                  strokeWidth: 1.5,
                  child: Text(
                    savingsRate,
                    style: const TextStyle(color: Color(0XFF4CFE78), fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              // Placeholder untuk grafik
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Chart Area')),
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarSection extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;

  const CalendarSection({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Dekorasi yang berulang diekstrak menjadi satu variabel untuk keringkasan.
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
        rowHeight: 40,
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
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(4),
          selectedDecoration: dayBoxDecoration.copyWith(color: const Color(0xFFFFD000)),
          todayDecoration: dayBoxDecoration.copyWith(color: const Color(0xfffef3c8)),
          defaultDecoration: dayBoxDecoration.copyWith(color: Colors.white),
          weekendDecoration: dayBoxDecoration.copyWith(color: const Color(0xFFFF5F5F)),
          outsideDecoration: dayBoxDecoration.copyWith(color: Colors.grey[300]),
          selectedTextStyle: const TextStyle(color: Colors.black),
          todayTextStyle: const TextStyle(color: Colors.black),
          weekendTextStyle: const TextStyle(color: Colors.black),
          outsideTextStyle: TextStyle(color: Colors.grey[600]!),
        ),
      ),
    );
  }
}

class ProfileCard extends StatefulWidget {
  const ProfileCard({
    super.key,
    required this.profileProvider,
  });

  final ProfileProvider profileProvider;

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    final profileProvider = Provider.of<ProfileProvider>(context);

    final String avatarUrl = profileProvider.profilePicturePath;
    final bool isSvg =
        avatarUrl.contains('api.dicebear.com') || avatarUrl.endsWith('.svg');
    
    return StyledCard(
      child: InkWell(
        onTap: () {
          Navigator.push(context,MaterialPageRoute(
            builder: (context) => ProfilePage(),
            ),
          );
        },
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    )
                  ),
                  Text(
                    profileProvider.userName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all()
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade300,
                child: ClipOval(
                  child: isSvg
                      ? SvgPicture.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 70,
                          height: 70,
                          placeholderBuilder: (_) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 70,
                          height: 70,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                ),
              ),
            ),
            )
          ],
        ),
      ) 
    );
  }

  
}

class MoodSummaryCard extends StatefulWidget {
  const MoodSummaryCard({super.key});

  @override
  State<MoodSummaryCard> createState() => _MoodSummaryCardState();
}

class _MoodSummaryCardState extends State<MoodSummaryCard> {
  int touchedIndex = -1; // Menyimpan indeks bagian chart yang disentuh

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        // Mengambil data mood untuk 7 hari terakhir
        final moods = moodProvider.getMoodsInDateRange(
          DateTime.now().subtract(const Duration(days: 6)),
          DateTime.now(),
        );

        // Jika tidak ada data, tampilkan pesan
        if (moods.isEmpty) {
          return StyledCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text("Mood Summary",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                        )),
                    Divider(height: 32),
                    Center(
                        child: Text(
                            "There is no mood data to display yet.",
                            style: TextStyle(color: Colors.grey),
                        ),
                    ),
                    SizedBox(height: 32),
                ],
            ),
          );
        }

        Map<MoodCategory, int> moodCounts = {};
        for (var mood in moods) {
          moodCounts[mood.moodCategory] = (moodCounts[mood.moodCategory] ?? 0) + 1;
        }

        // Membuat data untuk PieChart
        List<PieChartSectionData> sections = [];
        int i = 0;
        moodCounts.forEach((category, count) {
            final isTouched = i == touchedIndex;
            final fontSize = isTouched ? 16.0 : 12.0;
            final radius = isTouched ? 50.0 : 40.0;
            final color = category.color;

            sections.add(PieChartSectionData(
                color: color,
                value: count.toDouble(),
                title: '$count',
                radius: radius,
                titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xffffffff),
                    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 2)],
                ),
            ));
            i++;
        });

        return StyledCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Mood Summary",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  )),
              const Divider(height: 12),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2, // Memberi sedikit jarak antar bagian
                          centerSpaceRadius: 40,
                          sections: sections,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Bagian Legenda
                  Expanded(
                    flex: 2,
                    child: Wrap(
                        direction: Axis.vertical, // Menyusun chip secara vertikal
                        spacing: 3.0, // Jarak vertikal antar chip
                        runSpacing: 4.0,
                        children: moodCounts.entries.map((entry) {
                          return Chip(
                              avatar: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    backgroundColor: entry.key.color,
                                    radius: 10,
                                  )
                              ),
                              label: Text(entry.key.moodName), // Mengambil nama mood dari enum
                              labelPadding: EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                  ),
                ],
              ),
              SizedBox(height: 4)
            ],
          ),
        );
      },
    );
  }
}

class TaskSummaryCard extends StatelessWidget {
  const TaskSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final todayTasks = taskProvider.getTasksForDay(DateTime.now());
        final incompleteTodayTasks = todayTasks.where((t) => !t.status).toList();
        return StyledCard(
          color: customPink,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlineText(strokeWidth: 1.5, child: Text("Today's\nTask", maxLines: 2 ,overflow: TextOverflow.fade,style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1))),
                    SizedBox(height: 8),
                    Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 1, color: Colors.black),
                      borderRadius: BorderRadius.all(Radius.circular(8))
                    ),
                    child: Text(
                      "${incompleteTodayTasks.length} Task",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  ],
                )),
              const SizedBox(width: 8),
              Image.asset('images/illustration/Task_Illustration.png', scale: 3),
            ],
          ),
        );
      },
    );
  }
}

class TransactionSummaryCard extends StatefulWidget {
  const TransactionSummaryCard({super.key});

  @override
  State<StatefulWidget> createState() => TransactionSummaryCardState();
}

class TransactionSummaryCardState extends State<TransactionSummaryCard> {
  final Color incomeColor = const Color(0xFF27B56E); // Warna hijau yang lebih segar
  final Color expenseColor = const Color(0xFFE84545); // Warna merah yang lebih tegas

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final weeklyData = _generateWeeklyData(transactionProvider);
        final maxY = _calculateMaxY(weeklyData);
        final locale = transactionProvider.currencyLocale;
        final symbol = transactionProvider.currencySymbol;

        return StyledCard(
          child: AspectRatio(
            aspectRatio: 1.2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Money Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 12),
                const SizedBox(height: 4),
                Text(
                  'Summary of the last 7 days',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: BarChart(
                    mainBarData(weeklyData, maxY, locale, symbol),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(incomeColor, "Income"),
                    const SizedBox(width: 16),
                    _buildLegend(expenseColor, "Expenses"),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper untuk menghitung data mingguan
  List<Map<String, dynamic>> _generateWeeklyData(TransactionProvider provider) {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final dailyTransactions = provider.transactions.where((tx) => 
          !tx.date.isBefore(startOfDay) && tx.date.isBefore(endOfDay)).toList();

      double dailyIncome = dailyTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, item) => sum + item.amount);
      double dailyExpense = dailyTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, item) => sum + item.amount);
      
      data.add({'income': dailyIncome, 'expense': dailyExpense});
    }
    return data;
  }

  // Helper untuk menghitung nilai Y maksimum
  double _calculateMaxY(List<Map<String, dynamic>> weeklyData) {
    double maxVal = 0;
    for (var dayData in weeklyData) {
      if (dayData['income'] > maxVal) maxVal = dayData['income'];
      if (dayData['expense'] > maxVal) maxVal = dayData['expense'];
    }
    // Tambahkan buffer 20% agar chart tidak terlalu mepet ke atas
    return maxVal * 1.2;
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: <Widget>[
        Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  BarChartData mainBarData(List<Map<String, dynamic>> weeklyData, double maxY, String locale, String symbol) {
    return BarChartData(
      maxY: maxY,
      barTouchData: barTouchData(locale, symbol),
      titlesData: titlesData(locale, symbol),
      borderData: borderData,
      barGroups: List.generate(weeklyData.length, (i) {
        final dayData = weeklyData[i];
        return makeGroupData(i, dayData['income'], dayData['expense']);
      }),
      gridData: const FlGridData(show: false),
      alignment: BarChartAlignment.spaceBetween,
    );
  }

  BarTouchData barTouchData(String locale, String symbol) => BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String type = rod.color == incomeColor ? 'Income' : 'Expenses';
            // Gunakan fungsi formatCurrency dari provider
            final formattedValue = formatCurrency(rod.toY, locale, symbol);
            
            return BarTooltipItem(
              '$type\n',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              children: <TextSpan>[
                TextSpan(
                  text: formattedValue,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            );
          },
        ),
      );

  FlTitlesData titlesData(String locale, String symbol) => FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: getBottomTitles),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (value, meta) => getLeftTitles(value, meta, locale, symbol),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      );

  Widget getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 12);
    final day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
    String text = DateFormat('E').format(day); // Format: Sen, Sel, Rab, dst.
    return SideTitleWidget(meta: meta, space: 10, child: Text(text, style: style));
  }

  Widget getLeftTitles(double value, TitleMeta meta, String locale, String symbol) {
    // if (value == meta.max || value == 0) return const SizedBox();
    final formattedValue = NumberFormat.compactCurrency(locale: locale, symbol: symbol).format(value);
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(
        formattedValue,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 10),
        textAlign: TextAlign.start,
      ),
    );
  }

  FlBorderData get borderData => FlBorderData(show: false);

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 10,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: incomeColor,
          width: 10,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
        ),
        BarChartRodData(
          toY: y2,
          color: expenseColor,
          width: 10,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
        ),
      ],
    );
  }
}

class SavingPlanSummaryCard extends StatelessWidget {
  const SavingPlanSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer ganda untuk mengakses kedua provider
    return Consumer2<SavingplanProvider, TransactionProvider>(
      builder: (context, savingPlanProvider, transactionProvider, child) {
        
        final savingPlans = savingPlanProvider.savingplans;
        if (savingPlans.isEmpty) {
          return const SizedBox();
        }

        // Ambil pengaturan mata uang dari TransactionProvider
        final locale = transactionProvider.currencyLocale;
        final symbol = transactionProvider.currencySymbol;

        return Padding(
          padding: EdgeInsetsGeometry.only(top: 12),
          child: StyledCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Saving Plan",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: savingPlans.length,
                  itemBuilder: (context, index) {
                    final plan = savingPlans[index];
                    final double totalFilled = plan.transactions.fold(0, (sum, item) => sum + item.amount);
                    final double progress = (plan.target > 0) ? (totalFilled / plan.target).clamp(0, 1) : 0.0;
          
                    // Format nominal menggunakan pengaturan dinamis
                    final formattedFilled = formatCurrency(totalFilled, locale, symbol);
                    final formattedTarget = formatCurrency(plan.target, locale, symbol);
          
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              plan.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              formattedTarget,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.all(Radius.circular(8))
                          ),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            color: customGreen, // Warna hijau konsisten
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$formattedFilled / $formattedTarget',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(height: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShortcutMenu extends StatelessWidget {
  const ShortcutMenu({super.key});


  @override
  Widget build(BuildContext context) {

  void onShowMoodNotes() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const MoodNotesPage()),
      );
  }

  void onShowMoodCalendar() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const MoodCalendarPage()),
      );
  }

  void onShowTimer() {
    Navigator.push(context,
      MaterialPageRoute(
        builder: (context) => TimerPage(),
      ),
    );
  }
  
  void onShowHabitNotes() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const HabitNotesPage()),
      );
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Finance', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButtonHelper(icon: Icons.book_outlined, label: 'Trans', ontap: openHistory),
              IconButtonHelper(icon: Icons.category_outlined, label: 'Cat', ontap: openCategory),
              IconButtonHelper(icon: Icons.cloud_outlined, label: 'Save', ontap: showSavingPlanPopup),
              IconButtonHelper(icon: Icons.calculate_outlined, label: 'Calc', ontap: showCalculatorPopup),
              IconButtonHelper(icon: Icons.add_outlined, label: 'Add', ontap: showTransactionPopup),
            ],
          ),
          SizedBox(height: 8),
          Divider(height: 8),
          Text('Habit', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            spacing: 10,
            children: [
              Expanded(flex : 1, child: IconButtonHelper2(icon: Icons.note_add_outlined, label: 'Notes', ontap: onShowHabitNotes)),
              Expanded(flex : 1 ,child: IconButtonHelper2(icon: Icons.timer_outlined, label: 'Timer', ontap: onShowTimer)),
            ],
          ),
          SizedBox(height: 8),
          Divider(height: 8),
          Text('Mood', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            spacing: 10,
            children: [
              Expanded(flex : 1, child: IconButtonHelper2(icon: Icons.note_add_outlined, label: 'Notes', ontap: onShowMoodNotes)),
              Expanded(flex : 1 ,child: IconButtonHelper2(icon: Icons.calendar_month_outlined, label: 'Calendar', ontap: onShowMoodCalendar)),
            ],
          )
        ],
      ),
    );
  }
}


class FactCard extends StatefulWidget {
  const FactCard({super.key});

  @override
  State<FactCard> createState() => _FactCardState();
}

class _FactCardState extends State<FactCard> {
  late Future<String> _factFuture;
  final String _apiKey = 'lEqyBYiTRJO0Oalkl+UBwQ==1tFNKmqMXRG8so1c'; // <-- Ganti dengan API Key Anda

  @override
  void initState() {
    super.initState();
    _factFuture = _fetchFact();
  }

  Future<String> _fetchFact() async {
    if (_apiKey == 'lEqyBYiTRJO0Oalkl+UBwQ==1tFNKmqMXRG8so1c ' || _apiKey.isEmpty) {
      return "Mohon masukkan API Key Anda untuk menampilkan fakta.";
    }

    final url = Uri.parse('https://api.api-ninjas.com/v1/facts');
    try {
      final response = await http.get(
        url,
        headers: {'X-Api-Key': _apiKey},
      );

      if (response.statusCode == 200) {
        // Jika berhasil, parse JSON dan ambil fakta pertama
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data[0]['fact'];
        }
        return "Fact not Found.";
      } else {
        // Jika gagal, tampilkan pesan error dari status code
        return "Failed to load facts. Error: ${response.statusCode}";
      }
    } catch (e) {
      // Jika terjadi error koneksi
      return "Failed to connect. Check your internet connection.";
    }
  }

  void _refreshFact() {
    setState(() {
      _factFuture = _fetchFact();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyledCard(
      color: customPink,
      padding: EdgeInsets.only(top: 8, bottom: 12, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlineText(
                      child: Text(
                        'Fact of the Day!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshFact,
                tooltip: 'Get a new fact',
              )
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                    color: customCream,
                  ),
                  child: FutureBuilder<String>(
                    future: _factFuture,
                    builder: (context, snapshot) {
                      // 1. Saat data masih dimuat
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(color: Colors.black),
                          ),
                        );
                      }
                      // 2. Jika terjadi error
                      if (snapshot.hasError) {
                        return Text(
                          'There is an error: ${snapshot.error}',
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        );
                      }
                      // 3. Jika data berhasil didapat
                      if (snapshot.hasData) {
                        return Text(
                          snapshot.data!,
                          style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400),
                        );
                      }
                      // State default
                      return const Text(
                        'Failed to load facts.',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Image.asset('images/illustration/hello_character.png',
                scale: 0.5),
              )
            ],
          ),
          SizedBox(height: 8)
        ],
      ),
    );
  }
}
