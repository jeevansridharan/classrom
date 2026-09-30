// lib/services/question_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question_model.dart';

enum QuestionSortOrder { recent, topVoted, unanswered }

class QuestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Post a Question ────────────────────────────────────────────────────────
  Future<String> postQuestion({
    required String title,
    required String body,
    required List<String> tags,
    String? imageUrl,
    required String authorHandle,
    String? classroomId,
    String category = 'General',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final ref = _db.collection('questions').doc();

    final questionMap = {
      'authorUid': uid,
      'authorHandle': authorHandle,
      'title': title.trim(),
      'body': body.trim(),
      'tags': tags,
      'imageUrl': imageUrl,
      'voteCount': 0,
      'viewCount': 0,
      'answerCount': 0,
      'isResolved': false,
      'classroomId': classroomId,
      'category': category,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'searchTokens': _buildSearchTokens(title, body, tags),
    };

    final batch = _db.batch();
    batch.set(ref, questionMap);

    // Update tag counts
    for (final tag in tags) {
      final tagRef = _db.collection('tags').doc(tag);
      batch.set(
        tagRef,
        {'name': tag, 'questionCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    }

    // Update classroom questionCount if associated with a classroom
    if (classroomId != null && classroomId.isNotEmpty) {
      final classroomRef = _db.collection('classrooms').doc(classroomId);
      batch.update(classroomRef, {
        'questionCount': FieldValue.increment(1),
      });
    }

    await batch.commit();
    return ref.id;
  }

  // ── Fetch Questions (Feed with Classroom Scope) ────────────────────────────
  Stream<List<QuestionModel>> questionsStream({
    QuestionSortOrder sort = QuestionSortOrder.recent,
    String? tag,
    String? classroomId,
    String? category,
    int limit = 30,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('questions');

    if (classroomId != null && classroomId.isNotEmpty) {
      query = query.where('classroomId', isEqualTo: classroomId);
    }

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    if (tag != null && tag.isNotEmpty) {
      query = query.where('tags', arrayContains: tag);
    }

    if (sort == QuestionSortOrder.unanswered) {
      query = query.where('answerCount', isEqualTo: 0);
    }

    query = sort == QuestionSortOrder.topVoted
        ? query.orderBy('voteCount', descending: true)
        : query.orderBy('createdAt', descending: true);

    return query.limit(limit).snapshots().map(
          (snap) => snap.docs
              .map((doc) => QuestionModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ── Fetch Single Question ──────────────────────────────────────────────────
  Future<QuestionModel?> getQuestion(String questionId) async {
    final doc = await _db.collection('questions').doc(questionId).get();
    if (!doc.exists) return null;
    return QuestionModel.fromFirestore(doc);
  }

  Stream<QuestionModel?> questionStream(String questionId) {
    return _db
        .collection('questions')
        .doc(questionId)
        .snapshots()
        .map((doc) => doc.exists ? QuestionModel.fromFirestore(doc) : null);
  }

  // ── Increment View Count ───────────────────────────────────────────────────
  Future<void> incrementViewCount(String questionId) async {
    await _db.collection('questions').doc(questionId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // ── Mark as Resolved ──────────────────────────────────────────────────────
  Future<void> markResolved(String questionId, bool isResolved) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final doc = await _db.collection('questions').doc(questionId).get();
    if (doc['authorUid'] != uid) throw Exception('Not authorized');

    await _db.collection('questions').doc(questionId).update({
      'isResolved': isResolved,
      'updatedAt': Timestamp.now(),
    });
  }

  // ── User's Questions ───────────────────────────────────────────────────────
  Stream<List<QuestionModel>> userQuestionsStream(String uid) {
    return _db
        .collection('questions')
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => QuestionModel.fromFirestore(d)).toList());
  }

  // ── Build Search Tokens ────────────────────────────────────────────────────
  static List<String> _buildSearchTokens(
    String title,
    String body,
    List<String> tags,
  ) {
    final tokens = <String>{};
    final words = '${title.toLowerCase()} ${body.toLowerCase()}'.split(
      RegExp(r'\s+'),
    );
    for (final word in words) {
      final cleaned = word.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (cleaned.length >= 3) {
        tokens.add(cleaned);
        for (int i = 3; i <= cleaned.length; i++) {
          tokens.add(cleaned.substring(0, i));
        }
      }
    }
    for (final tag in tags) {
      tokens.add(tag.toLowerCase());
    }
    return tokens.toList();
  }
}
