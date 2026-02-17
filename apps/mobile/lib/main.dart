import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_bootstrap.dart';
import 'shared/services/telemetry_service.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        final exception = details.exception;
        if (_isRecoverableOAuthException(exception)) {
          debugPrint('Recoverable OAuth error: $exception');
          return;
        }
        TelemetryService.instance.recordError(
          exception,
          details.stack ?? StackTrace.current,
          fatal: false,
          context: 'flutter_error',
        );
        FlutterError.presentError(details);
      };
      ui.PlatformDispatcher.instance.onError = (error, stack) {
        if (_isRecoverableOAuthException(error)) {
          debugPrint('Recoverable OAuth async error: $error');
          return true;
        }
        TelemetryService.instance.recordError(
          error,
          stack,
          fatal: true,
          context: 'platform_dispatcher',
        );
        // Keep process alive on async runtime errors.
        return true;
      };
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
      try {
        await SupabaseBootstrap.initialize();
      } catch (error, stack) {
        await TelemetryService.instance.recordError(
          error,
          stack,
          fatal: true,
          context: 'supabase_initialize',
        );
      }
      runApp(const IleoTokTokApp());
    },
    (error, stack) async {
      await TelemetryService.instance.recordError(
        error,
        stack,
        fatal: true,
        context: 'run_zoned_guarded',
      );
    },
  );
}

bool _isRecoverableOAuthException(Object error) {
  if (error is! AuthException) {
    return false;
  }

  final message = error.message.toLowerCase();
  return message.contains('unable to exchange external code') ||
      message.contains('oauth state has expired') ||
      message.contains('invalid_client');
}
