import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/job_model.dart';
import '../providers/jobs_provider.dart';
import 'widgets/job_card.dart';
import 'job_detail_screen.dart';

/// Jobs currently offered to this provider, awaiting accept/reject.
class AvailableJobsScreen extends ConsumerWidget {
  const AvailableJobsScreen({super.key});

  Future<void> _accept(BuildContext context, WidgetRef ref, JobModel job) async {
    try {
      await ref.read(jobsRepositoryProvider).acceptJob(job);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Accepted ${job.id}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not accept job. Try again.')));
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, JobModel job) async {
    try {
      await ref.read(jobsRepositoryProvider).rejectJob(job);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Declined ${job.id}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not decline job. Try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeredAsync = ref.watch(offeredJobsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Available Jobs')),
      body: offeredAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No open offers right now.\nNew dispatches will show up here in real time.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: jobs.length,
            itemBuilder: (context, i) {
              final job = jobs[i];
              return Column(
                children: [
                  JobCard(
                    job: job,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _reject(context, ref, job),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _accept(context, ref, job),
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong: $e')),
      ),
    );
  }
}
