// lib/providers/question_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import '../services/answer_service.dart';
import '../services/vote_service.dart';
import '../services/search_service.dart';
import '../services/storage_service.dart';
import '../services/duplicate_detection_service.dart';

// ── Service Providers ──────────────────────────────────────────────────────────
final questionServiceProvider =
    Provider<QuestionService>((ref) => QuestionService());

final answerServiceProvider =
    Provider<AnswerService>((ref) => AnswerService());

final voteServiceProvider =
    Provider<VoteService>((ref) => VoteService());

final searchServiceProvider =
    Provider<SearchService>((ref) => SearchService());

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

final duplicateDetectionProvider =
    Provider<DuplicateDetectionService>((ref) => DuplicateDetectionService());

// ── Sort Order ─────────────────────────────────────────────────────────────────
final questionSortProvider =
    StateProvider<QuestionSortOrder>((ref) => QuestionSortOrder.recent);

final selectedTagProvider = StateProvider<String?>((ref) => null);

// ── Questions Feed ─────────────────────────────────────────────────────────────
final questionsStreamProvider =
    StreamProvider.autoDispose<List<QuestionModel>>((ref) {
  final sort = ref.watch(questionSortProvider);
  final tag = ref.watch(selectedTagProvider);
  return ref
      .watch(questionServiceProvider)
      .questionsStream(sort: sort, tag: tag);
});

// ── Single Question ────────────────────────────────────────────────────────────
final questionStreamProvider =
    StreamProvider.autoDispose.family<QuestionModel?, String>((ref, id) {
  return ref.watch(questionServiceProvider).questionStream(id);
});

// ── Answers for a Question ─────────────────────────────────────────────────────
final answersStreamProvider =
    StreamProvider.autoDispose.family((ref, String questionId) {
  return ref.watch(answerServiceProvider).answersStream(questionId);
});

// ── Replies for an Answer ──────────────────────────────────────────────────────
final repliesStreamProvider =
    StreamProvider.autoDispose.family((ref, String answerId) {
  return ref.watch(answerServiceProvider).repliesStream(answerId);
});

// ── Vote Stream ────────────────────────────────────────────────────────────────
final questionVoteStreamProvider =
    StreamProvider.autoDispose.family<int, String>((ref, questionId) {
  return ref.watch(voteServiceProvider).voteStream(
        target: VoteTarget.question,
        targetId: questionId,
      );
});

final answerVoteStreamProvider =
    StreamProvider.autoDispose.family<int, String>((ref, answerId) {
  return ref.watch(voteServiceProvider).voteStream(
        target: VoteTarget.answer,
        targetId: answerId,
      );
});

// ── Search ─────────────────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<QuestionModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final tag = ref.watch(selectedTagProvider);
  if (query.trim().isEmpty && tag == null) return Future.value([]);
  return ref.watch(searchServiceProvider).search(query: query, tag: tag);
});

final popularTagsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(searchServiceProvider).getPopularTags();
});

// ── Duplicate Detection ────────────────────────────────────────────────────────
final duplicateSuggestionsProvider =
    FutureProvider.autoDispose.family<List<QuestionModel>, Map<String, String>>(
  (ref, params) {
    return ref.watch(duplicateDetectionProvider).findSimilar(
          title: params['title'] ?? '',
          body: params['body'] ?? '',
        );
  },
);
