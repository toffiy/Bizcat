
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/cloudinary_service.dart';
import '../presentation/edit_profile_page.dart'; // ⬅️ Make sure this file exists

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String? firstName;
  String? lastName;
  String? email;
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(_currentUser.uid)
          .get();

      setState(() {
        firstName = doc['firstName'];
        lastName = doc['lastName'];
        email = doc['email'];
        profileImageUrl = doc['profileImageUrl'];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => isLoading = true);

    try {
      final url = await uploadImageToCloudinary(pickedFile);

      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(_currentUser!.uid)
          .update({'profileImageUrl': url});

      setState(() {
        profileImageUrl = url;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Picture
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage('assets/default_avatar.png')
                                  as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '${firstName ?? ''} ${lastName ?? ''}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    email ?? '',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 30),

                  // Edit Profile
                  _buildProfileCard(
                    icon: Icons.edit,
                    title: "Edit Profile",
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(
                            firstName: firstName ?? '',
                            lastName: lastName ?? '',
                            email: email ?? '',
                            profileImageUrl: profileImageUrl,
                          ),
                        ),
                      );
                      if (updated == true) {
                        _loadUserData();
                      }
                    },
                  ),

                  // Logout
                  _buildProfileCard(
                    icon: Icons.logout,
                    title: "Log Out",
                    iconColor: Colors.red,
                    onTap: _logout,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.blueAccent,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
