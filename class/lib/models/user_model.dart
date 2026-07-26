// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String handle; // pseudonym shown to other students
  final String email;  // private — only shown to the user themselves
  final int reputationPoints;
  final String? avatarUrl;
  final DateTime createdAt;
  final List<String> badges;

  const UserModel({
    required this.uid,
    required this.handle,
    required this.email,
    required this.reputationPoints,
    this.avatarUrl,
    required this.createdAt,
    this.badges = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      handle: data['handle'] as String? ?? 'Anonymous',
      email: data['email'] as String? ?? '',
      reputationPoints: data['reputationPoints'] as int? ?? 0,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      badges: List<String>.from(data['badges'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'handle': handle,
        'email': email,
        'reputationPoints': reputationPoints,
        'avatarUrl': avatarUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'badges': badges,
      };

  UserModel copyWith({
    String? handle,
    String? email,
    int? reputationPoints,
    String? avatarUrl,
    List<String>? badges,
  }) =>
      UserModel(
        uid: uid,
        handle: handle ?? this.handle,
        email: email ?? this.email,
        reputationPoints: reputationPoints ?? this.reputationPoints,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
        badges: badges ?? this.badges,
      );

  // ── Reputation tier ────────────────────────────────────────────────────────
  String get reputationTier {
    if (reputationPoints >= 500) return 'Expert';
    if (reputationPoints >= 200) return 'Advanced';
    if (reputationPoints >= 50) return 'Contributor';
    if (reputationPoints >= 10) return 'Learner';
    return 'Newcomer';
  }

  @override
  List<Object?> get props => [uid, handle, email, reputationPoints, avatarUrl];
}
