import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oneday/features/habit/widgets/timer_widget.dart';
import 'package:provider/provider.dart';

import '../../../core/models/timer_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../pages/habit_notes_page.dart';
import '../pages/timer_page.dart';

class HabitMenu extends StatelessWidget {
  const HabitMenu({super.key});


  @override
  Widget build(BuildContext context) {
    
    void onShowTimer() {
      Navigator.push(context,
        MaterialPageRoute(
          builder: (context) => TimerPage(),
        ),
      );
    }

    void onShowHabitNotes() {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const HabitNotesPage()),
        );
    }


    return StyledCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: 10,
        children: [
          Expanded(flex: 1, child: IconButtonHelper2(icon: Icons.note_add_outlined, label: 'Notes', ontap: onShowHabitNotes)),
          Expanded(flex: 1, child: IconButtonHelper2(icon: Icons.timer_outlined, label: 'Timer', ontap: onShowTimer)),
        ],
      ),
    );
  }
}

class _StopWatchDetailPage extends StatefulWidget {

  @override
  State<_StopWatchDetailPage> createState() => _StopWatchPageState();
}

class _StopWatchPageState extends State<_StopWatchDetailPage> {
  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    final timer = Provider.of<TimerModel>(context);
    return Material(
      color: customCream,
      child: Stack(
        children: [
          const GridBackground(gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: 
                Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    clipBehavior: Clip.none,
                    child: Column(
                      children: [
                        TopNavigationBar(
                              title: 'Stopwatch',
                        ),
                        SizedBox(height: 16,),
                        
                        TimerWidget(timer: timer,),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
