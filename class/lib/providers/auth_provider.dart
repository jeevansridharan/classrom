// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// ── Service instance ───────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Raw Firebase auth state ────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateStream;
});

// ── Current user profile (Firestore) ─────────────────────────────────────────
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(authServiceProvider).userProfileStream(uid);
});

// ── Auth Notifier (for sign-in / sign-up actions) ─────────────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier(this._service) : super(const AsyncValue.data(null));

  final AuthService _service;

  Future<void> signUp({
    required String email,
    required String password,
    required String handle,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.signUp(email: email, password: password, handle: handle),
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.signIn(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
