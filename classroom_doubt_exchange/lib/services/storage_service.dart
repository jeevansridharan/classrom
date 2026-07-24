// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  // ── Pick Image from Gallery ────────────────────────────────────────────────
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
  }

  // ── Upload Question Image ──────────────────────────────────────────────────
  Future<String> uploadQuestionImage(File file) async {
    final uid = _auth.currentUser?.uid ?? 'unknown';
    final ext = file.path.split('.').last;
    final fileName = '${_uuid.v4()}.$ext';
    final ref = _storage.ref('questions/$uid/$fileName');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );

    return task.ref.getDownloadURL();
  }

  // ── Upload Avatar ──────────────────────────────────────────────────────────
  Future<String> uploadAvatar(File file) async {
    final uid = _auth.currentUser?.uid ?? 'unknown';
    final ext = file.path.split('.').last;
    final ref = _storage.ref('avatars/$uid.$ext');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );

    return task.ref.getDownloadURL();
  }

  // ── Delete File ────────────────────────────────────────────────────────────
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // File may already be deleted
    }
  }
}
