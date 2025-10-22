import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/cloudinary_service.dart';
import '../presentation/edit_profile_page.dart';

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

   Widget _buildProfileImage() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: profileImageUrl != null
            ? Image.network(
                profileImageUrl!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              )
            : Image.asset(
                'lib/assets/default_avatar.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
      ),
    );
  }


  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.black87,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.grey.shade300),
          foregroundColor: color,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildProfileImage(),
                  const SizedBox(height: 16),
                  Text(
                    '${firstName ?? ''} ${lastName ?? ''}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    label: "Edit Profile",
                    icon: Icons.edit_outlined,
                    onPressed: () async {
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
                      if (updated == true) _loadUserData();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    label: "Log Out",
                    icon: Icons.logout,
                    color: Colors.redAccent,
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
    );
  }
}
