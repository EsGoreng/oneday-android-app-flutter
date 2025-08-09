import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/savingplan_model.dart';
import '../../../core/providers/savingplan_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class SavingPlanDetailPage extends StatelessWidget {
  final Savingplan plan;
  const SavingPlanDetailPage({super.key, required this.plan});

  void _showAddFillingDialog(BuildContext context, String symbol) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Filling',
      pageBuilder: (context, anim1, anim2) => _AddFillingDialog(planId: plan.id, symbol: symbol),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Plan',
      pageBuilder: (context, anim1, anim2) => _DeletePlanDialog(plan: plan),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  void _showTransactionOptionsDialog(BuildContext context, Savingplan currentPlan, SavingTransaction tx, String symbol) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Transaction Options',
      pageBuilder: (context, anim1, anim2) => _TransactionOptionsDialog(
        plan: currentPlan,
        transaction: tx,
        symbol: symbol,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    return Consumer2<SavingplanProvider, TransactionProvider>(
      builder: (context, savingProvider, transactionProvider, child) {
        final currentPlan = savingProvider.savingplans.firstWhere((p) => p.id == plan.id, orElse: () => plan);
        
        final double collected = currentPlan.transactions.fold(0.0, (sum, item) => sum + item.amount);
        final double remaining = currentPlan.target - collected;
        final double progressValue = (currentPlan.target > 0) ? (collected / currentPlan.target).clamp(0.0, 1.0) : 0.0;
        
        final locale = transactionProvider.currencyLocale;
        final symbol = transactionProvider.currencySymbol;

        final int periodsToComplete = remaining > 0 && currentPlan.filling > 0 ? (remaining / currentPlan.filling).ceil() : 0;
        DateTime estimatedCompletionDate = DateTime.now();
        if (periodsToComplete > 0) {
          switch (currentPlan.rangeType) {
            case SavingRangeType.daily:
              estimatedCompletionDate = DateTime.now().add(Duration(days: periodsToComplete));
              break;
            case SavingRangeType.weekly:
              estimatedCompletionDate = DateTime.now().add(Duration(days: periodsToComplete * 7));
              break;
            case SavingRangeType.monthly:
              estimatedCompletionDate = DateTime.now().add(Duration(days: periodsToComplete * 30));
              break;
          }
        }

        return Scaffold(
          backgroundColor: customCream, // customCream
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
                        clipBehavior: Clip.none,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TopNavigationBar(
                              title: currentPlan.name, 
                              onEditPressed: () => _showDeleteConfirmationDialog(context),
                              actionIcon: Icons.delete_outline,
                            ),
                            const SizedBox(height: 12),
                            StyledCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(8)),
                                    child: LinearProgressIndicator(
                                      value: progressValue,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(8),
                                      backgroundColor: Colors.grey[300],
                                      color: customGreen, // customGreen
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(flex: 1, child: _InfoText(label: 'Saved', value: formatCurrency(collected, locale, symbol))),
                                      Expanded(flex: 1, child: _InfoText(label: 'Remaining', value: formatCurrency(remaining > 0 ? remaining : 0, locale, symbol), align: CrossAxisAlignment.end)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            StyledCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Plan Detail', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  _DetailRow(label: 'Target', value: formatCurrency(currentPlan.target, locale, symbol)),
                                  _DetailRow(label: 'Saving Plan', value: '${formatCurrency(currentPlan.filling, locale, symbol)} / ${currentPlan.rangeType.name}'),
                                  (remaining > 0)
                                    ? _DetailRow(
                                        label: 'Complete Estimation',
                                        value: DateFormat('d MMMM y', locale).format(estimatedCompletionDate),
                                      )
                                    : const _DetailRow(
                                        label: 'Status',
                                        value: 'Completed',
                                      ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            StyledCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  if (currentPlan.transactions.isEmpty)
                                    const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No saving history yet.')))
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: currentPlan.transactions.length,
                                      itemBuilder: (ctx, index) {
                                        final tx = currentPlan.transactions[index];
                                        return ListTile(
                                          onTap:() => _showTransactionOptionsDialog(context, currentPlan, tx, symbol),
                                          leading: Icon(tx.amount > 0 ? Icons.arrow_upward : Icons.arrow_downward, color: tx.amount > 0 ? Colors.green : Colors.red),
                                          title: Text(formatCurrency(tx.amount.abs(), locale, symbol)),
                                          subtitle: Text(DateFormat('d MMM y, HH:mm').format(tx.date)),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 84)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddFillingDialog(context, symbol),
            backgroundColor: customPink, // customPink
            child: const Icon(Icons.edit),
          ),
        );
      },
    );
  }
}

class _AddFillingDialog extends StatefulWidget {
  final String planId;
  final String symbol;
  const _AddFillingDialog({required this.planId, required this.symbol});

  @override
  State<_AddFillingDialog> createState() => _AddFillingDialogState();
}

class _AddFillingDialogState extends State<_AddFillingDialog> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  Future<void> _addAmount(double amount) async {
    if (_isSaving) return;
    final cleanAmount = double.tryParse(_controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (cleanAmount <= 0) return;

    setState(() { _isSaving = true; });

    try {
      await context.read<SavingplanProvider>().addFilling(widget.planId, amount * cleanAmount);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          child: StyledCard(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Update Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                  ],
                ),
                CustomTextField(
                  prefix: '${widget.symbol} ',
                  controller: _controller,
                  hintText: 'Amount',
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PrimaryButton(
                      color: customRed, // customRed
                      text: _isSaving ? 'Loading...' : 'Decrease',
                      padding: const EdgeInsets.all(8),
                      onPressed: _isSaving ? null : () => _addAmount(-1),
                    ),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      padding: const EdgeInsets.all(8),
                      color: customGreen, // customGreen
                      text: _isSaving ? 'Loading...' : 'Increase',
                      onPressed: _isSaving ? null : () => _addAmount(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeletePlanDialog extends StatefulWidget {
  final Savingplan plan;
  const _DeletePlanDialog({required this.plan});

  @override
  State<_DeletePlanDialog> createState() => _DeletePlanDialogState();
}

class _DeletePlanDialogState extends State<_DeletePlanDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    setState(() { _isDeleting = true; });
    
    try {
      await context.read<SavingplanProvider>().deleteSavingPlan(widget.plan.id);
      if (mounted) {
        Navigator.of(context).pop(); // Tutup dialog
        Navigator.of(context).pop(); // Kembali ke halaman finance
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      if (mounted) setState(() { _isDeleting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: StyledCard(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delete Plan?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Are you sure you want to delete this Saving Plan? This action cannot be undone.'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    text: _isDeleting ? 'Deleting...' : 'Delete',
                    onPressed: _isDeleting ? null : _handleDelete,
                    padding: EdgeInsets.all(8),
                    color: customRed,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionOptionsDialog extends StatelessWidget {
  final Savingplan plan;
  final SavingTransaction transaction;
  final String symbol;

  const _TransactionOptionsDialog({required this.plan, required this.transaction, required this.symbol});

  void _showEditDialog(BuildContext context) {
     showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Transaction',
      pageBuilder: (context, anim1, anim2) => _EditTransactionDialog(plan: plan, transaction: transaction, symbol: symbol),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
     );
  }

  void _showDeleteDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Transaction',
      pageBuilder: (context, anim1, anim2) => _DeleteTransactionDialog(planId: plan.id, transactionId: transaction.id),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: StyledCard(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('History Detail', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    transaction.amount > 0 ? '+ ' : '- ',
                    style: TextStyle(color: transaction.amount > 0 ? const Color(0xFF4CAF50) : const Color(0xFFC62828)),
                  ),
                  Text(
                    formatCurrency(transaction.amount.abs(), context.read<TransactionProvider>().currencyLocale, symbol),
                    style: TextStyle(fontSize: 24, color: transaction.amount > 0 ? const Color(0xFF4CAF50) : const Color(0xFFC62828), letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(DateFormat('d MMM y, HH:mm').format(transaction.date)),
              const SizedBox(height: 12),
              Row(
                children: [
                  PrimaryButton(text: 'Delete', onPressed: () {Navigator.of(context).pop(); _showDeleteDialog(context);}, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18), color: customRed),
                  const SizedBox(width: 8),
                  PrimaryButton(text: 'Edit', onPressed: () {Navigator.of(context).pop(); _showEditDialog(context);}, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18), color: customGreen),       
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _EditTransactionDialog extends StatefulWidget {
  final Savingplan plan;
  final SavingTransaction transaction;
  final String symbol;

  const _EditTransactionDialog({required this.plan, required this.transaction, required this.symbol});

  @override
  State<_EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<_EditTransactionDialog> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.transaction.amount.abs().toStringAsFixed(0));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final rawValue = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final newAmount = double.tryParse(rawValue) ?? 0;
    if (newAmount <= 0) return;

    setState(() { _isSaving = true; });

    try {
      final finalAmount = widget.transaction.amount.isNegative ? -newAmount : newAmount;
      await context.read<SavingplanProvider>().editSavingTransaction(widget.plan.id, widget.transaction.id, finalAmount);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: StyledCard(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              CustomTextField(
                prefix: '${widget.symbol} ',
                controller: _controller,
                hintText: 'Amount',
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: PrimaryButton(
                  text: _isSaving ? 'Saving...' : 'Save Changes',
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteTransactionDialog extends StatefulWidget {
  final String planId;
  final String transactionId;
  const _DeleteTransactionDialog({required this.planId, required this.transactionId});

  @override
  State<_DeleteTransactionDialog> createState() => _DeleteTransactionDialogState();
}

class _DeleteTransactionDialogState extends State<_DeleteTransactionDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    setState(() { _isDeleting = true; });

    try {
      await context.read<SavingplanProvider>().deleteSavingTransaction(widget.planId, widget.transactionId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() { _isDeleting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: StyledCard(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delete Entry?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Are you sure you want to delete this history entry?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    text: _isDeleting ? 'Deleting...' : 'Delete',
                    onPressed: _isDeleting ? null : _handleDelete,
                    color: customRed,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Widget helper
class _InfoText extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment? align;

  const _InfoText({required this.label, required this.value, this.align});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align ?? CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1, color: Color(0xFF4CAF50))),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.black))),
          const Text(': ', style: TextStyle(color: Colors.black)),
          Expanded(flex: 3, child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1, color: Colors.black, overflow: TextOverflow.ellipsis))),
        ],
      ),
    );
  }
}