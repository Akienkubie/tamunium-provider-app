import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/workforce_onboarding_repository.dart';

class WorkforceOnboardingScreen extends ConsumerStatefulWidget {
  const WorkforceOnboardingScreen({super.key});

  @override
  ConsumerState<WorkforceOnboardingScreen> createState() => _WorkforceOnboardingScreenState();
}

class _WorkforceOnboardingScreenState extends ConsumerState<WorkforceOnboardingScreen> {
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _surname = TextEditingController();
  final _phone = TextEditingController();
  final _experience = TextEditingController(text: '0');
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _bank = TextEditingController();
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _picker = ImagePicker();
  int _stage = 1;
  String _track = 'artisan';
  bool _acceptedSafety = false;
  bool _saving = false;
  final Set<String> _selectedCategories = {};
  final Map<String, Map<String, dynamic>> _categoryRows = {};
  String? _error;

  @override
  void dispose() {
    for (final c in [_first, _middle, _surname, _phone, _experience, _emergencyName, _emergencyPhone, _bank, _accountName, _accountNumber]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    setState(() { _saving = true; _error = null; });
    try {
      final repo = ref.read(workforceOnboardingRepositoryProvider);
      if (_stage == 1) {
        if (_first.text.trim().isEmpty || _surname.text.trim().isEmpty || _phone.text.trim().isEmpty) throw Exception('First name, surname, and phone are required.');
        await repo.saveIdentity(firstName: _first.text, middleName: _middle.text, surname: _surname.text, phone: _phone.text, workforceTrack: _track, nextStage: 2);
      } else if (_stage == 2) {
        if (_selectedCategories.isEmpty) throw Exception('Select at least one service.');
        await repo.saveCapabilities(workforceTrack: _track, capabilities: _selectedCategories.map((id) => {'service_category_id': id, 'skill_level': _track == 'labour_corps' ? 'entry' : 'intermediate', 'years_experience': double.tryParse(_experience.text) ?? 0, 'requires_supervision': (_categoryRows[id]?['requires_supervision'] == true)}).toList(), nextStage: 3);
      } else if (_stage == 3) {
        if (_track == 'artisan' && _categoryRows.values.any((r) => _selectedCategories.contains(r['id']) && r['requires_certificate'] == true)) {
          // Evidence can be uploaded progressively; Central will keep the application under review until complete.
        }
        await _advanceStage(4);
      } else if (_stage == 4) {
        await repo.saveSafety(emergencyName: _emergencyName.text, emergencyPhone: _emergencyPhone.text, accepted: _acceptedSafety, nextStage: 5);
      } else {
        if (_bank.text.trim().isEmpty || _accountName.text.trim().isEmpty || _accountNumber.text.trim().isEmpty) throw Exception('Complete all payout fields.');
        await repo.savePayout(bankName: _bank.text, accountName: _accountName.text, accountNumber: _accountNumber.text);
        await repo.submit();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted to TAMUNIUM Central for review.')));
      }
      if (_stage < 5 && mounted) setState(() => _stage++);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _advanceStage(int stage) async {
    await ref.read(workforceOnboardingRepositoryProvider).advanceToStage(stage);
  }

  Future<void> _upload(String type) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1800, maxHeight: 1800, imageQuality: 82);
    if (file == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(workforceOnboardingRepositoryProvider).uploadDocument(file: file, documentType: type);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_label(type)} uploaded for review.')));
    } catch (error) {
      if (mounted) setState(() => _error = 'Upload failed: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _label(String value) => value.replaceAll('_', ' ').split(' ').map((v) => v.isEmpty ? v : '${v[0].toUpperCase()}${v.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(currentProviderProvider).valueOrNull;
    if (provider != null && _first.text.isEmpty) {
      final parts = provider.fullName.trim().split(RegExp(r'\s+'));
      _first.text = parts.first;
      _surname.text = parts.length > 1 ? parts.last : '';
      _middle.text = parts.length > 2 ? parts.sublist(1, parts.length - 1).join(' ') : '';
      _phone.text = provider.phone ?? '';
    }
    return Scaffold(appBar: AppBar(title: const Text('Workforce onboarding')), body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Join the TAMUNIUM internal workforce', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4), const Text('Learn, grow, and receive work that matches your approved skills.'),
      const SizedBox(height: 20), _Progress(stage: _stage), const SizedBox(height: 24),
      if (_stage == 1) _stageOne(),
      if (_stage == 2) _stageTwo(),
      if (_stage == 3) _stageThree(),
      if (_stage == 4) _stageFour(),
      if (_stage == 5) _stageFive(),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      const SizedBox(height: 24), FilledButton(onPressed: _saving ? null : _next, child: _saving ? const CircularProgressIndicator() : Text(_stage == 5 ? 'Submit for Central review' : 'Save and continue')),
      if (_stage > 1) TextButton(onPressed: _saving ? null : () => setState(() => _stage--), child: const Text('Back')),
    ]));
  }

  Widget _stageOne() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('1. Personal identity', 'Use your legal name. This name must match your verification and payout details.'),
    _field(_first, 'First name *'), _field(_middle, 'Middle name'), _field(_surname, 'Surname *'), _field(_phone, 'Phone number *', keyboard: TextInputType.phone),
    const SizedBox(height: 12), const Text('Workforce track', style: TextStyle(fontWeight: FontWeight.bold)),
    DropdownButtonFormField<String>(
      initialValue: _track,
      decoration: const InputDecoration(labelText: 'Workforce track'),
      items: const [
        DropdownMenuItem(value: 'artisan', child: Text('Skilled artisan')),
        DropdownMenuItem(value: 'labour_corps', child: Text('TAMUNIUM Labour Corps')),
      ],
      onChanged: (value) => setState(() => _track = value ?? 'artisan'),
    ),
    const SizedBox(height: 8),
    Text(_track == 'artisan' ? 'Technical work such as plumbing, electrical, or HVAC.' : 'Flexible hourly and support work such as lawn care, cleaning, or kitchen assistance.'),
  ]);

  Widget _stageTwo() {
    final categories = ref.watch(workforceCategoriesProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('2. Skills and services', 'Select only services you can safely perform.'),
      _field(_experience, 'Years of experience', keyboard: TextInputType.number),
      categories.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Text('Could not load services: $e'), data: (items) {
        final filtered = items.where((r) => r['workforce_track'] == _track).toList();
        for (final row in filtered) {
          _categoryRows[row['id'].toString()] = row;
        }
        return Column(
          children: filtered.map((row) {
            final id = row['id'].toString();
            return CheckboxListTile(
              value: _selectedCategories.contains(id),
              onChanged: (checked) => setState(() {
                if (checked == true) {
                  _selectedCategories.add(id);
                } else {
                  _selectedCategories.remove(id);
                }
              }),
              title: Text(row['category_name'].toString()),
              subtitle: Text(row['supports_hourly_work'] == true ? 'Hourly work available' : row['requires_certificate'] == true ? 'Certificate required for approval' : 'Approval and safety review required'),
            );
          }).toList(),
        );
      }),
    ]);
  }

  Widget _stageThree() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('3. Training, certificates, and work evidence', 'Upload clear photos. Central staff will review each item privately.'),
    if (_track == 'artisan') ...[_uploadTile('apprentice_certificate', Icons.school_outlined), _uploadTile('school_certificate', Icons.workspace_premium_outlined), _uploadTile('trade_certificate', Icons.card_membership_outlined), _uploadTile('nabteb_certificate', Icons.verified_outlined)],
    _uploadTile('government_id', Icons.badge_outlined), _uploadTile('work_reference', Icons.people_outline), _uploadTile('completed_work_photo', Icons.photo_library_outlined),
  ]);

  Widget _stageFour() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('4. Identity and safety', 'These checks protect you, customers, and the TAMUNIUM platform.'),
    _uploadTile('government_id', Icons.badge_outlined), _field(_emergencyName, 'Emergency contact name'), _field(_emergencyPhone, 'Emergency contact phone', keyboard: TextInputType.phone),
    CheckboxListTile(value: _acceptedSafety, onChanged: (v) => setState(() => _acceptedSafety = v ?? false), title: const Text('I agree to TAMUNIUM safety, honesty, and customer-conduct requirements.'), controlAffinity: ListTileControlAffinity.leading),
  ]);

  Widget _stageFive() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('5. Payout details', 'Your account name must match the legal name on your TAMUNIUM profile. Central will verify it before payout eligibility.'),
    _field(_bank, 'Bank name'), _field(_accountName, 'Account holder name'), _field(_accountNumber, 'Account number', keyboard: TextInputType.number),
    const Card(color: AppTheme.cream, child: Padding(padding: EdgeInsets.all(14), child: Text('Payout details remain pending until your identity, skills, safety review, and account-name match are approved by TAMUNIUM Central.'))),
  ]);

  Widget _uploadTile(String type, IconData icon) => Card(child: ListTile(leading: Icon(icon, color: AppTheme.navy), title: Text(_label(type)), subtitle: const Text('Tap to select a secure upload'), trailing: const Icon(Icons.upload_file), onTap: _saving ? null : () => _upload(type)));
  Widget _heading(String title, String description) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(description)]));
  Widget _field(TextEditingController controller, String label, {TextInputType? keyboard}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: controller, keyboardType: keyboard, decoration: InputDecoration(labelText: label)));
}

class _Progress extends StatelessWidget {
  final int stage;
  const _Progress({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: index < stage ? 1 : 0,
                  minHeight: 7,
                  color: index < stage ? AppTheme.gold : Colors.black12,
                ),
                const SizedBox(height: 6),
                Text('${index + 1}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      }),
    );
  }
}
