import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final String? petName;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.task,
    this.petName,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.brown.shade100,
            child: Icon(
              task.done ? Icons.check_circle : Icons.task_alt,
              color: task.done ? Colors.green : Colors.brown.shade700,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              _buildStatusChip(task),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.brown),
                tooltip: 'Edit',
                onPressed: () => _showEditDialog(context),
              ),
            ],
          ),
          subtitle: Text(_buildSubtitle()),
          trailing: IconButton(
            icon: Icon(task.done ? Icons.undo : Icons.more_vert, color: const Color(0xFF8B4513)),
            onPressed: () => _showActions(context),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Task task) {
    Color bg;
    String label;
    switch (task.status) {
      case 'done':
        bg = Colors.green.shade200;
        label = 'Done';
        break;
      case 'missed':
        bg = Colors.red.shade200;
        label = 'Missed';
        break;
      default:
        bg = Colors.blueGrey.shade200;
        label = 'Upcoming';
    }
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (petName != null && petName!.isNotEmpty) {
      parts.add('🐾 $petName');
    }
    if (task.desc.isNotEmpty) parts.add(task.desc);
    if (task.date != null) {
      final d = task.date!;
      final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      parts.add('Date: ${d.day}/${d.month}/${d.year} $time');
    }
    return parts.join('\n');
  }

  void _toggleTask(BuildContext context) async {
    try {
      await TaskService.toggleTask(task);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Toggle failed: $e')));
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยัน'),
        content: const Text('ลบงานนี้หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await TaskService.deleteTask(task);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('ลบงานแล้ว ✅')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
                }
              }
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    TaskService.showEditTaskDialog(context, task);
  }

  void _showActions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(task.done ? 'Mark as Undone' : 'Mark as Done'),
              onTap: () async {
                Navigator.pop(context);
                _toggleTask(context);
              },
            ),
            if (!task.done) ...[
              ListTile(
                leading: const Icon(Icons.snooze),
                title: const Text('Snooze 15 minutes'),
                onTap: () async {
                  Navigator.pop(context);
                  await TaskService.snoozeTask(task, const Duration(minutes: 15));
                },
              ),
              ListTile(
                leading: const Icon(Icons.snooze),
                title: const Text('Snooze 1 hour'),
                onTap: () async {
                  Navigator.pop(context);
                  await TaskService.snoozeTask(task, const Duration(hours: 1));
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
