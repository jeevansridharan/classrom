// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Auth State Stream ──────────────────────────────────────────────────────
  Stream<User?> get authStateStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String handle,
  }) async {
    // Validate handle uniqueness
    final existing = await _db
        .collection('users')
        .where('handle', isEqualTo: handle.trim())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('This handle is already taken. Please choose another.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    final userModel = UserModel(
      uid: user.uid,
      handle: handle.trim(),
      email: email.trim(),
      reputationPoints: 0,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(user.uid).set(userModel.toMap());

    // Update Firebase display name
    await user.updateDisplayName(handle.trim());

    return userModel;
  }

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final doc = await _db
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    if (!doc.exists) {
      throw Exception('User profile not found. Please contact support.');
    }

    return UserModel.fromFirestore(doc);
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();

  // ── Get Current User Profile ───────────────────────────────────────────────
  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentUid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ── Update Handle ──────────────────────────────────────────────────────────
  Future<void> updateHandle(String newHandle) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Not authenticated');

    // Check uniqueness
    final existing = await _db
        .collection('users')
        .where('handle', isEqualTo: newHandle.trim())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty && existing.docs.first.id != uid) {
      throw Exception('Handle already taken.');
    }

    await _db.collection('users').doc(uid).update({'handle': newHandle.trim()});
    await _auth.currentUser?.updateDisplayName(newHandle.trim());
  }

  // ── Password Reset ─────────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Stream user profile ────────────────────────────────────────────────────
  Stream<UserModel?> userProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}
