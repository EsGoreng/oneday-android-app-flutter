import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/savingplan_model.dart';
import '../../../core/providers/savingplan_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class SavingplanPopup extends StatefulWidget {
  const SavingplanPopup({super.key});

  @override
  State<SavingplanPopup> createState() => _AddSavingPlannPopupState();
}

class _AddSavingPlannPopupState extends State<SavingplanPopup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _fillingController = TextEditingController();

  SavingRangeType _selectedTimeRange = SavingRangeType.daily;
  String _estimation = '';
  DateTime? _completionDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _targetController.addListener(_updateEstimation);
    _fillingController.addListener(_updateEstimation);
  }

  @override
  void dispose() {
    _targetController.removeListener(_updateEstimation);
    _fillingController.removeListener(_updateEstimation);
    _targetController.dispose();
    _fillingController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  double _parseCurrency(String text) {
    if (text.isEmpty) return 0.0;
    final sanitized = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }

  void _updateEstimation() {
    final double target = _parseCurrency(_targetController.text);
    final double filling = _parseCurrency(_fillingController.text);

    if (target > 0 && filling > 0) {
      final int periods = (target / filling).ceil();
      String estimationText;
      DateTime calculatedDate;
      final now = DateTime.now();

      switch (_selectedTimeRange) {
        case SavingRangeType.daily:
          estimationText = '$periods Days';
          calculatedDate = now.add(Duration(days: periods));
          break;
        case SavingRangeType.weekly:
          estimationText = '$periods Weeks';
          calculatedDate = now.add(Duration(days: periods * 7));
          break;
        case SavingRangeType.monthly:
          estimationText = '$periods Months';
          calculatedDate = now.add(Duration(days: periods * 30));
          break;
      }
      setState(() {
        _estimation = estimationText;
        _completionDate = calculatedDate;
      });
    } else {
      setState(() {
        _estimation = '';
        _completionDate = null;
      });
    }
  }

  Future<void> _submitData() async {
    if (_isSaving) return;
    // --- PERBAIKAN: Gunakan validasi form ---
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      final name = _nameController.text;
      final target = _parseCurrency(_targetController.text);
      final filling = _parseCurrency(_fillingController.text);

      try {
        await context.read<SavingplanProvider>().addSavingPlan(
          name,
          target,
          filling,
          _selectedTimeRange,
        );
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add plan: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final currencySymbol = '${transactionProvider.currencySymbol} ';
    final currencyLocale = transactionProvider.currencyLocale;

    String formatDate(DateTime date, {String? locale}) {
      return DateFormat('d MMMM y', locale ?? currencyLocale).format(date);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,  
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 42,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 42,
                  left: 16,
                  right: 16,
                ),
                child: StyledCard(
                  width: 320,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Add Saving Plan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const Text('Saving Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(hintText: 'Savings Name'),
                          // --- PERBAIKAN: Tambahkan validator ---
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text('Saving Target', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _targetController,
                          decoration: InputDecoration(hintText: 'Savings Target', prefixText: currencySymbol),
                          inputFormatters: [CurrencyInputFormatter()],
                          keyboardType: TextInputType.number,
                          // --- PERBAIKAN: Tambahkan validator ---
                          validator: (value) {
                            if (value == null || _parseCurrency(value) <= 0) {
                              return 'Target must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text('Filling Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _fillingController,
                          decoration: InputDecoration(hintText: 'Filling Nominal', prefixText: currencySymbol),
                          inputFormatters: [CurrencyInputFormatter()],
                          keyboardType: TextInputType.number,
                          // --- PERBAIKAN: Tambahkan validator ---
                          validator: (value) {
                            if (value == null || _parseCurrency(value) <= 0) {
                              return 'Amount must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                  padding: const EdgeInsets.all(8),
                                  text: 'Daily',
                                  onPressed: () => setState(() {
                                        _selectedTimeRange = SavingRangeType.daily;
                                        _updateEstimation();
                                      }),
                                  isSelected: _selectedTimeRange == SavingRangeType.daily,
                                  color: _selectedTimeRange == SavingRangeType.daily ? customGreen : Colors.grey.shade300,
                                  textColor: Colors.black),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PrimaryButton(
                                  padding: const EdgeInsets.all(8),
                                  text: 'Weekly',
                                  onPressed: () => setState(() {
                                        _selectedTimeRange = SavingRangeType.weekly;
                                        _updateEstimation();
                                      }),
                                  isSelected: _selectedTimeRange == SavingRangeType.weekly,
                                  color: _selectedTimeRange == SavingRangeType.weekly ? customGreen : Colors.grey.shade300,
                                  textColor: Colors.black),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PrimaryButton(
                                  padding: const EdgeInsets.all(8),
                                  text: 'Monthly',
                                  onPressed: () => setState(() {
                                        _selectedTimeRange = SavingRangeType.monthly;
                                        _updateEstimation();
                                      }),
                                  isSelected: _selectedTimeRange == SavingRangeType.monthly,
                                  color: _selectedTimeRange == SavingRangeType.monthly ? customGreen : Colors.grey.shade300,
                                  textColor: Colors.black),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estimation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              if (_completionDate != null)
                                Text('Completed on: ${formatDate(_completionDate!, locale: currencyLocale)}')
                              else
                                const Text('Completed on: -'),
                              if (_estimation.isNotEmpty)
                                Text('Duration: $_estimation')
                              else
                                const Text('Duration: -'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: PrimaryButton(
                              text: _isSaving ? 'Saving...' : 'Add to Saving Plan',
                              onPressed: _isSaving ? null : _submitData,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
