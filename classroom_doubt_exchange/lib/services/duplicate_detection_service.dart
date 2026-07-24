// lib/services/duplicate_detection_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

/// Detects potentially duplicate questions using TF-IDF cosine similarity.
/// Runs entirely on the client over the 100 most recent questions.
/// For production, replace with a Cloud Function + embedding-based approach.
class DuplicateDetectionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const double _similarityThreshold = 0.35;
  static const int _maxCandidates = 100;
  static const int _maxSuggestions = 3;

  // ── Public API ─────────────────────────────────────────────────────────────
  /// Returns up to 3 similar questions, or empty list if none found.
  Future<List<QuestionModel>> findSimilar({
    required String title,
    required String body,
  }) async {
    if (title.trim().length < 10) return [];

    final inputText = '${title.trim()} ${body.trim()}';
    final inputTokens = _tokenize(inputText);

    // Fetch recent questions from Firestore
    final snap = await _db
        .collection('questions')
        .orderBy('createdAt', descending: true)
        .limit(_maxCandidates)
        .get();

    if (snap.docs.isEmpty) return [];

    final candidates = snap.docs
        .map((d) => QuestionModel.fromFirestore(d))
        .toList();

    // Build corpus
    final corpus = candidates
        .map((q) => _tokenize('${q.title} ${q.body}'))
        .toList();

    // Compute IDF across corpus + input
    final allDocs = [...corpus, inputTokens];
    final idf = _computeIdf(allDocs);

    // TF-IDF vectors
    final inputVec = _tfidfVector(inputTokens, idf);
    final similarities = <double>[];

    for (final docTokens in corpus) {
      final docVec = _tfidfVector(docTokens, idf);
      similarities.add(_cosineSimilarity(inputVec, docVec));
    }

    // Rank by similarity
    final indexed = List.generate(candidates.length, (i) => i)
      ..sort((a, b) => similarities[b].compareTo(similarities[a]));

    return indexed
        .where((i) => similarities[i] >= _similarityThreshold)
        .take(_maxSuggestions)
        .map((i) => candidates[i])
        .toList();
  }

  // ── Tokenization ───────────────────────────────────────────────────────────
  List<String> _tokenize(String text) {
    final stopWords = {
      'the', 'a', 'an', 'is', 'it', 'in', 'on', 'at', 'to', 'of', 'for',
      'and', 'or', 'but', 'with', 'how', 'what', 'why', 'when', 'where',
      'do', 'i', 'my', 'can', 'be', 'this', 'that', 'are', 'was', 'has',
      'have', 'not', 'no', 'its', 'from', 'by', 'as', 'if', 'so', 'we',
    };

    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3 && !stopWords.contains(w))
        .toList();
  }

  // ── IDF ────────────────────────────────────────────────────────────────────
  Map<String, double> _computeIdf(List<List<String>> corpus) {
    final docFreq = <String, int>{};
    for (final doc in corpus) {
      final unique = doc.toSet();
      for (final term in unique) {
        docFreq[term] = (docFreq[term] ?? 0) + 1;
      }
    }
    final n = corpus.length;
    return docFreq.map(
      (term, df) => MapEntry(term, log((n + 1) / (df + 1)) + 1),
    );
  }

  // ── TF-IDF Vector ─────────────────────────────────────────────────────────
  Map<String, double> _tfidfVector(
    List<String> tokens,
    Map<String, double> idf,
  ) {
    final tf = <String, double>{};
    for (final token in tokens) {
      tf[token] = (tf[token] ?? 0) + 1;
    }
    if (tf.isEmpty) return {};
    final maxFreq = tf.values.reduce(max);
    return tf.map(
      (term, freq) => MapEntry(term, (freq / maxFreq) * (idf[term] ?? 1.0)),
    );
  }

  // ── Cosine Similarity ─────────────────────────────────────────────────────
  double _cosineSimilarity(
    Map<String, double> a,
    Map<String, double> b,
  ) {
    if (a.isEmpty || b.isEmpty) return 0.0;

    double dot = 0.0;
    for (final term in a.keys) {
      if (b.containsKey(term)) dot += a[term]! * b[term]!;
    }

    final magA = sqrt(a.values.map((v) => v * v).reduce((x, y) => x + y));
    final magB = sqrt(b.values.map((v) => v * v).reduce((x, y) => x + y));

    if (magA == 0 || magB == 0) return 0.0;
    return dot / (magA * magB);
  }
}
