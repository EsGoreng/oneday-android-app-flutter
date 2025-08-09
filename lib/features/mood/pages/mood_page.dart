import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:oneday/core/models/mood_models.dart';
import 'package:oneday/core/providers/profile_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/mood_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../widgets/mood_chart.dart';
import '../widgets/mood_count.dart';
import '../widgets/mood_widgets.dart';

enum ChartRange { weekly, monthly, custom }

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  static const nameRoute = 'moodPage';

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  final String _adUnitId = "ca-app-pub-3940256099942544/9214589741a";

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  ChartRange _selectedRange = ChartRange.weekly;
  DateTimeRange? _customDateRange;



  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _customDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedRange = ChartRange.custom;
        _customDateRange = picked;
      });
    }
  }

  String _getChartTitle() {
    switch (_selectedRange) {
      case ChartRange.weekly:
        return 'Last 7 Days';
      case ChartRange.monthly:
        return 'Last 30 Days';
      case ChartRange.custom:
        if (_customDateRange != null) {
          final start = DateFormat('d MMM').format(_customDateRange!.start);
          final end = DateFormat('d MMM').format(_customDateRange!.end);
          return '$start - $end';
        }
        return 'Custom Range';
    }
  }

  

  @override
  Widget build(BuildContext context) {

    final moodProvider = Provider.of<MoodProvider>(context);

    final profileProvider = Provider.of<ProfileProvider>(context);

    final todaysMood = moodProvider.getMoodForDay(DateTime.now());

    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                HomeAppBar(profileProvider: profileProvider),
                const SizedBox(height: 12),
                MoodCount(),
                const SizedBox(height: 12),
                _isAdLoaded
                        ? SizedBox(
                            width: _bannerAd!.size.width.toDouble(),
                            height: _bannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: _bannerAd!),
                          )
                        : Container(),
                _isAdLoaded
                  ? const SizedBox(height: 12)
                  : Container(),
                MoodMenu(),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: todaysMood == null
                        ? StyledCard(
                            key: const ValueKey('moodTracker'),
                            padding: const EdgeInsets.all(16),
                            child: MoodTracker(
                              selectedDate: DateTime.now(),
                              popOnSelect: false,
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ),
                
                // Widget-widget lain di bawah MoodTracker
                if (todaysMood != null) ...{
                  StyledCard(
                    color: customPink,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlineText(strokeWidth: 1.5, child: const Text("Today's\nMood ", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1))),
                              const SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(todaysMood.moodCategory.imagePath, height: 30),
                                    const SizedBox(width: 8),
                                    Text(todaysMood.moodCategory.moodName, style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Image.asset('images/illustration/Mood_Illustration.png', scale: 3),
                        )
                      ],
                    ),
                  ),
                },
                const SizedBox(height: 12),
                StyledCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- BARU: Header Chart dengan Tombol ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mood Chart',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _getChartTitle(), // Judul dinamis
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                          // Tombol untuk mengubah rentang
                          PopupMenuButton<ChartRange>(
                            onSelected: (ChartRange result) {
                              if (result == ChartRange.custom) {
                                _selectCustomDateRange();
                              } else {
                                setState(() {
                                  _selectedRange = result;
                                  _customDateRange = null; // Reset custom range
                                });
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<ChartRange>>[
                              const PopupMenuItem<ChartRange>(
                                value: ChartRange.weekly,
                                child: Text('Weekly'),
                              ),
                              const PopupMenuItem<ChartRange>(
                                value: ChartRange.monthly,
                                child: Text('Monthly'),
                              ),
                              const PopupMenuItem<ChartRange>(
                                value: ChartRange.custom,
                                child: Text('Custom'),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // --- AKHIR: Header Chart ---
                      MoodChart(
                        // Kirim parameter baru ke chart
                        range: _selectedRange,
                        customDateRange: _customDateRange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 76),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
