import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth. Email/password for now since that's
/// how the pilot's 6 accounts were created in the dashboard; swap
/// signInWithPassword for signInWithOtp(phone: ...) later for phone-first
/// provider onboarding without changing anything downstream.
class AuthService {
  static const emailConfirmationRedirect = 'com.tamunium.provider://auth-callback/';
  static const passwordRecoveryRedirect = 'com.tamunium.provider://reset-password/';
  final SupabaseClient _client;
  AuthService(this._client);

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    final user = _client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final role = metadata['role'];
    if (user != null && (role == 'provider' || role == 'customer')) {
      final existingProfile = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (existingProfile == null) await ensureApplicationProfile();
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: passwordRecoveryRedirect,
    );
  }

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? customerType,
    String? organizationName,
    String? address,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: emailConfirmationRedirect,
      data: {
        'full_name': fullName,
        'role': role,
        'onboarding': true,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (customerType != null) 'customer_type': customerType,
        if (organizationName != null && organizationName.isNotEmpty) 'organization_name': organizationName,
        if (address != null && address.isNotEmpty) 'address': address,
      },
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
    final phone = metadata['phone'] as String?;

    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': displayName,
      'email': user.email,
      'role': role,
      'status': 'active',
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });

    if (role == 'provider') {
      await _client.from('providers').upsert({
        'id': 'provider_${user.id.substring(0, 8)}',
        'user_id': user.id,
        'full_name': displayName,
        'email': user.email,
        'status': 'active',
        'verification_status': 'pending',
        'current_availability': 'offline',
        'availability_status': 'offline',
        'managed_workforce_status': 'independent',
      });
    } else {
      final existingCustomer = await _client
          .from('customers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      final customerData = {
        'user_id': user.id,
        'contact_name': displayName,
        'email': user.email,
        'status': 'active',
        'customer_type': metadata['customer_type'] as String? ?? 'individual',
        if (metadata['organization_name'] != null) 'organization_name': metadata['organization_name'],
        if (metadata['address'] != null) 'address': metadata['address'],
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };
      if (existingCustomer == null) {
        await _client.from('customers').insert(customerData);
      } else {
        await _client.from('customers').update(customerData).eq('id', existingCustomer['id']);
      }
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
