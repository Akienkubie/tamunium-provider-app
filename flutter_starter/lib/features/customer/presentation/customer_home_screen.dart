import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/jobs/presentation/widgets/status_chip.dart';
import '../../../models/job_model.dart';
import '../data/customer_jobs_repository.dart';
import 'customer_review_screen.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(customerJobsStreamProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TAMUNIUM'),
          actions: [
            IconButton(
              tooltip: 'Refresh jobs',
              onPressed: () => ref.invalidate(customerJobsStreamProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Active'), Tab(text: 'Completed')]),
        ),
        body: jobsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Could not load your jobs: $error')),
          data: (jobs) {
            final active = jobs.where((job) => !{'completed', 'cancelled'}.contains(job.status)).toList();
            final completed = jobs.where((job) => job.status == 'completed').toList();
            return TabBarView(
              children: [
                _JobList(jobs: active, emptyText: 'No active jobs yet.'),
                _JobList(jobs: completed, emptyText: 'No completed jobs yet.'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  final List<JobModel> jobs;
  final String emptyText;
  const _JobList({required this.jobs, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return Center(child: Text(emptyText));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(job.jobType ?? 'Service job', style: Theme.of(context).textTheme.titleMedium)),
                    StatusChip(status: job.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Job ${job.id}', style: Theme.of(context).textTheme.bodySmall),
                if (job.providerNotes != null && job.providerNotes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(job.providerNotes!),
                ],
                if (job.rateAmount != null) ...[
                  const SizedBox(height: 8),
                  Text('Rate: ₦${job.rateAmount!.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy)),
                ],
                if (job.status == 'completed') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CustomerReviewScreen(jobId: job.id)),
                    ),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Review provider'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
