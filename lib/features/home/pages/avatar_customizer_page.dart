
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oneday/features/home/widgets/avatar_customizer.dart';

import '../../../shared/widgets/common_widgets.dart';

class AvatarCustomizerPage extends StatelessWidget {
  const AvatarCustomizerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double maxWidth = min(MediaQuery.of(context).size.width * 0.9, 540.0);
    return Scaffold(
      body: Material(
        color: customCream,
        child: Stack(
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
                          TopNavigationBar(title: 'Avatar Maker'),
                          SizedBox(height: 12),
                          AvatarCustomizer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ) 
            )
          ],
        ),
      ),
    );
  }
}