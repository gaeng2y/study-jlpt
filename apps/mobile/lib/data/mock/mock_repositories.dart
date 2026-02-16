import 'dart:math';

import '../../core/models/content_item.dart';
import '../../core/models/profile_settings.dart';
import '../../core/models/study_card.dart';
import '../../core/models/today_summary.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../../domain/usecases/study_algorithms.dart';

class MockContentRepository implements ContentRepository {
  final List<ContentItem> _items = seedContent;

  @override
  Future<List<ContentItem>> listAll() async => List.unmodifiable(_items);

  @override
  Future<List<ContentItem>> search(String query, {String? jlptLevel}) async {
    return _items.where((item) {
      final levelOk = jlptLevel == null || item.jlptLevel == jlptLevel;
      if (!levelOk) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      return item.jp.contains(query) ||
          item.reading.contains(query) ||
          item.meaningKo.contains(query);
    }).toList();
  }
}

class MockStudyRepository implements StudyRepository {
  MockStudyRepository()
      : _queue = seedContent
            .take(12)
            .map((item) => StudyCard(content: item))
            .toList(growable: true);

  final List<StudyCard> _queue;
  final Set<String> _learnedIds = <String>{};

  @override
  Future<int> dueCount() async => _queue.length;

  @override
  Future<Set<String>> learnedContentIds() async =>
      Set<String>.from(_learnedIds);

  @override
  Future<TodaySummary> todaySummary() async {
    final due = _queue.length;
    return TodaySummary(
      dueCount: due,
      newCount: 5,
      estMinutes: (due / 4).ceil().clamp(1, 60),
      streak: 6,
      freezeLeft: 1,
      cardsDone: 0,
      isCompleted: false,
    );
  }

  @override
  Future<List<StudyCard>> dueQueue({required int limit}) async {
    return _queue.take(limit).toList();
  }

  @override
  Future<void> gradeCard({required StudyCard card, required bool good}) async {
    _learnedIds.add(card.content.id);
    _queue.removeWhere((element) => element.content.id == card.content.id);

    if (!good) {
      _queue.add(
        StudyCard(
          content: card.content,
          reps: card.reps + 1,
          intervalDays: nextIntervalDays(
            currentInterval: card.intervalDays,
            good: false,
          ),
          lapses: card.lapses + 1,
        ),
      );
    }
  }

  @override
  Future<void> completeTodaySession() async {}
}

class MockProfileRepository implements ProfileRepository {
  ProfileSettings _settings = ProfileSettings.defaults;

  @override
  Future<int> currentStreak() async => 6;

  @override
  Future<int> freezeLeft() async => 1;

  @override
  Future<ProfileSettings> getSettings() async => _settings;

  @override
  Future<void> saveSettings(ProfileSettings settings) async {
    _settings = settings;
  }
}

final List<ContentItem> seedContent = [
  const ContentItem(
    id: '1',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '学校',
    reading: 'がっこう',
    meaningKo: '학교',
  ),
  const ContentItem(
    id: '2',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '友達',
    reading: 'ともだち',
    meaningKo: '친구',
  ),
  const ContentItem(
    id: '3',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '先生',
    reading: 'せんせい',
    meaningKo: '선생님',
  ),
  const ContentItem(
    id: '4',
    kind: 'kana',
    jlptLevel: 'N5',
    jp: 'あ',
    reading: 'a',
    meaningKo: '히라가나 a',
  ),
  const ContentItem(
    id: '5',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '水',
    reading: 'みず',
    meaningKo: '물',
  ),
  const ContentItem(
    id: '6',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '時間',
    reading: 'じかん',
    meaningKo: '시간',
  ),
  const ContentItem(
    id: '7',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '今日',
    reading: 'きょう',
    meaningKo: '오늘',
  ),
  const ContentItem(
    id: '8',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '本',
    reading: 'ほん',
    meaningKo: '책',
  ),
  const ContentItem(
    id: '9',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '電車',
    reading: 'でんしゃ',
    meaningKo: '전철',
  ),
  const ContentItem(
    id: '10',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '雨',
    reading: 'あめ',
    meaningKo: '비',
  ),
  const ContentItem(
    id: '11',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '日本語',
    reading: 'にほんご',
    meaningKo: '일본어',
  ),
  const ContentItem(
    id: '12',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '朝',
    reading: 'あさ',
    meaningKo: '아침',
  ),
  const ContentItem(
    id: '13',
    kind: 'vocab',
    jlptLevel: 'N5',
    jp: '夜',
    reading: 'よる',
    meaningKo: '밤',
  ),
  const ContentItem(
    id: '14',
    kind: 'kana',
    jlptLevel: 'N5',
    jp: 'カ',
    reading: 'ka',
    meaningKo: '가타카나 ka',
  ),
];

ContentItem randomTodayWord() =>
    seedContent[Random().nextInt(seedContent.length)];
