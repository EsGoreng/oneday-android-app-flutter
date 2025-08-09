import 'package:flutter/material.dart';
import 'package:oneday/features/finance/pages/transaction_page/budgetting_transaction.dart';
import 'package:oneday/features/finance/pages/transaction_page/calendar_transaction.dart';
import 'package:oneday/features/finance/pages/transaction_page/daily_transaction.dart';
import 'package:oneday/features/finance/pages/transaction_page/monthly_transaction_.dart';
import 'package:oneday/features/finance/pages/transaction_page/note_transaction.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:ui';

import '../../../core/models/transaction_model.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../widgets/finance_widgets.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  static const nameRoute = 'historyPage';
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _selectedIndex = 1; // Default ke 'Daily'
  final ScrollController _scrollController = ScrollController(); // 1. Membuat ScrollController

  @override
  void dispose() {
    _scrollController.dispose(); // 4. Membersihkan controller
    super.dispose();
  }

  void _onItemTapped(int index) {
    // 3. Lompat ke atas sebelum mengubah state
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showSelectionPopup(BuildContext context) {

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Select & Delete Transactions',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return _SelectionAndDeletePopup();
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

  @override
  Widget build(BuildContext context) {

    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;

    // Hitung total income dan expenses dari data
    final double totalIncome = transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double totalExpenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double total = totalIncome - totalExpenses;

    // Daftar halaman sekarang menggunakan data yang sebenarnya
    final List<Widget> pages = <Widget>[
      HistorypageCalendar(),
      HistorypageDaily(), // Kirim data transaksi
      HistorypageMonthly(transactions: transactions,),
      HistorypageBudget(),
      HistorypageNote(),
    ];

    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    return Scaffold(
      backgroundColor: customCream,
      body: Stack(
        children: [
          const GridBackground(gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    controller: _scrollController, // 2. Mengaitkan controller
                    clipBehavior: Clip.none,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TopNavigationBar(
                          title: 'Transaction',
                          actionIcon: Icons.delete,
                          onEditPressed: () => _showSelectionPopup(context)),
                        const SizedBox(height: 12),
                        StyledTopNavBar(
                          selectedIndex: _selectedIndex,
                          onItemTapped: _onItemTapped,
                        ),
                        const SizedBox(height: 12),
                        HistoryPageBalance(
                          income: totalIncome,
                          expenses: totalExpenses,
                          total: total,
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return Stack(
                              children: <Widget>[
                                // Halaman lama yang memudar keluar 
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                                // Halaman baru yang memudar masuk
                                FadeTransition(
                                  opacity: animation,
                                  child: Container(
                                    key: ValueKey<int>(_selectedIndex),
                                    child: pages[_selectedIndex],
                                  ),
                                )
                              ],
                            );
                          },
                          // Child di sini tidak lagi digambar langsung karena sudah ditangani di Stack
                          child: Container(key: ValueKey<int>(_selectedIndex)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SelectionAndDeletePopup extends StatefulWidget {

  const _SelectionAndDeletePopup();

  @override
  State<_SelectionAndDeletePopup> createState() => _SelectionAndDeletePopupState();
}

class _SelectionAndDeletePopupState extends State<_SelectionAndDeletePopup> {
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_selectedIds.isEmpty || _isDeleting) return;

    setState(() {
      _isDeleting = true; // Mulai loading
    });

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    await provider.deleteMultipleTransactions(_selectedIds);

    // Cek jika widget masih ada sebelum menutup
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {

    final transactions = context.watch<TransactionProvider>().transactions;
    final locale = context.watch<TransactionProvider>().currencyLocale;
    final symbol = context.watch<TransactionProvider>().currencySymbol;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StyledCard(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Popup
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select to Delete', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Daftar Transaksi yang bisa dipilih
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      border: Border.all()
                    ),
                    child: transactions.isEmpty
                        ? SizedBox(height: 50,child: const Center(child: Text("No transactions to select.")))
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              final isSelected = _selectedIds.contains(transaction.id);
                              final String formattedBalance = formatCurrency(transaction.amount, locale, symbol);
                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(transaction.id);
                              } else {
                                _selectedIds.remove(transaction.id);
                              }
                            });
                          },
                          title: Text(transaction.category),
                          subtitle: transaction.note.isNotEmpty // <-- CEK APAKAH NOTE TIDAK KOSONG
                            ? Text(transaction.note, maxLines: 1, overflow: TextOverflow.ellipsis) // <-- JIKA YA, TAMPILKAN TEXT
                            : null,
                          secondary: OutlineText(
                            child: Text(
                              formattedBalance,
                              style: TextStyle(
                                color: transaction.type == TransactionType.expense ? customRed : customGreen,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1
                              ),
                            ),
                          ),
                          activeColor: customPink,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tombol Aksi Hapus
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: PrimaryButton(
                    text: 'Delete (${_selectedIds.length}) Selected',
                    onPressed: _selectedIds.isNotEmpty ? _handleDelete : null,
                    color: _selectedIds.isNotEmpty ? customRed : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

