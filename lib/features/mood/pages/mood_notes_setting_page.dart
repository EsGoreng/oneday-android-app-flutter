import 'dart:math';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/mood_notes_model.dart';
import '../../../core/providers/mood_notes_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class NotesSettingsPage extends StatelessWidget {
  const NotesSettingsPage({super.key});
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
                            _NotesList(provider: provider),
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

class _NotesList extends StatelessWidget {
  final MoodNotesProvider provider;
  const _NotesList({required this.provider,});

  @override
  Widget build(BuildContext context) {
    if (provider.notes.isEmpty) {
      return StyledCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No notes yet. Tap + to add one!'),
        ),
      );
    }

    return StyledCard(
      padding: const EdgeInsets.all(0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.notes.length,
        itemBuilder: (context, index) {
          final note = provider.notes[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.note_alt_outlined, size: 30),
            title: Text(note.noteName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              note.note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                    customYellow
                      ),
                    side: WidgetStateProperty.all(
                      BorderSide(color: Colors.black)
                      ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.all(Radius.circular(8))
                      )
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () => _showAddEditNoteDialog(context, existingNote: note),
                ),
                SizedBox(width: 4,),
                IconButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                    customRed
                      ),
                    side: WidgetStateProperty.all(
                      BorderSide(color: Colors.black)
                      ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.all(Radius.circular(8))
                      )
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_outlined, color: Colors.white),
                  onPressed: () => _showDeleteConfirmationDialog(context, note),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _showAddEditNoteDialog(BuildContext context, {MoodNote? existingNote}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add/Edit Note',
    barrierColor: Colors.black.withValues(alpha: 0.2),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) => _AddEditNotePopup(existingNote: existingNote),
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

// Fungsi untuk menampilkan dialog konfirmasi hapus catatan
void _showDeleteConfirmationDialog(BuildContext context, MoodNote note) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Delete Confirmation',
    barrierColor: Colors.black.withValues(alpha: 0.2),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) => _DeleteConfirmationPopup(note: note),
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

// Widget untuk popup tambah/edit catatan
class _AddEditNotePopup extends StatefulWidget {
  final MoodNote? existingNote;
  const _AddEditNotePopup({this.existingNote});

  @override
  State<_AddEditNotePopup> createState() => _AddEditNotePopupState();
}

class _AddEditNotePopupState extends State<_AddEditNotePopup> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;

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

  Future<void> _submitForm() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      final title = _titleController.text;
      final content = _contentController.text;
      final provider = context.read<MoodNotesProvider>();

      try {
        if (widget.existingNote == null) {
          await provider.addNote(title, content);
        } else {
          await provider.updateNote(widget.existingNote!.id, title, content);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save note: $e"), backgroundColor: const Color(0xFFC62828)),
          );
        }
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
                    validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
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
                    validator: (value) => value == null || value.trim().isEmpty ? 'Content is required' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: PrimaryButton(
                      text: _isSaving ? 'Saving...' : 'Save Note',
                      onPressed: _isSaving ? null : _submitForm,
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

// Widget untuk popup konfirmasi hapus catatan
class _DeleteConfirmationPopup extends StatefulWidget {
  final MoodNote note;
  const _DeleteConfirmationPopup({required this.note});

  @override
  State<_DeleteConfirmationPopup> createState() => _DeleteConfirmationPopupState();
}

class _DeleteConfirmationPopupState extends State<_DeleteConfirmationPopup> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    setState(() { _isDeleting = true; });

    try {
      await context.read<MoodNotesProvider>().deleteNote(widget.note.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete note: $e"), backgroundColor: const Color(0xFFC62828)),
        );
      }
    } finally {
      if (mounted) setState(() { _isDeleting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: StyledCard(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Delete Note', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete "${widget.note.noteName}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black)),
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
