// lib/services/vote_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum VoteTarget { question, answer }

class VoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reputation points awarded/deducted on vote
  static const int _upvoteReputation = 5;
  static const int _downvoteReputation = -2;
  static const int _postReceivedUpvoteReputation = 10;
  static const int _postReceivedDownvoteReputation = -2;

  // ── Cast or Toggle Vote ────────────────────────────────────────────────────
  /// Returns the new vote value after toggling.
  Future<int> vote({
    required VoteTarget target,
    required String targetId,
    required int value, // 1 = upvote, -1 = downvote
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final collection = target == VoteTarget.question ? 'questions' : 'answers';
    final docRef = _db.collection(collection).doc(targetId);
    final voteRef = docRef.collection('votes').doc(uid);

    return _db.runTransaction<int>((tx) async {
      final voteSnap = await tx.get(voteRef);
      final targetSnap = await tx.get(docRef);

      final prevValue = voteSnap.exists ? (voteSnap['value'] as int) : 0;
      final authorUid = targetSnap['authorUid'] as String?;

      int newValue;
      int voteDelta;
      int repDelta;

      if (prevValue == value) {
        // Toggle OFF (un-vote)
        newValue = 0;
        voteDelta = -value;
        repDelta = value == 1
            ? -_postReceivedUpvoteReputation
            : -_postReceivedDownvoteReputation;
      } else if (prevValue == 0) {
        // New vote
        newValue = value;
        voteDelta = value;
        repDelta = value == 1
            ? _postReceivedUpvoteReputation
            : _postReceivedDownvoteReputation;
      } else {
        // Flip vote (from -1 to 1 or vice versa)
        newValue = value;
        voteDelta = value * 2; // e.g., was -1 now +1 → delta = +2
        repDelta = value == 1
            ? _postReceivedUpvoteReputation - _postReceivedDownvoteReputation
            : _postReceivedDownvoteReputation - _postReceivedUpvoteReputation;
      }

      // Update vote record
      if (newValue == 0) {
        tx.delete(voteRef);
      } else {
        tx.set(voteRef, {'value': newValue, 'votedAt': Timestamp.now()});
      }

      // Update target voteCount
      tx.update(docRef, {'voteCount': FieldValue.increment(voteDelta)});

      // Update author reputation (if author is found and not self-voting)
      if (authorUid != null && authorUid != uid) {
        final authorRef = _db.collection('users').doc(authorUid);
        tx.update(authorRef, {
          'reputationPoints': FieldValue.increment(repDelta),
        });

        // Voter also gets a small reputation change for voting
        final voterRef = _db.collection('users').doc(uid);
        final voterRepDelta =
            value == 1 ? _upvoteReputation : _downvoteReputation;
        if (prevValue == 0) {
          // Only award voter rep on new votes, not toggles
          tx.update(voterRef, {
            'reputationPoints': FieldValue.increment(voterRepDelta),
          });
        }
      }

      return newValue;
    });
  }

  // ── Get Current User's Vote on a Target ───────────────────────────────────
  Future<int> getCurrentVote({
    required VoteTarget target,
    required String targetId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    final collection = target == VoteTarget.question ? 'questions' : 'answers';
    final doc = await _db
        .collection(collection)
        .doc(targetId)
        .collection('votes')
        .doc(uid)
        .get();

    return doc.exists ? (doc['value'] as int) : 0;
  }

  // ── Stream Vote for a Target ───────────────────────────────────────────────
  Stream<int> voteStream({
    required VoteTarget target,
    required String targetId,
  }) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    final collection = target == VoteTarget.question ? 'questions' : 'answers';
    return _db
        .collection(collection)
        .doc(targetId)
        .collection('votes')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? (doc['value'] as int? ?? 0) : 0);
  }
}
