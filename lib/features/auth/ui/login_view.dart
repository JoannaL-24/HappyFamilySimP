import 'package:flutter/material.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final Function(String) onLoginSuccess;
  const LoginScreen({
    super.key,
    required this.authRepository,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _parentFormKey = GlobalKey<FormState>();
  final _childFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _childCodeController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isCodeVisible = false;
  bool _isLoading = false;

  Future<void> _handleLogin(GlobalKey<FormState> formKey) async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final isParent = formKey == _parentFormKey;
        final email = isParent
            ? _emailController.text.trim()
            : Utils.getChildEmail(
                _emailController.text.trim(),
                _childCodeController.text,
              );
        final password = isParent
            ? _passwordController.text
            : _childCodeController.text;

        final role = await widget.authRepository.signIn(email, password);

        if (mounted) {
          // update current role in main app state
          // rebuild the router widget, so don't need to redirect
          widget.onLoginSuccess(role);

          Utils.showSuccess('Welcome back!');
        }
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        Utils.showError(message);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Happy Family Sim'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.supervisor_account), text: 'Parent'),
              Tab(icon: Icon(Icons.child_care), text: 'Child'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildParentLoginForm(), _buildChildLoginForm()],
        ),
      ),
    );
  }

  Widget _buildParentLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _parentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Log in with parent',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => Utils.emailValidator(value),
            ),
            const SizedBox(height: 16),

            // password
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  context.go('/forgot-password');
                }, // TODO: forgot password user story
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 24),

            // login Button
            ElevatedButton(
              onPressed: _isLoading ? null : () => _handleLogin(_parentFormKey),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _childFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Log in with child',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => Utils.emailValidator(value),
            ),
            const SizedBox(height: 16),

            // 6-digit code
            TextFormField(
              controller: _childCodeController,
              keyboardType: TextInputType.number,
              obscureText: !_isCodeVisible,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: '6-digit code',
                counterText: '',
                prefixIcon: const Icon(Icons.numbers),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isCodeVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _isCodeVisible = !_isCodeVisible),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your 6-digit code';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            // login Button
            ElevatedButton(
              onPressed: _isLoading ? null : () => _handleLogin(_childFormKey),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _childCodeController.dispose();
    super.dispose();
  }
}
