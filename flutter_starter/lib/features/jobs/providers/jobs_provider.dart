import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/job_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/jobs_repository.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(ref.watch(supabaseClientProvider));
});

/// Single realtime subscription per provider; screens derive their own
/// filtered view from this instead of opening separate streams.
final myJobsStreamProvider = StreamProvider<List<JobModel>>((ref) {
  final providerAsync = ref.watch(currentProviderProvider);
  return providerAsync.when(
    data: (provider) {
      if (provider == null) return const Stream.empty();
      return ref.watch(jobsRepositoryProvider).myJobs(provider.id);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

final offeredJobsProvider = Provider<AsyncValue<List<JobModel>>>((ref) {
  final jobs = ref.watch(myJobsStreamProvider);
  return jobs.whenData((list) => list.where((j) => j.status == 'offered').toList());
});

final activeJobsProvider = Provider<AsyncValue<List<JobModel>>>((ref) {
  final jobs = ref.watch(myJobsStreamProvider);
  return jobs.whenData((list) =>
      list.where((j) => j.status == 'accepted' || j.status == 'in_progress').toList());
});

final jobHistoryProvider = Provider<AsyncValue<List<JobModel>>>((ref) {
  final jobs = ref.watch(myJobsStreamProvider);
  return jobs.whenData((list) =>
      list.where((j) => j.status == 'completed' || j.status == 'cancelled').toList());
});
