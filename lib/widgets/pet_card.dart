import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../services/supabase_storage_service.dart';
import 'local_image_widget.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PetCard({
    super.key,
    required this.pet,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildImageWidget(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16, color: Colors.brown),
                        tooltip: 'Edit',
                        onPressed: () => PetService.showEditPetDialog(context, pet),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pet.breed}, ${pet.age}${pet.sex.isNotEmpty ? ', ${pet.sex}' : ''}${pet.color.isNotEmpty ? ', ${pet.color}' : ''}',
                    style: TextStyle(fontSize: 10, color: Colors.brown.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pet.desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      pet.desc,
                      style: TextStyle(fontSize: 11, color: Colors.brown.shade800),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยัน'),
        content: const Text('ลบสัตว์เลี้ยงนี้หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await PetService.deletePet(pet);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('ลบสัตว์เลี้ยงแล้ว ✅')));
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

  Widget _buildImageWidget() {
    // Debug: แสดงข้อมูล photoUrl
    print('Pet: ${pet.name}, PhotoUrl: ${pet.photoUrl}');
    
    // ตรวจสอบว่ามี photoUrl และไม่ใช่ค่าว่าง
    if (pet.photoUrl != null && pet.photoUrl!.isNotEmpty) {
      if (SupabaseStorageService.isSupabaseStorageUrl(pet.photoUrl!)) {
        print('Using Image.network for Supabase Storage URL: ${pet.photoUrl}');
        return Image.network(
          pet.photoUrl!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.brown.shade50,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 42, color: Colors.brown.shade300),
                  const SizedBox(height: 4),
                  Text(
                    'No photo',
                    style: TextStyle(fontSize: 10, color: Colors.brown.shade500),
                  ),
                ],
              ),
            );
          },
        );
      } else if (pet.photoUrl!.startsWith('pet_image_')) {
        print('Using LocalImageWidget for key: ${pet.photoUrl}');
        return LocalImageWidget(
          imageKey: pet.photoUrl!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }
    
    print('No photoUrl, showing default icon');
    // ไม่มีรูปภาพ แสดงไอคอน default
    return Container(
      color: Colors.brown.shade50,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 42, color: Colors.brown.shade300),
          const SizedBox(height: 4),
          Text(
            'No photo',
            style: TextStyle(fontSize: 10, color: Colors.brown.shade500),
          ),
        ],
      ),
    );
  }


  // Removed unused fallback widget

  
}
