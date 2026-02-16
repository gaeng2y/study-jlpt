import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_local_config.dart';

class SupabaseBootstrap {
  static Future<void> initialize() async {
    final url = _resolvedUrl;
    final anonKey = _resolvedKey;

    if (url.isEmpty || anonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('Supabase env not provided. Running in local mock mode.');
      }
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    // Sign-in is handled explicitly by AuthScreen (Google/Apple).
  }

  static bool get isConfigured {
    final url = _resolvedUrl;
    final anonKey = _resolvedKey;
    return url.isNotEmpty && anonKey.isNotEmpty;
  }

  static String get _resolvedUrl {
    const fromEnv = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return SupabaseLocalConfig.url;
  }

  static String get _resolvedKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return SupabaseLocalConfig.publishableKey;
  }
}
