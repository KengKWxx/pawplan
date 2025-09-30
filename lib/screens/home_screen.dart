import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';

class Pet {
  final String id;
  final String name;
  final String breed;
  final String age;
  final String sex;
  final String color;
  final String? photoUrl;

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.sex,
    required this.color,
    this.photoUrl,
  });

  factory Pet.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Pet(
      id: doc.id,
      name: d['name'] ?? '',
      breed: d['breed'] ?? '',
      age: d['age'] ?? '',
      sex: d['sex'] ?? '',
      color: d['color'] ?? '',
      photoUrl: d['photoUrl'],
    );
  }
}

class Task {
  final String id;
  final String title;
  final String desc;
  final DateTime? date;
  final bool done;

  Task({
    required this.id,
    required this.title,
    required this.desc,
    this.date,
    required this.done,
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
    );
  }
}

/// ---------------- Widgets ----------------
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// ---------------- Home Screen ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final auth = FirebaseAuth.instance;
  User? get user => auth.currentUser;
  int _nav = 0;

  CollectionReference<Map<String, dynamic>> get _petsCol =>
      FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('pets');
  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('tasks');

  final _breedPresets = <String>[
    'Labrador Retriever',
    'Poodle',
    'Shih Tzu',
    'Golden Retriever',
    'Bulldog',
    'Persian Cat',
    'Siamese Cat',
    'Maine Coon',
    'Hamster',
    'Parrot',
    'Other'
  ];

  /// ---------------- Add Pet Dialog ----------------
  Future<void> _addPetDialog() async {
    if (user == null) return;
    final name = TextEditingController();
    final age = TextEditingController();
    final sex = TextEditingController();
    final color = TextEditingController();
    final otherBreed = TextEditingController();
    String? breed = _breedPresets.first;
    XFile? picked;
    bool uploading = false;
    double progress = 0;

    await showDialog(
      context: context,
      barrierDismissible: !uploading,
      builder: (ctx) {
        final width = MediaQuery.of(ctx).size.width;
        final maxWidth = width > 600 ? 500.0 : width * 0.9;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            title: Row(
              children: [
                Icon(Icons.pets, color: Colors.brown.shade400),
                const SizedBox(width: 8),
                const Text('Add Pet'),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    InkWell(
                      onTap: uploading
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                              if (x != null) setLocal(() => picked = x);
                            },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.brown.shade200),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.brown.shade50,
                          image: picked != null && !kIsWeb
                              ? DecorationImage(
                                  image: FileImage(File(picked!.path)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: picked == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.brown.shade400),
                                  const SizedBox(height: 6),
                                  Text("Tap to add photo", style: TextStyle(color: Colors.brown.shade400)),
                                ],
                              )
                            : const SizedBox(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Name', controller: name),
                    DropdownButtonFormField<String>(
                      value: breed,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Breed'),
                      items: _breedPresets
                          .map((b) => DropdownMenuItem<String>(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (v) => setLocal(() => breed = v),
                    ),
                    if (breed == 'Other') AppTextField(label: 'Custom Breed', controller: otherBreed),
                    Row(
                      children: [
                        Expanded(child: AppTextField(label: 'Age', controller: age)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: sex.text.isNotEmpty ? sex.text : null,
                            decoration: const InputDecoration(labelText: 'Sex'),
                            items: ['Male', 'Female', 'Other']
                                .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => sex.text = v ?? '',
                          ),
                        ),
                      ],
                    ),
                    AppTextField(label: 'Color', controller: color),
                    if (uploading) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: progress == 0 ? null : progress),
                      const SizedBox(height: 6),
                      Text('Uploading ${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12, color: Colors.brown.shade600)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: uploading ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: uploading
                    ? null
                    : () async {
                        if (name.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Please enter pet name')));
                          return;
                        }
                        if (breed == 'Other' && otherBreed.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Please enter custom breed')));
                          return;
                        }
                        setLocal(() => uploading = true);
                        final petId = FirebaseFirestore.instance.collection('_tmp').doc().id;
                        String? photoUrl;
                        try {
                          if (picked != null) {
                            final ext = picked!.name.split('.').last;
                            final ref = FirebaseStorage.instance.ref('users/${user!.uid}/pets/$petId.$ext');
                            UploadTask task;
                            if (kIsWeb) {
                              final bytes = await picked!.readAsBytes();
                              task = ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
                            } else {
                              task = ref.putFile(File(picked!.path));
                            }
                            await task;
                            photoUrl = await ref.getDownloadURL();
                            print('photoUrl: $photoUrl'); // ตรวจสอบว่าขึ้น https://... จริง
                          }
                          await _petsCol.doc(petId).set({
                            'name': name.text.trim(),
                            'breed': breed == 'Other' ? otherBreed.text.trim() : breed,
                            'age': age.text.trim(),
                            'sex': sex.text.trim(),
                            'color': color.text.trim(),
                            'owner': user?.displayName ?? user?.email ?? 'User',
                            'photoUrl': photoUrl,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          print('photoUrl: $photoUrl');
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Pet added ✅')));
                          }
                        } catch (e) {
                          setLocal(() => uploading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Add pet failed: $e')));
                          }
                        }
                      },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ---------------- Add Task Dialog ----------------
  Future<void> _addTaskDialog() async {
    final petsSnap = await _petsCol.get();
    if (petsSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a pet first')));
      return;
    }
    final title = TextEditingController();
    final desc = TextEditingController();
    String petId = petsSnap.docs.first.id;
    DateTime? date;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Row(
            children: [
              Icon(Icons.task_alt, color: Colors.brown.shade400),
              const SizedBox(width: 8),
              const Text('Add Task'),
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
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                        date == null ? 'Pick Date' : '${date!.day}/${date!.month}/${date!.year}'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setLocal(() => date = picked);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (title.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Please enter task title')));
                  return;
                }
                await _tasksCol.add({
                  'petId': petId,
                  'title': title.text.trim(),
                  'desc': desc.text.trim(),
                  'date': date,
                  'done': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Task added ✅')));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Confirm / Delete ----------------
  Future<bool> _confirm(String msg) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _deletePet(Pet pet) async {
    if (!await _confirm('Delete this pet?')) return;
    final snap = await _tasksCol.where('petId', isEqualTo: pet.id).get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
    await _petsCol.doc(pet.id).delete();
    if (pet.photoUrl != null) {
      try {
        await FirebaseStorage.instance.refFromURL(pet.photoUrl!).delete();
      } catch (_) {}
    }
  }

  Future<void> _deleteTask(Task task) async {
    if (!await _confirm('Delete this task?')) return;
    await _tasksCol.doc(task.id).delete();
  }

  // ---------------- Cards ----------------
  Widget _petCard(Pet pet) {
    return GestureDetector(
      onLongPress: () => _deletePet(pet),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: (pet.photoUrl != null && pet.photoUrl!.startsWith('http'))
                    ? Image.network(
                        pet.photoUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.brown.shade50,
                          alignment: Alignment.center,
                          child: Icon(Icons.broken_image, color: Colors.brown.shade300),
                        ),
                      )
                    : Container(
                        color: Colors.brown.shade50,
                        alignment: Alignment.center,
                        child: Icon(Icons.pets, size: 42, color: Colors.brown.shade300),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.brown),
                        tooltip: 'Edit',
                        onPressed: () => _editPetDialog(pet),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pet.breed}, ${pet.age}, ${pet.sex}${pet.color.isNotEmpty ? ', ${pet.color}' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.brown.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- แก้ไข _taskTile ให้มีปุ่ม edit ---
  Widget _taskTile(Task t) {
    return GestureDetector(
      onLongPress: () => _deleteTask(t),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.brown.shade100,
            child: Icon(
              t.done ? Icons.check_circle : Icons.task_alt,
              color: t.done ? Colors.green : Colors.brown.shade700,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  t.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: t.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.brown),
                tooltip: 'Edit',
                onPressed: () => _editTaskDialog(t),
              ),
            ],
          ),
          subtitle: Text(
            '${t.desc}${t.date != null ? '\nDate: ${t.date!.day}/${t.date!.month}/${t.date!.year}' : ''}',
          ),
          trailing: IconButton(
            icon: Icon(t.done ? Icons.undo : Icons.check, color: const Color(0xFF8B4513)),
            onPressed: () =>
                _tasksCol.doc(t.id).update({'done': !t.done}),
          ),
        ),
      ),
    );
  }

  // --- เพิ่มฟังก์ชันแก้ไข Task ---
  Future<void> _editTaskDialog(Task t) async {
    final petsSnap = await _petsCol.get();
    if (petsSnap.docs.isEmpty) return;
    final title = TextEditingController(text: t.title);
    final desc = TextEditingController(text: t.desc);
    String petId = t.id; // แก้เป็น t.petId ถ้ามี field นี้ใน Task
    DateTime? date = t.date;

    // หา petId เดิม
    if (t is Task && t.id.isNotEmpty) {
      // ถ้ามี field petId ใน Task ให้ใช้ t.petId
      final doc = await _tasksCol.doc(t.id).get();
      if (doc.exists && doc.data()?['petId'] != null) {
        petId = doc.data()!['petId'];
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Row(
            children: [
              Icon(Icons.task_alt, color: Colors.brown.shade400),
              const SizedBox(width: 8),
              const Text('Edit Task'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                        date == null ? 'Pick Date' : '${date!.day}/${date!.month}/${date!.year}'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setLocal(() => date = picked);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (title.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Please enter task title')));
                  return;
                }
                await _tasksCol.doc(t.id).update({
                  'petId': petId,
                  'title': title.text.trim(),
                  'desc': desc.text.trim(),
                  'date': date,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Task updated ✅')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // --- เพิ่มฟังก์ชันแก้ไขสัตว์เลี้ยง ---
  Future<void> _editPetDialog(Pet pet) async {
    final name = TextEditingController(text: pet.name);
    final age = TextEditingController(text: pet.age);
    final sex = TextEditingController(text: pet.sex);
    final color = TextEditingController(text: pet.color);
    final otherBreed = TextEditingController(
        text: _breedPresets.contains(pet.breed) ? '' : pet.breed);
    String? breed = _breedPresets.contains(pet.breed) ? pet.breed : 'Other';
    XFile? picked;
    bool uploading = false;
    double progress = 0;
    String? photoUrl = pet.photoUrl;

    await showDialog(
      context: context,
      barrierDismissible: !uploading,
      builder: (ctx) {
        final width = MediaQuery.of(ctx).size.width;
        final maxWidth = width > 600 ? 500.0 : width * 0.9;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            title: Row(
              children: [
                Icon(Icons.pets, color: Colors.brown.shade400),
                const SizedBox(width: 8),
                const Text('Edit Pet'),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    InkWell(
                      onTap: uploading
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                              if (x != null) setLocal(() => picked = x);
                            },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.brown.shade200),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.brown.shade50,
                          image: picked != null && !kIsWeb
                              ? DecorationImage(
                                  image: FileImage(File(picked!.path)),
                                  fit: BoxFit.cover,
                                )
                              : (photoUrl != null && photoUrl?.startsWith('http') == true)
                                  ? DecorationImage(
                                      image: NetworkImage(photoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: picked == null && (photoUrl == null || photoUrl?.startsWith('http') != true)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.brown.shade400),
                                  const SizedBox(height: 6),
                                  Text("Tap to add photo", style: TextStyle(color: Colors.brown.shade400)),
                                ],
                              )
                            : const SizedBox(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Name', controller: name),
                    DropdownButtonFormField<String>(
                      value: breed,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Breed'),
                      items: _breedPresets
                          .map((b) => DropdownMenuItem<String>(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (v) => setLocal(() => breed = v),
                    ),
                    if (breed == 'Other') AppTextField(label: 'Custom Breed', controller: otherBreed),
                    Row(
                      children: [
                        Expanded(child: AppTextField(label: 'Age', controller: age)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: sex.text.isNotEmpty ? sex.text : null,
                            decoration: const InputDecoration(labelText: 'Sex'),
                            items: ['Male', 'Female']
                                .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => sex.text = v ?? '',
                          ),
                        ),
                      ],
                    ),
                    AppTextField(label: 'Color', controller: color),
                    if (uploading) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: progress == 0 ? null : progress),
                      const SizedBox(height: 6),
                      Text('Uploading ${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12, color: Colors.brown.shade600)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: uploading ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: uploading
                    ? null
                    : () async {
                        if (name.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Please enter pet name')));
                          return;
                        }
                        if (breed == 'Other' && otherBreed.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Please enter custom breed')));
                          return;
                        }
                        setLocal(() => uploading = true);
                        try {
                          if (picked != null) {
                            final ext = picked!.name.split('.').last;
                            final ref = FirebaseStorage.instance.ref('users/${user!.uid}/pets/${pet.id}.$ext');
                            UploadTask task;
                            if (kIsWeb) {
                              final bytes = await picked!.readAsBytes();
                              task = ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
                            } else {
                              task = ref.putFile(File(picked!.path));
                            }
                            await task;
                            photoUrl = await ref.getDownloadURL();
                          }
                          await _petsCol.doc(pet.id).update({
                            'name': name.text.trim(),
                            'breed': breed == 'Other' ? otherBreed.text.trim() : breed,
                            'age': age.text.trim(),
                            'sex': sex.text.trim(),
                            'color': color.text.trim(),
                            'photoUrl': photoUrl,
                          });
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Pet updated ✅')));
                          }
                        } catch (e) {
                          setLocal(() => uploading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Update failed: $e')));
                          }
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- Sections ----------------
  Widget _homeSection() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.brown.shade100,
              child: Icon(Icons.pets, color: Colors.brown.shade700, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Hi. ${user?.displayName ?? user?.email ?? 'User'}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: _addPetDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Pet'),
              style: _primaryBtn(),
            ),
            ElevatedButton.icon(
              onPressed: _addTaskDialog,
              icon: const Icon(Icons.task),
              label: const Text('Add Task'),
              style: _secondaryBtn(),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Recent Pets',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
                fontSize: 16)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _petsCol.orderBy('createdAt', descending: true).limit(4).snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final pets = snap.data!.docs.map(Pet.fromDoc).toList();
            if (pets.isEmpty) {
              return Text('No pets yet', style: TextStyle(color: Colors.brown.shade400));
            }
            return SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(width: 150, child: _petCard(pets[i])),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Recent Tasks',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
                fontSize: 16)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _tasksCol.orderBy('createdAt', descending: true).limit(5).snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final tasks = snap.data!.docs.map(Task.fromDoc).toList();
            if (tasks.isEmpty) {
              return Text('No tasks yet', style: TextStyle(color: Colors.brown.shade400));
            }
            return Column(children: tasks.map(_taskTile).toList());
          },
        ),
      ],
    );
  }

  Widget _petsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _petsCol.orderBy('createdAt').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final pets = snap.data!.docs.map(Pet.fromDoc).toList();
        if (pets.isEmpty) return _emptyState('No pets', 'Add Pet', _addPetDialog);
        final width = MediaQuery.of(context).size.width;
        final cross = width > 1000
            ? 5
            : width > 800
                ? 4
                : width > 600
                    ? 3
                    : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: .68,
          ),
          itemCount: pets.length,
          itemBuilder: (_, i) => _petCard(pets[i]),
        );
      },
    );
  }

  Widget _tasksSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _tasksCol.orderBy('createdAt', descending: true).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final tasks = snap.data!.docs.map(Task.fromDoc).toList();
        if (tasks.isEmpty) return _emptyState('No tasks', 'Add Task', _addTaskDialog);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: tasks.length,
          itemBuilder: (_, i) => _taskTile(tasks[i]),
        );
      },
    );
  }

  Widget _settingsSection() {
    final nameCtl = TextEditingController(text: user?.displayName ?? '');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.brown.shade100,
            child: Icon(Icons.person, color: Colors.brown.shade700),
          ),
          title: Text(user?.email ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(user?.displayName?.isEmpty ?? true
              ? 'No display name'
              : user!.displayName!),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: nameCtl,
          decoration: InputDecoration(
            labelText: 'Display Name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save Name'),
          style: _secondaryBtn(),
          onPressed: () async {
            if (nameCtl.text.trim().isEmpty) return;
            await user?.updateDisplayName(nameCtl.text.trim());
            await user?.reload();
            setState(() {});
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Updated')));
          },
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () async {
            await auth.signOut();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          'Long press pet/task to delete.\nTap check to toggle task.',
          style: TextStyle(fontSize: 12, color: Colors.brown.shade500),
        ),
      ],
    );
  }

  // ---------------- Helpers ----------------
  ButtonStyle _primaryBtn() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
  ButtonStyle _secondaryBtn() => ElevatedButton.styleFrom(
        backgroundColor: Colors.brown.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
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

  Widget _body() {
    switch (_nav) {
      case 1:
        return _petsSection();
      case 2:
        return _tasksSection();
      case 3:
        return _settingsSection();
      default:
        return _homeSection();
    }
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5DC),
        elevation: 0,
        title: const Text('PawPlan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A3A16))),
        actions: [
          if (_nav != 3)
            IconButton(
              tooltip: 'Settings',
              onPressed: () => setState(() => _nav = 3),
              icon: const Icon(Icons.settings),
              color: const Color(0xFF5A3A16),
            ),
        ],
      ),
      body: _body(),
      floatingActionButton: _nav == 1
          ? FloatingActionButton(
              onPressed: _addPetDialog,
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : _nav == 2
              ? FloatingActionButton(
                  onPressed: _addTaskDialog,
                  backgroundColor: Colors.brown.shade400,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.task),
                )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _nav,
        selectedItemColor: const Color(0xFF8B4513),
        unselectedItemColor: Colors.brown.shade300,
        onTap: (i) => setState(() => _nav = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
