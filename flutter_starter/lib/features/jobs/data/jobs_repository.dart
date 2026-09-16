import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/job_model.dart';

class JobsRepository {
  final SupabaseClient _client;
  JobsRepository(this._client);

  /// Realtime stream of ALL this provider's jobs, any status. RLS
  /// (`jobs_select`) already restricts rows to jobs assigned to this
  /// provider or visible to staff, so this is safe to query directly.
  /// Screens filter by status client-side (offered / active / history)
  /// so we only need one realtime subscription per provider.
  Future<List<JobModel>> fetchMyJobs(String providerId) async {
    final rows = await _client
        .from('jobs')
        .select()
        .eq('assigned_provider_id', providerId)
        .order('scheduled_start');
    return rows.map(JobModel.fromJson).toList();
  }

  Stream<List<JobModel>> myJobs(String providerId) async* {
    // Always render the current database state first. This prevents a
    // Realtime configuration problem from making a real job appear as zero.
    yield await fetchMyJobs(providerId);

    while (true) {
      try {
        await for (final rows in _client
            .from('jobs')
            .stream(primaryKey: ['id'])
            .eq('assigned_provider_id', providerId)
            .order('scheduled_start')) {
          yield rows.map(JobModel.fromJson).toList();
        }
      } catch (_) {
        // Realtime can be unavailable until the table is added to the
        // publication. Keep the app usable and refresh the database state.
        await Future<void>.delayed(const Duration(seconds: 10));
        yield await fetchMyJobs(providerId);
      }
    }
  }

  Future<JobModel?> getJob(String jobId) async {
    final row = await _client.from('jobs').select().eq('id', jobId).maybeSingle();
    if (row == null) return null;
    return JobModel.fromJson(row);
  }

  /// Provider accepts an offered job. Moves the job to 'accepted', and
  /// best-effort updates the matching `dispatches` row (found via the
  /// job's request_id) so the offer's audit trail stays in sync — if no
  /// matching dispatch row exists (e.g. a manually-assigned job) this
  /// step is silently skipped rather than failing the whole action.
  Future<void> acceptJob(JobModel job) async {
    await _client.from('jobs').update({
      'status': 'accepted',
    }).eq('id', job.id);

    if (job.requestId != null) {
      await _client
          .from('dispatches')
          .update({
            'dispatch_status': 'accepted',
            'response_at': DateTime.now().toIso8601String(),
          })
          .eq('request_id', job.requestId as Object)
          .eq('provider_id', job.assignedProviderId as Object);
    }
  }

  Future<void> rejectJob(JobModel job) async {
    await _client.from('jobs').update({
      'status': 'cancelled',
    }).eq('id', job.id);

    if (job.requestId != null) {
      await _client
          .from('dispatches')
          .update({
            'dispatch_status': 'rejected',
            'response_at': DateTime.now().toIso8601String(),
          })
          .eq('request_id', job.requestId as Object)
          .eq('provider_id', job.assignedProviderId as Object);
    }
  }

  /// Provider marks the job as started. jobs_update RLS lets the
  /// assigned provider change status/timestamps but not rate_amount
  /// or reassign — matches what this call touches.
  Future<void> startJob(String jobId) async {
    await _client.from('jobs').update({
      'status': 'in_progress',
      'actual_start': DateTime.now().toIso8601String(),
    }).eq('id', jobId);
  }

  Future<void> completeJob({
    required String jobId,
    String? providerNotes,
  }) async {
    await _client.from('jobs').update({
      'status': 'completed',
      'actual_end': DateTime.now().toIso8601String(),
      if (providerNotes != null) 'provider_notes': providerNotes,
      'provider_approval': true,
    }).eq('id', jobId);
  }

  Future<void> setAvailability({
    required String providerId,
    required String availability,
  }) async {
    await _client.from('providers').update({
      'current_availability': availability,
      'availability_status': availability,
    }).eq('id', providerId);
  }
}
