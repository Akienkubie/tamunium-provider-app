import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).updatePassword(_passwordController.text);
      await ref.read(authServiceProvider).signOut();
      if (!mounted) return;
      setState(() => _message = 'Password updated. You can now sign in with your new password.');
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = _friendlyError(error));
    } catch (_) {
      if (mounted) setState(() => _message = 'Password update failed. Request a new reset email and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(AuthException error) {
    if (error.code == 'same_password') return 'Choose a password different from the old password.';
    if (error.code == 'weak_password') return 'Choose a stronger password with at least eight characters.';
    return 'Password update failed. The reset link may have expired.';
  }

  InputDecoration _decoration(String label, bool visible, VoidCallback toggle) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: IconButton(
        tooltip: visible ? 'Hide password' : 'Show password',
        icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
        onPressed: toggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Choose a new password', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Use at least eight characters. You can show or hide the password while typing.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: _decoration('New password', _showPassword, () => setState(() => _showPassword = !_showPassword)),
                  validator: (value) => value == null || value.length < 8 ? 'Use at least 8 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_showConfirm,
                  decoration: _decoration('Confirm new password', _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
                  validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Update password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
