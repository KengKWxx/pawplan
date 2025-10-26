import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/task.dart';
import '../widgets/app_text_field.dart';
import 'notification_service.dart';

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _firestore.collection('users').doc(_auth.currentUser!.uid).collection('tasks');
  static CollectionReference<Map<String, dynamic>> get _petsCol =>
      _firestore.collection('users').doc(_auth.currentUser!.uid).collection('pets');

  /// แสดง dialog เพิ่ม task
  static Future<void> showAddTaskDialog(BuildContext context) async {
    final petsSnap = await _petsCol.get();
    if (petsSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('โปรดเพิ่มสัตว์เลี้ยงก่อน')));
      return;
    }
    final title = TextEditingController();
    final desc = TextEditingController();
    String petId = petsSnap.docs.first.id;
    DateTime? date;
    TimeOfDay? time;
    String status = 'upcoming';
    int? remindMinutesBefore = 30;
    String recurrence = 'none';
    String category = 'general';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          scrollable: true,
          title: Row(
            children: [
              Icon(Icons.task_alt, color: Colors.brown.shade400),
              const SizedBox(width: 8),
              const Text('เพิ่มงาน'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: petId,
                  decoration: const InputDecoration(labelText: 'Pet'),
                  items: petsSnap.docs
                      .map((d) =>
                          DropdownMenuItem<String>(value: d.id, child: Text(d.data()['name'] ?? 'Pet')))
                      .toList(),
                  onChanged: (v) => setLocal(() => petId = v ?? petId),
                ),
                AppTextField(label: 'Task Title', controller: title),
                AppTextField(label: 'Description', controller: desc, maxLines: 3),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('ทั่วไป')),
                    DropdownMenuItem(value: 'medication', child: Text('ให้ยา')),
                    DropdownMenuItem(value: 'grooming', child: Text('อาบน้ำ/ตัดขน')),
                    DropdownMenuItem(value: 'walk', child: Text('พาเดิน')),
                    DropdownMenuItem(value: 'vet', child: Text('พบสัตวแพทย์')),
                  ],
                  onChanged: (v) => setLocal(() {
                    category = v ?? 'general';
                    // set default time by category if not chosen yet
                    if (time == null) {
                      switch (category) {
                        case 'medication':
                          time = const TimeOfDay(hour: 8, minute: 0);
                          break;
                        case 'grooming':
                          time = const TimeOfDay(hour: 10, minute: 0);
                          break;
                        case 'walk':
                          time = const TimeOfDay(hour: 7, minute: 0);
                          break;
                        case 'vet':
                          time = const TimeOfDay(hour: 15, minute: 0);
                          break;
                        default:
                          time = const TimeOfDay(hour: 9, minute: 0);
                      }
                      status = _computeStatus(_mergeDateTime(date, time), true);
                    }
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(date == null
                            ? 'Pick Date'
                            : '${date!.day}/${date!.month}/${date!.year}'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setLocal(() {
                            date = picked;
                            status = _computeStatus(_mergeDateTime(date, time), true);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(time == null ? 'Pick Time' : time!.format(ctx)),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) setLocal(() {
                            time = picked;
                            status = _computeStatus(_mergeDateTime(date, time), true);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: remindMinutesBefore,
                        decoration: const InputDecoration(labelText: 'Reminder'),
                        items: const [
                          DropdownMenuItem<int?>(value: null, child: Text('ไม่ต้องเตือน')),
                          DropdownMenuItem<int?>(value: 5, child: Text('ก่อนหน้า 5 นาที')),
                          DropdownMenuItem<int?>(value: 15, child: Text('ก่อนหน้า 15 นาที')),
                          DropdownMenuItem<int?>(value: 30, child: Text('ก่อนหน้า 30 นาที')),
                          DropdownMenuItem<int?>(value: 60, child: Text('ก่อนหน้า 1 ชั่วโมง')),
                          DropdownMenuItem<int?>(value: 120, child: Text('ก่อนหน้า 2 ชั่วโมง')),
                        ],
                        onChanged: (v) => setLocal(() => remindMinutesBefore = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: recurrence,
                        decoration: const InputDecoration(labelText: 'Repeat'),
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('ไม่ทำซ้ำ')),
                          DropdownMenuItem(value: 'daily', child: Text('ทุกวัน')),
                          DropdownMenuItem(value: 'weekly', child: Text('ทุกสัปดาห์')),
                          DropdownMenuItem(value: 'monthly', child: Text('ทุกเดือน')),
                        ],
                        onChanged: (v) => setLocal(() => recurrence = v ?? 'none'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_statusLabel(status), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (title.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('โปรดกรอกชื่องาน')));
                  return;
                }
                DateTime? dateTime = _mergeDateTime(date, time);
                status = _computeStatus(dateTime, true);
                final doc = await _tasksCol.add({
                  'petId': petId,
                  'title': title.text.trim(),
                  'desc': desc.text.trim(),
                  'date': dateTime,
                  'done': false,
                  'status': status,
                  'remindMinutesBefore': remindMinutesBefore,
                  'recurrence': recurrence,
                  'category': category,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                // schedule notification if date exists (skip on web)
                if (dateTime != null && !kIsWeb) {
                  try {
                    final id = _notificationId(doc.id);
                    final notifyAt = (remindMinutesBefore == null)
                        ? dateTime
                        : dateTime.subtract(Duration(minutes: remindMinutesBefore!));
                    await NotificationService.scheduleAt(
                      id: id,
                      title: 'Task Reminder',
                      body: title.text.trim(),
                      dateTime: notifyAt.isBefore(DateTime.now()) ? dateTime : notifyAt,
                    );
                  } catch (_) {
                    // Ignore notification errors
                  }
                }
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('เพิ่มงานแล้ว ✅')));
                }
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }

  /// แสดง dialog แก้ไข task
  static Future<void> showEditTaskDialog(BuildContext context, Task task) async {
    final petsSnap = await _petsCol.get();
    if (petsSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('โปรดเพิ่มสัตว์เลี้ยงก่อน')));
      return;
    }

    final title = TextEditingController(text: task.title);
    final desc = TextEditingController(text: task.desc);
    String? petId = task.petId ?? (petsSnap.docs.isNotEmpty ? petsSnap.docs.first.id : null);
    DateTime? date = task.date;
    TimeOfDay? time = task.date != null ? TimeOfDay(hour: task.date!.hour, minute: task.date!.minute) : null;
    String status = task.status;
    bool done = task.done;
    int? remindMinutesBefore = task.remindMinutesBefore;
    String recurrence = task.recurrence ?? 'none';
    String category = task.category ?? 'general';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          scrollable: true,
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.brown.shade400),
              const SizedBox(width: 8),
              const Text('แก้ไขงาน'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: petId,
                  decoration: const InputDecoration(labelText: 'Pet'),
                  items: petsSnap.docs
                      .map((d) => DropdownMenuItem<String>(value: d.id, child: Text(d.data()['name'] ?? 'Pet')))
                      .toList(),
                  onChanged: (v) => setLocal(() => petId = v ?? petId),
                ),
                AppTextField(label: 'Task Title', controller: title),
                AppTextField(label: 'Description', controller: desc, maxLines: 3),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('ทั่วไป')),
                    DropdownMenuItem(value: 'medication', child: Text('ให้ยา')),
                    DropdownMenuItem(value: 'grooming', child: Text('อาบน้ำ/ตัดขน')),
                    DropdownMenuItem(value: 'walk', child: Text('พาเดิน')),
                    DropdownMenuItem(value: 'vet', child: Text('พบสัตวแพทย์')),
                  ],
                  onChanged: (v) => setLocal(() {
                    category = v ?? 'general';
                    if (time == null) {
                      switch (category) {
                        case 'medication':
                          time = const TimeOfDay(hour: 8, minute: 0);
                          break;
                        case 'grooming':
                          time = const TimeOfDay(hour: 10, minute: 0);
                          break;
                        case 'walk':
                          time = const TimeOfDay(hour: 7, minute: 0);
                          break;
                        case 'vet':
                          time = const TimeOfDay(hour: 15, minute: 0);
                          break;
                        default:
                          time = const TimeOfDay(hour: 9, minute: 0);
                      }
                      status = _computeStatus(_mergeDateTime(date, time), true);
                    }
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(date == null ? 'Pick Date' : '${date!.day}/${date!.month}/${date!.year}'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: date ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setLocal(() {
                            date = picked;
                            status = _computeStatus(_mergeDateTime(date, time), true);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(time == null ? 'Pick Time' : time!.format(ctx)),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: time ?? TimeOfDay.now(),
                          );
                          if (picked != null) setLocal(() {
                            time = picked;
                            status = _computeStatus(_mergeDateTime(date, time), true);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: remindMinutesBefore,
                        decoration: const InputDecoration(labelText: 'Reminder'),
                        items: const [
                          DropdownMenuItem<int?>(value: null, child: Text('ไม่ต้องเตือน')),
                          DropdownMenuItem<int?>(value: 5, child: Text('ก่อนหน้า 5 นาที')),
                          DropdownMenuItem<int?>(value: 15, child: Text('ก่อนหน้า 15 นาที')),
                          DropdownMenuItem<int?>(value: 30, child: Text('ก่อนหน้า 30 นาที')),
                          DropdownMenuItem<int?>(value: 60, child: Text('ก่อนหน้า 1 ชั่วโมง')),
                          DropdownMenuItem<int?>(value: 120, child: Text('ก่อนหน้า 2 ชั่วโมง')),
                        ],
                        onChanged: (v) => setLocal(() => remindMinutesBefore = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: recurrence,
                        decoration: const InputDecoration(labelText: 'Repeat'),
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('ไม่ทำซ้ำ')),
                          DropdownMenuItem(value: 'daily', child: Text('ทุกวัน')),
                          DropdownMenuItem(value: 'weekly', child: Text('ทุกสัปดาห์')),
                          DropdownMenuItem(value: 'monthly', child: Text('ทุกเดือน')),
                        ],
                        onChanged: (v) => setLocal(() => recurrence = v ?? 'none'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_statusLabel(status), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('เสร็จแล้ว'),
                  value: done,
                  activeColor: Colors.brown.shade400,
                  onChanged: (v) => setLocal(() => done = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (title.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('โปรดกรอกชื่องาน')));
                  return;
                }
                DateTime? dateTime;
                if (date != null) {
                  final t = time ?? const TimeOfDay(hour: 9, minute: 0);
                  dateTime = DateTime(date!.year, date!.month, date!.day, t.hour, t.minute);
                }

                await _tasksCol.doc(task.id).update({
                  'petId': petId,
                  'title': title.text.trim(),
                  'desc': desc.text.trim(),
                  'date': dateTime,
                  'done': done,
                  'status': status,
                  'remindMinutesBefore': remindMinutesBefore,
                  'recurrence': recurrence,
                  'category': category,
                });
                // reschedule/cancel notification
                final nid = _notificationId(task.id);
                try {
                  await NotificationService.cancel(nid);
                  if (dateTime != null && !done && !kIsWeb) {
                    final notifyAt = (remindMinutesBefore == null)
                        ? dateTime
                        : dateTime.subtract(Duration(minutes: remindMinutesBefore!));
                    await NotificationService.scheduleAt(
                      id: nid,
                      title: 'Task Reminder',
                      body: title.text.trim(),
                      dateTime: notifyAt.isBefore(DateTime.now()) ? dateTime : notifyAt,
                    );
                  }
                } catch (_) {
                  // Ignore notification errors
                }
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('อัปเดตงานแล้ว ✅')));
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle task status
  static Future<void> toggleTask(Task task) async {
    final newDone = !task.done;
    String newStatus = task.status;
    if (newDone) {
      newStatus = 'done';
    } else {
      newStatus = _computeStatus(task.date, true);
    }
    await _tasksCol.doc(task.id).update({'done': newDone, 'status': newStatus});
    // cancel or reschedule notification on toggle
    final nid = _notificationId(task.id);
    try {
      await NotificationService.cancel(nid);
      if (!newDone && task.date != null && !kIsWeb) {
        await NotificationService.scheduleAt(
          id: nid,
          title: 'Task Reminder',
          body: task.title,
          dateTime: task.date!,
        );
      }
    } catch (_) {
      // Ignore notification errors
    }
  }

  /// ลบ task
  static Future<void> deleteTask(Task task) async {
    await _tasksCol.doc(task.id).delete();
    try {
      await NotificationService.cancel(_notificationId(task.id));
    } catch (_) {
      // Ignore notification errors
    }
  }

  /// ทำเครื่องหมายงานว่าเสร็จสิ้น (ใช้ใน bulk actions) และยกเลิกการแจ้งเตือน
  static Future<void> markDoneById(String taskId) async {
    await _tasksCol.doc(taskId).update({'done': true, 'status': 'done'});
    try {
      await NotificationService.cancel(_notificationId(taskId));
    } catch (_) {
      // Ignore notification errors
    }
  }

  /// Snooze งาน: เลื่อนไปอีกตามระยะเวลา และจัดการแจ้งเตือนใหม่
  static Future<void> snoozeTask(Task task, Duration duration) async {
    if (task.done) return; // ไม่ snooze งานที่เสร็จแล้ว
    final newDate = DateTime.now().add(duration);
    final newStatus = _computeStatus(newDate, true);
    await _tasksCol.doc(task.id).update({'date': newDate, 'status': newStatus});
    final nid = _notificationId(task.id);
    try {
      await NotificationService.cancel(nid);
      if (!kIsWeb) {
        await NotificationService.scheduleAt(
          id: nid,
          title: 'Task Reminder',
          body: task.title,
          dateTime: newDate,
        );
      }
    } catch (_) {
      // Ignore notification errors
    }
  }
}

// Helpers
Color _statusColor(String status) {
  switch (status) {
    case 'done':
      return Colors.green;
    case 'missed':
      return Colors.red;
    default:
      return Colors.blueGrey;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'done':
      return 'Done';
    case 'missed':
      return 'Missed';
    default:
      return 'Upcoming';
  }
}

DateTime? _mergeDateTime(DateTime? date, TimeOfDay? time) {
  if (date == null) return null;
  final t = time ?? const TimeOfDay(hour: 9, minute: 0);
  return DateTime(date.year, date.month, date.day, t.hour, t.minute);
}

String _computeStatus(DateTime? dateTime, bool defaultUpcoming) {
  if (dateTime == null) return defaultUpcoming ? 'upcoming' : 'upcoming';
  final now = DateTime.now();
  if (dateTime.isBefore(now)) return 'missed';
  return 'upcoming';
}

int _notificationId(String taskId) {
  // create stable integer id from taskId hashCode
  return taskId.hashCode & 0x7fffffff;
}
