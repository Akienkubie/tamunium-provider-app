import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/job_evidence_model.dart';
import '../../auth/providers/auth_provider.dart';

class CustomerReviewRepository {
  final SupabaseClient _client;
  CustomerReviewRepository(this._client);

  Future<Map<String, dynamic>> getJobReviewData(String jobId) async {
    final job = await _client.from('jobs').select('id, status, customer_approval, customer_rating, assigned_provider_id, provider_notes, completion_notes').eq('id', jobId).single();
    final evidenceRows = await _client.from('job_evidence').select().eq('job_id', jobId).order('created_at');
    final storage = _client.storage.from('job-evidence');
    final evidence = <JobEvidenceModel>[];
    for (final row in evidenceRows) {
      final path = row['storage_path'] as String;
      evidence.add(JobEvidenceModel.fromJson(row, signedUrl: await storage.createSignedUrl(path, 3600)));
    }
    final rating = await _client.from('ratings').select('rating, comment').eq('job_id', jobId).maybeSingle();
    return {'job': job, 'evidence': evidence, 'rating': rating};
  }

  Future<void> approveAndRate({
    required String jobId,
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('You must be signed in.');
    await _client.from('jobs').update({'customer_approval': true, 'customer_rating': rating}).eq('id', jobId);
    await _client.from('ratings').upsert({
      'job_id': jobId,
      'provider_id': providerId,
      'customer_id': user.id,
      'rating': rating,
      'comment': comment,
      'rated_date': DateTime.now().toIso8601String().substring(0, 10),
    }, onConflict: 'job_id,customer_id');
  }
}

final customerReviewRepositoryProvider = Provider<CustomerReviewRepository>((ref) {
  return CustomerReviewRepository(ref.watch(supabaseClientProvider));
});
