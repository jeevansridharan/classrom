// lib/providers/classroom_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/classroom_model.dart';
import '../models/classroom_member_model.dart';
import '../models/knowledge_record_model.dart';
import '../services/classroom_service.dart';
import '../services/knowledge_service.dart';

// Currently selected classroom filter (null = global feed / all user classrooms)
final selectedClassroomProvider = StateProvider<ClassroomModel?>((ref) => null);

// User's joined classrooms stream
final userClassroomsProvider = StreamProvider<List<ClassroomModel>>((ref) {
  final service = ref.watch(classroomServiceProvider);
  return service.userClassroomsStream();
});

// Single classroom stream provider
final classroomDetailsProvider =
    StreamProvider.family<ClassroomModel?, String>((ref, classroomId) {
  final service = ref.watch(classroomServiceProvider);
  return service.classroomStream(classroomId);
});

// Classroom members stream provider
final classroomMembersProvider =
    StreamProvider.family<List<ClassroomMemberModel>, String>((ref, classroomId) {
  final service = ref.watch(classroomServiceProvider);
  return service.classroomMembersStream(classroomId);
});

// Classroom preserved knowledge records provider
final classroomKnowledgeProvider =
    StreamProvider.family<List<KnowledgeRecordModel>, String>((ref, classroomId) {
  final service = ref.watch(knowledgeServiceProvider);
  return service.classroomKnowledgeStream(classroomId);
});
