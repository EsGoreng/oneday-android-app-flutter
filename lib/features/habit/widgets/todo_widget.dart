import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/task_model.dart';
import '../../../core/providers/task_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../pages/task_detail_page.dart';

// Fungsi helper tidak berubah
void showAddTaskDialog(BuildContext context, DateTime selectedDate, {Task? existingTask}) { // Tambah parameter optional
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add/Edit Task', // Ubah label
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) => AddTaskDialog(selectedDate: selectedDate, existingTask: existingTask), // Kirim task
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

void showDeleteTaskDialog(BuildContext context, Task task) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Delete Task',
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) => DeleteTaskDialog(task: task),
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

class DeleteTaskDialog extends StatefulWidget {
  final Task task;
  const DeleteTaskDialog({super.key, required this.task});

  @override
  State<DeleteTaskDialog> createState() => _DeleteTaskDialogState();
}

class _DeleteTaskDialogState extends State<DeleteTaskDialog> {
  bool _isDeleting = false;

  Future<void> _delete(AsyncCallback onDelete) async {
    if (_isDeleting) return;
    setState(() { _isDeleting = true; });

    try {
      await onDelete();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: const Color(0xFFC62828)));
        setState(() { _isDeleting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final bool isRecurring = widget.task.recurringGroupId != null;
    final double maxWidth = 300;


    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: StyledCard(
            width: maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Delete Task?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Are you sure you want to delete "${widget.task.title}"?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: Colors.grey.shade300,
                        text: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: customRed, // customRed
                        text: _isDeleting ? 'Deleting...' : 'Delete',
                        onPressed: _isDeleting ? null : () {
                          if (isRecurring) {
                            _delete(() => taskProvider.deleteTaskSeries(widget.task.recurringGroupId!));
                          } else {
                            _delete(() => taskProvider.deleteTask(widget.task.id));
                          }
                        },
                      ),
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

class AddTaskDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Task? existingTask; // Tambah properti ini

  const AddTaskDialog({super.key, required this.selectedDate, this.existingTask}); // Tambah di constructor

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}
class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _timeController = TextEditingController();
  late Task? _oldTask;
  
  late DateTime _startDate;
  DateTime? _endDate;
  late TimeOfDay _selectedTime;
  TaskPriority _selectedPriority = TaskPriority.low;
  bool _isRecurring = false;
  bool _addDescription = false;
  bool _isSaving = false;
  final Set<int> _selectedWeekdays = {};
  
  bool _isInit = true;

  @override
  void initState() {
    super.initState();

    final bool isEditMode = widget.existingTask != null;

    if (isEditMode) {
      // Jika mode edit, isi semua field dengan data dari task yang ada
      final task = widget.existingTask!;
      _oldTask = task; // Simpan state lama
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _startDate = task.date;
      _selectedTime = TimeOfDay.fromDateTime(task.date);
      _selectedPriority = task.priority;
      _addDescription = task.description.isNotEmpty;
      _isRecurring = task.recurringGroupId != null;
      if (task.reminderOffsets != null) {
        _selectedReminders = task.reminderOffsets!.map((m) => Duration(minutes: m)).toList();
      }
    } else {
      // Mode tambah, biarkan kosong
      _oldTask = null;
      _startDate = widget.selectedDate;
      _selectedTime = TimeOfDay.now();
    }

    _startDateController.text = DateFormat('dd MMMM yyyy').format(_startDate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // Pindahkan inisialisasi timeController ke sini
      _timeController.text = _selectedTime.format(context);
      _isInit = false; // Set flag agar tidak dijalankan lagi
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _timeController.text = _selectedTime.format(context);
      });
    }
  }

  void _selectDate(bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(DateTime.now().year - 5), 
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          _startDateController.text = DateFormat('dd MMMM yyyy').format(_startDate);
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = _startDate;
            _endDateController.text = DateFormat('dd MMMM yyyy').format(_endDate!);
          }
        } else {
          _endDate = pickedDate;
          _endDateController.text = DateFormat('dd MMMM yyyy').format(_endDate!);
        }
      });
    }
  }

  List<Duration> _selectedReminders = [const Duration(minutes: 30)];

  final List<Duration> _reminderOptions = const [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
  ];

  Future<void> _submitTask() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      if (_isRecurring && (_endDate == null || _selectedWeekdays.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: customRed, content: Text('Please select an end date and at least one day.')),
        );
        return;
      }

      if (_selectedReminders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: customRed, content: Text('Please select at least one reminder.')),
        );
        return;
      } 
      
      setState(() { _isSaving = true; });
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      // Gabungkan tanggal dan waktu yang dipilih
      final taskDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      try {
        if (widget.existingTask != null) {
          // --- LOGIKA EDIT ---
          final updatedTask = Task(
            id: widget.existingTask!.id,
            title: _titleController.text,
            description: _descriptionController.text,
            date: taskDateTime,
            priority: _selectedPriority,
            status: widget.existingTask!.status, // Status tidak diubah di sini
            recurringGroupId: widget.existingTask!.recurringGroupId, // Recurring tidak bisa diubah
            reminderOffsets: _selectedReminders.map((d) => d.inMinutes).toList(),
          );
          await taskProvider.updateTask(updatedTask, _oldTask!);
        } else {
        if (_isRecurring) {
          await taskProvider.addRecurringTasks(
            title: _titleController.text,
            description: _descriptionController.text,
            startDate: taskDateTime, // Gunakan DateTime yang sudah digabung
            endDate: _endDate!,
            priority: _selectedPriority,
            daysOfWeek: _selectedWeekdays,
            reminderOffsets: _selectedReminders,
          );
        } else {
          await taskProvider.addTask(
            _titleController.text,
            _descriptionController.text,
            taskDateTime, // Gunakan DateTime yang sudah digabung
            _selectedPriority,
            _selectedReminders,
          );
        }
      }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: customRed));
      } finally {
        if (mounted) setState(() { _isSaving = false; });
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes before';
    } else {
      return '${duration.inHours} hours before';
    }
  }

  void _showReminderSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Gunakan StatefulBuilder agar state di dalam dialog bisa diupdate
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Reminders'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _reminderOptions.map((duration) {
                    final isSelected = _selectedReminders.contains(duration);
                    return CheckboxListTile(
                      title: Text(_formatDuration(duration)),
                      value: isSelected,
                      onChanged: (bool? selected) {
                        setDialogState(() {
                          if (selected == true) {
                            _selectedReminders.add(duration);
                          } else {
                            _selectedReminders.remove(duration);
                          }
                        });
                        // Update state utama juga
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedRemindersDisplay() {
    if (_selectedReminders.isEmpty) {
      return const Text('No reminder selected', style: TextStyle(color: Colors.grey));
    }
    // Urutkan durasi dari yang terkecil
    _selectedReminders.sort((a, b) => a.compareTo(b));
    return Text(
      '${_selectedReminders.length.toString()} Reminder Selected',

    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.existingTask != null;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 42),
            child: StyledCard(
              width: 320,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 500),
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.topCenter,
                curve: Curves.easeInOut,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isEditMode ? 'Edit Task' : 'Add a New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close))
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Title', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(hintText: 'e.g., Read a book'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
                      ),
                      SwitchListTile(
                        title: const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        value: _addDescription, 
                        onChanged: (bool value) => setState(() => _addDescription = value),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_addDescription) ...{
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(hintText: 'Add Description'),
                        ),
                        const SizedBox(height: 16),
                      },
                      const Text('Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _selectDate(true),
                        child: AbsorbPointer(child: TextFormField(controller: _startDateController, decoration: const InputDecoration(hintText: 'Select a start date...'))),
                      ),
                      const SizedBox(height: 16),
                      const Text('Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _selectTime,
                        child: AbsorbPointer(child: TextFormField(controller: _timeController, decoration: const InputDecoration(hintText: 'Select a time...'))),
                      ),
                      const SizedBox(height: 16),
                      const Text('Reminder', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _showReminderSelectionDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.black),
                          ),
                          child: _buildSelectedRemindersDisplay(),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Recurring Task', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        value: _isRecurring,
                        onChanged: (bool value) {
                          setState(() {
                            _isRecurring = value;
                            if (_isRecurring && _endDate == null) {
                              _endDate = _startDate.add(const Duration(days: 7));
                              _endDateController.text = DateFormat('dd MMMM yyyy').format(_endDate!);
                            }
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_isRecurring) ...[
                        const Text('End Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _selectDate(false),
                          child: AbsorbPointer(child: TextFormField(controller: _endDateController, decoration: const InputDecoration(hintText: 'Select an end date...'))),
                        ),
                        const SizedBox(height: 16),
                        const Text('Repeat On', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        _buildWeekdaysSelector(),
                      ],
                      const Text('Priority', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TaskPriority>(
                            value: _selectedPriority,
                            isExpanded: true,
                            items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                            onChanged: (value) => setState(() => _selectedPriority = value!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        onPressed: _isSaving ? null : _submitTask,
                        padding: const EdgeInsets.all(12),
                        color: customGreen, // customGreen
                        text: _isSaving ? 'Saving...' : (isEditMode ? 'Save Changes' : 'Add Task'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildWeekdaysSelector() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final dayIndex = index + 1;
          final isSelected = _selectedWeekdays.contains(dayIndex);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(weekdays[index]),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedWeekdays.add(dayIndex);
                  } else {
                    _selectedWeekdays.remove(dayIndex);
                  }
                });
              },
            ),
          );
        }),
      ),
    );
  }
}

class TaskEmpty extends StatelessWidget {
  const TaskEmpty({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('No Task Available'),
        const SizedBox(height: 8),
        PrimaryButton(padding: const EdgeInsets.all(18), text: 'Add a Task', onPressed: onPressed),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: tasks.length,
          itemBuilder: (context, index) => _TaskList(task: tasks[index]),
          separatorBuilder: (context, index) => const Divider(height: 8),
        )
      ],
    );
  }
}

class _TaskList extends StatelessWidget {
  final Task task;
  const _TaskList({required this.task});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () => showDeleteTaskDialog(context, task),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _TaskItemHeader(title: task.title, date: task.date, isCompleted: task.status),
          const SizedBox(height: 4),
          _TaskItemBody(task: task),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TaskItemHeader extends StatelessWidget {
  final String title;
  final DateTime date;
  final bool isCompleted;

  const _TaskItemHeader({required this.title, required this.date, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(DateFormat('yyyy-MM-dd HH:mm').format(date), style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// --- PERBAIKI _TaskItemBody MENJADI STATEFUL WIDGET ---
class _TaskItemBody extends StatefulWidget {
  final Task task;
  const _TaskItemBody({required this.task});

  @override
  State<_TaskItemBody> createState() => _TaskItemBodyState();
}

class _TaskItemBodyState extends State<_TaskItemBody> {
  bool _isToggling = false;

  Future<void> _toggleStatus() async {
    if (_isToggling) return;
    setState(() { _isToggling = true; });

    try {
      await context.read<TaskProvider>().toggleTaskStatus(widget.task.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: const Color(0xFFC62828)));
      }
    } finally {
      if (mounted) {
        setState(() { _isToggling = false; });
      }
    }
  }
  
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return Colors.red.shade100;
      case TaskPriority.medium: return Colors.orange.shade100;
      case TaskPriority.low: return Colors.green.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.task.description.isNotEmpty)
                Text(
                  widget.task.description,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _getPriorityColor(widget.task.priority),
                      border: Border.all(),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(widget.task.priority.name),
                  ),
                  const SizedBox(width: 8),
                  if (widget.task.recurringGroupId != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        border: Border.all(),
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: const Text('Recurring Task'),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade100,
                        border: Border.all(),
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: const Text('Single Task'),
                    )
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: widget.task.status,
            onChanged: _isToggling ? null : (bool? value) => _toggleStatus(),
          ),
        ),
      ],
    );
  }
}
