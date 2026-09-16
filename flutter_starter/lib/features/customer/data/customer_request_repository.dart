import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_provider.dart';

class CustomerRequestRepository {
  final SupabaseClient _client;
  const CustomerRequestRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchActiveCategories() async {
    final rows = await _client
        .from('service_categories')
        .select('id, category_name, description, typical_duration_hrs, service_mode')
        .eq('status', 'active')
        .order('category_name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<String> _customerId() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('You must be signed in to request a service.');
    final row = await _client
        .from('customers')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) throw StateError('Your customer profile is not ready yet. Please sign out and sign in again.');
    return row['id'] as String;
  }

  Future<void> submitRequest({
    required String categoryId,
    required String serviceType,
    required String description,
    required String serviceAddress,
    required String priority,
    DateTime? preferredDate,
    String? preferredTimeWindow,
    String? customerNotes,
  }) async {
    final customerId = await _customerId();
    final requestId = 'REQ-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('service_requests').insert({
      'id': requestId,
      'customer_id': customerId,
      'category_id': categoryId,
      'service_type': serviceType,
      'description': description,
      'service_address': serviceAddress,
      'location': serviceAddress,
      'priority': priority,
      'preferred_date': preferredDate?.toIso8601String().split('T').first,
      'preferred_time_window': preferredTimeWindow,
      'notes': customerNotes,
      'status': 'submitted',
      'submitted_at': now,
      'updated_at': now,
    });
  }
}

final customerRequestRepositoryProvider = Provider<CustomerRequestRepository>((ref) {
  return CustomerRequestRepository(ref.watch(supabaseClientProvider));
});

final activeServiceCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(customerRequestRepositoryProvider).fetchActiveCategories();
});
