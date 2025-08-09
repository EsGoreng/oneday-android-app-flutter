import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/models/mood_models.dart';
import '../../../core/providers/mood_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../widgets/mood_calendar_widgets.dart';

class MoodCalendarPage extends StatefulWidget {
  const MoodCalendarPage({super.key});

  @override
  State<MoodCalendarPage> createState() => _MoodCalendarPageState();
}

class _MoodCalendarPageState extends State<MoodCalendarPage> {
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
      });
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, Mood mood) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Confirmation',
      pageBuilder: (context, anim1, anim2) => _DeleteConfirmationPopup(mood: mood),
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
    // --- PERBAIKAN: Gunakan Consumer untuk memastikan data selalu terbaru ---
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        final selectedMood = _selectedDay != null ? moodProvider.getMoodForDay(_selectedDay!) : null;

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
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          children: [
                            TopNavigationBar(
                              title: 'Mood Calendar',
                              onEditPressed: selectedMood == null
                                  ? null
                                  : () => _showDeleteConfirmationDialog(context, selectedMood),
                              actionIcon: Icons.delete_outline,
                            ),
                            const SizedBox(height: 16),
                            MoodCalendarSection(
                              focusedDay: _focusedDay,
                              selectedDay: _selectedDay,
                              onDaySelected: _onDaySelected,
                            ),
                            const SizedBox(height: 82),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- PERBAIKAN: Ubah menjadi StatefulWidget ---
class _DeleteConfirmationPopup extends StatefulWidget {
  final Mood mood;
  const _DeleteConfirmationPopup({required this.mood});

  @override
  State<_DeleteConfirmationPopup> createState() => _DeleteConfirmationPopupState();
}

class _DeleteConfirmationPopupState extends State<_DeleteConfirmationPopup> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    setState(() { _isDeleting = true; });

    try {
      await context.read<MoodProvider>().deleteMood(widget.mood.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting mood: $e"), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } finally {
      if (mounted) setState(() { _isDeleting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM').format(widget.mood.date);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: StyledCard(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Delete Mood', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete the mood history for "$formattedDate"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: PrimaryButton(
                        text: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: PrimaryButton(
                        text: _isDeleting ? 'Deleting...' : 'Delete',
                        onPressed: _isDeleting ? null : _handleDelete,
                        color: customRed, // customRed
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
