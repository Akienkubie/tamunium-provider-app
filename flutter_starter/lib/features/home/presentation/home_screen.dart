import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/presentation/customer_home_screen.dart';
import '../../dispatcher/presentation/dispatcher_shortlist_screen.dart';
import 'provider_home_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return profile.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Could not load account: $error'))),
      data: (profile) {
        final role = profile?['role']?.toString().toLowerCase();
        if (role == 'customer' || role == 'client') return const CustomerHomeScreen();
        if ({'dispatcher', 'operations_manager', 'platform_admin', 'facility_manager'}.contains(role)) {
          return const DispatcherShortlistScreen();
        }
        return const ProviderHomeScreen();
      },
    );
  }
}
