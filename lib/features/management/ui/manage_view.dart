import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:happy_family_sim/core/utils.dart';
import 'package:happy_family_sim/features/auth/data/auth_repository.dart';
import 'package:happy_family_sim/features/management/data/manage_repository.dart';

class ManageChildrenScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final ManageRepository manageRepository;
  const ManageChildrenScreen({
    super.key,
    required this.authRepository,
    required this.manageRepository,
  });

  @override
  State<ManageChildrenScreen> createState() => _ManageChildrenScreenState();
}

class _ManageChildrenScreenState extends State<ManageChildrenScreen> {
  bool _showAllCodes = false;
  final _nameController = TextEditingController();
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _children = [];

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.authRepository.currentUser?.id;
      if (userId == null) return;

      final result = await widget.manageRepository.fetchChildrenData(userId);

      if (mounted) {
        setState(() {
          _children = result;
        });
      }
    } catch (e) {
      Utils.showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String sixDigitCode, String childName) {
    Clipboard.setData(ClipboardData(text: sixDigitCode));
    Utils.showSuccess('Copied $childName\'s code to clipboard!');
  }

  String _generateUniqueCode() {
    final random = Random();
    String newCode;

    final existingCodes = _children.map((c) => c['code'].toString()).toSet();

    do {
      // generates a code between "100000" and "999999"
      newCode = (random.nextInt(900000) + 100000).toString();
    } while (existingCodes.contains(newCode));

    return newCode;
  }

  Future<void> _createChildAccount() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();

      final parentUser = widget.authRepository.currentUser;

      if (parentUser == null || parentUser.email == null) {
        Utils.showError("Parent session not found. Please log in again.");
        return;
      }

      final String sixDigitCode = _generateUniqueCode();
      final String childEmail = Utils.getChildEmail(
        parentUser.email!,
        sixDigitCode,
      );

      setState(() => _isLoading = true);

      try {
        await widget.manageRepository.addChild(
          name,
          childEmail,
          sixDigitCode,
          parentUser.id,
        );

        if (mounted) {
          Navigator.pop(context);
          Utils.showSuccess("$name's profile has been created!");
          _nameController.clear();
          await _fetchChildren();
        }
      } catch (e) {
        Utils.showError(e.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showAddChildSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add a Family Member',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your child\'s name to set up their account and link them to your family.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Child\'s Name',
                  prefixIcon: const Icon(Icons.face_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createChildAccount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Child Profile',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Management'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => setState(() => _showAllCodes = !_showAllCodes),
            icon: Icon(_showAllCodes ? Icons.visibility_off : Icons.visibility),
            tooltip: _showAllCodes ? 'Hide all codes' : 'Show all codes',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _children.isEmpty
                ? _buildEmptyState()
                : _buildChildList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChildSheet(context),
        label: const Text('Add Child'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _children.length,
      itemBuilder: (context, index) {
        final child = _children[index];
        final childName = child['name']!;
        final sixDigitCode = child['code']!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(child['name']![0]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    child['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Code Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _showAllCodes ? sixDigitCode : '••••••',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Copy Button
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(sixDigitCode, childName),
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No children added yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
