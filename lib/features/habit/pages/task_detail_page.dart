import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/task_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'package:oneday/features/habit/widgets/todo_widget.dart';

class TaskDetailScreen extends StatelessWidget {

  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
    });


  @override
  Widget build(BuildContext context) {

    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    String formattedDate = DateFormat('yyyy-MM-dd - HH:mm').format(task.date);

    final String status;

    if (task.status == false) {
      status = "Incomplete";
    } else {
      status = "Completed";
    }

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
                        TopNavigationBar(
                          title: task.title,
                          actionIcon: Icons.edit_note, // Ikon edit
                          onEditPressed: () {
                            // Panggil dialog edit dari todo_widget.dart
                            showAddTaskDialog(context, task.date, existingTask: task);
                          },
                          ),
                        StyledCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Task Detail',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              Divider(height: 24,),
                              TaskRowHelper(text: 'Title', data: task.title),
                              SizedBox(height: 24),
                              if (task.description.isNotEmpty) ...{
                                TaskRowHelper(text: 'Description', data: task.description),
                                SizedBox(height: 24),
                              },
                              TaskRowHelper(text: 'Priority', data: task.priority.name),
                              SizedBox(height: 24),
                              TaskRowHelper(text: 'Status', data: status),
                              SizedBox(height: 24),
                              TaskRowHelper(text: 'Date', data: formattedDate),
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
  });

  final dynamic text;
  final dynamic data;
  


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
          child: Text(':')
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
