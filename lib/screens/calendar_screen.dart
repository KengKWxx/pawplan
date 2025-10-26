import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final tasksCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks');

    return Scaffold(
      appBar: AppBar(title: const Text('ปฏิทิน')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2015, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder(
              stream: tasksCol.orderBy('date').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final qs = snapshot.data as QuerySnapshot<Map<String, dynamic>>;
                final tasks = qs.docs.map(Task.fromDoc).where((t) {
                  if (_selectedDay == null || t.date == null) return false;
                  final d = t.date!;
                  return d.year == _selectedDay!.year && d.month == _selectedDay!.month && d.day == _selectedDay!.day;
                }).toList();
                if (tasks.isEmpty) {
                  return const Center(child: Text('ไม่มีงานในวันนี้'));
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (_, i) => TaskTile(task: tasks[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}






