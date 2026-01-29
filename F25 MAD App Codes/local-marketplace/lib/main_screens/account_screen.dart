import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:olxapp/auth_screens/auth_service.dart';
import 'package:olxapp/auth_screens/login_screen.dart';
import 'account_subscreens/booked_cars.dart';
import 'account_subscreens/chat_list_screen.dart';
import 'account_subscreens/feedback_screen.dart';
import 'account_subscreens/notifications_screen.dart';
import 'account_subscreens/faq_screen.dart';
import 'account_subscreens/about_screen.dart';
import 'dart:io';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  XFile? _imageFile;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  String? _userEmail;
  String? _userPhone;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userEmail = user.email;

        final userDoc = await FirebaseFirestore. instance
            .collection('users')
            . doc(user.uid)
            . get();

        if (userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            _userPhone = data?['phoneNumber'] ?? 'Not set';
            _profileImageUrl = data?['profileImageUrl'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _userPhone = 'Not set';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (picked != null) {
        setState(() {
          _imageFile = picked;
        });

        await _uploadImageToFirebase(picked);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image.')),
        );
      }
    }
  }

  Future<void> _uploadImageToFirebase(XFile imageFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final String fileName = 'profile_${user.uid}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          . child('profile_images')
          .child(fileName);

      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        final file = File(imageFile.path);
        uploadTask = storageRef.putFile(file);
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref. getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          . doc(user.uid)
          .set({
        'profileImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _profileImageUrl = downloadUrl;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEmailDialog() async {
    final TextEditingController emailController = TextEditingController(
      text: _userEmail ??  '',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons. email),
              ),
              keyboardType: TextInputType. emailAddress,
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: You may need to re-authenticate to change your email.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateEmail(emailController.text. trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEmail(String newEmail) async {
    if (newEmail.isEmpty || ! newEmail.contains('@')) {
      if (mounted) {
        ScaffoldMessenger.of(context). showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address.')),
        );
      }
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user. updateEmail(newEmail);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'email': newEmail});

        setState(() {
          _userEmail = newEmail;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email updated successfully!')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to update email. ';
      if (e.code == 'requires-recent-login') {
        message = 'Please log out and log back in to update your email.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email is already in use.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      debugPrint('Error updating email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred.')),
        );
      }
    }
  }

  Future<void> _showPhoneDialog() async {
    final TextEditingController phoneController = TextEditingController(
      text: _userPhone == 'Not set' ? '' : _userPhone,
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Phone Number'),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
            hintText: '+1234567890',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updatePhoneNumber(phoneController.text. trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePhoneNumber(String newPhone) async {
    if (newPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger. of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a phone number.')),
        );
      }
      return;
    }

    try {
      final user = FirebaseAuth.instance. currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            . collection('users')
            . doc(user.uid)
            . set({'phoneNumber': newPhone}, SetOptions(merge: true));

        setState(() {
          _userPhone = newPhone;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number updated successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating phone number: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update phone number.')),
        );
      }
    }
  }

  Widget _buildProfileImage() {
    if (_isUploading) {
      return Container(
        color: const Color(0xFF1E3A5F),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE8C87C),
          ),
        ),
      );
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return Image.network(
        _profileImageUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF1E3A5F),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE8C87C),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF1E3A5F),
            child: const Icon(
              Icons.person,
              size: 70,
              color: Color(0xFFE8C87C),
            ),
          );
        },
      );
    }

    if (_imageFile != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _imageFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: 120,
                height: 120,
              );
            }
            return Container(
              color: const Color(0xFF1E3A5F),
              child: const Icon(
                Icons.person,
                size: 70,
                color: Color(0xFFE8C87C),
              ),
            );
          },
        );
      } else {
        return Image.file(
          File(_imageFile!.path),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        );
      }
    }

    return Container(
      color: const Color(0xFF1E3A5F),
      child: const Icon(
        Icons. person,
        size: 70,
        color: Color(0xFFE8C87C),
      ),
    );
  }

  void _handleLogout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log out. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Profile
              Container(
                width: double.infinity,
                color: const Color(0xFFE8C87C),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Top Bar with Logo and Menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A5F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'GC',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE8C87C),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Get Cars',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E3A5F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Profile Picture
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: _buildProfileImage(),
                          ),
                        ),
                        if (_isUploading)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E3A5F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_upload,
                                color: Color(0xFFE8C87C),
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Upload Image Button
                    TextButton(
                      onPressed: _isUploading ? null : _pickImageFromGallery,
                      child: Text(
                        _isUploading ? 'Uploading...' : 'Upload Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isUploading
                              ? Colors.grey
                              : const Color(0xFF1E3A5F),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Menu Items
              Padding(
                padding: const EdgeInsets. all(20),
                child: Column(
                  children: [
                    _buildInfoMenuItem(
                      context,
                      'E Mail ID',
                      Icons.email_outlined,
                      _userEmail ?? 'Not set',
                      _showEmailDialog,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoMenuItem(
                      context,
                      'Phone number',
                      Icons.phone_outlined,
                      _userPhone ?? 'Not set',
                      _showPhoneDialog,
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      'Chats',
                      Icons.chat_outlined,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatListScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      'My Bookings',
                      Icons. event_available,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookedCarsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      'Feedback',
                      Icons.chat_bubble_outline,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FeedbackScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      'Notifications',
                      Icons.notifications_outlined,
                          () {
                        Navigator. push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      "FAQ's",
                      Icons.help_outline,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FaqScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      'About',
                      Icons.info_outline,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      'Log out',
                      Icons.logout_outlined,
                      _handleLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoMenuItem(
      BuildContext context,
      String title,
      IconData icon,
      String value,
      VoidCallback onPressed,
      ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey. withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight. w500,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  icon,
                  color: const Color(0xFF1E3A5F),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius. circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight. w500,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                Icon(
                  icon,
                  color: const Color(0xFF1E3A5F),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}