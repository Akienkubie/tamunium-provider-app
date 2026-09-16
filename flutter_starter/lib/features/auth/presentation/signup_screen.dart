import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _role = 'customer';
  String _customerType = 'individual';
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  String? _message;

  bool get _isCustomer => _role == 'customer';
  bool get _isBusiness => _customerType == 'business';

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _message = null; });
    try {
      final response = await ref.read(authServiceProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            role: _role,
            phone: _phoneController.text.trim(),
            customerType: _isCustomer ? _customerType : null,
            organizationName: _isCustomer && _isBusiness ? _organizationController.text.trim() : null,
            address: _isCustomer ? _addressController.text.trim() : null,
          );
      if (!mounted) return;
      setState(() => _message = response.session == null
          ? 'Registration received. Check your email to confirm your account, then sign in.'
          : 'Account created. Welcome to TAMUNIUM.');
    } catch (e) {
      if (mounted) setState(() => _message = 'Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoration(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        border: const OutlineInputBorder(),
      );

  InputDecoration _passwordDecoration(String label, bool visible, VoidCallback toggle) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: visible ? 'Hide password' : 'Show password',
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      );

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Enter your $label' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Join TAMUNIUM', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Create a secure account to request services or manage jobs.'),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: _decoration('I am joining as'),
                  items: const [
                    DropdownMenuItem(value: 'customer', child: Text('Customer')),
                    DropdownMenuItem(value: 'provider', child: Text('Service provider')),
                  ],
                  onChanged: _isLoading ? null : (value) => setState(() => _role = value ?? 'customer'),
                ),
                if (_isCustomer) ...[
                  const SizedBox(height: 20),
                  Text('Customer type', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'individual', label: Text('Individual'), icon: Icon(Icons.person_outline)),
                      ButtonSegment(value: 'business', label: Text('Business'), icon: Icon(Icons.business_outlined)),
                    ],
                    selected: {_customerType},
                    onSelectionChanged: _isLoading ? null : (selection) => setState(() => _customerType = selection.first),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(_isBusiness && _isCustomer ? 'Contact person' : 'Full name', icon: Icons.person_outline),
                  validator: (v) => _required(v, _isBusiness && _isCustomer ? 'contact name' : 'full name'),
                ),
                if (_isCustomer && _isBusiness) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _organizationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('Business or organization name', icon: Icons.domain),
                    validator: (v) => _required(v, 'business name'),
                  ),
                ],
                if (_isCustomer) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('Service address', icon: Icons.location_on_outlined),
                    validator: (v) => _required(v, 'service address'),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _decoration('Phone number', icon: Icons.phone_outlined),
                  validator: (v) => _required(v, 'phone number'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration('Email', icon: Icons.email_outlined),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: _passwordDecoration('Password', _showPassword, () => setState(() => _showPassword = !_showPassword)),
                  validator: (v) => v == null || v.length < 8 ? 'Use at least 8 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_showConfirm,
                  decoration: _passwordDecoration('Confirm password', _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                ),
                if (_message != null) ...[const SizedBox(height: 16), Text(_message!)],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
