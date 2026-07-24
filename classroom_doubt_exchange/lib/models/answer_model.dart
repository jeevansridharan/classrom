// lib/models/answer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AnswerModel extends Equatable {
  final String id;
  final String questionId;
  // authorUid is intentionally NOT in this model (anonymity)
  final String body;
  final int voteCount;
  final bool isAccepted;
  final String? parentAnswerId; // null = top-level, non-null = nested reply
  final DateTime createdAt;
  final List<AnswerModel> replies; // nested replies (1 level deep shown in UI)

  // Pseudonym
  final String? authorHandle;
  final String? authorAvatarUrl;

  // Current user's vote
  final int? currentUserVote;

  const AnswerModel({
    required this.id,
    required this.questionId,
    required this.body,
    required this.voteCount,
    required this.isAccepted,
    this.parentAnswerId,
    required this.createdAt,
    this.replies = const [],
    this.authorHandle,
    this.authorAvatarUrl,
    this.currentUserVote,
  });

  factory AnswerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnswerModel(
      id: doc.id,
      questionId: data['questionId'] as String? ?? '',
      body: data['body'] as String? ?? '',
      voteCount: data['voteCount'] as int? ?? 0,
      isAccepted: data['isAccepted'] as bool? ?? false,
      parentAnswerId: data['parentAnswerId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorHandle: data['authorHandle'] as String?,
    );
  }

  Map<String, dynamic> toMap({required String authorUid}) => {
        'questionId': questionId,
        'authorUid': authorUid,
        'authorHandle': authorHandle ?? 'Anonymous',
        'body': body,
        'voteCount': 0,
        'isAccepted': false,
        'parentAnswerId': parentAnswerId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  AnswerModel copyWith({
    String? body,
    int? voteCount,
    bool? isAccepted,
    List<AnswerModel>? replies,
    int? currentUserVote,
  }) =>
      AnswerModel(
        id: id,
        questionId: questionId,
        body: body ?? this.body,
        voteCount: voteCount ?? this.voteCount,
        isAccepted: isAccepted ?? this.isAccepted,
        parentAnswerId: parentAnswerId,
        createdAt: createdAt,
        replies: replies ?? this.replies,
        authorHandle: authorHandle,
        authorAvatarUrl: authorAvatarUrl,
        currentUserVote: currentUserVote ?? this.currentUserVote,
      );

  @override
  List<Object?> get props => [id, questionId, body, voteCount, isAccepted];
}
