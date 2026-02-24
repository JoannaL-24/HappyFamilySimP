import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:happy_family_sim/core/utils.dart';

class ManageChildrenScreen extends StatefulWidget {
  const ManageChildrenScreen({super.key});

  @override
  State<ManageChildrenScreen> createState() => _ManageChildrenScreenState();
}

class _ManageChildrenScreenState extends State<ManageChildrenScreen> {
  bool _showAllCodes = false;
  final _nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // fake data
  final List<Map<String, dynamic>> _children = [
    {'id': '1', 'name': 'Alice Huang', 'sixDigitCode': '482910'},
    {'id': '2', 'name': 'Bobby Huang', 'sixDigitCode': '123456'},
    {'id': '3', 'name': 'Charlie', 'sixDigitCode': '987654'},
  ];

  void _copyToClipboard(String sixDigitCode, String childName) {
    Clipboard.setData(ClipboardData(text: sixDigitCode));
    Utils.showSuccess('Copied $childName\'s code to clipboard!');
  }

  Future<void> _createChildAccount() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();

      // Logic for account creation goes here

      if (mounted) {
        Navigator.pop(context);
        Utils.showSuccess("$name's profile has been created!");

        _nameController.clear();
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
                textCapitalization: TextCapitalization.words,
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
                onPressed: _createChildAccount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
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
            child: _children.isEmpty ? _buildEmptyState() : _buildChildList(),
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
        final sixDigitCode = child['sixDigitCode']!;

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
