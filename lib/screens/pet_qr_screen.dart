import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../models/pet.dart';
import '../l10n/app_localizations.dart';

class PetQrScreen extends StatelessWidget {
  final Pet pet;
  const PetQrScreen({super.key, required this.pet});

  Future<Map<String, dynamic>> _loadOwner(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.petQrCode ?? 'Pet QR Code'),
        actions: [
          // Temporarily disabled due to incompatible image_gallery_saver plugin with AGP 8
          // IconButton(
          //   tooltip: AppLocalizations.of(context)?.save ?? 'Save',
          //   icon: const Icon(Icons.download),
          //   onPressed: () async {
          //     final data = await QrPainter(
          //       data: [
          //         'PawPlan',
          //         'Pet:',
          //         '- Name: ${pet.name}',
          //         '- สายพันธุ์: ${pet.breed}',
          //         '- เพศ: ${pet.sex}',
          //         '- Color: ${pet.color}',
          //         if ((pet.vaccinations ?? '').isNotEmpty) '- Vaccinations: ${pet.vaccinations}',
          //         if ((pet.deworming ?? '').isNotEmpty) '- Deworming: ${pet.deworming}',
          //         if ((pet.allergies ?? '').isNotEmpty) '- Allergies: ${pet.allergies}',
          //         if (pet.desc.isNotEmpty) '- Note: ${pet.desc}',
          //       ].join('\n'),
          //       version: QrVersions.auto,
          //       color: Colors.black,
          //       emptyColor: Colors.white,
          //       gapless: true,
          //     ).toImageData(1024, format: ui.ImageByteFormat.png);
          //     if (data != null && context.mounted) {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(content: Text(AppLocalizations.of(context)?.save ?? 'Saved QR to gallery')),
          //       );
          //     }
          //   },
          // ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: user == null ? Future.value(<String, dynamic>{}) : _loadOwner(user.uid),
        builder: (context, ownerSnap) {
          if (user == null) {
            return Center(child: Text(AppLocalizations.of(context)?.pleaseLogin ?? 'Please login'));
          }
          if (ownerSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final owner = ownerSnap.data ?? const <String, dynamic>{};
          final ownerEmail = (owner['email'] ?? user.email ?? '') as String;
          final ownerPhone = (owner['phone'] ?? '') as String;
          final ownerAddress = (owner['address'] ?? '') as String;

          // ปรับเป็นข้อความอ่านง่าย (ไม่ใช่ JSON) เพื่อให้กล้องทั่วไปแสดงเป็นข้อความ
          // แสดงแบบปกติ (ไม่ดัดแปลง) ให้คนอ่านง่าย
          final displayEmail = ownerEmail;
          final displayPhone = ownerPhone;

          final String qrData = [
            'PawPlan',
            'Pet:',
            '- Name: ${pet.name}',
            '- สายพันธุ์: ${pet.breed}',
            '- เพศ: ${pet.sex}',
            '- Color: ${pet.color}',
            if ((pet.vaccinations ?? '').isNotEmpty) '- Vaccinations: ${pet.vaccinations}',
            if ((pet.deworming ?? '').isNotEmpty) '- Deworming: ${pet.deworming}',
            if ((pet.allergies ?? '').isNotEmpty) '- Allergies: ${pet.allergies}',
            if (pet.desc.isNotEmpty) '- Note: ${pet.desc}',
            'Owner:',
            '- Email: $displayEmail',
            if (ownerPhone.isNotEmpty) '- Phone: $displayPhone',
            if (ownerAddress.isNotEmpty) '- Address: $ownerAddress',
          ].join('\n');

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                      ],
                    ),
                    child: FutureBuilder<ByteData?>(
                      future: QrPainter(
                        data: qrData,
                        version: QrVersions.auto,
                        color: Colors.black,
                        emptyColor: Colors.white,
                        gapless: true,
                      ).toImageData(240, format: ui.ImageByteFormat.png),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const SizedBox(width: 240, height: 240, child: Center(child: CircularProgressIndicator()));
                        }
                        final bytes = snap.data!.buffer.asUint8List();
                        return Image.memory(bytes, width: 240, height: 240);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(pet.breed),
                  const SizedBox(height: 24),
                  Text(
                    'สแกนด้วยกล้องมือถือทั่วไป จะได้ข้อมูลของสัตว์และเจ้าของในรูปแบบข้อความ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.brown.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
