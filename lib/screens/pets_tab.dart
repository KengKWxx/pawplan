import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';
import '../widgets/pet_card.dart';
import '../services/user_service.dart';
import '../l10n/app_localizations.dart';

class PetsTab extends StatelessWidget {
  final User user;
  final VoidCallback onAddPet;

  const PetsTab({
    super.key,
    required this.user,
    required this.onAddPet,
  });

  CollectionReference<Map<String, dynamic>> get _petsCol =>
      FirebaseFirestore.instance.collection('users').doc(user.uid).collection('pets');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _petsCol.orderBy('createdAt').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final pets = snap.data!.docs.map(Pet.fromDoc).toList();
        if (pets.isEmpty) return _emptyState(AppLocalizations.of(context)?.noPetsYet ?? 'No pets yet', AppLocalizations.of(context)?.addPet ?? 'Add Pet', onAddPet);
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
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _showPetMenu(context, pets[i]),
            child: PetCard(pet: pets[i]),
          ),
        );
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

  void _showPetMenu(BuildContext context, Pet pet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star),
              title: Text(AppLocalizations.of(context)?.setAsFavorite ?? 'Set as Favorite'),
              onTap: () async {
                Navigator.pop(ctx);
                await UserService.setFavoritePet(petId: pet.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)?.setAsFavorite ?? 'Set as Favorite'} ✅')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(AppLocalizations.of(context)?.viewHealthDetails ?? 'View Health Details'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('${pet.name} - Health'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        if ((pet.vaccinations ?? '').isNotEmpty) ...[
                            Text(AppLocalizations.of(context)?.vaccinations ?? 'Vaccinations', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(pet.vaccinations!),
                            const SizedBox(height: 8),
                          ],
                          if ((pet.deworming ?? '').isNotEmpty) ...[
                            Text(AppLocalizations.of(context)?.deworming ?? 'Deworming', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(pet.deworming!),
                            const SizedBox(height: 8),
                          ],
                          if ((pet.allergies ?? '').isNotEmpty) ...[
                            Text(AppLocalizations.of(context)?.allergies ?? 'Allergies', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(pet.allergies!),
                          ],
                          if ((pet.vaccinations ?? '').isEmpty && (pet.deworming ?? '').isEmpty && (pet.allergies ?? '').isEmpty)
                            Text(AppLocalizations.of(context)?.noHealthInfoYet ?? 'No health info yet'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)?.close ?? 'Close')),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: Text(AppLocalizations.of(context)?.showQrCode ?? 'Show QR Code'),
              onTap: () async {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed('/pet_qr', arguments: pet);
              },
            ),
          ],
        ),
      ),
    );
  }
}
