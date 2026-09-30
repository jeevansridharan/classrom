// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ── Send Notification ───────────────────────────────────────────────────────
  Future<void> sendNotification({
    required String recipientUserId,
    required String title,
    required String body,
    required String type,
    required String referenceId,
  }) async {
    // Don't send notification to oneself
    if (recipientUserId == currentUserId) return;

    final docRef = _db.collection('notifications').doc();
    final notification = NotificationModel(
      id: docRef.id,
      userId: recipientUserId,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      read: false,
      createdAt: DateTime.now(),
    );

    await docRef.set(notification.toMap());
  }

  // ── Stream User Notifications ───────────────────────────────────────────────
  Stream<List<NotificationModel>> userNotificationsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  // ── Stream Unread Count ─────────────────────────────────────────────────────
  Stream<int> unreadCountStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(0);

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ── Mark Single Notification as Read ────────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'read': true});
  }

  // ── Mark All Notifications as Read ──────────────────────────────────────────
  Future<void> markAllAsRead() async {
    final uid = currentUserId;
    if (uid == null) return;

    final unreadQuery = await _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in unreadQuery.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
