import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet.dart';
import '../widgets/app_text_field.dart';
import 'local_storage_service.dart';
import 'supabase_storage_service.dart';

class PetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _petsCol =>
      _firestore.collection('users').doc(_auth.currentUser!.uid).collection('pets');

  static final _breedPresets = <String>[
    // สุนัข
    'Labrador Retriever',
    'Golden Retriever', 
    'German Shepherd',
    'French Bulldog',
    'Bulldog',
    'Poodle',
    'Beagle',
    'Rottweiler',
    'German Shorthaired Pointer',
    'Yorkshire Terrier',
    'Siberian Husky',
    'Dachshund',
    'Boxer',
    'Great Dane',
    'Chihuahua',
    'Shih Tzu',
    'Border Collie',
    'Australian Shepherd',
    'Cocker Spaniel',
    'Boston Terrier',
    'Pomeranian',
    'Jack Russell Terrier',
    'Dalmatian',
    'Maltese',
    'Bichon Frise',
    'Cavalier King Charles Spaniel',
    'Doberman Pinscher',
    'Weimaraner',
    'Mastiff',
    'Saint Bernard',
    'Basset Hound',
    'Bloodhound',
    'Bull Terrier',
    'Staffordshire Bull Terrier',
    'Whippet',
    'Greyhound',
    'Irish Setter',
    'Vizsla',
    'Akita',
    'Shiba Inu',
    'Samoyed',
    'Alaskan Malamute',
    'Chow Chow',
    'Shar Pei',
    'Basenji',
    'Afghan Hound',
    'Saluki',
    'Irish Wolfhound',
    'Scottish Terrier',
    'West Highland White Terrier',
    'Cairn Terrier',
    'Norfolk Terrier',
    'Norwich Terrier',
    'Airedale Terrier',
    'Welsh Terrier',
    'Lakeland Terrier',
    'Border Terrier',
    'Bedlington Terrier',
    'Kerry Blue Terrier',
    'Soft Coated Wheaten Terrier',
    'Irish Terrier',
    'Welsh Springer Spaniel',
    'English Springer Spaniel',
    'Field Spaniel',
    'Clumber Spaniel',
    'Sussex Spaniel',
    'American Cocker Spaniel',
    'English Cocker Spaniel',
    'Brittany',
    'Pointer',
    'Setter',
    'Retriever',
    'Spaniel',
    'Terrier',
    'Hound',
    'Working Dog',
    'Herding Dog',
    'Toy Dog',
    'Sporting Dog',
    'Non-Sporting Dog',
    'Mixed Breed',
    
    // แมว
    'Persian',
    'Maine Coon',
    'British Shorthair',
    'Ragdoll',
    'Siamese',
    'American Shorthair',
    'Abyssinian',
    'Scottish Fold',
    'Sphynx',
    'Devon Rex',
    'Cornish Rex',
    'Russian Blue',
    'Norwegian Forest Cat',
    'Siberian',
    'Birman',
    'Oriental Shorthair',
    'Tonkinese',
    'Burmese',
    'Bombay',
    'Manx',
    'American Curl',
    'Japanese Bobtail',
    'Munchkin',
    'Himalayan',
    'Exotic Shorthair',
    'Selkirk Rex',
    'LaPerm',
    'Peterbald',
    'Bengal',
    'Savannah',
    'Ocicat',
    'Egyptian Mau',
    'Chartreux',
    'Korat',
    'Singapura',
    'Balinese',
    'Javanese',
    'Havana Brown',
    'Somali',
    'Turkish Angora',
    'Turkish Van',
    'American Bobtail',
    'Pixie-bob',
    'Highland Fold',
    'Mixed Breed Cat',
    
    // สัตว์เลี้ยงอื่นๆ
    'Hamster',
    'Guinea Pig',
    'Rabbit',
    'Parrot',
    'Canary',
    'Finch',
    'Cockatiel',
    'Lovebird',
    'Budgerigar',
    'Cockatoo',
    'Macaw',
    'African Grey Parrot',
    'Amazon Parrot',
    'Conure',
    'Quaker Parrot',
    'Sun Conure',
    'Green Cheek Conure',
    'Blue and Gold Macaw',
    'Scarlet Macaw',
    'Umbrella Cockatoo',
    'Sulphur-crested Cockatoo',
    'Galah Cockatoo',
    'Eclectus Parrot',
    'Indian Ringneck Parakeet',
    'Alexandrine Parakeet',
    'Monk Parakeet',
    'Lineolated Parakeet',
    'Bourke\'s Parakeet',
    'Turquoise Parakeet',
    'Splendid Parakeet',
    'Scarlet-chested Parakeet',
    'Red-rumped Parakeet',
    'Bourke\'s Parakeet',
    'Turquoise Parakeet',
    'Splendid Parakeet',
    'Scarlet-chested Parakeet',
    'Red-rumped Parakeet',
    'Other'
  ];

  // แยกสายพันธุ์ตามประเภทหลัก เพื่อให้กรองตามที่เลือกได้สะดวก
  static final List<String> _dogBreeds = <String>[
    'Labrador Retriever',
    'Golden Retriever',
    'German Shepherd',
    'French Bulldog',
    'Bulldog',
    'Poodle',
    'Beagle',
    'Rottweiler',
    'German Shorthaired Pointer',
    'Yorkshire Terrier',
    'Siberian Husky',
    'Dachshund',
    'Boxer',
    'Great Dane',
    'Chihuahua',
    'Shih Tzu',
    'Border Collie',
    'Australian Shepherd',
    'Cocker Spaniel',
    'Boston Terrier',
    'Pomeranian',
    'Jack Russell Terrier',
    'Dalmatian',
    'Maltese',
    'Bichon Frise',
    'Cavalier King Charles Spaniel',
    'Doberman Pinscher',
    'Weimaraner',
    'Mastiff',
    'Saint Bernard',
    'Basset Hound',
    'Bloodhound',
    'Bull Terrier',
    'Staffordshire Bull Terrier',
    'Whippet',
    'Greyhound',
    'Irish Setter',
    'Vizsla',
    'Akita',
    'Shiba Inu',
    'Samoyed',
    'Alaskan Malamute',
    'Chow Chow',
    'Shar Pei',
    'Basenji',
    'Afghan Hound',
    'Saluki',
    'Irish Wolfhound',
    'Scottish Terrier',
    'West Highland White Terrier',
    'Cairn Terrier',
    'Norfolk Terrier',
    'Norwich Terrier',
    'Airedale Terrier',
    'Welsh Terrier',
    'Lakeland Terrier',
    'Border Terrier',
    'Bedlington Terrier',
    'Kerry Blue Terrier',
    'Soft Coated Wheaten Terrier',
    'Irish Terrier',
    'Welsh Springer Spaniel',
    'English Springer Spaniel',
    'Field Spaniel',
    'Clumber Spaniel',
    'Sussex Spaniel',
    'American Cocker Spaniel',
    'English Cocker Spaniel',
    'Brittany',
    'Pointer',
    'Setter',
    'Retriever',
    'Spaniel',
    'Terrier',
    'Hound',
    'Working Dog',
    'Herding Dog',
    'Toy Dog',
    'Sporting Dog',
    'Non-Sporting Dog',
    'Mixed Breed',
  ];

  static final List<String> _catBreeds = <String>[
    'Persian',
    'Maine Coon',
    'British Shorthair',
    'Ragdoll',
    'Siamese',
    'American Shorthair',
    'Abyssinian',
    'Scottish Fold',
    'Sphynx',
    'Devon Rex',
    'Cornish Rex',
    'Russian Blue',
    'Norwegian Forest Cat',
    'Siberian',
    'Birman',
    'Oriental Shorthair',
    'Tonkinese',
    'Burmese',
    'Bombay',
    'Manx',
    'American Curl',
    'Japanese Bobtail',
    'Munchkin',
    'Himalayan',
    'Exotic Shorthair',
    'Selkirk Rex',
    'LaPerm',
    'Peterbald',
    'Bengal',
    'Savannah',
    'Ocicat',
    'Egyptian Mau',
    'Chartreux',
    'Korat',
    'Singapura',
    'Balinese',
    'Javanese',
    'Havana Brown',
    'Somali',
    'Turkish Angora',
    'Turkish Van',
    'American Bobtail',
    'Pixie-bob',
    'Highland Fold',
    'Mixed Breed Cat',
  ];


  /// แสดง dialog เพิ่มสัตว์เลี้ยง
  static Future<void> showAddPetDialog(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = TextEditingController();
    final desc = TextEditingController();
    final color = TextEditingController();
    final otherBreed = TextEditingController();
    final otherSpecies = TextEditingController();
    final vaccinations = TextEditingController();
    final deworming = TextEditingController();
    final allergies = TextEditingController();
    final Set<String> selectedVaccines = {}; // เก็บตัวเลือกวัคซีนที่ติ๊ก
    final Set<String> selectedParasites = {}; // เก็บตัวเลือกถ่ายพยาธิ/ป้องกัน
    final Set<String> selectedAllergies = {}; // เก็บตัวเลือกอาการแพ้
    final breedSearchController = TextEditingController();
    String species = 'สุนัข'; // สุนัข/แมว/อื่นๆ
    String? breed = _breedPresets.first;
    String? sex;
    DateTime? birthDate;
    XFile? picked;
    bool uploading = false;
    double progress = 0;
    List<String> filteredBreeds = List.from(_dogBreeds);

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
                const Text('เพิ่มสัตว์เลี้ยง'),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // เลือกประเภทสัตว์ก่อน
                    DropdownButtonFormField<String>(
                      value: species,
                      decoration: const InputDecoration(labelText: 'ประเภทสัตว์'),
                      items: const [
                        DropdownMenuItem(value: 'สุนัข', child: Text('สุนัข')),
                        DropdownMenuItem(value: 'แมว', child: Text('แมว')),
                        DropdownMenuItem(value: 'อื่นๆ', child: Text('อื่นๆ')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() {
                          species = v;
                          if (v == 'สุนัข') {
                            filteredBreeds = List.from(_dogBreeds);
                          } else if (v == 'แมว') {
                            filteredBreeds = List.from(_catBreeds);
                          } else {
                            filteredBreeds = [];
                          }
                          breed = filteredBreeds.isNotEmpty ? filteredBreeds.first : null;
                          breedSearchController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: uploading
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final x = await picker.pickImage(
                                source: ImageSource.gallery, 
                                imageQuality: 75
                              );
                              if (x != null) {
                                print('Image picked: ${x.name}');
                                // ไม่มีการ crop แล้ว ส่งคืนรูปภาพต้นฉบับ
                                setLocal(() => picked = x);
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
                        child: picked == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.brown.shade400),
                                  const SizedBox(height: 6),
                                  Text("แตะเพื่อเพิ่มรูป", style: TextStyle(color: Colors.brown.shade400)),
                                ],
                              )
                            : FutureBuilder<Uint8List>(
                                future: picked!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Container(
                                      decoration: BoxDecoration(
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
                    const SizedBox(height: 16),
                    AppTextField(label: 'ชื่อ', controller: name),
                    AppTextField(label: 'คำอธิบาย', controller: desc, maxLines: 3),
                    
                    // ค้นหาสายพันธุ์ตามประเภทที่เลือก
                    TextField(
                      controller: breedSearchController,
                      decoration: InputDecoration(
                        labelText: 'ค้นหาสายพันธุ์',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: breedSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  breedSearchController.clear();
                                  setLocal(() {
                                    if (species == 'สุนัข') {
                                      filteredBreeds = List.from(_dogBreeds);
                                    } else if (species == 'แมว') {
                                      filteredBreeds = List.from(_catBreeds);
                                    } else {
                                      filteredBreeds = [];
                                    }
                                    breed = filteredBreeds.isNotEmpty ? filteredBreeds.first : null;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setLocal(() {
                          final list = species == 'สุนัข'
                              ? _dogBreeds
                              : species == 'แมว'
                                  ? _catBreeds
                                  : <String>[];
                          filteredBreeds = list
                              .where((b) => b.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                          breed = filteredBreeds.isNotEmpty ? filteredBreeds.first : null;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Breed dropdown
                    DropdownButtonFormField<String>(
                      value: breed,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'สายพันธุ์'),
                      items: filteredBreeds
                          .map((b) => DropdownMenuItem<String>(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (v) => setLocal(() => breed = v),
                    ),
                    if (species == 'อื่นๆ') ...[
                      AppTextField(label: 'ระบุประเภทสัตว์', controller: otherSpecies),
                      AppTextField(label: 'กำหนดสายพันธุ์เอง', controller: otherBreed),
                    ],
                    
                    // Birth Date picker
                    InkWell(
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: birthDate ?? DateTime.now().subtract(const Duration(days: 365)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          setLocal(() => birthDate = selectedDate);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.brown.shade400),
                            const SizedBox(width: 12),
                            Text(
                              birthDate != null 
                                  ? '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}'
                                  : 'เลือกวันเกิด',
                              style: TextStyle(
                                color: birthDate != null ? Colors.black : Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ),
                    if (birthDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Age: ${_calculateAge(birthDate!)}',
                        style: TextStyle(
                          color: Colors.brown.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    // Sex dropdown (only Male/Female)
                    DropdownButtonFormField<String>(
                      value: sex,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'เพศ',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        DropdownMenuItem(value: 'Male', child: Text('เพศผู้')),
                        DropdownMenuItem(value: 'Female', child: Text('เพศเมีย')),
                      ],
                      onChanged: (v) => setLocal(() => sex = v),
                    ),
                    const SizedBox(height: 12),
                    // Color selection with chips
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('สี', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.brown.shade700)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'น้ำตาล', 'ดำ', 'ขาว', 'เทา', 'ทอง', 'แดง', 'ครีม', 'ลาย', 'อื่นๆ'
                      ].map((colorOption) => ChoiceChip(
                        label: Text(colorOption),
                        selected: color.text == colorOption,
                        onSelected: (selected) {
                          setLocal(() {
                            if (selected) {
                              color.text = colorOption;
                            } else {
                              color.clear();
                            }
                          });
                        },
                        selectedColor: Colors.brown.shade100,
                        checkmarkColor: Colors.brown.shade700,
                      )).toList(),
                    ),
                    if (color.text == 'อื่นๆ') ...[
                      const SizedBox(height: 8),
                      AppTextField(label: 'ระบุสีเอง', controller: color),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('ข้อมูลสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
                    ),
                    const SizedBox(height: 8),
                    // วัคซีนตามประเภทสัตว์ (ติ๊กได้หลายรายการ)
                    ExpansionTile(
                      title: const Text('วัคซีนที่ได้รับ'),
                      children: [
                        ...(
                          species == 'แมว'
                              ? [
                                  'พิษสุนัขบ้า (Rabies)',
                                  'FVRCP (ไข้หวัด/ตาอักเสบ/ลำไส้อักเสบ)',
                                  'FeLV (ลิวคีเมียในแมว)'
                                ]
                              : [
                                  'พิษสุนัขบ้า (Rabies)',
                                  'DHPP (หัดสุนัข/ตับอักเสบ/พาร์โว/พาราอินฟลูเอนซา)',
                                  'เลปโตสไปโรซิส (Leptospirosis)',
                                  'บอร์เดเทลลา (ไอกรนสุนัข)'
                                ]
                        ).map((v) => CheckboxListTile(
                              value: selectedVaccines.contains(v),
                              onChanged: (val) {
                                setLocal(() {
                                  if (val == true) {
                                    selectedVaccines.add(v);
                                  } else {
                                    selectedVaccines.remove(v);
                                  }
                                  vaccinations.text = selectedVaccines.join(', ');
                                });
                              },
                              title: Text(v),
                            )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: AppTextField(label: 'เพิ่มระบุเอง', controller: vaccinations, maxLines: 2),
                        ),
                      ],
                    ),
                    // ถ่ายพยาธิ/ป้องกัน
                    ExpansionTile(
                      title: const Text('ถ่ายพยาธิ/ป้องกัน'),
                      children: [
                        ...[
                          'ถ่ายพยาธิลำไส้',
                          'ป้องกันพยาธิหนอนหัวใจ (Heartworm)',
                          'ป้องกันหมัด/เห็บ (Flea/Tick)'
                        ].map((p) => CheckboxListTile(
                              value: selectedParasites.contains(p),
                              onChanged: (val) {
                                setLocal(() {
                                  if (val == true) {
                                    selectedParasites.add(p);
                                  } else {
                                    selectedParasites.remove(p);
                                  }
                                  deworming.text = selectedParasites.join(', ');
                                });
                              },
                              title: Text(p),
                            )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: AppTextField(label: 'เพิ่มระบุเอง', controller: deworming, maxLines: 2),
                        ),
                      ],
                    ),
                    // แพ้อะไรบ้าง
                    ExpansionTile(
                      title: const Text('แพ้'),
                      children: [
                        ...['ไก่', 'เนื้อวัว', 'ปลา', 'นม', 'ละอองเกสร'].map((a) => CheckboxListTile(
                              value: selectedAllergies.contains(a),
                              onChanged: (val) {
                                setLocal(() {
                                  if (val == true) {
                                    selectedAllergies.add(a);
                                  } else {
                                    selectedAllergies.remove(a);
                                  }
                                  allergies.text = selectedAllergies.join(', ');
                                });
                              },
                              title: Text(a),
                            )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: AppTextField(label: 'เพิ่มระบุเอง', controller: allergies, maxLines: 2),
                        ),
                      ],
                    ),
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
              TextButton(onPressed: uploading ? null : () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
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
                        if (birthDate == null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Please select birth date')));
                          return;
                        }
                        if (sex == null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('โปรดเลือกเพศ')));
                          return;
                        }
                        if (species == 'อื่นๆ' && otherSpecies.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('โปรดระบุประเภทสัตว์')));
                          return;
                        }
                        setLocal(() => uploading = true);
                        final petId = _firestore.collection('_tmp').doc().id;
                        String? photoUrl;
                        try {
                          if (picked != null) {
                            // ใช้ Supabase Storage
                            photoUrl = await SupabaseStorageService.uploadImage(
                              userId: user.uid,
                              petId: petId,
                              imageFile: picked!,
                              onProgress: (p) => setLocal(() => progress = p),
                            );
                            print('Supabase Storage upload result: $photoUrl');
                          }
                          await _petsCol.doc(petId).set({
                            'name': name.text.trim(),
                            'species': species == 'อื่นๆ' ? otherSpecies.text.trim() : species,
                            'breed': breed == 'Other' ? otherBreed.text.trim() : breed,
                            'birthDate': birthDate!.toIso8601String(),
                            'age': _calculateAge(birthDate!),
                            'sex': sex,
                            'color': color.text.trim(),
                            'desc': desc.text.trim(),
                            'vaccinations': vaccinations.text.trim(),
                            'deworming': deworming.text.trim(),
                            'allergies': allergies.text.trim(),
                            'owner': user.displayName ?? user.email ?? 'User',
                            'photoUrl': photoUrl,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Pet added ✅')));
                          }
                        } catch (e) {
                          setLocal(() => uploading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Add pet failed: $e')));
                          }
                        }
                      },
                child: const Text('เพิ่ม'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// คำนวณอายุจากวันเกิด
  static String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      return '$days day${days > 1 ? 's' : ''}';
    }
  }

  /// ลบสัตว์เลี้ยง
  static Future<void> deletePet(Pet pet) async {
    try {
      // ลบ tasks ที่เกี่ยวข้อง
      final tasksSnap = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('tasks')
          .where('petId', isEqualTo: pet.id)
          .get();
      
      for (final taskDoc in tasksSnap.docs) {
        await taskDoc.reference.delete();
      }

      // ลบรูปภาพจาก Supabase Storage
      if (pet.photoUrl != null && pet.photoUrl!.isNotEmpty) {
        if (SupabaseStorageService.isSupabaseStorageUrl(pet.photoUrl!)) {
          await SupabaseStorageService.deleteImage(pet.photoUrl!);
        } else {
          // ถ้าเป็น local storage ให้ลบด้วย
          await LocalStorageService.deleteImage(pet.photoUrl!);
        }
      }

      // ลบข้อมูลสัตว์เลี้ยง
      await _petsCol.doc(pet.id).delete();
    } catch (e) {
      print('Error deleting pet: $e');
      rethrow;
    }
  }

  /// แก้ไขข้อมูลสัตว์เลี้ยง
  static Future<void> showEditPetDialog(BuildContext context, Pet pet) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = TextEditingController(text: pet.name);
    final color = TextEditingController(text: pet.color);
    final desc = TextEditingController(text: pet.desc);
    final vaccinations = TextEditingController(text: pet.vaccinations ?? '');
    final deworming = TextEditingController(text: pet.deworming ?? '');
    final allergies = TextEditingController(text: pet.allergies ?? '');
    String? sex = pet.sex.isNotEmpty ? pet.sex : null;
    String breed = pet.breed;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: 'Name', controller: name),
                AppTextField(label: 'Description', controller: desc, maxLines: 3),
                DropdownButtonFormField<String>(
                  value: sex,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Sex'),
                  items: ['Male', 'Female']
                      .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setLocal(() => sex = v),
                ),
                const SizedBox(height: 8),
                AppTextField(label: 'Breed', controller: TextEditingController(text: breed)),
                AppTextField(label: 'Color', controller: color),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ข้อมูลสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
                ),
                const SizedBox(height: 8),
                AppTextField(label: 'การฉีดวัคซีน (พิมพ์เพิ่มเติมได้)', controller: vaccinations, maxLines: 2),
                AppTextField(label: 'การถ่ายพยาธิ/ป้องกัน (พิมพ์เพิ่มเติมได้)', controller: deworming, maxLines: 2),
                AppTextField(label: 'อาการแพ้', controller: allergies, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await _petsCol.doc(pet.id).update({
                  'name': name.text.trim(),
                  'desc': desc.text.trim(),
                  'sex': sex,
                  'color': color.text.trim(),
                  'vaccinations': vaccinations.text.trim(),
                  'deworming': deworming.text.trim(),
                  'allergies': allergies.text.trim(),
                });
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Pet updated ✅')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
