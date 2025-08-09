import 'package:flutter/material.dart';
import 'package:oneday/features/habit/widgets/todo_widget.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/models/task_model.dart';
import '../../../core/providers/task_provider.dart';
import '../../../shared/widgets/common_widgets.dart';


class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // --- PERBAIKAN: Pindahkan logika ini ke dalam builder ---
  // Fungsi ini sekarang menerima provider sebagai argumen, bukan menggunakan context.read
  Color? _getCellColorForDay(DateTime day, TaskProvider taskProvider) {
    final tasksForDay = taskProvider.getTasksForDay(day);

    if (tasksForDay.isEmpty) {
      return null;
    }

    final totalTasks = tasksForDay.length;
    final completedTasks = tasksForDay.where((task) => task.status).length;

    if (completedTasks == 0) {
      return Colors.red.shade100;
    }
    if (completedTasks == totalTasks) {
      return Colors.green.shade200;
    }
    return Colors.yellow.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final dayBoxDecoration = BoxDecoration(
      shape: BoxShape.rectangle,
      border: Border.all(color: Colors.black, width: 1),
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
      ],
    );

    // --- PERBAIKAN UTAMA: Gunakan Consumer di level tertinggi ---
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Semua widget yang bergantung pada data task sekarang ada di dalam builder ini
        return StyledCard(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 500),
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('To-Do', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
                    IconButton(onPressed: () => showAddTaskDialog(context, _selectedDay!), icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor)),
                  ],
                ),
                const Divider(height: 8),
                TableCalendar(
                  rowHeight: 40,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    leftChevronPadding: EdgeInsets.zero,
                    rightChevronPadding: EdgeInsets.zero,
                  ),
                  calendarStyle: CalendarStyle(
                    cellMargin: const EdgeInsets.all(4),
                    selectedDecoration: dayBoxDecoration.copyWith(color: const Color(0xFFFFD000)),
                    todayDecoration: dayBoxDecoration.copyWith(color: const Color(0xfffef3c8)),
                    defaultDecoration: dayBoxDecoration.copyWith(color: Colors.white),
                    weekendDecoration: dayBoxDecoration.copyWith(color: const Color(0xFFFF5F5F)),
                    outsideDecoration: dayBoxDecoration.copyWith(color: Colors.grey[300]),
                    selectedTextStyle: const TextStyle(color: Colors.black),
                    todayTextStyle: const TextStyle(color: Colors.black),
                    weekendTextStyle: const TextStyle(color: Colors.black),
                    outsideTextStyle: TextStyle(color: Colors.grey[600]!),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  // --- PERBAIKAN: Gunakan instance provider dari builder ---
                  eventLoader: (day) {
                    return taskProvider.getTasksForDay(day);
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {  
                        final hasRecurringTask = events.any((event) => (event as Task).recurringGroupId != null);
                        final hasRegularTask = events.any((event) => (event as Task).recurringGroupId == null);

                        Color markerColor;
                        if (hasRecurringTask && hasRegularTask) {
                          markerColor = Colors.orange;
                        } else if (hasRecurringTask) {
                          markerColor = Colors.deepPurple;
                        } else {
                          markerColor = Colors.blue;
                        }
                        
                        return Positioned(
                          right: 1,
                          bottom: 1,
                          child: _buildEventsMarker(date, events, markerColor),
                        );
                      }
                      return null;
                    },
                    // --- PERBAIKAN: Kirim instance provider ke fungsi builder ---
                    defaultBuilder: (context, day, focusedDay) {
                      final color = _getCellColorForDay(day, taskProvider);
                      if (color != null) {
                        return Container(
                          margin: const EdgeInsets.all(4.0),
                          decoration: dayBoxDecoration.copyWith(color: color),
                          child: Center(child: Text(day.day.toString(), style: const TextStyle(color: Colors.black))),
                        );
                      }
                      return null;
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final color = _getCellColorForDay(day, taskProvider);
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: dayBoxDecoration.copyWith(
                          color: color ?? const Color(0xfffef3c8),
                        ),
                        child: Center(child: Text(day.day.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                      );
                    },
                    // Di `holidayBuilder`, kita asumsikan ini adalah untuk akhir pekan
                    // dan tetap menggunakan nama `holidayBuilder` sesuai API `table_calendar`
                    holidayBuilder: (context, day, focusedDay) {
                      final color = _getCellColorForDay(day, taskProvider);
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: dayBoxDecoration.copyWith(
                          color: color ?? const Color(0xFFFF5F5F),
                        ),
                        child: Center(child: Text(day.day.toString(), style: const TextStyle(color: Colors.black))),
                      );
                    }
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 12),
                // Bagian ini sudah menggunakan Consumer, jadi tidak perlu diubah
                // Namun, karena sekarang seluruh widget sudah di dalam Consumer,
                // kita bisa langsung mengakses provider tanpa membungkusnya lagi.
                Builder(builder: (context) {
                    final selectedTasks = taskProvider.getTasksForDay(_selectedDay!);
          
                    if (selectedTasks.isEmpty) {
                      return TaskEmpty(onPressed: () => showAddTaskDialog(context, _selectedDay!));
                    } else {
                      return TaskCard(tasks: selectedTasks);
                    }
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsMarker(DateTime date, List events, Color color) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,   
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}
