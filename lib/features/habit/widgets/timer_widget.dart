import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'package:provider/provider.dart';

import '../../../core/models/timer_model.dart';
import '../../../core/providers/timer_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key, required this.timer});

  final TimerModel timer;

  // Helper untuk format waktu
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    // Kita bisa hapus jam jika durasi timer di bawah 1 jam untuk layout lebih rapi
    if (duration.inHours > 0) {
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();
    final bool isActiveTimer = timerProvider.timerName == timer.name;

    // Durasi total timer dalam detik
    final totalDuration = Duration(minutes: timer.duration);

    // Durasi yang akan ditampilkan (sisa waktu jika aktif, atau durasi total jika tidak)
    final Duration displayDuration =
        isActiveTimer ? timerProvider.remainingTime : totalDuration;

    // Menghitung nilai progress untuk CircularProgressIndicator (0.0 sampai 1.0)
    final double progressValue =
        displayDuration.inSeconds / totalDuration.inSeconds;

    return StyledCard(
      padding: EdgeInsets.symmetric(horizontal: 24,vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              fit: StackFit.loose,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi), // Memutar balik lingkaran
                    child: CircularProgressIndicator(
                      strokeCap: StrokeCap.round,
                      value: progressValue,
                      strokeWidth: 16,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black),
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi), // Memutar balik lingkaran
                    child: CircularProgressIndicator(
                      strokeCap: StrokeCap.round,
                      value: progressValue,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          customYellow),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    _formatDuration(displayDuration),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timer.name,
                  style:
                      const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                if (timer.description != null && timer.description!.isNotEmpty) ...{
                  Text(
                  timer.description!,
                  style:
                      const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w400),
                  overflow: TextOverflow.ellipsis,
                  ),
                },
                SizedBox(height: 4),
                Container(
                  height: 40,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(8),
                    )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 24,
                        icon: Icon(
                          isActiveTimer && timerProvider.isRunning
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: customYellow,
                        ),
                        onPressed: () {
                          if (isActiveTimer && timerProvider.isRunning) {
                            timerProvider.pauseTimer();
                          } else if (isActiveTimer && timerProvider.isPaused) {
                            timerProvider.resumeTimer();
                          } else {
                            timerProvider.startTimer(
                              timer.name,
                              Duration(minutes: timer.duration),
                            );
                          }
                        },
                      ),
                                
                      if (isActiveTimer &&
                        (timerProvider.isRunning || timerProvider.isPaused))
                      IconButton(
                        iconSize: 24,
                        icon:
                            const Icon(Icons.stop_circle_outlined, color: customRed),
                        onPressed: () {
                          timerProvider.stopTimer();
                        },
                      ),
                                
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}