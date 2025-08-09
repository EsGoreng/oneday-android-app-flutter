import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/finance_widgets.dart';

class HistorypageCalendar extends StatefulWidget {
  const HistorypageCalendar({super.key});
  static const nameRoute = 'financeCalendarPage';

  @override
  State<HistorypageCalendar> createState() => _HistorypageCalendar();
}


class _HistorypageCalendar extends State<HistorypageCalendar> {

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: 
          FinanceCalendarSection(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  onDaySelected: _onDaySelected,
                ),
        ),
      ],
    );
  }
}
