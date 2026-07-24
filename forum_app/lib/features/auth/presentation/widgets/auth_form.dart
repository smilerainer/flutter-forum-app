import 'package:flutter/material.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/core/validators.dart';

class AuthForm extends StatefulWidget {
  final String submitLabel;
  final Future<Result<void>> Function(String email, String password) onSubmit;
  final VoidCallback? onSuccess;

  const AuthForm({super.key, required this.submitLabel, required this.onSubmit, this.onSuccess});

  // Test keys — not visible in the UI
  static const emailFieldKey = Key('auth_email_field');
  static const passwordFieldKey = Key('auth_password_field');
  static const submitBtnKey = Key('auth_submit_btn');

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final result = await widget.onSubmit(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success():
        widget.onSuccess?.call();
      case Failure(:final message):
        setState(() => _error = message);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: AuthForm.emailFieldKey,
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: Validators.email,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: AuthForm.passwordFieldKey,
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: Validators.password,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          _loading
              ? const CircularProgressIndicator()
              : ElevatedButton(key: AuthForm.submitBtnKey, onPressed: _submit, child: Text(widget.submitLabel)),
        ],
      ),
    );
  }
}