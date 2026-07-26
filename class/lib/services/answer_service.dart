// lib/services/answer_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/answer_model.dart';

class AnswerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Post an Answer ─────────────────────────────────────────────────────────
  Future<String> postAnswer({
    required String questionId,
    required String body,
    required String authorHandle,
    String? parentAnswerId, // for nested replies
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final ref = _db.collection('answers').doc();
    await ref.set({
      'questionId': questionId,
      'authorUid': uid,
      'authorHandle': authorHandle,
      'body': body.trim(),
      'voteCount': 0,
      'isAccepted': false,
      'parentAnswerId': parentAnswerId,
      'createdAt': Timestamp.now(),
    });

    // Increment answer count on question
    await _db.collection('questions').doc(questionId).update({
      'answerCount': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });

    return ref.id;
  }

  // ── Fetch Answers for a Question ───────────────────────────────────────────
  Stream<List<AnswerModel>> answersStream(String questionId) {
    return _db
        .collection('answers')
        .where('questionId', isEqualTo: questionId)
        .where('parentAnswerId', isNull: true) // top-level only
        .orderBy('isAccepted', descending: true)
        .orderBy('voteCount', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AnswerModel.fromFirestore(d)).toList());
  }

  // ── Fetch Replies for an Answer ────────────────────────────────────────────
  Stream<List<AnswerModel>> repliesStream(String parentAnswerId) {
    return _db
        .collection('answers')
        .where('parentAnswerId', isEqualTo: parentAnswerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AnswerModel.fromFirestore(d)).toList());
  }

  // ── Accept Answer ──────────────────────────────────────────────────────────
  Future<void> acceptAnswer({
    required String questionId,
    required String answerId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    // Verify question ownership
    final qDoc = await _db.collection('questions').doc(questionId).get();
    if (qDoc['authorUid'] != uid) throw Exception('Not authorized');

    // Un-accept any previously accepted answer
    final batch = _db.batch();
    final prevAccepted = await _db
        .collection('answers')
        .where('questionId', isEqualTo: questionId)
        .where('isAccepted', isEqualTo: true)
        .get();

    for (final doc in prevAccepted.docs) {
      batch.update(doc.reference, {'isAccepted': false});
    }

    batch.update(
      _db.collection('answers').doc(answerId),
      {'isAccepted': true},
    );

    batch.update(
      _db.collection('questions').doc(questionId),
      {'isResolved': true, 'updatedAt': Timestamp.now()},
    );

    await batch.commit();
  }

  // ── User's Answers ─────────────────────────────────────────────────────────
  Stream<List<AnswerModel>> userAnswersStream(String uid) {
    return _db
        .collection('answers')
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AnswerModel.fromFirestore(d)).toList());
  }
}
