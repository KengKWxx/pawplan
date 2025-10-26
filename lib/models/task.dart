import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String desc;
  final DateTime? date;
  final bool done;
  final String status; // 'upcoming' | 'done' | 'missed'
  final String? petId;
  // Reminder minutes before the date/time (e.g., 30 = 30 minutes before)
  final int? remindMinutesBefore;
  // Recurrence rule: none|daily|weekly|monthly
  final String? recurrence;
  // Optional category/type of task for default time logic
  final String? category;

  Task({
    required this.id,
    required this.title,
    required this.desc,
    this.date,
    required this.done,
    this.status = 'upcoming',
    this.petId,
    this.remindMinutesBefore,
    this.recurrence,
    this.category,
  });

  factory Task.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? date;
    if (d['date'] is Timestamp) date = (d['date'] as Timestamp).toDate();
    return Task(
      id: doc.id,
      title: d['title'] ?? '',
      desc: d['desc'] ?? '',
      date: date,
      done: d['done'] ?? false,
      status: d['status'] ?? 'upcoming',
      petId: d['petId'],
      remindMinutesBefore: (d['remindMinutesBefore'] is int) ? d['remindMinutesBefore'] as int : null,
      recurrence: d['recurrence'] as String?,
      category: d['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'desc': desc,
      'date': date,
      'done': done,
      'status': status,
      'petId': petId,
      'remindMinutesBefore': remindMinutesBefore,
      'recurrence': recurrence,
      'category': category,
    };
  }
}
