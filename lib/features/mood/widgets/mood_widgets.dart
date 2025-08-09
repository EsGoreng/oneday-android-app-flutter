import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/mood_models.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../pages/mood_calendar_page.dart';
import '../pages/mood_notes_page.dart';

class MoodMenu extends StatelessWidget {
  const MoodMenu({super.key});

  @override
  Widget build(BuildContext context) {

  void onShowMoodNotes() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const MoodNotesPage()),
      );
  }

  void onShowMoodCalendar() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const MoodCalendarPage()),
      );
  }

    return StyledCard(
      child: Row(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(flex : 1, child: IconButtonHelper2(icon: Icons.note_add_outlined, label: 'Note', ontap: onShowMoodNotes)),
          Expanded(flex : 1, child: IconButtonHelper2(icon: Icons.calendar_month_outlined, label: 'Calendar', ontap: onShowMoodCalendar))
        ],
      ),
    );
  }
}

// --- PERBAIKI: Ubah menjadi StatefulWidget ---
class MoodTracker extends StatefulWidget {
  final DateTime selectedDate;
  final bool popOnSelect;

  const MoodTracker({
    super.key,
    required this.selectedDate,
    this.popOnSelect = true,
  });

  @override
  State<MoodTracker> createState() => _MoodTrackerState();
}

class _MoodTrackerState extends State<MoodTracker> {
  bool _isSaving = false;
  MoodCategory? _savingCategory;

  Future<void> _handleSaveMood(MoodCategory category) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _savingCategory = category; // Tandai mood mana yang sedang disimpan
    });

    try {
      await context.read<MoodProvider>().saveMood(category, widget.selectedDate);
      if (widget.popOnSelect && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving mood: $e"), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savingCategory = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: MoodCategory.values.map((category) {
              final bool isCurrentlySaving = _isSaving && _savingCategory == category;
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isCurrentlySaving
                        ? const SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : IconButton(
                            iconSize: 40,
                            onPressed: _isSaving ? null : () => _handleSaveMood(category),
                            icon: Image.asset(category.imagePath),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      category.moodName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
