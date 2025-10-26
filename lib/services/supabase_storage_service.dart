import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class SupabaseStorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// อัปโหลดรูปภาพไป Supabase Storage
  static Future<String?> uploadImage({
    required String userId,
    required String petId,
    required XFile imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      print('Starting Supabase Storage upload...');
      print('User ID: $userId');
      print('Pet ID: $petId');
      print('Image name: ${imageFile.name}');

      // สร้าง path สำหรับเก็บรูป (แปลงชื่อไฟล์ให้ไม่มีตัวอักษรไทย)
      final safeFileName = _sanitizeFileName(imageFile.name);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
      final storagePath = 'users/$userId/pets/$petId/$fileName';
      
      // อัปโหลดไฟล์ (ใช้ bytes สำหรับ web)
      final bytes = await imageFile.readAsBytes();
      
      if (onProgress != null) onProgress(0.1);

      // อัปโหลดไป Supabase Storage
      await _supabase.storage.from('pawplan-images').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      if (onProgress != null) onProgress(0.5);
      final publicUrl = _supabase.storage.from('pawplan-images').getPublicUrl(storagePath);

      print('Supabase upload successful: $publicUrl');
      
      if (onProgress != null) onProgress(1.0);

      // ส่งกลับ Supabase URL (สำหรับ sync หลายเครื่อง)
      return publicUrl;
    } catch (e) {
      print('Error uploading to Supabase Storage: $e');
      return null;
    }
  }

  /// อัปโหลดรูปโปรไฟล์ผู้ใช้
  static Future<String?> uploadUserImage({
    required String userId,
    required XFile imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      print('Starting Supabase Storage user image upload...');
      
      // สร้าง path สำหรับเก็บรูปโปรไฟล์ (แปลงชื่อไฟล์ให้ไม่มีตัวอักษรไทย)
      final safeFileName = _sanitizeFileName(imageFile.name);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
      final storagePath = 'users/$userId/profile/$fileName';
      
      // อัปโหลดไฟล์ (ใช้ bytes สำหรับ web)
      final bytes = await imageFile.readAsBytes();
      
      if (onProgress != null) onProgress(0.1);

      // อัปโหลดไป Supabase Storage
      await _supabase.storage.from('pawplan-images').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      if (onProgress != null) onProgress(0.5);
      final publicUrl = _supabase.storage.from('pawplan-images').getPublicUrl(storagePath);

      print('Supabase user image upload successful: $publicUrl');
      
      if (onProgress != null) onProgress(1.0);

      // ส่งกลับ Supabase URL (สำหรับ sync หลายเครื่อง)
      return publicUrl;
    } catch (e) {
      print('Error uploading user image to Supabase Storage: $e');
      return null;
    }
  }

  /// ลบรูปภาพจาก Supabase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // แยก path จาก URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      // Path ใน Supabase Storage จะเริ่มหลังจาก 'public/pawplan-images/'
      final storagePathIndex = pathSegments.indexOf('pawplan-images');
      if (storagePathIndex == -1 || storagePathIndex + 1 >= pathSegments.length) {
        print('Invalid Supabase Storage URL for deletion: $imageUrl');
        return false;
      }
      final filePath = pathSegments.sublist(storagePathIndex + 1).join('/');

      await _supabase.storage.from('pawplan-images').remove([filePath]);
      print('Image deleted from Supabase Storage: $filePath');
      return true;
    } catch (e) {
      print('Error deleting image from Supabase Storage: $e');
      return false;
    }
  }

  /// ตรวจสอบว่าเป็น URL ของ Supabase Storage หรือไม่
  static bool isSupabaseStorageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('supabase.co') && url.contains('storage');
  }

  /// สร้าง URL สำหรับ resize รูปภาพ
  static String getResizedUrl(String originalUrl, {
    int? width,
    int? height,
  }) {
    if (!isSupabaseStorageUrl(originalUrl)) return originalUrl;
    
    // Supabase Storage ไม่มี built-in resize
    // ต้องใช้ client-side resize
    return originalUrl;
  }

  /// แปลงชื่อไฟล์ให้ปลอดภัย (ไม่มีตัวอักษรไทย)
  static String _sanitizeFileName(String fileName) {
    // แปลงตัวอักษรไทยเป็นภาษาอังกฤษ
    String sanitized = fileName
        .replaceAll('สกรีนช็อต', 'screenshot')
        .replaceAll('รูปภาพ', 'image')
        .replaceAll('รูป', 'photo')
        .replaceAll('ไฟล์', 'file');
    
    // ลบตัวอักษรพิเศษและเว้นวรรค
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
    
    // จำกัดความยาว
    if (sanitized.length > 50) {
      final extension = sanitized.split('.').last;
      sanitized = '${sanitized.substring(0, 50 - extension.length - 1)}.$extension';
    }
    
    return sanitized;
  }
}
