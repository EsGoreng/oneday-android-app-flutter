import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Digunakan untuk format angka

class CalculatorPopup extends StatefulWidget {
  const CalculatorPopup({super.key});

  @override
  State<CalculatorPopup> createState() => _CalculatorPopupState();
}

class _CalculatorPopupState extends State<CalculatorPopup> {
  String _displayValue = '0'; // Nilai yang ditampilkan di layar utama
  String _historyValue = ''; // Nilai yang ditampilkan di layar histori (baru)
  String _buffer = '0'; // Angka yang sedang diketik pengguna
  double? _operand1; // Angka pertama dalam operasi
  String? _operator; // Operator yang dipilih (+, -, *, /)
  bool _shouldResetBuffer = false; // Menandakan apakah input berikutnya harus memulai angka baru

  // Fungsi utama untuk menangani semua input tombol
  void _onButtonPressed(String value) {
    setState(() {
      if ("0123456789".contains(value)) {
        _handleNumberInput(value);
      } else if (value == '.') {
        _handleDecimalInput();
      } else if (value == 'C') {
        _resetCalculator();
      } else if (value == 'DEL') {
        _deleteLastDigit();
      } else if (value == '+/-') {
        _negateNumber();
      } else if (value == '%') {
        _calculatePercentage();
      } else if ("+-*/".contains(value)) {
        _handleOperatorInput(value);
      } else if (value == '=') {
        _calculateResult();
      }
    });
  }

  void _handleNumberInput(String number) {
    // Jika perhitungan baru dimulai setelah menekan '=', bersihkan histori.
    if (_shouldResetBuffer && _operator == null) {
      _historyValue = '';
    }

    if (_shouldResetBuffer || _buffer == '0') {
      _buffer = number;
      _shouldResetBuffer = false;
    } else {
      _buffer += number;
    }
    _displayValue = _formatNumberString(_buffer);
  }

  void _handleDecimalInput() {
    if (_shouldResetBuffer) {
      _buffer = '0.';
      _shouldResetBuffer = false;
    } else if (!_buffer.contains('.')) {
      _buffer += '.';
    }
    _displayValue = _buffer;
  }

  void _handleOperatorInput(String op) {
    if (_operand1 != null && _operator != null && !_shouldResetBuffer) {
      _calculateResult();
    }
    
    _operand1 = double.tryParse(_displayValue.replaceAll(',', ''));
    _operator = op;
    // Tampilkan pratinjau operasi di histori
    _historyValue = '${_formatNumber(_operand1!)} $op';
    _shouldResetBuffer = true;
  }

  void _calculateResult() {
    if (_operand1 == null || _operator == null) return;

    final double operand2 = double.parse(_buffer.replaceAll(',', ''));
    // Tampilkan persamaan lengkap di histori
    _historyValue = '${_formatNumber(_operand1!)} $_operator ${_formatNumberString(operand2.toString())} =';
    double result = 0;

    switch (_operator) {
      case '+':
        result = _operand1! + operand2;
        break;
      case '-':
        result = _operand1! - operand2;
        break;
      case '*':
        result = _operand1! * operand2;
        break;
      case '/':
        if (operand2 == 0) {
          _displayValue = "Error";
          _historyValue = '';
          return;
        }
        result = _operand1! / operand2;
        break;
    }
    
    _displayValue = _formatNumber(result);
    _operand1 = result;
    _buffer = result.toString();
    _shouldResetBuffer = true;
    _operator = null; // Menandakan perhitungan selesai, siap untuk yang baru
  }

  void _resetCalculator() {
    _displayValue = '0';
    _historyValue = ''; // Bersihkan histori
    _buffer = '0';
    _operand1 = null;
    _operator = null;
    _shouldResetBuffer = false;
  }

  void _deleteLastDigit() {
    if (_shouldResetBuffer || _buffer.length == 1) {
      _buffer = '0';
    } else {
      _buffer = _buffer.substring(0, _buffer.length - 1);
    }
    _displayValue = _formatNumberString(_buffer);
  }

  void _negateNumber() {
    if (_buffer == '0') return;
    if (_buffer.startsWith('-')) {
      _buffer = _buffer.substring(1);
    } else {
      _buffer = '-$_buffer';
    }
    _displayValue = _formatNumberString(_buffer);
  }

  void _calculatePercentage() {
    final double currentValue = double.parse(_buffer.replaceAll(',', ''));
    final double result = currentValue / 100;
    _displayValue = _formatNumber(result);
    _buffer = result.toString();
  }

  String _formatNumber(double number) {
    if (number.isNaN || number.isInfinite) return "Error";
    if (number == number.truncate()) {
      return NumberFormat("#,###").format(number);
    } else {
      return NumberFormat("#,##0.########").format(number);
    }
  }

  String _formatNumberString(String numberStr) {
    if (numberStr.isEmpty || numberStr == '-') return numberStr;
    final number = double.tryParse(numberStr);
    if (number == null) return numberStr;
    // Hanya format bagian integer, biarkan desimal apa adanya
    if (numberStr.contains('.')) {
        final parts = numberStr.split('.');
        final integerPart = NumberFormat("#,###").format(int.parse(parts[0]));
        return '$integerPart.${parts[1]}';
    }
    return NumberFormat("#,###").format(number);
  }


  // Helper untuk membuat tombol agar tidak mengulang kode
  Widget _buildCalcButton(String text, {Color color = const Color(0xffffd000), Color textColor = Colors.black}) {
    if ("/%*+-=".contains(text)) {
      color = Color(0XFF4CFE78);
      textColor = Colors.black;
    }
    if ("C DEL % +/-".contains(text)) {
      color = const Color(0xFFFF5F5F);
      textColor = Colors.black;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1),
          color: color,
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onButtonPressed(text),
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                text,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Calculator', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Layar histori
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _historyValue,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                  // Layar utama
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _displayValue,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Baris tombol
            Row(children: [
              _buildCalcButton('C'), _buildCalcButton('+/-'), _buildCalcButton('%'), _buildCalcButton('DEL'),
            ]),
            Row(children: [
              _buildCalcButton('7'), _buildCalcButton('8'), _buildCalcButton('9'), _buildCalcButton('/'),
            ]),
            Row(children: [
              _buildCalcButton('4'), _buildCalcButton('5'), _buildCalcButton('6'), _buildCalcButton('*'),
            ]),
            Row(children: [
              _buildCalcButton('1'), _buildCalcButton('2'), _buildCalcButton('3'), _buildCalcButton('-'),
            ]),
            Row(children: [
              _buildCalcButton('0'), _buildCalcButton('.'), _buildCalcButton('+'), _buildCalcButton('='),
            ]),
          ],
        ),
      ),
    );
  }
}
