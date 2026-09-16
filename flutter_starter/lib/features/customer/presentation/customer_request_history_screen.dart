import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_request_repository.dart';

class CustomerRequestHistoryScreen extends ConsumerWidget {
  const CustomerRequestHistoryScreen({super.key});

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'cancelled': return Theme.of(context).colorScheme.error;
      case 'in_progress': return Colors.blue;
      case 'dispatched':
      case 'accepted': return Colors.orange;
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(customerRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My requests'), actions: [
        IconButton(onPressed: () => ref.invalidate(customerRequestsProvider), icon: const Icon(Icons.refresh), tooltip: 'Refresh requests'),
      ]),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load requests: $error'))),
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('You have not submitted a service request yet.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final status = item['status']?.toString() ?? 'draft';
              final category = (item['service_categories'] as Map?)?['category_name']?.toString();
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(item['service_type']?.toString() ?? category ?? 'Service request'),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 8), child: Text('${category ?? 'Service'}\n${item['service_address'] ?? 'Address pending'}')),
                  isThreeLine: true,
                  trailing: Chip(label: Text(status.replaceAll('_', ' ')), labelStyle: TextStyle(color: _statusColor(context, status)), side: BorderSide(color: _statusColor(context, status))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
