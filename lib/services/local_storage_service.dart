import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class LocalStorageService {
  static const String _imagePrefix = 'pet_image_';

  /// บันทึกรูปภาพลง local storage (จาก bytes)
  static Future<String?> saveImageBytes({
    required String userId,
    required String petId,
    required String imageKey,
    required Uint8List imageBytes,
    Function(double)? onProgress,
  }) async {
    try {
      print('Starting local image save from bytes...');
      print('User ID: $userId');
      print('Pet ID: $petId');
      print('Image key: $imageKey');
      print('Image size: ${imageBytes.length} bytes');

      if (onProgress != null) onProgress(0.1);

      // สร้าง key ที่แยกตาม user
      final fullKey = '${_imagePrefix}${userId}_${petId}_$imageKey';
      
      if (onProgress != null) onProgress(0.3);

      // บันทึกลง SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(fullKey, base64Encode(imageBytes));
      
      if (onProgress != null) onProgress(0.7);

      if (success) {
        // บันทึก metadata
        final metadata = {
          'userId': userId,
          'petId': petId,
          'size': imageBytes.length,
          'savedAt': DateTime.now().toIso8601String(),
        };
        await prefs.setString('${fullKey}_metadata', jsonEncode(metadata));
        
        if (onProgress != null) onProgress(1.0);
        
        print('Local image saved successfully with key: $fullKey');
        return fullKey;
      } else {
        print('Failed to save image to SharedPreferences');
        return null;
      }
    } catch (e) {
      print('Error saving local image: $e');
      return null;
    }
  }

  /// บันทึกรูปภาพลง local storage
  static Future<String?> saveImage({
    required String userId,
    required String petId,
    required XFile imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      print('Starting local image save...');
      print('User ID: $userId');
      print('Pet ID: $petId');
      print('Image name: ${imageFile.name}');

      // อ่านข้อมูลรูปภาพ
      final bytes = await imageFile.readAsBytes();
      print('Image size: ${bytes.length} bytes');

      // แปลงเป็น base64
      final base64String = base64Encode(bytes);
      print('Base64 length: ${base64String.length}');

      // สร้าง key สำหรับเก็บ
      final key = '${_imagePrefix}${userId}_$petId';
      
      if (kIsWeb) {
        // สำหรับ Web ใช้ SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, base64String);
        print('Image saved to SharedPreferences with key: $key');
      } else {
        // สำหรับ Mobile ใช้ file system
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$key.png');
        await file.writeAsBytes(bytes);
        print('Image saved to file: ${file.path}');
      }

      // บันทึก metadata
      await _saveImageMetadata(key, {
        'userId': userId,
        'petId': petId,
        'originalName': imageFile.name,
        'size': bytes.length,
        'savedAt': DateTime.now().toIso8601String(),
      });

      if (onProgress != null) {
        onProgress(1.0); // เสร็จแล้ว
      }

      return key; // คืนค่า key แทน URL
    } catch (e) {
      print('Error saving image locally: $e');
      return null;
    }
  }

  /// โหลดรูปภาพจาก local storage
  static Future<Uint8List?> loadImage(String key) async {
    try {
      if (kIsWeb) {
        // สำหรับ Web ใช้ SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final base64String = prefs.getString(key);
        if (base64String != null) {
          return base64Decode(base64String);
        }
      } else {
        // สำหรับ Mobile ใช้ file system
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$key.png');
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      return null;
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  /// ลบรูปภาพจาก local storage
  static Future<bool> deleteImage(String key) async {
    try {
      if (kIsWeb) {
        // สำหรับ Web ใช้ SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } else {
        // สำหรับ Mobile ใช้ file system
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$key.png');
        if (await file.exists()) {
          await file.delete();
        }
      }

      // ลบ metadata
      await _deleteImageMetadata(key);
      
      print('Image deleted successfully: $key');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// บันทึก metadata ของรูปภาพ
  static Future<void> _saveImageMetadata(String key, Map<String, dynamic> metadata) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataKey = '${key}_metadata';
      await prefs.setString(metadataKey, jsonEncode(metadata));
    } catch (e) {
      print('Error saving image metadata: $e');
    }
  }

  /// ลบ metadata ของรูปภาพ
  static Future<void> _deleteImageMetadata(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataKey = '${key}_metadata';
      await prefs.remove(metadataKey);
    } catch (e) {
      print('Error deleting image metadata: $e');
    }
  }

  /// ดูรายการรูปภาพทั้งหมด
  static Future<List<String>> getAllImageKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys.where((key) => key.startsWith(_imagePrefix)).toList();
    } catch (e) {
      print('Error getting image keys: $e');
      return [];
    }
  }

  /// ดูข้อมูล metadata ของรูปภาพ
  static Future<Map<String, dynamic>?> getImageMetadata(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataKey = '${key}_metadata';
      final metadataString = prefs.getString(metadataKey);
      if (metadataString != null) {
        return jsonDecode(metadataString);
      }
      return null;
    } catch (e) {
      print('Error getting image metadata: $e');
      return null;
    }
  }

  /// Debug function - ดูรายการรูปภาพทั้งหมดที่เก็บไว้
  static Future<void> debugPrintAllImages() async {
    try {
      print('=== DEBUG: All stored images ===');
      final allKeys = await getAllImageKeys();
      print('Total images found: ${allKeys.length}');
      
      for (final key in allKeys) {
        print('Key: $key');
        final metadata = await getImageMetadata(key);
        if (metadata != null) {
          print('  - User ID: ${metadata['userId']}');
          print('  - Pet ID: ${metadata['petId']}');
          print('  - Size: ${metadata['size']} bytes');
          print('  - Saved at: ${metadata['savedAt']}');
        }
        
        // ตรวจสอบว่าสามารถโหลดได้หรือไม่
        final imageData = await loadImage(key);
        print('  - Can load: ${imageData != null}');
        if (imageData != null) {
          print('  - Data size: ${imageData.length} bytes');
        }
        print('---');
      }
      print('=== END DEBUG ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }
}
