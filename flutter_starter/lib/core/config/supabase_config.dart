// Keys are injected at build/run time, not hardcoded here.
// Run with:
//   flutter run --dart-define=SUPABASE_URL=https://uzjbduranfsenrmitivp.supabase.co \
//               --dart-define=SUPABASE_ANON_KEY=your_anon_key

class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static void assertConfigured() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Supabase not configured. Run with --dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}
