
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oneday/core/models/mood_notes_model.dart';
import 'package:oneday/features/mood/pages/mood_notes_setting_page.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/mood_notes_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'mood_notes_detail_page.dart';

class MoodNotesPage extends StatelessWidget {
  const MoodNotesPage({super.key});

  static const nameRoute = '/mood-notes-settings';

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    return Consumer<MoodNotesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
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
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            const TopNavigationBar(title: 'Mood Notes'),
                            const SizedBox(height: 12),
                            if (provider.notes.isEmpty)
                              _NotesEmptyCard()
                            else
                              _MainNotes(
                                notes: provider.notes,
                                provider: provider,
                              ),
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
            onPressed: () {
              _showAddEditNoteDialog(context, provider);
            },
            backgroundColor: customPink,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _MainNotes extends StatelessWidget {
  const _MainNotes({
    required this.notes,
    required this.provider,
  });

  final List<MoodNote> notes;
  final MoodNotesProvider provider;

  @override
  Widget build(BuildContext context) {
    return StyledCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              IconButton(
                onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotesSettingsPage()),
                  );
                },
                icon: const Icon(Icons.settings),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(customPink),
                  iconColor: WidgetStateProperty.all(Colors.black),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      side: BorderSide(width: 1),
                      borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
                    )
                  ),
                ),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              // Menggunakan _NotesCard yang sudah dimodifikasi
              return _NotesCard(
                note: note,
                provider: provider,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NotesEmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoodNotesProvider>(context, listen: false);
    return StyledCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('No Notes Available'),
          SizedBox(height: 8),
          PrimaryButton(
            padding: EdgeInsets.all(18),
            text: 'Add Notes',
            onPressed: () {
              _showAddEditNoteDialog(context, provider);
            },
          )
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final MoodNote note;
  final MoodNotesProvider provider;

  const _NotesCard({
    required this.note,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => MoodNoteDetailScreen(note: note))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.noteName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.yMMMd().format(note.noteDate),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                note.note,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showAddEditNoteDialog(BuildContext context, MoodNotesProvider provider, {MoodNote? existingNote}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add/Edit Note',
    barrierColor: Colors.black.withValues(alpha: 0.2),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) {
      return _AddEditNotePopup(
        provider: provider,
        existingNote: existingNote,
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      );
    },
  );
}

class _AddEditNotePopup extends StatefulWidget {
  final MoodNotesProvider provider;
  final MoodNote? existingNote;

  const _AddEditNotePopup({
    required this.provider,
    this.existingNote,
  });

  @override
  State<_AddEditNotePopup> createState() => _AddEditNotePopupState();
}

class _AddEditNotePopupState extends State<_AddEditNotePopup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.noteName ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.note ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final content = _contentController.text;

      if (widget.existingNote == null) {
        widget.provider.addNote(title, content);
      } else {
        widget.provider.updateNote(widget.existingNote!.id, title, content);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StyledCard(
            width: 320,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.existingNote == null ? 'Add Note' : 'Edit Note',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter note title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Content', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: 'Write your note here...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 5,
                    validator: (value) => value == null || value.isEmpty ? 'Content is required' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: PrimaryButton(
                      text: 'Save Note',
                      onPressed: _submitForm,
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