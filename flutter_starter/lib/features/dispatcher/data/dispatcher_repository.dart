import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';

class DispatcherRepository {
  final SupabaseClient _client;
  const DispatcherRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchOpenRequests() async {
    final rows = await _client
        .from('service_requests')
        .select('id, service_type, description, service_address, priority, status, created_at, preferred_date, category_id, service_categories(category_name)')
        .inFilter('status', ['submitted', 'matching'])
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> rankProviders(String requestId) async {
    final result = await _client.rpc('rank_providers_for_request', params: {'p_request_id': requestId});
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<List<Map<String, dynamic>>> fetchMatches(String requestId) async {
    final rows = await _client
        .from('job_provider_matches')
        .select('provider_id, match_score, skill_score, rating_score, distance_score, reliability_score, availability_score, distance_km, rank, status, providers(full_name, overall_rating, jobs_completed, verification_status, photo_url)')
        .eq('request_id', requestId)
        .order('rank');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> assignProvider({
    required String requestId,
    required String providerId,
    String? notes,
  }) async {
    final result = await _client.rpc('assign_provider_to_request', params: {
      'p_request_id': requestId,
      'p_provider_id': providerId,
      'p_notes': notes,
    });
    return Map<String, dynamic>.from(result as Map);
  }
}

final dispatcherRepositoryProvider = Provider<DispatcherRepository>((ref) {
  return DispatcherRepository(ref.watch(supabaseClientProvider));
});

final dispatcherOpenRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(dispatcherRepositoryProvider).fetchOpenRequests();
});
