import 'package:flutter/material.dart';
import 'attendance_screen.dart';
import 'attendance_history_screen.dart';
import 'students_screen.dart';
import 'timetable_screen.dart';
import 'announcements_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    AttendanceScreen(),
    AttendanceHistoryScreen(),
    StudentsScreen(),
    TimetableScreen(),
    AnnouncementsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'History'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.schedule), label: 'Timetable'),
          NavigationDestination(icon: Icon(Icons.campaign), label: 'Announce'),
        ],
      ),
    );
  }
}
