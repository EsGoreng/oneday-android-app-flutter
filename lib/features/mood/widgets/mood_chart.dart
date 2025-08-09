import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/mood_models.dart';
import '../../../core/providers/mood_provider.dart';
import '../pages/mood_page.dart';

// Helper class to structure chart data neatly
class _ChartData {
  final DateTime date;
  final Mood? mood;

  _ChartData(this.date, this.mood);
}

class MoodChart extends StatefulWidget {
  // BARU: Terima parameter rentang waktu
  final ChartRange range;
  final DateTimeRange? customDateRange;

  const MoodChart({
    super.key,
    this.range = ChartRange.weekly, // Default ke mingguan
    this.customDateRange,
  });

  @override
  State<MoodChart> createState() => _MoodChartState();
}

class _MoodChartState extends State<MoodChart> {
  int _touchedIndex = -1;

  LinearGradient _getBarGradient(MoodCategory category) {
    return LinearGradient(
      colors: [
        category.color.withValues(alpha: 0.7),
        category.color,
      ],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProvider>(context);

    // --- BARU: Logika Pemrosesan Data Dinamis ---
    final List<_ChartData> chartItems;
    final DateTime now = DateTime.now();
    
    DateTime startDate;
    int dayCount;

    switch (widget.range) {
      case ChartRange.monthly:
        startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
        dayCount = 30;
        break;
      case ChartRange.custom:
        if (widget.customDateRange != null) {
          startDate = widget.customDateRange!.start;
          dayCount = widget.customDateRange!.end.difference(startDate).inDays + 1;
        } else {
          // Fallback jika custom range null
          startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
          dayCount = 7;
        }
        break;
      case ChartRange.weekly:
      startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        dayCount = 7;
        break;
    }

    // Ambil data mood sesuai rentang
    final moodsInRange = moodProvider.getMoodsInDateRange(startDate, startDate.add(Duration(days: dayCount - 1)));
    final moodMap = {
      for (var mood in moodsInRange)
        DateTime(mood.date.year, mood.date.month, mood.date.day): mood
    };

    // Generate data untuk setiap hari dalam rentang
    chartItems = List.generate(dayCount, (index) {
      final date = startDate.add(Duration(days: index));
      return _ChartData(date, moodMap[date]);
    });
    // --- AKHIR: Logika Pemrosesan Data ---

    if (chartItems.every((item) => item.mood == null)) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Text("There is no mood data in this range."),
      );
    }

    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          maxY: 6,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = chartItems[groupIndex];
                if (item.mood == null) return null;

                return BarTooltipItem(
                  '${item.mood!.moodName}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: DateFormat('d MMM').format(item.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
            touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.spot == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = response.spot!.touchedBarGroupIndex;
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= chartItems.length) return const Text('');

                  // BARU: Logika label bawah yang lebih fleksibel
                  final date = chartItems[index].date;
                  String text;
                  // Tampilkan tanggal jika rentang lebih dari 7 hari
                  if (dayCount > 7) {
                    if (index % (dayCount / 5).ceil() == 0) { // Tampilkan sekitar 5 label
                       text = DateFormat('d/M').format(date);
                    } else {
                       return const Text('');
                    }
                  } else {
                    text = DateFormat('EEE').format(date);
                  }
                  
                  return SideTitleWidget(
                    meta: meta,
                    space: 8.0,
                    child: Text(text,
                        style: const TextStyle(color: Colors.black, fontSize: 10)),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          barGroups: chartItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isTouched = index == _touchedIndex;

            if (item.mood != null) {
              final yValue =
                  MoodCategory.values.indexOf(item.mood!.moodCategory).toDouble() + 1;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: isTouched ? yValue + 1 : yValue,
                    gradient: _getBarGradient(item.mood!.moodCategory),
                    width: isTouched ? 24 : 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                    borderSide: isTouched
                        ? BorderSide(
                            color: item.mood!.moodCategory.color.withValues(alpha: 0.9),
                            width: 2)
                        : const BorderSide(color: Colors.white, width: 0),
                  ),
                ],
              );
            } else {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: 0.5,
                    color: Colors.grey.shade300,
                    width: 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }
          }).toList(),
        ),
      ),
    );
  }
}