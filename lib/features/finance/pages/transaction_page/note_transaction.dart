import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/finance_notes_model.dart';
import '../../../../core/providers/finance_notes_providers..dart';
import '../../../../shared/widgets/common_widgets.dart';
import 'finance_notes_detail_page.dart';
import 'finance_notes_setting_page.dart';
import 'package:provider/provider.dart';

class HistorypageNote extends StatelessWidget {

  
  const HistorypageNote({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer agar widget rebuild saat ada perubahan di provider
    return Consumer<FinanceNotesProviders>(
      builder: (context, noteProvider, child) {
        final notes = noteProvider.notes;

        if (notes.isEmpty) {
          return SingleChildScrollView(
            child: _NotesEmptyCard(),
          );
        }

        return _MainNotes(notes: notes);
      },
    );
  }
}

class _MainNotes extends StatelessWidget {
  const _MainNotes({
    required this.notes,
  });

  final List<Notes> notes;

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
              return _NotesCard(note: note);
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
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotesSettingsPage()),
                );
            },
          )
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {

  final Notes note;

  const _NotesCard({
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => FinanceNoteDetailScreen(note: note))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 20),
          Text(
            note.noteName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            DateFormat.yMMMd().format(note.noteDate),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            note.note,
            style: TextStyle(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

        ],
      ),
    );
  }
}

