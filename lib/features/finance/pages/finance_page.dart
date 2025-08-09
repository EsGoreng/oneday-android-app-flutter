
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oneday/core/providers/profile_provider.dart';
import 'package:oneday/features/finance/pages/savingplan_detail_page.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/models/transaction_model.dart';
import '../../../core/providers/savingplan_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

import '../widgets/finance_widgets.dart';

enum TimeRange { daily, monthly, yearly, custom }

class FinancePage extends StatefulWidget {
  const FinancePage({
    super.key,
  });

  static const nameRoute = 'financePage';

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  DateTimeRange? _customDateRange;
  TimeRange _selectedTimeRange = TimeRange.daily;
  TransactionType _selectedTransactionType = TransactionType.expense;

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customDateRange,
    );

    if (pickedDateRange != null && pickedDateRange != _customDateRange) {
      setState(() {
        _customDateRange = pickedDateRange;
        _selectedTimeRange = TimeRange.custom; // Otomatis pindah ke custom
      });
    }
  }

  String _getTimeRangeText(TimeRange range) {
    switch (range) {
      case TimeRange.daily:
        return 'Daily';
      case TimeRange.monthly:
        return 'Monthly';
      case TimeRange.yearly:
        return 'Yearly';
      case TimeRange.custom:
        if (_customDateRange != null) {
          final start = DateFormat('d/M/yy').format(_customDateRange!.start);
          final end = DateFormat('d/M/yy').format(_customDateRange!.end);
          return '$start - $end';
        }
        return 'Custom';
    }
  }

  Widget _buildPercentageBreakdown(
      Map<String, double> dataMap, double totalValue, String locale, String symbol) {
    if (dataMap.isEmpty) {
      return const SizedBox.shrink(); // Jangan tampilkan apa pun jika tidak ada data
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: dataMap.entries.map((entry) {

          final formattedValue = formatCurrency(entry.value, locale, symbol);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: _getColorForCategory(entry.key),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '(${(entry.value / totalValue * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: Text(
                    formattedValue,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    // Simple color mapping for demonstration. You can create a more robust color generation logic.
    final List<Color> colors = [
      customRed,
      customGreen,
      Colors.blue,
      customYellow,
      Colors.purple,
      Colors.yellow,
      Colors.cyan,
      Colors.pink,
    ];
    final int hashCode = category.hashCode;
    return colors[hashCode % colors.length];
  }

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

    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        // Hitung total dari transaksi
        final transactions = transactionProvider.transactions;
        
        final double totalIncome = transactions
            .where((tx) => tx.type == TransactionType.income)
            .fold(0.0, (sum, item) => sum + item.amount);
        final double totalExpenses = transactions
            .where((tx) => tx.type == TransactionType.expense)
            .fold(0.0, (sum, item) => sum + item.amount);
        final double balance = totalIncome - totalExpenses;

        // Format ke dalam Rupiah
        final locale = transactionProvider.currencyLocale;
        final symbol = transactionProvider.currencySymbol;

        final String formattedBalance = formatCurrency(balance, locale, symbol);
        final String formattedIncome = formatCurrency(totalIncome, locale, symbol);
        final String formattedExpenses = formatCurrency(totalExpenses, locale, symbol);

        final filteredTransactions = transactionProvider
            .getTransactionsForTimeRange(_selectedTimeRange, _customDateRange)
            .where((tx) => tx.type == _selectedTransactionType)
            .toList();

        final Map<String, double> dataMap = {};

        for (var tx in filteredTransactions) {
          dataMap.update(tx.category, (value) => value + tx.amount,
              ifAbsent: () => tx.amount);
        }

        final double totalValue =
            filteredTransactions.fold(0.0, (sum, item) => sum + item.amount);

        bool isLastBadgeOnTop = false;

        final profileProvider = Provider.of<ProfileProvider>(context);

        double lastAngle = 0;
        
        final List<PieChartSectionData> sections = dataMap.entries.map((entry) {
          final double percentage = entry.value / totalValue * 100;
          final double currentAngle = (entry.value / totalValue) * 360;

          bool placeOnTop = isLastBadgeOnTop;
          if ((currentAngle + lastAngle) / 2 < 20) { // Jika sudut terlalu dekat
            placeOnTop = !isLastBadgeOnTop;
          }
          isLastBadgeOnTop = placeOnTop;
          lastAngle = currentAngle;

        return PieChartSectionData(
          borderSide: BorderSide(width: 1.5),
          color: _getColorForCategory(entry.key),
          value: entry.value,
          badgePositionPercentageOffset: 1.7,
          showTitle: false,
          title: '${percentage.toStringAsFixed(0)}%',
          titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),

          badgeWidget: BadgeWithLine(label: entry.key, color: _getColorForCategory(entry.key), placeOnTop: true,)
        );
      }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    HomeAppBar(profileProvider: profileProvider),
                    SizedBox(height: 12),
                    FinanceBalanceCard(
                      balance: formattedBalance,
                      income: formattedIncome,
                      expenses: formattedExpenses,
                    ),
                    SizedBox(height: 12),
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
                    FinanceMenu(),
                    SizedBox(height: 12),
                    StyledCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Chart',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              DropdownButton<TimeRange>(
                                underline: SizedBox(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: 'Poppins'
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                isDense: true,
                                value: _selectedTimeRange,
                                items: TimeRange.values.map((TimeRange range) {
                                  return DropdownMenuItem<TimeRange>(
                                    value: range,
                                    child: Text(_getTimeRangeText(range)),
                                  );
                                }).toList(),
                                onChanged: (TimeRange? newValue) {
                                  if (newValue == TimeRange.custom) {
                                    _selectCustomDateRange(context);
                                  } else if (newValue != null) {
                                    setState(() {
                                      _selectedTimeRange = newValue;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          Divider(height: 20),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  padding: EdgeInsets.all(8),
                                  text: 'Expense',
                                  onPressed: () {
                                    setState(() {
                                      _selectedTransactionType = TransactionType.expense;
                                    });
                                  },
                                  isSelected: _selectedTransactionType == TransactionType.expense,
                                  color: _selectedTransactionType == TransactionType.expense
                                      ? customRed
                                      : Colors.grey.shade300,
                                  textColor: _selectedTransactionType == TransactionType.expense
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: PrimaryButton(
                                  padding: EdgeInsets.all(8),
                                  text: 'Income',
                                  onPressed: () {
                                    setState(() {
                                      _selectedTransactionType = TransactionType.income;
                                    });
                                  },
                                  isSelected: _selectedTransactionType == TransactionType.income,
                                  color: _selectedTransactionType == TransactionType.income
                                      ? customGreen
                                      : Colors.grey.shade300,
                                  textColor: _selectedTransactionType == TransactionType.income
                                      ? Colors.black
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 34),
                          AnimatedSize(duration: Duration(milliseconds: 200), curve: Curves.easeIn, child: FinancialChart(sections: sections)),
                          SizedBox(height: 24),
                          Divider(height: 20),
                          _buildPercentageBreakdown(dataMap, totalValue, locale, symbol),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Consumer<SavingplanProvider>(
                      builder: (context, savingPlanProvider, child) {
            
                        final plans = savingPlanProvider.savingplans;
            
                        if (plans.isEmpty) {
                          // Jika tidak ada rencana, tampilkan kartu kosong
                          return SavingPlanEmptyCard();
                        } else {
                          // Jika ada, tampilkan dalam sebuah kartu
                          return StyledCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Saving Plans',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Divider(height: 20),
                                // Gunakan ListView.separated untuk membuat daftar dengan pemisah
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: plans.length,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SavingPlanDetailPage(
                                              plan: plans[index], // Kirim data plan yang diklik
                                            ),
                                          ),
                                        );
                                      },
                                      child: SavingPlan(savingplan: plans[index]),
                                    );
                                  },
                                  separatorBuilder: (context, index) => const Divider(),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 76),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


