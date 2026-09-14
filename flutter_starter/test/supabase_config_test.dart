import 'package:flutter_test/flutter_test.dart';
import 'package:tamunium_provider_app/core/config/supabase_config.dart';

void main() {
  test('requires Supabase values when build defines are absent', () {
    expect(SupabaseConfig.url, isEmpty);
    expect(SupabaseConfig.anonKey, isEmpty);
    expect(SupabaseConfig.assertConfigured, throwsStateError);
  });
}
