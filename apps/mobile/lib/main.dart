import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  runApp(const IleoTokTokApp());
}
