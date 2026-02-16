import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../core/models/today_summary.dart';

class WidgetCacheService {
  static const _groupId = 'group.com.ileotoktok.app';
  static const _summaryKey = 'today_summary_json';

  Future<void> saveTodaySummary(TodaySummary summary) async {
    await HomeWidget.setAppGroupId(_groupId);

    final payload = {
      'dueCount': summary.dueCount,
      'newCount': summary.newCount,
      'estMinutes': summary.estMinutes,
      'streak': summary.streak,
      'freezeLeft': summary.freezeLeft,
    };

    await HomeWidget.saveWidgetData<String>(_summaryKey, jsonEncode(payload));
    await HomeWidget.updateWidget(
      name: 'DueCountWidgetProvider',
      iOSName: 'DueCountWidget',
    );
  }
}
