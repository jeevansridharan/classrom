// lib/models/classroom_member_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ClassroomMemberModel extends Equatable {
  final String id;
  final String classroomId;
  final String userId;
  final String userHandle;
  final String? userAvatarUrl;
  final String role; // 'STUDENT', 'FACULTY', 'MODERATOR'
  final DateTime joinedAt;

  const ClassroomMemberModel({
    required this.id,
    required this.classroomId,
    required this.userId,
    required this.userHandle,
    this.userAvatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory ClassroomMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassroomMemberModel(
      id: doc.id,
      classroomId: data['classroomId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userHandle: data['userHandle'] as String? ?? 'Member',
      userAvatarUrl: data['userAvatarUrl'] as String?,
      role: data['role'] as String? ?? 'STUDENT',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'classroomId': classroomId,
        'userId': userId,
        'userHandle': userHandle,
        'userAvatarUrl': userAvatarUrl,
        'role': role,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  @override
  List<Object?> get props => [id, classroomId, userId, role, joinedAt];
}
