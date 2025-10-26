import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';
import '../models/task.dart';
import '../widgets/pet_card.dart';
import '../widgets/task_tile.dart';
import '../widgets/local_image_widget.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_storage_service.dart';
import '../l10n/app_localizations.dart';

class HomeTab extends StatelessWidget {
  final User user;
  final VoidCallback onAddPet;
  final VoidCallback onAddTask;

  const HomeTab({
    super.key,
    required this.user,
    required this.onAddPet,
    required this.onAddTask,
  });

  CollectionReference<Map<String, dynamic>> get _petsCol =>
      FirebaseFirestore.instance.collection('users').doc(user.uid).collection('pets');
  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      FirebaseFirestore.instance.collection('users').doc(user.uid).collection('tasks');

  @override
  Widget build(BuildContext context) {
    // Debug: ตรวจสอบรูปภาพที่เก็บไว้
    LocalStorageService.debugPrintAllImages();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        children: [
        Row(
          children: [
            _buildUserAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppLocalizations.of(context)?.hiUser(user.displayName ?? user.email ?? 'User') ?? 'Hi. ${user.displayName ?? user.email ?? 'User'}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
              onPressed: onAddPet,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)?.addPet ?? 'Add Pet'),
              style: _primaryBtn(),
            ),
            ElevatedButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.task),
              label: Text(AppLocalizations.of(context)?.addTask ?? 'Add Task'),
              style: _secondaryBtn(),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildFavoriteCard(),
        const SizedBox(height: 20),
        Text(AppLocalizations.of(context)?.recentPets ?? 'Recent Pets',
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
              return Text(AppLocalizations.of(context)?.noPetsYet ?? 'No pets yet', style: TextStyle(color: Colors.brown.shade400));
            }
            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(width: 140, child: PetCard(pet: pets[i])),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)?.recentTasks ?? 'Recent Tasks',
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
              return Text(AppLocalizations.of(context)?.noTasksYet ?? 'No tasks yet', style: TextStyle(color: Colors.brown.shade400));
            }
            return Column(children: tasks.map((t) => TaskTile(task: t)).toList());
          },
        ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard() {
    final usersCol = FirebaseFirestore.instance.collection('users');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: usersCol.doc(user.uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();
        final data = userSnap.data!.data() ?? {};
        final favoritePetId = data['favoritePetId'] as String?;
        if (favoritePetId == null || favoritePetId.isEmpty) return const SizedBox.shrink();
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _petsCol.doc(favoritePetId).snapshots(),
          builder: (context, petSnap) {
            if (!petSnap.hasData || !petSnap.data!.exists) return const SizedBox.shrink();
            final pet = Pet.fromDoc(petSnap.data!);
            return Container(
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                border: Border.all(color: Colors.brown.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.brown.shade100,
                    child: ClipOval(
                      child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                          ? (SupabaseStorageService.isSupabaseStorageUrl(pet.photoUrl!)
                              ? Image.network(pet.photoUrl!, width: 56, height: 56, fit: BoxFit.cover)
                              : LocalImageWidget(imageKey: pet.photoUrl!, width: 56, height: 56, fit: BoxFit.cover))
                          : Icon(Icons.pets, color: Colors.brown.shade700, size: 30),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(pet.breed, style: TextStyle(color: Colors.brown.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.star, color: Colors.amber.shade600),
                ],
              ),
            );
          },
        );
      },
    );
  }

  ButtonStyle _primaryBtn() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
  Widget _buildUserAvatar() {
    final user = this.user;
    print('Building user avatar for user: ${user.uid}');
    print('User photoURL: ${user.photoURL}');
    
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      if (SupabaseStorageService.isSupabaseStorageUrl(user.photoURL!)) {
        print('Using Image.network with Supabase Storage URL: ${user.photoURL}');
        return CircleAvatar(
          radius: 28,
          backgroundColor: Colors.brown.shade100,
          child: ClipOval(
            child: Image.network(
              user.photoURL!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.pets, color: Colors.brown.shade700, size: 30);
              },
            ),
          ),
        );
      } else if (user.photoURL!.startsWith('pet_image_')) {
        print('Using LocalImageWidget with key: ${user.photoURL}');
        return CircleAvatar(
          radius: 28,
          backgroundColor: Colors.brown.shade100,
          child: ClipOval(
            child: LocalImageWidget(
              imageKey: user.photoURL!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }
    
    print('Using default icon');
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.brown.shade100,
      child: Icon(Icons.pets, color: Colors.brown.shade700, size: 30),
    );
  }

  ButtonStyle _secondaryBtn() => ElevatedButton.styleFrom(
        backgroundColor: Colors.brown.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}
