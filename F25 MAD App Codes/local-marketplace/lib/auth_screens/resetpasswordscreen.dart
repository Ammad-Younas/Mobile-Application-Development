import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olxapp/providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  // Email Validator
  bool emailValidator(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Get Error Message
  String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection. ';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState! .validate()) {
      return;
    }

    final email = _emailController.text. trim();

    if (!emailValidator(email)) {
      _showSnackBar('❌ Please enter a valid email address', Colors.red);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final auth = ref.read(firebaseAuthProvider);
      await auth.sendPasswordResetEmail(email:  email);

      if (mounted) {
        setState(() {
          _emailSent = true;
        });

        _showSnackBar(
          '✅ Password reset email sent!  Check your inbox.',
          Colors. green,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = getErrorMessage(e. code);
        _showSnackBar('❌ $errorMessage', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to send reset email', Colors.red);
        print('Reset password error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendPasswordResetEmail() async {
    final email = _emailController.text. trim();

    try {
      setState(() => _isLoading = true);

      final auth = ref.read(firebaseAuthProvider);
      await auth.sendPasswordResetEmail(email:  email);

      if (mounted) {
        _showSnackBar(
          '✅ Password reset email resent! Check your inbox.',
          Colors.green,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = getErrorMessage(e.code);
        _showSnackBar('❌ $errorMessage', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to resend reset email', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If email has been sent, show confirmation screen
    if (_emailSent) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8C87C),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment. center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color:  const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mark_email_read,
                        size: 60,
                        color: Color(0xFFE8C87C),
                      ),
                    ),
                  ),
                  const SizedBox(height:  30),

                  const Text(
                    'Check Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'We sent a password reset link to: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors. grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _emailController.text.trim(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:  Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.info_outline, color: Color(0xFF1E3A5F), size: 30),
                        SizedBox(height: 12),
                        Text(
                          'Please check your email and click the password reset link to create a new password.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E3A5F),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'After resetting your password, return to the app and log in with your new password.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors. grey,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height:  30),

                  // Resend Email Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _resendPasswordResetEmail,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E3A5F),
                          strokeWidth:  2,
                        ),
                      )
                          : const Text(
                        'Resend Reset Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Back to Login Button
                  SizedBox(
                    width:  double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child:  const Text(
                        'Back to Login',
                        style:  TextStyle(
                          fontSize:  16,
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
        ),
      );
    }

    // Original password reset form
    return Scaffold(
      backgroundColor: const Color(0xFFE8C87C),
      body: SafeArea(
        child: Center(
          child:  SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back Button
                  Align(
                    alignment:  Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1E3A5F),
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius. circular(20),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: Color(0xFFE8C87C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'someone@example.com',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF1E3A5F),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:  BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!emailValidator(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Send Reset Link Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendPasswordResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        disabledBackgroundColor:
                        const Color(0xFF1E3A5F).withOpacity(0.5),
                      ),
                      child:  _isLoading
                          ?  const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          :  const Text(
                        'Send Reset Link',
                        style:  TextStyle(
                          fontSize:  16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height:  20),

                  // Back to Login Link
                  Row(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Remember your password?  ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}