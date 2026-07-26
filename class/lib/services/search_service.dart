// lib/services/search_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class SearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Full-Text Search ────────────────────────────────────────────────────────
  // Uses the searchTokens array built when a question is posted.
  // Firestore doesn't support native full-text search; this uses array-contains
  // which covers prefix-tokenized terms.
  Future<List<QuestionModel>> search({
    required String query,
    String? tag,
    int limit = 30,
  }) async {
    if (query.trim().isEmpty && tag == null) return [];

    List<QuestionModel> results = [];

    if (query.trim().isNotEmpty) {
      final token = query.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (token.length < 2) return [];

      var q = _db
          .collection('questions')
          .where('searchTokens', arrayContains: token)
          .orderBy('voteCount', descending: true)
          .limit(limit);

      if (tag != null) {
        q = _db
            .collection('questions')
            .where('searchTokens', arrayContains: token)
            .where('tags', arrayContains: tag)
            .orderBy('voteCount', descending: true)
            .limit(limit);
      }

      final snap = await q.get();
      results = snap.docs.map((d) => QuestionModel.fromFirestore(d)).toList();
    } else if (tag != null) {
      // Tag-only filter
      final snap = await _db
          .collection('questions')
          .where('tags', arrayContains: tag)
          .orderBy('voteCount', descending: true)
          .limit(limit)
          .get();
      results = snap.docs.map((d) => QuestionModel.fromFirestore(d)).toList();
    }

    return results;
  }

  // ── Fetch Popular Tags ──────────────────────────────────────────────────────
  Future<List<String>> getPopularTags({int limit = 15}) async {
    final snap = await _db
        .collection('tags')
        .orderBy('questionCount', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  // ── Search Suggestions (debounced) ─────────────────────────────────────────
  Future<List<QuestionModel>> getSuggestions(String query) async {
    if (query.length < 3) return [];
    return search(query: query, limit: 5);
  }
}
