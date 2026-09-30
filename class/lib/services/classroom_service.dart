// lib/services/classroom_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/classroom_model.dart';
import '../models/classroom_member_model.dart';

final classroomServiceProvider = Provider<ClassroomService>((ref) {
  return ClassroomService();
});

class ClassroomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ── Generate Random 6-Character Join Code ───────────────────────────────────
  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude ambiguous chars like I, O, 0, 1
    final rnd = Random();
    return List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  // ── Create a Classroom (Faculty / Moderator) ────────────────────────────────
  Future<ClassroomModel> createClassroom({
    required String name,
    required String description,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    // Fetch user handle
    final userDoc = await _db.collection('users').doc(uid).get();
    final userHandle = userDoc.data()?['handle'] as String? ?? 'Faculty';

    final code = _generateJoinCode();
    final docRef = _db.collection('classrooms').doc();

    final classroom = ClassroomModel(
      id: docRef.id,
      name: name,
      code: code,
      description: description,
      createdBy: uid,
      creatorHandle: userHandle,
      createdAt: DateTime.now(),
      memberCount: 1,
      questionCount: 0,
    );

    final batch = _db.batch();

    // 1. Save classroom doc
    batch.set(docRef, classroom.toMap());

    // 2. Add creator as FACULTY member
    final memberRef = _db
        .collection('classrooms')
        .doc(docRef.id)
        .collection('members')
        .doc(uid);

    final member = ClassroomMemberModel(
      id: uid,
      classroomId: docRef.id,
      userId: uid,
      userHandle: userHandle,
      role: 'FACULTY',
      joinedAt: DateTime.now(),
    );
    batch.set(memberRef, member.toMap());

    // 3. Add classroom ID to user profile
    final userRef = _db.collection('users').doc(uid);
    batch.update(userRef, {
      'joinedClassroomIds': FieldValue.arrayUnion([docRef.id]),
    });

    await batch.commit();
    return classroom;
  }

  // ── Join a Classroom using 6-character Code ─────────────────────────────────
  Future<ClassroomModel> joinClassroomByCode(String code) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final cleanCode = code.toUpperCase().trim();
    if (cleanCode.length != 6) {
      throw Exception('Invalid join code format. Code must be 6 characters.');
    }

    final query = await _db
        .collection('classrooms')
        .where('code', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No classroom found with code "$cleanCode". Check and try again.');
    }

    final classroomDoc = query.docs.first;
    final classroom = ClassroomModel.fromFirestore(classroomDoc);

    // Check if already member
    final memberRef = _db
        .collection('classrooms')
        .doc(classroom.id)
        .collection('members')
        .doc(uid);

    final memberSnap = await memberRef.get();
    if (memberSnap.exists) {
      return classroom; // Already joined
    }

    // Fetch user handle
    final userDoc = await _db.collection('users').doc(uid).get();
    final userHandle = userDoc.data()?['handle'] as String? ?? 'Student';
    final userAvatar = userDoc.data()?['avatarUrl'] as String?;

    final batch = _db.batch();

    // 1. Add member
    final member = ClassroomMemberModel(
      id: uid,
      classroomId: classroom.id,
      userId: uid,
      userHandle: userHandle,
      userAvatarUrl: userAvatar,
      role: 'STUDENT',
      joinedAt: DateTime.now(),
    );
    batch.set(memberRef, member.toMap());

    // 2. Increment member count
    batch.update(classroomDoc.reference, {
      'memberCount': FieldValue.increment(1),
    });

    // 3. Update user joinedClassroomIds
    batch.update(_db.collection('users').doc(uid), {
      'joinedClassroomIds': FieldValue.arrayUnion([classroom.id]),
    });

    await batch.commit();
    return classroom;
  }

  // ── Stream User Classrooms ──────────────────────────────────────────────────
  Stream<List<ClassroomModel>> userClassroomsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .asyncMap((userSnap) async {
      if (!userSnap.exists) return [];

      final data = userSnap.data();
      final ids = List<String>.from(data?['joinedClassroomIds'] as List? ?? []);

      if (ids.isEmpty) return [];

      // Firestore whereIn max 30 items per query
      final query = await _db
          .collection('classrooms')
          .where(FieldPath.documentId, whereIn: ids.take(30).toList())
          .get();

      return query.docs.map((doc) => ClassroomModel.fromFirestore(doc)).toList();
    });
  }

  // ── Stream Single Classroom Details ─────────────────────────────────────────
  Stream<ClassroomModel?> classroomStream(String classroomId) {
    return _db
        .collection('classrooms')
        .doc(classroomId)
        .snapshots()
        .map((doc) => doc.exists ? ClassroomModel.fromFirestore(doc) : null);
  }

  // ── Stream Classroom Members ────────────────────────────────────────────────
  Stream<List<ClassroomMemberModel>> classroomMembersStream(String classroomId) {
    return _db
        .collection('classrooms')
        .doc(classroomId)
        .collection('members')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ClassroomMemberModel.fromFirestore(doc)).toList());
  }
}
