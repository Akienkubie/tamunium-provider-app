import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/jobs_provider.dart';
import 'job_detail_screen.dart';
import 'widgets/job_card.dart';

/// Jobs this provider has accepted — active work plus completed history,
/// in separate tabs so "what's next" and "what did I finish" don't compete.
class MyJobsScreen extends ConsumerWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeJobsProvider);
    final historyAsync = ref.watch(jobHistoryProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Jobs'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Active'), Tab(text: 'History')],
          ),
        ),
        body: TabBarView(
          children: [
            activeAsync.when(
              data: (jobs) => jobs.isEmpty
                  ? const Center(child: Text('No active jobs.'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: jobs
                          .map((j) => JobCard(
                                job: j,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => JobDetailScreen(jobId: j.id),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Something went wrong: $e')),
            ),
            historyAsync.when(
              data: (jobs) => jobs.isEmpty
                  ? const Center(child: Text('No completed jobs yet.'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: jobs
                          .map((j) => JobCard(
                                job: j,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => JobDetailScreen(jobId: j.id),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Something went wrong: $e')),
            ),
          ],
        ),
      ),
    );
  }
}
