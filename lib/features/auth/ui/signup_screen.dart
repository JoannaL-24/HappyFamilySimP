import 'package:flutter/cupertino.dart';
import '../data/auth_repository.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authRepo = AuthRepository();

  void _handleSignUp() async {
    try {
      await _authRepo.signUpParent(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
      );
      // Navigate to success or check email page
    } catch (e) {
      // Use your logger here!
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Create Account')),
      child: SafeArea(
        child: Column(
          children: [
            CupertinoTextField(controller: _nameController, placeholder: 'Name'),
            CupertinoTextField(controller: _emailController, placeholder: 'Email'),
            CupertinoTextField(controller: _passwordController, placeholder: 'Password', obscureText: true),
            CupertinoButton.filled(child: Text('Create Account'), onPressed: _handleSignUp),
          ],
        ),
      ),
    );
  }
}
