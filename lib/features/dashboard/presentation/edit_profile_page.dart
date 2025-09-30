import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
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
        'email': _email,
        'profileImageUrl': _profileImageUrl,
      });

      Navigator.pop(context, true);
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    // Profile Avatar
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : const AssetImage('lib/assets/default_avatar.png')
                                    as ImageProvider,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // First Name
                    TextFormField(
                      initialValue: _firstName,
                      decoration: _inputDecoration("First Name"),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Enter first name";
                        }
                        if (v.length < 2) {
                          return "Must be at least 2 characters";
                        }
                        if (!RegExp(r"^[a-zA-Z]+$").hasMatch(v)) {
                          return "Only letters allowed";
                        }
                        return null;
                      },
                      onSaved: (v) => _firstName = v!.trim(),
                    ),
                    const SizedBox(height: 20),

                    // Last Name
                    TextFormField(
                      initialValue: _lastName,
                      decoration: _inputDecoration("Last Name"),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Enter last name";
                        }
                        if (!RegExp(r"^[a-zA-Z]+$").hasMatch(v)) {
                          return "Only letters allowed";
                        }
                        return null;
                      },
                      onSaved: (v) => _lastName = v!.trim(),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextFormField(
                      initialValue: _email,
                      decoration: _inputDecoration("Email"),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Enter email";
                        }
                     if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[a-zA-Z]{2,}$').hasMatch(v)) {
  return "Enter a valid email";
}

                        return null;
                      },
                      onSaved: (v) => _email = v!.trim(),
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
