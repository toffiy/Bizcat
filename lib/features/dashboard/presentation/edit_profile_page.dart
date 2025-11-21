import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/cloudinary_service.dart';

class EditProfilePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImageUrl;

  const EditProfilePage({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  late String _firstName;
  late String _lastName;
  late String _email;
  String? _profileImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstName = widget.firstName;
    _lastName = widget.lastName;
    _email = widget.email;
    _profileImageUrl = widget.profileImageUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isSaving = true);
    try {
      final url = await uploadImageToCloudinary(pickedFile);
      setState(() => _profileImageUrl = url);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image upload failed. Try again.")),
      );
    }
    setState(() => _isSaving = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(_auth.currentUser!.uid)
          .update({
        'firstName': _firstName,
        'lastName': _lastName,
        // 🚫 email not updated here
        'profileImageUrl': _profileImageUrl,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save profile. Try again.")),
      );
    }

    setState(() => _isSaving = false);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('lib/assets/default_avatar.png')
                                as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // First Name
                    TextFormField(
                      initialValue: _firstName,
                      decoration: _inputDecoration("First Name"),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter first name" : null,
                      onSaved: (v) => _firstName = v!.trim(),
                    ),
                    const SizedBox(height: 20),

                    // Last Name
                    TextFormField(
                      initialValue: _lastName,
                      decoration: _inputDecoration("Last Name"),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter last name" : null,
                      onSaved: (v) => _lastName = v!.trim(),
                    ),
                    const SizedBox(height: 20),

                    // Email (read-only)
                    TextFormField(
                      initialValue: _email,
                      enabled: false, // 🚫 disables editing
                      decoration: _inputDecoration("Email"),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text("Save Changes"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
