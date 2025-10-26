import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'local_storage_service.dart';
import 'supabase_storage_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  /// อัปเดตข้อมูล User
  static Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    String? phone,
    String? address,
    String? favoritePetId,
  }) async {
    try {
      await _usersCol.doc(uid).set({
        'uid': uid,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'phone': phone,
        'address': address,
        'favoritePetId': favoritePetId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // อัปเดต Firebase Auth profile
      if (displayName != null) {
        await _auth.currentUser?.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await _auth.currentUser?.updatePhotoURL(photoUrl);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// บันทึกรูปภาพโปรไฟล์ผู้ใช้ลง Local Storage
  static Future<String?> saveUserImage({
    required String userId,
    required XFile imageFile,
    Function(double)? onProgress,
  }) async {
    return await LocalStorageService.saveImage(
      userId: userId,
      petId: userId, // petId เป็น userId สำหรับรูปโปรไฟล์
      imageFile: imageFile,
      onProgress: onProgress,
    );
  }

  /// ฟังก์ชัน crop รูปภาพ (ตอนนี้จะส่งคืนรูปภาพต้นฉบับโดยตรง)
  static Future<XFile?> cropImage(XFile imageFile, {required BuildContext context}) async {
    // เนื่องจากผู้ใช้ต้องการตัดฟังก์ชัน crop ออกไป
    // เราจะส่งคืนรูปภาพต้นฉบับโดยตรง
    print('Crop function skipped. Returning original image.');
    return imageFile;
  }


  /// แสดง dialog แก้ไขโปรไฟล์ผู้ใช้
  static Future<void> editUserProfileDialog(BuildContext context, User user) async {
    final nameController = TextEditingController(text: user.displayName ?? '');
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    // Prefill from Firestore if available
    try {
      final doc = await _usersCol.doc(user.uid).get();
      final data = doc.data() ?? {};
      final phone = (data['phone'] ?? '') as String;
      final address = (data['address'] ?? '') as String;
      phoneController.text = phone;
      addressController.text = address;
    } catch (_) {}
    XFile? pickedImage;
    double uploadProgress = 0;
    bool uploading = false;

    await showDialog(
      context: context,
      barrierDismissible: !uploading,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            title: Row(
              children: [
                Icon(Icons.person, color: Colors.brown.shade400),
                const SizedBox(width: 8),
                const Text('Edit Profile'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: uploading
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final x = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 75,
                            );
                            if (x != null) {
                              // ไม่มีการ crop แล้ว ส่งคืนรูปภาพต้นฉบับ
                              setLocal(() => pickedImage = x);
                            }
                          },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.brown.shade200),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.brown.shade50,
                      ),
                      child: pickedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.brown.shade400),
                                const SizedBox(height: 6),
                                Text("Tap to add photo",
                                    style: TextStyle(color: Colors.brown.shade400)),
                              ],
                            )
                          : FutureBuilder<Uint8List>(
                              future: pickedImage!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image: MemoryImage(snapshot.data!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                } else {
                                  return Container(
                                    color: Colors.brown.shade50,
                                    child: Center(
                                      child: CircularProgressIndicator(color: Colors.brown.shade400),
                                    ),
                                  );
                                }
                              },
                            ),
                    ),
                  ),
                  if (uploading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(value: uploadProgress),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: uploading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: uploading
                    ? null
                    : () async {
                        setLocal(() => uploading = true);
                        String? photoUrl;
                        try {
                          if (pickedImage != null) {
                            // ใช้ Supabase Storage
                            photoUrl = await SupabaseStorageService.uploadUserImage(
                              userId: user.uid,
                              imageFile: pickedImage!,
                              onProgress: (p) => setLocal(() => uploadProgress = p),
                            );
                            print('User photo uploaded to Supabase Storage: $photoUrl');
                          }

                          // Update Firebase Auth profile
                          await user.updateDisplayName(nameController.text.trim());
                          if (photoUrl != null) {
                            await user.updatePhotoURL(photoUrl);
                          }
                          await user.reload(); // Reload user to get updated data

                          // Update Firestore user document
                          await _usersCol.doc(user.uid).set(
                            UserModel(
                              uid: user.uid,
                              email: user.email ?? '',
                              displayName: user.displayName,
                              photoUrl: user.photoURL,
                              phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                              address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                            ).toMap(),
                            SetOptions(merge: true),
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Profile updated ✅')));
                          }
                        } catch (e) {
                          setLocal(() => uploading = false);
                          if (context.mounted) {
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

  /// ตั้งค่าสัตว์เลี้ยงตัวโปรด
  static Future<void> setFavoritePet({required String petId}) async {
    final u = _auth.currentUser;
    if (u == null) return;
    await _usersCol.doc(u.uid).set({'favoritePetId': petId, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
}
