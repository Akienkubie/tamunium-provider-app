import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/provider_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

/// Emits every time auth state changes (sign in / sign out / token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// The current logged-in user's row from `providers`, keyed by auth.uid().
/// Null if the logged-in profile isn't a provider (e.g. an admin account).
final currentProviderProvider = FutureProvider<ProviderModel?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;

  final row = await client
      .from('providers')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();

  if (row == null) return null;
  return ProviderModel.fromJson(row);
});
