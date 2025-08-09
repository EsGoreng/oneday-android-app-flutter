import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/timer_preset_provider.dart';
import '../../../core/providers/timer_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../widgets/timer_widget.dart';

// Dialog untuk menambah timer (sekarang memanggil TimerPresetProvider)
class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    final presetProvider = context.watch<TimerPresetProvider>();

    return Scaffold( // Gunakan Scaffold untuk FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: presetProvider.timers.isEmpty ? null : () => _showAddTimerDialog(context),
        backgroundColor: presetProvider.timers.isEmpty ? Colors.transparent : customPink, 
        elevation: presetProvider.timers.isEmpty ? 0 : 0, 
        child: presetProvider.timers.isEmpty ? Container() : Icon(Icons.add),
      ),
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
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        TopNavigationBar(
                          title: 'Timer',
                          onEditPressed: presetProvider.timers.isEmpty
                              ? null
                              : () => _showDeleteTimerDialog(context),
                          actionIcon: Icons.delete_outline,
                        ),
                        const SizedBox(height: 16),
                        if (presetProvider.timers.isEmpty)
                          const _TimerEmptyCard()
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: presetProvider.timers.length,
                            itemBuilder: (context, index) {
                              final timer = presetProvider.timers[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: TimerWidget(timer: timer),
                              );
                            },
                          ),
                        const SizedBox(height: 80), // Beri ruang untuk FAB
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
  }
}

class _TimerEmptyCard extends StatelessWidget {
  const _TimerEmptyCard();

  @override
  Widget build(BuildContext context) {
    return StyledCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('No Timer Available'),
          const SizedBox(height: 8),
          PrimaryButton(
            padding: const EdgeInsets.all(18),
            text: 'Add New Timer',
            onPressed: () => _showAddTimerDialog(context),
          )
        ],
      ),
    );
  }
}

void _showAddTimerDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add Timer',
    barrierColor: Colors.black.withValues(alpha: 0.2),
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
    pageBuilder: (context, anim1, anim2) => StatefulBuilder(
      builder: (context, setState) {
        return _AddTimerDialog();
      },
    ),
  );
}

class _AddTimerDialog extends StatefulWidget {
  const _AddTimerDialog();

  @override
  State<_AddTimerDialog> createState() => _AddTimerDialogState();
}

class _AddTimerDialogState extends State<_AddTimerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedDuration = 25;
  bool _isSaving = false;

  Future<void> _submitTimer() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });
      try {
        await context.read<TimerPresetProvider>().addTimer(
          _nameController.text,
          _selectedDuration,
          _descriptionController.text,
        );
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        if (mounted) setState(() { _isSaving = false; });
      }
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... UI Dialog (Title, Name, Description, Duration Picker)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add Timer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Timer Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Enter timer name'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  const Text('Description (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(hintText: 'Enter timer description'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Duration (minutes)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle),
                          onPressed: () => setState(() { if (_selectedDuration > 1) _selectedDuration--; }),
                        ),
                        Text('$_selectedDuration', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () => setState(() => _selectedDuration += 5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: PrimaryButton(
                      text: _isSaving ? 'Saving...' : 'Add Timer',
                      onPressed: _isSaving ? null : _submitTimer,
                      color: customGreen, // customGreen
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dialog untuk menghapus timer (sekarang memanggil TimerPresetProvider)
void _showDeleteTimerDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Delete Timers',
    barrierColor: Colors.black.withValues(alpha: 0.2),
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
    pageBuilder: (context, anim1, anim2) => StatefulBuilder(
      builder: (context, setState) => Scaffold(
        backgroundColor: Colors.transparent,
        body: _DeleteTimerDialog(),
      ),
    ),
  );
}

class _DeleteTimerDialog extends StatefulWidget {
  const _DeleteTimerDialog();

  @override
  State<_DeleteTimerDialog> createState() => _DeleteTimerDialogState();
}

class _DeleteTimerDialogState extends State<_DeleteTimerDialog> {
  final List<String> _selectedTimerIds = [];
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting || _selectedTimerIds.isEmpty) return;
    setState(() { _isDeleting = true; });

    final presetProvider = context.read<TimerPresetProvider>();
    final timerProvider = context.read<TimerProvider>();

    try {
      for (var timerId in _selectedTimerIds) {
        final timerPreset = presetProvider.timers.firstWhere((t) => t.id == timerId);
        if (timerProvider.timerName == timerPreset.name) {
          await timerProvider.stopTimer();
        }
      }
      await presetProvider.deleteMultipleTimers(_selectedTimerIds);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() { _isDeleting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final presetProvider = context.watch<TimerPresetProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: StyledCard(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Timer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(),
                  borderRadius: BorderRadius.all(Radius.circular(8))
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: presetProvider.timers.length,
                  itemBuilder: (context, index) {
                    final timer = presetProvider.timers[index];
                    return CheckboxListTile(
                      title: Text(timer.name),
                      value: _selectedTimerIds.contains(timer.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedTimerIds.add(timer.id);
                          } else {
                            _selectedTimerIds.remove(timer.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: _isDeleting ? 'Deleting...' : 'Delete Selected',
                onPressed: _isDeleting || _selectedTimerIds.isEmpty ? null : _handleDelete,
                padding: EdgeInsets.all(8),
                color: customRed, // customRed
              ),
            ],
          ),
        ),
      ),
    );
  }
}
