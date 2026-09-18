import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../jobs/providers/jobs_provider.dart';
import '../../jobs/presentation/available_jobs_screen.dart';
import '../../jobs/presentation/my_jobs_screen.dart';
import '../../profile/presentation/provider_profile_screen.dart';
import '../../workforce/presentation/workforce_onboarding_screen.dart';
import '../../../shared/widgets/tamunium_avatar.dart';

const _availabilityOptions = ['available', 'busy', 'offline', 'on_leave'];

/// Landing screen after login: availability toggle + earnings/job summary,
/// plus quick nav into Available Jobs and My Jobs.
class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  Future<void> _changeAvailability(
    BuildContext context,
    WidgetRef ref,
    String providerId,
    String newValue,
  ) async {
    try {
      await ref.read(jobsRepositoryProvider).setAvailability(
            providerId: providerId,
            availability: newValue,
          );
      ref.invalidate(currentProviderProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update availability.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(currentProviderProvider);
    final offeredCount =
        ref.watch(offeredJobsProvider).maybeWhen(data: (l) => l.length, orElse: () => 0);
    final activeCount =
        ref.watch(activeJobsProvider).maybeWhen(data: (l) => l.length, orElse: () => 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: providerAsync.when(
        data: (provider) {
          if (provider == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This account isn\'t linked to a provider profile yet. '
                  'Contact your dispatcher.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: TamuniumAvatar(
                    imageUrl: provider.photoUrl,
                    name: provider.fullName,
                    size: 58,
                    verified: provider.verificationStatus == 'verified',
                  ),
                  title: Text('Welcome back, ${provider.fullName}'),
                  subtitle: const Text('View and update your provider profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProviderProfileScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Availability', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _availabilityOptions.map((opt) {
                            final selected = provider.currentAvailability == opt;
                            return ChoiceChip(
                              label: Text(opt.replaceAll('_', ' ')),
                              selected: selected,
                              onSelected: (_) => _changeAvailability(
                                context,
                                ref,
                                provider.id,
                                opt,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.assignment_outlined),
                  title: const Text('Workforce onboarding'),
                  subtitle: const Text('Complete verification to become eligible for matched jobs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkforceOnboardingScreen())),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(label: 'Rating', value: provider.overallRating.toStringAsFixed(1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(label: 'Completed', value: '${provider.jobsCompleted}'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Badge(
                    label: Text('$offeredCount'),
                    isLabelVisible: offeredCount > 0,
                    child: const Icon(Icons.inbox_outlined),
                  ),
                  title: const Text('Available Jobs'),
                  subtitle: Text('$offeredCount new offer${offeredCount == 1 ? '' : 's'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AvailableJobsScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.work_outline),
                  title: const Text('My Jobs'),
                  subtitle: Text('$activeCount active'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyJobsScreen()),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong: $e')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
