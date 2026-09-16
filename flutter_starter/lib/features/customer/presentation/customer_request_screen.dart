import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_request_repository.dart';

class CustomerRequestScreen extends ConsumerStatefulWidget {
  const CustomerRequestScreen({super.key});

  @override
  ConsumerState<CustomerRequestScreen> createState() => _CustomerRequestScreenState();
}

class _CustomerRequestScreenState extends ConsumerState<CustomerRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String? _categoryId;
  String _priority = 'normal';
  String? _timeWindow;
  DateTime? _preferredDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
      initialDate: _preferredDate ?? today,
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(customerRequestRepositoryProvider).submitRequest(
            categoryId: _categoryId!,
            serviceType: _serviceTypeController.text.trim(),
            description: _descriptionController.text.trim(),
            serviceAddress: _addressController.text.trim(),
            priority: _priority,
            preferredDate: _preferredDate,
            preferredTimeWindow: _timeWindow,
            customerNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted. TAMUNIUM Central will review it shortly.')));
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit request: $error')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _dateLabel() {
    final date = _preferredDate;
    if (date == null) return 'Choose a preferred date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(activeServiceCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Request a service')),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load services: $error')),
        data: (items) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Tell us what you need', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('We will match your request with qualified, available providers near you.'),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Service category', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_outlined)),
                items: items.map((item) => DropdownMenuItem<String>(value: item['id'] as String, child: Text(item['category_name'] as String))).toList(),
                onChanged: _isSubmitting ? null : (value) => setState(() => _categoryId = value),
                validator: (value) => value == null ? 'Select a service category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceTypeController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Service needed', hintText: 'For example: leaking kitchen tap', border: OutlineInputBorder(), prefixIcon: Icon(Icons.build_outlined)),
                validator: (value) => value == null || value.trim().length < 3 ? 'Describe the service needed' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Describe the problem', hintText: 'Add useful details for the provider and dispatcher.', border: OutlineInputBorder(), alignLabelWithHint: true),
                validator: (value) => value == null || value.trim().length < 10 ? 'Add at least a few details about the request' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Service address', hintText: 'Where should the provider come?', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (value) => value == null || value.trim().length < 5 ? 'Enter the service address' : null,
              ),
              const SizedBox(height: 20),
              Text('Urgency', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'low', label: Text('Low')),
                  ButtonSegment(value: 'normal', label: Text('Normal')),
                  ButtonSegment(value: 'high', label: Text('High')),
                  ButtonSegment(value: 'emergency', label: Text('Emergency')),
                ],
                selected: {_priority},
                onSelectionChanged: _isSubmitting ? null : (selection) => setState(() => _priority = selection.first),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(onPressed: _isSubmitting ? null : _chooseDate, icon: const Icon(Icons.calendar_today_outlined), label: Text(_dateLabel())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _timeWindow,
                decoration: const InputDecoration(labelText: 'Preferred time window (optional)', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'morning', child: Text('Morning (8:00–12:00)')),
                  DropdownMenuItem(value: 'afternoon', child: Text('Afternoon (12:00–16:00)')),
                  DropdownMenuItem(value: 'evening', child: Text('Evening (16:00–20:00)')),
                ],
                onChanged: _isSubmitting ? null : (value) => setState(() => _timeWindow = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Additional notes (optional)', border: OutlineInputBorder(), alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_outlined),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
