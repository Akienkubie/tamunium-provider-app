import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/tamunium_avatar.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    final user = Supabase.instance.client.auth.currentUser;
    final provider = ref.read(currentProviderProvider).valueOrNull;
    if (user == null || provider == null) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final bytes = await picked.readAsBytes();
      final extension = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final path = '${user.id}/avatar.$extension';
      final storage = Supabase.instance.client.storage.from('profile-avatars');
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$extension', upsert: true),
      );
      final publicUrl = storage.getPublicUrl(path);
      await Supabase.instance.client
          .from('providers')
          .update({'photo_url': publicUrl})
          .eq('id', provider.id);
      ref.invalidate(currentProviderProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not upload photo: $error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerAsync = ref.watch(currentProviderProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Profile')),
      body: providerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load profile: $error')),
        data: (provider) {
          if (provider == null) return const Center(child: Text('Provider profile not found.'));
          final verified = provider.verificationStatus == 'verified';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    TamuniumAvatar(
                      imageUrl: provider.photoUrl,
                      name: provider.fullName,
                      size: 132,
                      verified: verified,
                    ),
                    FloatingActionButton.small(
                      heroTag: 'profile-photo',
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.navy,
                      onPressed: _uploading ? null : _pickAndUpload,
                      child: _uploading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.camera_alt_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(provider.fullName, style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(height: 6),
              Center(child: Text(verified ? 'Verified Provider' : 'Verification pending')),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Provider details', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 14),
                      _row('Career level', provider.careerLevel),
                      _row('Availability', provider.currentAvailability.replaceAll('_', ' ')),
                      _row('Rating', provider.overallRating.toStringAsFixed(1)),
                      _row('Jobs completed', '${provider.jobsCompleted}'),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              const Text('Use a clear, professional photo. JPG, PNG, and WebP images up to 5 MB are supported.'),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
        ),
      );
}
