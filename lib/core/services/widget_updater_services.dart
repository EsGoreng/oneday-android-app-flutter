import 'package:home_widget/home_widget.dart';
import 'package:oneday/core/providers/transaction_provider.dart';

// Fungsi ini membutuhkan instance dari TransactionProvider
Future<void> updateBalanceWidget(TransactionProvider provider) async {
  try {
    // Gunakan getter yang sudah kita buat
    final balance = provider.currentBalance;
    final income = provider.totalIncome;
    final expenses = provider.totalExpenses;

    // Format nilai menjadi string mata uang
    final balanceStr = provider.formatCurrency(balance, provider.currencyLocale, provider.currencySymbol);
    final incomeStr = provider.formatCurrency(income, provider.currencyLocale, provider.currencySymbol);
    final expensesStr = provider.formatCurrency(expenses, provider.currencyLocale, provider.currencySymbol);

    // Simpan data untuk diakses oleh widget native
    await HomeWidget.saveWidgetData<String>('balance', balanceStr);
    await HomeWidget.saveWidgetData<String>('income', incomeStr);
    await HomeWidget.saveWidgetData<String>('expenses', expensesStr);

    // Memicu update pada widget
    await HomeWidget.updateWidget(
      name: 'BalanceWidgetProvider',
      androidName: 'BalanceWidgetProvider',
    );

  } catch (e) {
    print('Error updating balance widget: $e');
  }
}