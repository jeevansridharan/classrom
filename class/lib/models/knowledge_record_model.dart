// lib/models/knowledge_record_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class KnowledgeRecordModel extends Equatable {
  final String id;
  final String questionId;
  final String questionTitle;
  final String answerId;
  final String answerBody;
  final String contentHash; // SHA-256 hash of question title + body + accepted answer body
  final String? ipfsCid; // IPFS Content Identifier for decentralized preservation
  final DateTime verifiedAt;
  final String verifiedByHandle;
  final String? classroomId;

  const KnowledgeRecordModel({
    required this.id,
    required this.questionId,
    required this.questionTitle,
    required this.answerId,
    required this.answerBody,
    required this.contentHash,
    this.ipfsCid,
    required this.verifiedAt,
    required this.verifiedByHandle,
    this.classroomId,
  });

  factory KnowledgeRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KnowledgeRecordModel(
      id: doc.id,
      questionId: data['questionId'] as String? ?? '',
      questionTitle: data['questionTitle'] as String? ?? '',
      answerId: data['answerId'] as String? ?? '',
      answerBody: data['answerBody'] as String? ?? '',
      contentHash: data['contentHash'] as String? ?? '',
      ipfsCid: data['ipfsCid'] as String?,
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedByHandle: data['verifiedByHandle'] as String? ?? 'Verified',
      classroomId: data['classroomId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'questionId': questionId,
        'questionTitle': questionTitle,
        'answerId': answerId,
        'answerBody': answerBody,
        'contentHash': contentHash,
        'ipfsCid': ipfsCid,
        'verifiedAt': Timestamp.fromDate(verifiedAt),
        'verifiedByHandle': verifiedByHandle,
        'classroomId': classroomId,
      };

  @override
  List<Object?> get props => [
        id,
        questionId,
        questionTitle,
        answerId,
        contentHash,
        ipfsCid,
        verifiedAt,
        classroomId,
      ];
}
