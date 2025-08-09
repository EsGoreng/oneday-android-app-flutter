// mood_calendar_widgets.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/models/mood_models.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'mood_widgets.dart';

class MoodCalendarSection extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;

  const MoodCalendarSection({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  // Widget untuk konten sel (tidak berubah)
  Widget _buildCellContent(BuildContext context, DateTime day, Mood? moodOfTheDay) {
    return SizedBox(
      height: 52,
      width: 32,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('${day.day}', style: const TextStyle(fontSize: 14)),
          if (moodOfTheDay != null)
            Image.asset(
              moodOfTheDay.moodCategory.imagePath,
              height: 20,
            )
          else
            Container(height: 20),
        ],
      ),
    );
  }

  // BARU: Fungsi untuk menampilkan dialog tambah/ubah mood
  void _showAddEditMoodDialog(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        // Gunakan MoodTracker di dalam dialog
        child: MoodTracker(selectedDate: date),
      ),
    );
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

    final moodProvider = context.watch<MoodProvider>();
    final selectedMood = selectedDay != null ? moodProvider.getMoodForDay(selectedDay!) : null;

    return StyledCard(
      child: Column(
        children: [
          TableCalendar(
            rowHeight: 60,
            focusedDay: focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: onDaySelected,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              leftChevronPadding: EdgeInsets.zero,
              rightChevronPadding: EdgeInsets.zero,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final moodOfTheDay = moodProvider.getMoodForDay(day);
                final cellColor = moodOfTheDay?.moodCategory.color ?? Colors.white;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  decoration: dayBoxDecoration.copyWith(color: cellColor),
                  child: _buildCellContent(context, day, moodOfTheDay),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final moodOfTheDay = moodProvider.getMoodForDay(day);
                final cellColor = moodOfTheDay?.moodCategory.color ?? const Color(0xfffef3c8);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  decoration: dayBoxDecoration.copyWith(
                    color: cellColor,
                    border: Border.all(color: Colors.orangeAccent, width: 2),
                  ),
                  child: _buildCellContent(context, day, moodOfTheDay),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                final cellColor = const Color(0xFFFFD000);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  decoration: dayBoxDecoration.copyWith(color: cellColor),
                  child: _buildCellContent(context, day, moodProvider.getMoodForDay(day)),
                );
              },
              outsideBuilder: (context, day, focusedDay) {
                final moodOfTheDay = moodProvider.getMoodForDay(day);
                final cellColor = moodOfTheDay?.moodCategory.color ?? Colors.grey[200];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  decoration: dayBoxDecoration.copyWith(color: cellColor),
                  child: Opacity(
                    opacity: 0.6,
                    child: _buildCellContent(context, day, moodOfTheDay),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 24),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
            child: selectedMood != null
                ? _MoodDisplay(
                    key: ValueKey(selectedMood.id),
                    mood: selectedMood,
                    onEdit: () => _showAddEditMoodDialog(context, selectedDay!),
                  )
                : _AddMoodPrompt(
                    key: ValueKey(selectedDay),
                    onAdd: () => _showAddEditMoodDialog(context, selectedDay!),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MoodDisplay extends StatelessWidget {
  final Mood mood;
  final VoidCallback onEdit;

  const _MoodDisplay({super.key, required this.mood, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Your mood on this day:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Image.asset(mood.moodCategory.imagePath, height: 40),
          const SizedBox(height: 8),
          Text(mood.moodCategory.moodName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const Spacer(),
          PrimaryButton(
            text: 'Change Mood',
            onPressed: onEdit,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}

class _AddMoodPrompt extends StatelessWidget {
  final VoidCallback onAdd;

  const _AddMoodPrompt({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No mood recorded for this day.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Add Mood',
            onPressed: onAdd,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ],
      ),
    );
  }
}