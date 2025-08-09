import 'package:flutter/material.dart';

import '../../features/finance/pages/finance_page.dart';
import '../../features/habit/pages/habit_page.dart';
import '../../features/home/pages/home.dart';
import '../../features/mood/pages/mood_page.dart';
import 'common_widgets.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});
  static const nameRoute = 'mainNavigation';

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[

      const MoodPage(),
      const HabitPage(),
      const FinancePage(),
      const HomePage(),
    ];

    return Scaffold(
      backgroundColor: customCream,
      resizeToAvoidBottomInset: false,
      body: Align(
        child: Stack(
          children: [
            const GridBackground(gridSize: 50, lineColor: Color.fromARGB(50, 0, 0, 0)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                height: double.infinity,
                key: ValueKey<int>(_selectedIndex),
                child: pages[_selectedIndex],
              ),
              
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: StyledBottomNavBar(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

