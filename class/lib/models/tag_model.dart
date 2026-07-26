// lib/models/tag_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TagModel extends Equatable {
  final String name;
  final int questionCount;

  const TagModel({
    required this.name,
    required this.questionCount,
  });

  factory TagModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TagModel(
      name: doc.id,
      questionCount: data['questionCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'questionCount': questionCount,
      };

  @override
  List<Object?> get props => [name, questionCount];
}

// ─── Preset popular academic tags ────────────────────────────────────────────
const kPresetTags = [
  'Mathematics',
  'Physics',
  'Chemistry',
  'Biology',
  'Computer Science',
  'Data Structures',
  'Algorithms',
  'Machine Learning',
  'Linear Algebra',
  'Calculus',
  'Statistics',
  'Economics',
  'English',
  'History',
  'Mechanics',
  'Thermodynamics',
  'Circuits',
  'Signals & Systems',
  'DBMS',
  'Operating Systems',
];
