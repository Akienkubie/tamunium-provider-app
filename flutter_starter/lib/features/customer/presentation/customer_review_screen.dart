import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/job_evidence_model.dart';
import '../data/customer_review_repository.dart';
import '../data/customer_jobs_repository.dart';

class CustomerReviewScreen extends ConsumerStatefulWidget {
  final String jobId;
  const CustomerReviewScreen({super.key, required this.jobId});

  @override
  ConsumerState<CustomerReviewScreen> createState() => _CustomerReviewScreenState();
}

class _CustomerReviewScreenState extends ConsumerState<CustomerReviewScreen> {
  int _rating = 0;
  bool _loading = true;
  bool _submitting = false;
  String? _providerId;
  String? _error;
  List<JobEvidenceModel> _evidence = [];
  Map<String, dynamic>? _job;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(customerReviewRepositoryProvider).getJobReviewData(widget.jobId);
      final job = data['job'] as Map<String, dynamic>;
      final existing = data['rating'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _job = job;
          _providerId = job['assigned_provider_id'] as String?;
          _evidence = (data['evidence'] as List<JobEvidenceModel>);
          _rating = (existing?['rating'] as num?)?.toInt() ?? 0;
          _commentController.text = existing?['comment'] as String? ?? '';
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() { _error = 'Could not load review: $error'; _loading = false; });
    }
  }

  Future<void> _submit() async {
    if (_rating < 1 || _providerId == null) {
      setState(() => _error = 'Choose a rating from 1 to 5 stars.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await ref.read(customerReviewRepositoryProvider).approveAndRate(
        jobId: widget.jobId,
        providerId: _providerId!,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      ref.invalidate(customerJobsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job approved and review submitted.')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not submit review: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Review Provider')), body: const Center(child: CircularProgressIndicator()));
    if (_error != null && _job == null) return Scaffold(appBar: AppBar(title: const Text('Review Provider')), body: Center(child: Text(_error!)));
    final alreadyApproved = _job?['customer_approval'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Review Provider')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('How was your service?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Job ${widget.jobId}', style: Theme.of(context).textTheme.bodySmall),
          if ((_job?['completion_notes'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_job!['completion_notes'] as String))),
          ],
          const SizedBox(height: 20),
          Text('Completion evidence', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_evidence.isEmpty) const Text('No completion photos were uploaded.')
          else SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _evidence.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_evidence[index].signedUrl!, width: 110, height: 110, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Rate the provider', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => IconButton(
              onPressed: alreadyApproved ? null : () => setState(() => _rating = index + 1),
              iconSize: 42,
              color: AppTheme.gold,
              icon: Icon(index < _rating ? Icons.star : Icons.star_border),
            )),
          ),
          TextField(
            controller: _commentController,
            enabled: !alreadyApproved,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Comment (optional)', border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: alreadyApproved || _submitting ? null : _submit,
            icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
            label: Text(alreadyApproved ? 'Already approved' : 'Approve and submit review'),
          ),
        ],
      ),
    );
  }
}
