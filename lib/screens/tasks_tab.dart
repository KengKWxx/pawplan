import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';
import '../l10n/app_localizations.dart';

class TasksTab extends StatelessWidget {
  final User user;
  final VoidCallback onAddTask;

  const TasksTab({
    super.key,
    required this.user,
    required this.onAddTask,
  });

  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      FirebaseFirestore.instance.collection('users').doc(user.uid).collection('tasks');
  CollectionReference<Map<String, dynamic>> get _petsCol =>
      FirebaseFirestore.instance.collection('users').doc(user.uid).collection('pets');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _tasksCol.orderBy('date', descending: false).snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          // Fallback: try createdAt ordering (no composite index needed)
          return StreamBuilder(
            stream: _tasksCol.orderBy('createdAt', descending: true).snapshots(),
            builder: (_, snap2) {
              if (snap2.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(AppLocalizations.of(context)?.failedToLoadTasks ?? 'Failed to load tasks'),
                        const SizedBox(height: 8),
                        Text('${snap.error}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }
              if (!snap2.hasData) return const Center(child: CircularProgressIndicator());
              final qs2 = snap2.data as QuerySnapshot<Map<String, dynamic>>;
              final tasks2 = qs2.docs.map(Task.fromDoc).toList();
              if (tasks2.isEmpty) return _emptyState(AppLocalizations.of(context)?.noTasksYet ?? 'No tasks yet', AppLocalizations.of(context)?.addTask ?? 'Add Task', onAddTask);
              return _withPets(context, tasks2);
            },
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final qs = snap.data as QuerySnapshot<Map<String, dynamic>>;
        final tasks = qs.docs.map(Task.fromDoc).toList();
        if (tasks.isEmpty) return _emptyState(AppLocalizations.of(context)?.noTasksYet ?? 'No tasks yet', AppLocalizations.of(context)?.addTask ?? 'Add Task', onAddTask);
        return _withPets(context, tasks);
      },
    );
  }


  Widget _emptyState(String msg, String action, VoidCallback onAdd) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 70, color: Colors.brown.shade300),
              const SizedBox(height: 14),
              Text(msg,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.brown.shade600)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(action),
                style: _primaryBtn(),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      );

  ButtonStyle _primaryBtn() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
  Widget _withPets(BuildContext context, List<Task> tasks) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _petsCol.snapshots(),
      builder: (_, petSnap) {
        final Map<String, String> petIdToName = {};
        if (petSnap.hasData) {
          for (final d in petSnap.data!.docs) {
            petIdToName[d.id] = (d.data()['name'] ?? '') as String;
          }
        }
        return _TaskList(tasks: tasks, petIdToName: petIdToName);
      },
    );
  }
}

class _TaskList extends StatefulWidget {
  final List<Task> tasks;
  final Map<String, String> petIdToName;
  const _TaskList({required this.tasks, required this.petIdToName});

  @override
  State<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<_TaskList> {
  final Set<String> _selected = {};
  String _query = '';
  String _statusFilter = 'all'; // all,today,upcoming,missed,done
  String? _petFilter; // petId or null for all

  @override
  Widget build(BuildContext context) {
    final filtered = widget.tasks.where((t) {
      final matchesQuery = _query.isEmpty ||
          t.title.toLowerCase().contains(_query.toLowerCase()) ||
          t.desc.toLowerCase().contains(_query.toLowerCase());
      final now = DateTime.now();
      bool matchesStatus = true;
      switch (_statusFilter) {
        case 'today':
          if (t.date == null) {
            matchesStatus = false;
          } else {
            final d = t.date!;
            matchesStatus = d.year == now.year && d.month == now.month && d.day == now.day;
          }
          break;
        case 'upcoming':
          matchesStatus = t.status == 'upcoming' && t.done == false;
          break;
        case 'missed':
          matchesStatus = t.status == 'missed' && t.done == false;
          break;
        case 'done':
          matchesStatus = t.done == true;
          break;
        default:
          matchesStatus = true;
      }
      final matchesPet = _petFilter == null || (t.petId ?? '') == _petFilter;
      return matchesQuery && matchesStatus && matchesPet;
    }).toList();

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: filtered.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return _buildControls(context);
            }
            final t = filtered[i - 1];
            final selected = _selected.contains(t.id);
            return GestureDetector(
              onLongPress: () => setState(() => _selected.add(t.id)),
              onTap: () {
                if (_selected.isNotEmpty) {
                  setState(() {
                    if (selected) {
                      _selected.remove(t.id);
                    } else {
                      _selected.add(t.id);
                    }
                  });
                }
              },
              child: Container(
                decoration: selected
                    ? BoxDecoration(
                        border: Border.all(color: Colors.brown.shade300),
                        borderRadius: BorderRadius.circular(14),
                      )
                    : null,
                child: TaskTile(task: t, petName: widget.petIdToName[t.petId ?? '']),
              ),
            );
          },
        ),
        if (_selected.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(AppLocalizations.of(context)?.confirm ?? 'Confirm'),
                          content: Text(AppLocalizations.of(context)?.deleteNTasks(_selected.length) ?? 'Delete ${_selected.length} task(s)?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)?.delete ?? 'Delete')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        for (final id in _selected) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('tasks')
                              .doc(id)
                              .delete();
                        }
                        if (mounted) setState(() => _selected.clear());
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: Text(AppLocalizations.of(context)?.deleteSelected ?? 'Delete Selected'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      for (final id in _selected) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('tasks')
                            .doc(id)
                            .update({'done': true, 'status': 'done'});
                      }
                      if (mounted) setState(() => _selected.clear());
                    },
                    icon: const Icon(Icons.check_circle),
                    label: Text(AppLocalizations.of(context)?.markDone ?? 'Mark Done'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.searchTasks ?? 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          _buildPetSelector(),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('all', AppLocalizations.of(context)?.all ?? 'All'),
                _chip('today', AppLocalizations.of(context)?.today ?? 'Today'),
                _chip('upcoming', AppLocalizations.of(context)?.upcoming ?? 'Upcoming'),
                _chip('missed', AppLocalizations.of(context)?.missed ?? 'Missed'),
                _chip('done', AppLocalizations.of(context)?.done ?? 'Done'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetSelector() {
    final entries = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text(AppLocalizations.of(context)?.all ?? 'All'),
      ),
      ...widget.petIdToName.entries
          .map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value)))
          .toList(),
    ];
    return DropdownButtonFormField<String?>(
      value: _petFilter,
      items: entries,
      onChanged: (v) => setState(() => _petFilter = v),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.pets),
        labelText: AppLocalizations.of(context)?.searchTasks ?? 'Filter by pet',
      ),
    );
  }

  Widget _chip(String v, String label) {
    final selected = _statusFilter == v;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = v),
      ),
    );
  }
}
