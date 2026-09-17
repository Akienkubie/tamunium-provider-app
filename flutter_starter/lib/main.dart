import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  try {
    SupabaseConfig.assertConfigured();
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    runApp(const ProviderScope(child: TamuniumApp()));
  } catch (error) {
    runApp(_StartupErrorApp(error: error));
  }
}

class _StartupErrorApp extends StatelessWidget {
  final Object error;
  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF061A2B),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('TAMUNIUM', style: TextStyle(color: Color(0xFFE8B15A), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 20),
                  const Text('The app could not start', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  const Text('Please reinstall the latest build after configuration is corrected.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience accessor used across the app, e.g. supabase.from('jobs').select()
final supabase = Supabase.instance.client;
