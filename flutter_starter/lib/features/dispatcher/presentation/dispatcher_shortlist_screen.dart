import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dispatcher_repository.dart';

class DispatcherShortlistScreen extends ConsumerStatefulWidget {
  const DispatcherShortlistScreen({super.key});

  @override
  ConsumerState<DispatcherShortlistScreen> createState() => _DispatcherShortlistScreenState();
}

class _DispatcherShortlistScreenState extends ConsumerState<DispatcherShortlistScreen> {
  String? _rankingRequest;
  String? _assigningProvider;
  final Map<String, List<Map<String, dynamic>>> _matches = {};
  final Set<String> _assignedRequests = {};

  Future<void> _rank(String requestId) async {
    setState(() => _rankingRequest = requestId);
    try {
      await ref.read(dispatcherRepositoryProvider).rankProviders(requestId);
      final matches = await ref.read(dispatcherRepositoryProvider).fetchMatches(requestId);
      if (mounted) setState(() => _matches[requestId] = matches);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not rank providers: $error')));
    } finally {
      if (mounted) setState(() => _rankingRequest = null);
    }
  }

  Future<void> _assign(String requestId, String providerId, String providerName) async {
    setState(() => _assigningProvider = providerId);
    try {
      final result = await ref.read(dispatcherRepositoryProvider).assignProvider(requestId: requestId, providerId: providerId);
      if (!mounted) return;
      setState(() => _assignedRequests.add(requestId));
      ref.invalidate(dispatcherOpenRequestsProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$providerName assigned. Job ${result['job_id']} offered.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not assign provider: $error')));
    } finally {
      if (mounted) setState(() => _assigningProvider = null);
    }
  }

  String _text(dynamic value, [String fallback = '—']) => value?.toString().isNotEmpty == true ? value.toString() : fallback;

  Widget _score(String label, dynamic value) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_text(value), style: const TextStyle(fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 11))]));

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(dispatcherOpenRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('TAMUNIUM Central'), actions: [IconButton(onPressed: () => ref.invalidate(dispatcherOpenRequestsProvider), icon: const Icon(Icons.refresh), tooltip: 'Refresh requests')]),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load dispatcher queue: $error'))),
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('No submitted requests need matching.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = items[index];
              final id = request['id'].toString();
              final category = (request['service_categories'] as Map?)?['category_name']?.toString();
              final matches = _matches[id];
              final assigned = _assignedRequests.contains(id);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(_text(request['service_type'], category ?? 'Service request'), style: Theme.of(context).textTheme.titleMedium)), Chip(label: Text(_text(request['status']))) ]),
                    const SizedBox(height: 6),
                    Text('Request $id'),
                    Text('Priority: ${_text(request['priority'])} · ${_text(request['service_address'], 'Address pending')}'),
                    const SizedBox(height: 12),
                    if (!assigned) SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _rankingRequest == id ? null : () => _rank(id), icon: _rankingRequest == id ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: Text(_rankingRequest == id ? 'Ranking providers...' : 'Rank providers'))),
                    if (assigned) const Padding(padding: EdgeInsets.only(top: 12), child: Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Provider assigned and offer sent')])),
                    if (matches != null) ...[
                      const SizedBox(height: 12),
                      Text('${matches.length} ranked provider${matches.length == 1 ? '' : 's'}', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      ...matches.map((match) => _MatchCard(match: match, score: _score, assigning: _assigningProvider == match['provider_id'], disabled: assigned || _assigningProvider != null, onAssign: () => _assign(id, match['provider_id'].toString(), ((match['providers'] as Map?)?['full_name']?.toString() ?? 'Provider')))),
                    ],
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final Widget Function(String, dynamic) score;
  final bool assigning;
  final bool disabled;
  final VoidCallback onAssign;
  const _MatchCard({required this.match, required this.score, required this.assigning, required this.disabled, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    final provider = (match['providers'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [CircleAvatar(child: Text((provider['full_name']?.toString() ?? 'P').substring(0, 1).toUpperCase())), const SizedBox(width: 10), Expanded(child: Text(provider['full_name']?.toString() ?? 'Provider', style: const TextStyle(fontWeight: FontWeight.bold))), Chip(label: Text('#${match['rank'] ?? '—'}'))]),
        const SizedBox(height: 8),
        Row(children: [score('Match', match['match_score']), score('Skills', match['skill_score']), score('Rating', match['rating_score']), score('Distance', match['distance_km'] == null ? '—' : '${match['distance_km']} km')]),
        const SizedBox(height: 6),
        Row(children: [score('Reliability', match['reliability_score']), score('Availability', match['availability_score']), score('Jobs', provider['jobs_completed']), score('Rating', provider['overall_rating'])]),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: disabled ? null : onAssign, icon: assigning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_outlined), label: Text(assigning ? 'Assigning...' : 'Assign provider'))),
      ]),
    );
  }
}
