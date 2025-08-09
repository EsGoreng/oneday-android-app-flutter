import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/models/timer_session_model.dart';

class TimerUsageBarChart extends StatefulWidget {
  final Map<String, double> timerUsageData;

  const TimerUsageBarChart({super.key, required this.timerUsageData});

  /// Helper untuk memproses data mentah menjadi data yang siap untuk chart.
  /// Logika ini tidak diubah.
  static Map<String, double> processData(List<TimerSession> sessions) {
    final Map<String, double> data = {};
    for (var session in sessions) {
      final minutes = session.actualDuration.inSeconds / 60.0;
      data.update(
        session.name,
        (value) => value + minutes,
        ifAbsent: () => minutes,
      );
    }
    return data;
  }

  @override
  State<TimerUsageBarChart> createState() => _TimerUsageBarChartState();
}

class _TimerUsageBarChartState extends State<TimerUsageBarChart> {
  // State untuk melacak bar mana yang sedang disentuh
  int _touchedIndex = -1;

  // Definisikan palet warna dan gradient untuk tampilan yang konsisten
  final Color _barColor = const Color(0xff4ECDC4);
  final Color _touchedBarColor = const Color(0xff29A0B1);

  @override
  Widget build(BuildContext context) {
    if (widget.timerUsageData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Text('There is no data.'),
        ),
      );
    }

    final entries = widget.timerUsageData.entries.toList();
    final maxY = entries.isEmpty
        ? 0.0
        : (entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2)
            .ceilToDouble();

    return AspectRatio(
      aspectRatio: 1.3,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),

          // --- Interaktivitas & Tooltip ---
          barTouchData: BarTouchData(
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    barTouchResponse == null ||
                    barTouchResponse.spot == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              });
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = entries[groupIndex];
                final minutes = entry.value.toStringAsFixed(1);
                return BarTooltipItem(
                  '${entry.key}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '$minutes minute',
                      style: TextStyle(
                        color: _barColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // --- Grid & Latar Belakang ---
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: Colors.black12,
              strokeWidth: 1,
            ),
          ),

          // --- Label Sumbu (Titles) ---
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value >= maxY) return const Text('');
                  return Text('${value.toInt()}m', style: const TextStyle(fontSize: 10, color: Colors.black54));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42, // Beri ruang lebih untuk label miring
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= entries.length) return const Text('');
                  final titleText = entries[index].key;
                  
                  // Miringkan label agar tidak tumpang tindih
                  return SideTitleWidget(
                    meta: meta,
                    space: 8.0,
                    child: Transform.rotate(
                      angle: -pi / 5, // Sudut kemiringan
                      child: Text(
                        titleText.length > 10 ? '${titleText.substring(0, 8)}...' : titleText,
                        style: const TextStyle(fontSize: 10, color: Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // --- Data Bar ---
          barGroups: List.generate(entries.length, (i) {
            final isTouched = i == _touchedIndex;
            final entry = entries[i];

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  gradient: LinearGradient( // Gunakan gradient
                    colors: [
                      _barColor,
                      _touchedBarColor,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: isTouched ? 22 : 16, // Efek membesar saat disentuh
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  borderSide: isTouched // Efek border saat disentuh
                      ? BorderSide(color: _touchedBarColor.withValues(alpha: 0.9), width: 2)
                      : const BorderSide(width: 0, color: Colors.transparent),
                ),
              ],
            );
          }),
        ),
        // Aktifkan animasi
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      ),
    );
  }
}