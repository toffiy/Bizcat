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

      Navigator.pop(context, true); // Return to ProfilePage
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                        radius: 50,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('lib/assets/default_avatar.png')
                                as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _firstName,
                      decoration: const InputDecoration(labelText: "First Name"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter first name" : null,
                      onSaved: (v) => _firstName = v!,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      initialValue: _lastName,
                      decoration: const InputDecoration(labelText: "Last Name"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter last name" : null,
                      onSaved: (v) => _lastName = v!,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      initialValue: _email,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter email" : null,
                      onSaved: (v) => _email = v!,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 16),
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
