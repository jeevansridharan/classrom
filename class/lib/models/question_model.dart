// lib/models/question_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class QuestionModel extends Equatable {
  final String id;
  final String? authorUid;
  final String title;
  final String body;
  final List<String> tags;
  final String? imageUrl;
  final int voteCount;
  final int viewCount;
  final int answerCount;
  final bool isResolved;
  final String? classroomId;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Author handle (pseudonym) — displayed in UI instead of real name for privacy
  final String? authorHandle;
  final String? authorAvatarUrl;

  // Current user's vote: 1, -1, or 0 (null)
  final int? currentUserVote;

  const QuestionModel({
    required this.id,
    this.authorUid,
    required this.title,
    required this.body,
    required this.tags,
    this.imageUrl,
    required this.voteCount,
    required this.viewCount,
    required this.answerCount,
    required this.isResolved,
    this.classroomId,
    this.category = 'General',
    required this.createdAt,
    required this.updatedAt,
    this.authorHandle,
    this.authorAvatarUrl,
    this.currentUserVote,
  });

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id: doc.id,
      authorUid: data['authorUid'] as String?,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      tags: List<String>.from(data['tags'] as List? ?? []),
      imageUrl: data['imageUrl'] as String?,
      voteCount: data['voteCount'] as int? ?? 0,
      viewCount: data['viewCount'] as int? ?? 0,
      answerCount: data['answerCount'] as int? ?? 0,
      isResolved: data['isResolved'] as bool? ?? false,
      classroomId: data['classroomId'] as String?,
      category: data['category'] as String? ?? 'General',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorHandle: data['authorHandle'] as String?,
    );
  }

  Map<String, dynamic> toMap({required String authorUid}) => {
        'authorUid': authorUid,
        'authorHandle': authorHandle ?? 'Anonymous',
        'title': title,
        'body': body,
        'tags': tags,
        'imageUrl': imageUrl,
        'voteCount': 0,
        'viewCount': 0,
        'answerCount': 0,
        'isResolved': false,
        'classroomId': classroomId,
        'category': category,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  QuestionModel copyWith({
    String? authorUid,
    String? title,
    String? body,
    List<String>? tags,
    String? imageUrl,
    int? voteCount,
    int? viewCount,
    int? answerCount,
    bool? isResolved,
    String? classroomId,
    String? category,
    String? authorHandle,
    String? authorAvatarUrl,
    int? currentUserVote,
  }) =>
      QuestionModel(
        id: id,
        authorUid: authorUid ?? this.authorUid,
        title: title ?? this.title,
        body: body ?? this.body,
        tags: tags ?? this.tags,
        imageUrl: imageUrl ?? this.imageUrl,
        voteCount: voteCount ?? this.voteCount,
        viewCount: viewCount ?? this.viewCount,
        answerCount: answerCount ?? this.answerCount,
        isResolved: isResolved ?? this.isResolved,
        classroomId: classroomId ?? this.classroomId,
        category: category ?? this.category,
        createdAt: createdAt,
        updatedAt: updatedAt,
        authorHandle: authorHandle ?? this.authorHandle,
        authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
        currentUserVote: currentUserVote ?? this.currentUserVote,
      );

  @override
  List<Object?> get props => [
        id,
        authorUid,
        title,
        voteCount,
        answerCount,
        isResolved,
        classroomId,
        category,
      ];
}
