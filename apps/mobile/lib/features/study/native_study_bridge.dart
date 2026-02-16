import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/models/study_card.dart';

enum NativeStudyResult { good, again, unsupported }

class NativeStudyBridge {
  static const _channel = MethodChannel('studyjlpt/native_study');

  static bool get isSupported => Platform.isIOS || Platform.isAndroid;

  static Future<NativeStudyResult> openCard(StudyCard card) async {
    if (!isSupported) {
      return NativeStudyResult.unsupported;
    }

    try {
      final result = await _channel.invokeMethod<String>('startStudyCard', {
        'id': card.content.id,
        'kind': card.content.kind,
        'jlptLevel': card.content.jlptLevel,
        'jp': card.content.jp,
        'reading': card.content.reading,
        'meaningKo': card.content.meaningKo,
      });

      if (result == 'good') {
        return NativeStudyResult.good;
      }
      if (result == 'again') {
        return NativeStudyResult.again;
      }
      return NativeStudyResult.unsupported;
    } on MissingPluginException {
      return NativeStudyResult.unsupported;
    } on PlatformException {
      return NativeStudyResult.unsupported;
    }
  }
}
