import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelemetryService {
  TelemetryService._();

  static final TelemetryService instance = TelemetryService._();
  static const int _eventVersion = 1;

  SupabaseClient? _client;

  void initialize(SupabaseClient? client) {
    _client = client;
  }

  Future<void> logEvent(
    String name,
    Map<String, dynamic> properties,
  ) async {
    final payload = Map<String, dynamic>.from(properties);
    payload.putIfAbsent('event_version', () => _eventVersion);

    if (kDebugMode) {
      debugPrint('[analytics] $name $payload');
    }

    final client = _client;
    if (client == null) {
      return;
    }

    try {
      await client.from('analytics_events').insert({
        'user_id': client.auth.currentUser?.id,
        'event_name': name,
        'properties': payload,
      });
    } catch (_) {
      // Ignore telemetry transport errors in app runtime.
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    String? context,
  }) async {
    if (kDebugMode) {
      debugPrint('[error] fatal=$fatal context=$context error=$error');
    }

    final client = _client;
    if (client == null) {
      return;
    }

    try {
      await client.from('client_error_logs').insert({
        'user_id': client.auth.currentUser?.id,
        'message': error.toString(),
        'stack': stack.toString(),
        'context': context,
        'is_fatal': fatal,
      });
    } catch (_) {
      // Ignore telemetry transport errors in app runtime.
    }
  }
}
