import 'dart:io';

import 'package:flutter/material.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/profile/data/profile_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class ChildProfileScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;

  const ChildProfileScreen({
    super.key,
    required this.authRepository,
    required this.profileRepository,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _nameController = TextEditingController();
  File? _selectedImage;
  String? _originalName;
  String? _originalAvatarUrl;
  bool _isLoading = true;
  bool get _saveEnabled {
    final nameChanged = _nameController.text.trim() != _originalName;
    final imageChanged = _selectedImage != null;

    return nameChanged || imageChanged;
  }

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    _fetchProfileData();
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.authRepository.currentUser?.id;
      if (userId == null) return;

      final profile = await widget.profileRepository.fetchUserProfile(userId);

      if (mounted) {
        setState(() {
          _originalName = profile.name;
          _originalAvatarUrl = profile.avatarUrl;

          _nameController.text = _originalName ?? "";
        });
      }
    } catch (e) {
      Utils.showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _nameController.text = _originalName ?? "";
      _selectedImage = null;
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      // check image is a valid file type and lower than 5 mb
      if (_selectedImage != null) {
        final filePath = _selectedImage!.path.toLowerCase();
        final fileSize = await _selectedImage!.length(); // size in bytes

        final isInvalidType =
            !filePath.endsWith('.png') &&
            !filePath.endsWith('.jpg') &&
            !filePath.endsWith('.jpeg') &&
            !filePath.endsWith('.webp');

        if (isInvalidType) {
          Utils.showError('Only PNG, JPEG, and WebP images are allowed.');
          return;
        }

        // Check Size (5MB = 5 * 1024 * 1024 bytes)
        if (fileSize > 5 * 1024 * 1024) {
          Utils.showError('Image size must be less than 5MB.');
          return;
        }
      }

      setState(() => _isLoading = true);

      try {
        final userId = widget.authRepository.currentUser?.id;
        if (userId == null) {
          throw Exception('No authenticated user found');
        }

        final nameToUpdate = _nameController.text.trim() != _originalName
            ? _nameController.text.trim()
            : null;

        final resultMessage = await widget.profileRepository.updateUserProfile(
          userId,
          nameToUpdate,
          null,
          _selectedImage,
        );

        if (mounted) {
          setState(() {
            _selectedImage = null;
            _formKey.currentState?.reset();
          });

          Utils.showSuccess(resultMessage);
          await _fetchProfileData();
        }
      } catch (e) {
        Utils.showError(e.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out?'),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      await widget.authRepository.signOut();

      // don't have to redirect, main app is listening for the logout event
      // it will automatically change the role and rebuild the router
      Utils.showSuccess('Logged out successfully!');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E8),
      appBar: AppBar(
        backgroundColor: const Color(0xffebdfcc),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5A3E36), //soft dark brown
              ),
        ),
        centerTitle: true,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: colorScheme.surfaceDim,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
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
                  prefixIcon: Icon(Icons.person_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelEdit,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFA8E6CF), width: 2),
                        backgroundColor: const Color(0xFFE8FFF6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child:Text(
                        'Cancel',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5A3E36),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveEnabled ? _updateProfile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD6E0),
                        foregroundColor: const Color(0xFF5A3E36),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(
                            color: Color(0xFFE8AFC1),
                            width: 1.5,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5A3E36),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(),

              // logout
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _handleLogout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    super.dispose();
  }
}
