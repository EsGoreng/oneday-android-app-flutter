import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oneday/core/models/habit_notes_model.dart';

import '../../../shared/widgets/common_widgets.dart';

class HabitNoteDetailScreen extends StatelessWidget {

  final HabitNote note;

  const HabitNoteDetailScreen({
    super.key,
    required this.note,
    });


  @override
  Widget build(BuildContext context) {

    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);

    String formattedDate = DateFormat('yyyy-MM-dd').format(note.noteDate);

    return Scaffold(
      backgroundColor: customCream,
      body: Stack(
        children: [
          const GridBackground(
              gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      spacing: 12,
                      children: [
                        TopNavigationBar(title: note.noteName),
                        StyledCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Note Detail',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              Divider(height: 24,),
                              TaskRowHelper(text: 'Title', data: note.noteName),
                              SizedBox(height: 24),
                              TaskRowHelper(text: 'Date', data: formattedDate),
                              Divider(height: 24),
                              if (note.note.isNotEmpty) ...{
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    
                                    TaskRowHelper(data: '', text: 'Context', colon: false,),
                                    SizedBox(height:12 ),
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: BoxBorder.all(),
                                        borderRadius: BorderRadius.all(Radius.circular(8)),
                                      ),
                                      padding: EdgeInsets.all(8),
                                      child: Text(note.note)
                                      ),
                                  ],
                                ),
                                SizedBox(height: 24),
                              },
                              SizedBox(height: 18),
                            ],
                          )
                        )
                      ],
                    ),
                  ),
                ),
              )
            )
          )
        ],
      ),
    );
  }
}

class TaskRowHelper extends StatelessWidget {
  const TaskRowHelper({
    super.key,
    required this.data,
    required this.text,
    this.colon = true,
  });

  final dynamic text;
  final dynamic data;
  final bool colon;
  


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w500
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: colon ? Text(':') : Text(''),
        ),
        Expanded(
          flex: 5,
          child: Text(
            data,
            textAlign: TextAlign.start,
            )
        ),
      ],
    );
  }
}
