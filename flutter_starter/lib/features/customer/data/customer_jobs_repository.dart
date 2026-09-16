import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/job_model.dart';
import '../../auth/providers/auth_provider.dart';

class CustomerJobsRepository {
  final SupabaseClient _client;
  CustomerJobsRepository(this._client);

  Future<List<JobModel>> fetchJobs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client
        .from('jobs')
        .select('*, service_requests!inner(customer_id)')
        .eq('service_requests.customer_id', user.id)
        .order('created_at', ascending: false);
    return rows.map(JobModel.fromJson).toList();
  }

  Stream<List<JobModel>> jobs() async* {
    yield await fetchJobs();
    while (true) {
      try {
        await for (final rows in _client
            .from('jobs')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)) {
          final user = _client.auth.currentUser;
          if (user == null) {
            yield [];
            continue;
          }
          final requests = await _client
              .from('service_requests')
              .select('id')
              .eq('customer_id', user.id);
          final requestIds = requests.map((r) => r['id']).toSet();
          yield rows
              .where((row) => requestIds.contains(row['request_id']))
              .map(JobModel.fromJson)
              .toList();
        }
      } catch (_) {
        await Future<void>.delayed(const Duration(seconds: 10));
        yield await fetchJobs();
      }
    }
  }
}

final customerJobsRepositoryProvider = Provider<CustomerJobsRepository>((ref) {
  return CustomerJobsRepository(ref.watch(supabaseClientProvider));
});

final customerJobsStreamProvider = StreamProvider<List<JobModel>>((ref) {
  return ref.watch(customerJobsRepositoryProvider).jobs();
});
