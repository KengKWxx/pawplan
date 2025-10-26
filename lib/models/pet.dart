import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final String breed;
  final String age;
  final String sex;
  final String color;
  final String desc;
  final String? photoUrl;
  // Health info (simple text for MVP; can be structured later)
  final String? vaccinations; // e.g., Rabies 2024-10-01; DHPP 2025-01-01
  final String? deworming; // e.g., Drontal 2025-02-01 every 3 months
  final String? allergies; // e.g., Chicken, Pollen

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.sex,
    required this.color,
    required this.desc,
    this.photoUrl,
    this.vaccinations,
    this.deworming,
    this.allergies,
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
      desc: d['desc'] ?? '',
      photoUrl: d['photoUrl'],
      vaccinations: d['vaccinations'],
      deworming: d['deworming'],
      allergies: d['allergies'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'age': age,
      'sex': sex,
      'color': color,
      'desc': desc,
      'photoUrl': photoUrl,
      'vaccinations': vaccinations,
      'deworming': deworming,
      'allergies': allergies,
    };
  }
}
