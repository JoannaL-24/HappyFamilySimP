import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _pickedImage;
  String? _originalName;
  String? _originalAvatarUrl;
  bool _isLoading = true;
  bool get _saveEnabled {
    final nameChanged = _nameController.text.trim() != _originalName;

    final imageChanged = _pickedImage != null;

    final passwordAttempted =
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;

    return nameChanged || imageChanged || passwordAttempted;
  }

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
    _confirmPasswordController.addListener(_onTextChanged);
    _fetchProfileData();
  }

  void _onTextChanged() {
    setState(() {});
  }

  // 2. Fetch Logic: Called once when page opens
  Future<void> _fetchProfileData() async {
    // Simulate Supabase fetch delay
    await Future.delayed(const Duration(seconds: 1));

    // Assume these values came from: supabase.from('profiles').select().single();
    if (mounted) {
      setState(() {
        _originalName = "Taylor";
        _originalAvatarUrl =
            "https://jpniuhsorgjkaqfxjgsr.supabase.co/storage/v1/object/public/avatars/system/default_avatar.png";

        _nameController.text = _originalName!;
        _isLoading = false;
      });
    }
  }

  // 3. Revert Logic: Reset UI to the "Original" data fetched in initState
  void _cancelEdit() {
    setState(() {
      _nameController.text = _originalName ?? "";
      _passwordController.clear();
      _confirmPasswordController.clear();
      _pickedImage = null;
    });
  }

  // 4. Update Logic: Where you will eventually call Supabase
  Future<void> _updateProfile() async {
    print('name: ${_nameController.text}');
    print('pickedImage: ${_pickedImage?.path}');
    print('newPassword: ${_passwordController.text}');
    print('confirmPassword: ${_confirmPasswordController.text}');

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Logic for User Story #1-1 Acceptance Criteria #4/5 goes here
        // 1. Upload _localImagePath to Supabase Storage if it exists
        // 2. Update 'profiles' table with _nameController.text

        // On Success:
        if (mounted) {
          setState(() {
            _originalName =
                _nameController.text; // Update our "revert" baseline
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        // Use your ToastUtils.showError here!
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a spinner while the initial fetch happens
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // AVATAR SECTION
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : NetworkImage(_originalAvatarUrl ?? ""),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton.filled(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.edit, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // new password
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) => Utils.passwordValidator(value),
              ),
              const SizedBox(height: 16),

              // confirm new password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelEdit,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveEnabled ? _updateProfile : null,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(),

              // LOGOUT
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        )
      ),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _passwordController.removeListener(_onTextChanged);
    _confirmPasswordController.removeListener(_onTextChanged);

    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
