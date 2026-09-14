import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth. Email/password for now since that's
/// how the pilot's 6 accounts were created in the dashboard; swap
/// signInWithPassword for signInWithOtp(phone: ...) later for phone-first
/// provider onboarding without changing anything downstream.
class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    await ensureApplicationProfile();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.tamunium.provider://reset-password',
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role},
    );
    if (response.session != null) await ensureApplicationProfile();
    return response;
  }

  Future<void> ensureApplicationProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final role = metadata['role'] == 'customer' ? 'customer' : 'provider';
    final fullName = (metadata['full_name'] as String?)?.trim() ?? '';
    final displayName = fullName.isEmpty ? (user.email ?? 'TAMUNIUM user') : fullName;

    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': displayName,
      'email': user.email,
      'role': role,
      'status': 'active',
    });

    if (role == 'provider') {
      await _client.from('providers').upsert({
        'id': 'provider_${user.id.substring(0, 8)}',
        'user_id': user.id,
        'full_name': displayName,
        'email': user.email,
        'status': 'active',
      });
    } else {
      await _client.from('customers').upsert({
        'user_id': user.id,
        'contact_name': displayName,
        'email': user.email,
        'status': 'active',
      }, onConflict: 'user_id');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
