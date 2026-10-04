import 'package:flutter/material.dart';

import 'community/community_screen.dart';
import 'home/home_screen.dart';
import 'nutrition/nutrition_screen.dart';
import 'planner/plan_screen.dart';
import 'progress/progress_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> {
  int _index = 0;

  void go(int i) => setState(() => _index = i);

  static ShellState? of(BuildContext context) => context.findAncestorStateOfType<ShellState>();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: const [
          HomeScreen(),
          PlanScreen(),
          ProgressScreen(),
          CommunityScreen(),
          NutritionScreen(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: go,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Plan'),
            NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progress'),
            NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Circles'),
            NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Nutrition'),
          ],
        ),
      );
}
