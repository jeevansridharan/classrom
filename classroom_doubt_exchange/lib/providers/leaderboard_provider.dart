// lib/providers/leaderboard_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final leaderboardProvider =
    StreamProvider.autoDispose<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('reputationPoints', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
});

// ── User profile by UID (for leaderboard avatars, etc.) ───────────────────────
final userProfileProvider =
    StreamProvider.autoDispose.family<UserModel?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});

// ── Current user's past questions ─────────────────────────────────────────────
final userQuestionsProvider =
    StreamProvider.autoDispose.family<List<QuestionModel>, String>(
  (ref, uid) {
    return FirebaseFirestore.instance
        .collection('questions')
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => QuestionModel.fromFirestore(d)).toList());
  },
);

// ── Current user's past answers ────────────────────────────────────────────────
final userAnswersCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('answers')
      .where('authorUid', isEqualTo: uid)
      .count()
      .get();
  return snap.count ?? 0;
});
