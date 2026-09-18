import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';

class WorkforceOnboardingRepository {
  final SupabaseClient _client;
  const WorkforceOnboardingRepository(this._client);

  Future<Map<String, dynamic>> _provider() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('You must be signed in.');
    final row = await _client.from('providers').select('id').eq('user_id', user.id).single();
    return Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> serviceCategories() async {
    final rows = await _client.from('service_categories').select('id, category_name, workforce_track, requires_certificate, requires_supervision, supports_hourly_work').eq('status', 'active').order('category_name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> load() async {
    final provider = await _provider();
    final providerId = provider['id'];
    final onboarding = await _client.from('provider_onboarding').select().eq('provider_id', providerId).maybeSingle();
    final capabilities = await _client.from('provider_capabilities').select('service_category_id, workforce_track, skill_level, years_experience, requires_supervision, approval_status').eq('provider_id', providerId);
    final documents = await _client.from('provider_documents').select('id, document_type, review_status, storage_path, reviewer_notes').eq('provider_id', providerId).order('created_at');
    final payout = await _client.from('provider_payout_accounts').select('bank_name, account_name, account_number, account_name_match, verification_status').eq('provider_id', providerId).maybeSingle();
    return {'provider': provider, 'onboarding': onboarding, 'capabilities': List<Map<String, dynamic>>.from(capabilities), 'documents': List<Map<String, dynamic>>.from(documents), 'payout': payout};
  }

  Future<void> saveIdentity({required String firstName, String? middleName, required String surname, required String phone, required String workforceTrack, required int nextStage}) async {
    final provider = await _provider();
    await _client.from('providers').update({'legal_first_name': firstName.trim(), 'legal_middle_name': middleName?.trim(), 'legal_surname': surname.trim(), 'full_name': [firstName, if (middleName != null && middleName.trim().isNotEmpty) middleName, surname].join(' ').trim(), 'phone': phone.trim(), 'workforce_track': workforceTrack}).eq('id', provider['id']);
    await _upsertStage(provider['id'], nextStage);
  }

  Future<void> saveCapabilities({required String workforceTrack, required List<Map<String, dynamic>> capabilities, required int nextStage}) async {
    final provider = await _provider();
    await _client.from('providers').update({'workforce_track': workforceTrack}).eq('id', provider['id']);
    for (final capability in capabilities) {
      await _client.from('provider_capabilities').upsert({...capability, 'provider_id': provider['id'], 'workforce_track': workforceTrack}, onConflict: 'provider_id,service_category_id');
    }
    await _upsertStage(provider['id'], nextStage);
  }

  Future<void> uploadDocument({required XFile file, required String documentType}) async {
    final provider = await _provider();
    final bytes = await file.readAsBytes();
    final extension = file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final path = '${provider['id']}/$documentType/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storage = _client.storage.from('provider-documents');
    await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: 'image/$extension', upsert: false));
    await _client.from('provider_documents').insert({'provider_id': provider['id'], 'document_type': documentType, 'storage_path': path});
  }

  Future<void> saveSafety({required String emergencyName, required String emergencyPhone, required bool accepted, required int nextStage}) async {
    if (!accepted) throw Exception('Please accept the safety and customer-conduct agreement.');
    final provider = await _provider();
    await _client.from('providers').update({'emergency_contact_name': emergencyName.trim(), 'emergency_contact_phone': emergencyPhone.trim()}).eq('id', provider['id']);
    await _upsertStage(provider['id'], nextStage, safetyStatus: 'submitted');
  }

  Future<void> savePayout({required String bankName, required String accountName, required String accountNumber}) async {
    final provider = await _provider();
    await _client.from('provider_payout_accounts').upsert({'provider_id': provider['id'], 'bank_name': bankName.trim(), 'account_name': accountName.trim(), 'account_number': accountNumber.trim(), 'account_name_match': false, 'verification_status': 'pending'}, onConflict: 'provider_id');
    await _upsertStage(provider['id'], 5, payoutStatus: 'submitted', onboardingStatus: 'submitted');
  }

  Future<void> submit() async {
    final provider = await _provider();
    await _client.from('provider_onboarding').update({'onboarding_status': 'submitted', 'submitted_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String()}).eq('provider_id', provider['id']);
  }

  Future<void> advanceToStage(int stage) async {
    final provider = await _provider();
    await _upsertStage(provider['id'].toString(), stage);
  }

  Future<void> _upsertStage(String providerId, int stage, {String? safetyStatus, String? payoutStatus, String? onboardingStatus}) async {
    await _client.from('provider_onboarding').upsert({'provider_id': providerId, 'current_stage': stage, if (safetyStatus != null) 'safety_status': safetyStatus, if (payoutStatus != null) 'payout_status': payoutStatus, if (onboardingStatus != null) 'onboarding_status': onboardingStatus, 'updated_at': DateTime.now().toIso8601String()}, onConflict: 'provider_id');
  }
}

final workforceOnboardingRepositoryProvider = Provider<WorkforceOnboardingRepository>((ref) => WorkforceOnboardingRepository(ref.watch(supabaseClientProvider)));
final workforceCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) => ref.watch(workforceOnboardingRepositoryProvider).serviceCategories());
