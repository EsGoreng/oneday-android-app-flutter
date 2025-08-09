import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:oneday/core/providers/profile_provider.dart';
import 'package:oneday/features/habit/pages/timer_history_page.dart';
import 'package:provider/provider.dart';

import '../../../core/models/quote_model.dart';
import '../../../core/providers/timer_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/habit_widget.dart';
import '../widgets/timer_usage_widget.dart';

class HabitPage extends StatefulWidget {
  const HabitPage({super.key});
  static const nameRoute = 'habitPage';

  @override
  State<HabitPage> createState() => _HabitPage();
}

class _HabitPage extends State<HabitPage> {

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

  @override
  Widget build(BuildContext context) {

    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);

    final profileProvider = Provider.of<ProfileProvider>(context);
    final sessions = Provider.of<TimerProvider>(context).completedSessions;
    final chartData = TimerUsageBarChart.processData(sessions);

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
                QOTDCard(),
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
                CalendarWidget(),
                const SizedBox(height: 12),
                HabitMenu(),
                const SizedBox(height: 12),
                StyledCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Timer Chart',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          
                          if (sessions.isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_note),
                              tooltip: 'Manage History',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>  const ManageHistoryPage()),
                                );
                              },
                            ),
                          ]
                          ,
                        ],
                      ),
                      const Divider(height: 12),
                      const SizedBox(height: 12),
                      TimerUsageBarChart(timerUsageData: chartData),
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


class QOTDCard extends StatefulWidget {
  const QOTDCard({
    super.key,
  });

  @override
  State<QOTDCard> createState() => _QOTDCardState();
}

class _QOTDCardState extends State<QOTDCard> {
  late Future<Quote> futureQuote;

  @override
  void initState() {
    super.initState();
    futureQuote = fetchQuote();
  }

  Future<Quote> fetchQuote() async {
    final response =
        await http.get(Uri.parse('https://api.quotable.io/random'));

    if (response.statusCode == 200) {
      return Quote.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load quote');
    }
  }

  void _refreshFact() {
    setState(() {
      futureQuote = fetchQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyledCard(
      padding: EdgeInsets.only(top: 8, bottom: 12, left: 16, right: 16),
      color: customPink,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlineText(
                child: Text(
                  'Daily Quotes',
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
                tooltip: 'Get a new Quotes',
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                    color: customCream,
                  ),
                  child: FutureBuilder<Quote>(
                    future: futureQuote,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(color: Colors.black),
                          )
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              ' "${snapshot.data!.content}" ',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '- ${snapshot.data!.author}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12
                              ),
                            ),
                          ],
                        );
                      }
                      // State default jika tidak ada data
                      return const Text('Loading quote...');
                    },
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Image.asset('images/illustration/Happy_Flowers.png',
                scale: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
