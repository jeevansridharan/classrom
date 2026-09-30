// lib/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'new_answer', 'upvote', 'accepted', 'classroom_joined'
  final String referenceId;
  final bool read;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.referenceId,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'system',
      referenceId: data['referenceId'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'referenceId': referenceId,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [id, userId, title, type, referenceId, read, createdAt];
}
