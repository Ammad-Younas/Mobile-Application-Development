import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text. trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your feedback before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Save feedback to Firestore
      await _firestore.collection('feedback').add({
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'feedback': _feedbackController.text. trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // Can be: pending, reviewed, resolved
      });

      // Clear the text field
      _feedbackController. clear();

      if (mounted) {
        ScaffoldMessenger.of(context). showSnackBar(
          const SnackBar(
            content: Text('Thank you!  Your feedback has been submitted successfully.'),
            backgroundColor: Colors. green,
            duration: Duration(seconds: 3),
          ),
        );

        // Optional: Navigate back after successful submission
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator. pop(context);
          }
        });
      }
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8C87C),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          borderRadius: BorderRadius. circular(8),
                        ),
                        child: const Text(
                          'GC',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight. bold,
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
                  IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Color(0xFF1E3A5F),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Title
                    const Text(
                      'Your',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const Text(
                      'Feedback',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const Text(
                      "help's us",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Write here label
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Write here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E3A5F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Feedback Text Area
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C87C),
                        borderRadius: BorderRadius. circular(16),
                        border: Border.all(
                          color: const Color(0xFF1E3A5F),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _feedbackController,
                            maxLines: null,
                            expands: true,
                            enabled: !_isSubmitting,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets. all(16),
                              hintText: 'Share your thoughts with us...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                              ),
                            ),
                            style: const TextStyle(
                              color: Color(0xFF1E3A5F),
                              fontSize: 16,
                            ),
                          ),
                          // Pen Icon
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: Icon(
                              Icons.edit,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 4,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFFE8C87C),
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}