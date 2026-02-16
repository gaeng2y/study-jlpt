import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../core/models/content_item.dart';
import '../../core/models/today_summary.dart';

class WidgetCacheService {
  static const _groupId = 'group.co.gaeng2y.studyjlpt';
  static const _summaryKey = 'today_summary_json';
  static const _dailyWordKey = 'today_word_json';

  Future<void> saveTodaySummary(
    TodaySummary summary, {
    ContentItem? dailyWord,
  }) async {
    await HomeWidget.setAppGroupId(_groupId);

    final payload = {
      'dueCount': summary.dueCount,
      'newCount': summary.newCount,
      'estMinutes': summary.estMinutes,
      'streak': summary.streak,
      'freezeLeft': summary.freezeLeft,
    };

    final wordPayload = dailyWord == null
        ? null
        : {
            'jp': dailyWord.jp,
            'reading': dailyWord.reading,
            'meaningKo': dailyWord.meaningKo,
            'jlptLevel': dailyWord.jlptLevel,
          };

    await HomeWidget.saveWidgetData<String>(_summaryKey, jsonEncode(payload));
    await HomeWidget.saveWidgetData<String>(
      _dailyWordKey,
      wordPayload == null ? null : jsonEncode(wordPayload),
    );
    await HomeWidget.updateWidget(
      name: 'DueCountWidgetProvider',
      iOSName: 'DueCountWidget',
    );
    await HomeWidget.updateWidget(
      name: 'DailyWordWidgetProvider',
      iOSName: 'DailyWordWidget',
    );
  }
}
