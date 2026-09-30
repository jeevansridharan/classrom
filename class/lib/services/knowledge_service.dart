// lib/services/knowledge_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/knowledge_record_model.dart';
import '../models/question_model.dart';
import '../models/answer_model.dart';

final knowledgeServiceProvider = Provider<KnowledgeService>((ref) {
  return KnowledgeService();
});

class KnowledgeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Pure Dart SHA-256 Hash Function for Content Verification ────────────────
  String computeContentHash(String text) {
    // Generate deterministic 64-character SHA-256 hex string from text bytes
    final bytes = utf8.encode(text);
    return _sha256Hex(bytes);
  }

  // ── Create & Preserve Knowledge Record ───────────────────────────────────────
  Future<KnowledgeRecordModel> createKnowledgeRecord({
    required QuestionModel question,
    required AnswerModel answer,
  }) async {
    final rawContent = '${question.title}\n\n${question.body}\n\nACCEPTED ANSWER:\n${answer.body}';
    final contentHash = computeContentHash(rawContent);

    // Mock IPFS CID (decentralized content identifier format: bafybeig...)
    final mockIpfsCid = 'bafybeig${contentHash.substring(0, 32)}';

    final uid = _auth.currentUser?.uid ?? '';
    final userDoc = await _db.collection('users').doc(uid).get();
    final verifierHandle = userDoc.data()?['handle'] as String? ?? 'Verified';

    final docRef = _db.collection('knowledgeRecords').doc(question.id);
    final record = KnowledgeRecordModel(
      id: docRef.id,
      questionId: question.id,
      questionTitle: question.title,
      answerId: answer.id,
      answerBody: answer.body,
      contentHash: contentHash,
      ipfsCid: mockIpfsCid,
      verifiedAt: DateTime.now(),
      verifiedByHandle: verifierHandle,
      classroomId: question.classroomId,
    );

    await docRef.set(record.toMap());

    // Mark question as resolved
    await _db.collection('questions').doc(question.id).update({
      'isResolved': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return record;
  }

  // ── Stream Knowledge Record by Question ID ──────────────────────────────────
  Stream<KnowledgeRecordModel?> getKnowledgeRecordStream(String questionId) {
    return _db
        .collection('knowledgeRecords')
        .doc(questionId)
        .snapshots()
        .map((doc) => doc.exists ? KnowledgeRecordModel.fromFirestore(doc) : null);
  }

  // ── Stream All Preserved Knowledge Records in a Classroom ───────────────────
  Stream<List<KnowledgeRecordModel>> classroomKnowledgeStream(String classroomId) {
    return _db
        .collection('knowledgeRecords')
        .where('classroomId', isEqualTo: classroomId)
        .orderBy('verifiedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => KnowledgeRecordModel.fromFirestore(doc)).toList());
  }

  // ── SHA-256 Digest Pure Dart Implementation ─────────────────────────────────
  String _sha256Hex(List<int> bytes) {
    final K = <int>[
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ];

    var H0 = 0x6a09e667, H1 = 0xbb67ae85, H2 = 0x3c6ef372, H3 = 0xa54ff53a;
    var H4 = 0x510e527f, H5 = 0x9b05688c, H6 = 0x1f83d9ab, H7 = 0x5be0cd19;

    final bitLen = bytes.length * 8;
    final padded = List<int>.from(bytes)..add(0x80);
    while ((padded.length + 8) % 64 != 0) {
      padded.add(0x00);
    }
    for (var i = 7; i >= 0; i--) {
      padded.add((bitLen >> (i * 8)) & 0xff);
    }

    final W = List<int>.filled(64, 0);

    for (var chunk = 0; chunk < padded.length; chunk += 64) {
      for (var i = 0; i < 16; i++) {
        W[i] = (padded[chunk + i * 4] << 24) |
            (padded[chunk + i * 4 + 1] << 16) |
            (padded[chunk + i * 4 + 2] << 8) |
            padded[chunk + i * 4 + 3];
      }
      for (var i = 16; i < 64; i++) {
        final s0 = _rotr(W[i - 15], 7) ^ _rotr(W[i - 15], 18) ^ (W[i - 15] >> 3);
        final s1 = _rotr(W[i - 2], 17) ^ _rotr(W[i - 2], 19) ^ (W[i - 2] >> 10);
        W[i] = (W[i - 16] + s0 + W[i - 7] + s1) & 0xffffffff;
      }

      var a = H0, b = H1, c = H2, d = H3, e = H4, f = H5, g = H6, h = H7;

      for (var i = 0; i < 64; i++) {
        final S1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e) & g);
        final temp1 = (h + S1 + ch + K[i] + W[i]) & 0xffffffff;
        final S0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (S0 + maj) & 0xffffffff;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xffffffff;
      }

      H0 = (H0 + a) & 0xffffffff;
      H1 = (H1 + b) & 0xffffffff;
      H2 = (H2 + c) & 0xffffffff;
      H3 = (H3 + d) & 0xffffffff;
      H4 = (H4 + e) & 0xffffffff;
      H5 = (H5 + f) & 0xffffffff;
      H6 = (H6 + g) & 0xffffffff;
      H7 = (H7 + h) & 0xffffffff;
    }

    return [H0, H1, H2, H3, H4, H5, H6, H7]
        .map((h) => h.toRadixString(16).padLeft(8, '0'))
        .join();
  }

  int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;
}
