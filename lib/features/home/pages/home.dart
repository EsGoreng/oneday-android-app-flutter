import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';

import 'package:provider/provider.dart';

import '../../../core/providers/profile_provider.dart';
import '../widgets/home_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const nameRoute = 'homePage';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

    final profileProvider = Provider.of<ProfileProvider>(context);

    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                ProfileCard(profileProvider: profileProvider,),
                const SizedBox(height: 12),
                FactCard(),
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
                ShortcutMenu(),
                const SizedBox(height: 12),
                const TaskSummaryCard(),
                const SizedBox(height: 12),
                const TransactionSummaryCard(),
                const SavingPlanSummaryCard(),
                const SizedBox(height: 12),
                const MoodSummaryCard(),
                const SizedBox(height: 76),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
