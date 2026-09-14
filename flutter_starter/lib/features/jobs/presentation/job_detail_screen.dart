import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/job_model.dart';
import '../providers/jobs_provider.dart';
import 'widgets/status_chip.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isSubmitting = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _startJob(JobModel job) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(jobsRepositoryProvider).startJob(job.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not start job. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _completeJob(JobModel job) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(jobsRepositoryProvider).completeJob(
            jobId: job.id,
            providerNotes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not complete job. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pull the job from whichever list currently has it, so the detail
    // screen updates live without a separate fetch.
    final allJobs = ref.watch(myJobsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.jobId)),
      body: allJobs.when(
        data: (jobs) {
          JobModel? job;
          for (final j in jobs) {
            if (j.id == widget.jobId) {
              job = j;
              break;
            }
          }
          if (job == null) {
            return const Center(child: Text('Job not found.'));
          }
          return _buildBody(job);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong: $e')),
      ),
    );
  }

  Widget _buildBody(JobModel job) {
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final dateFmt = job.scheduledStart != null
        ? DateFormat('EEE, MMM d, y · h:mm a').format(job.scheduledStart!.toLocal())
        : 'Unscheduled';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(status: job.status),
          const SizedBox(height: 12),
          Text(job.jobType ?? 'Job', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _detailRow(Icons.schedule, 'Scheduled', dateFmt),
          if (job.rateAmount != null)
            _detailRow(
              Icons.payments_outlined,
              'Rate',
              '${currency.format(job.rateAmount)}${job.pricingType == 'Hourly' ? ' / hr' : ''}',
            ),
          if (job.estateId != null) _detailRow(Icons.home_work_outlined, 'Estate', job.estateId!),
          if (job.providerNotes != null && job.providerNotes!.isNotEmpty)
            _detailRow(Icons.notes, 'Notes', job.providerNotes!),
          const SizedBox(height: 24),
          if (job.status == 'accepted')
            FilledButton.icon(
              onPressed: _isSubmitting ? null : () => _startJob(job),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Job'),
            ),
          if (job.status == 'in_progress') ...[
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Completion notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : () => _completeJob(job),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark Complete'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
