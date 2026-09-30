// lib/models/classroom_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ClassroomModel extends Equatable {
  final String id;
  final String name;
  final String code; // 6-character join code e.g. "CS101X"
  final String description;
  final String createdBy;
  final String creatorHandle;
  final DateTime createdAt;
  final int memberCount;
  final int questionCount;
  final bool isArchived;

  const ClassroomModel({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.createdBy,
    required this.creatorHandle,
    required this.createdAt,
    this.memberCount = 1,
    this.questionCount = 0,
    this.isArchived = false,
  });

  factory ClassroomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassroomModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled Classroom',
      code: data['code'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      creatorHandle: data['creatorHandle'] as String? ?? 'Faculty',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberCount: data['memberCount'] as int? ?? 1,
      questionCount: data['questionCount'] as int? ?? 0,
      isArchived: data['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'code': code.toUpperCase(),
        'description': description,
        'createdBy': createdBy,
        'creatorHandle': creatorHandle,
        'createdAt': Timestamp.fromDate(createdAt),
        'memberCount': memberCount,
        'questionCount': questionCount,
        'isArchived': isArchived,
      };

  ClassroomModel copyWith({
    String? name,
    String? code,
    String? description,
    int? memberCount,
    int? questionCount,
    bool? isArchived,
  }) =>
      ClassroomModel(
        id: id,
        name: name ?? this.name,
        code: code ?? this.code,
        description: description ?? this.description,
        createdBy: createdBy,
        creatorHandle: creatorHandle,
        createdAt: createdAt,
        memberCount: memberCount ?? this.memberCount,
        questionCount: questionCount ?? this.questionCount,
        isArchived: isArchived ?? this.isArchived,
      );

  @override
  List<Object?> get props => [id, name, code, createdBy, memberCount, questionCount, isArchived];
}
