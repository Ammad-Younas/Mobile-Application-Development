import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olxapp/providers/auth_provider.dart';
import 'signup_screen.dart';
import 'resetpasswordscreen.dart'; // ← ADDED THIS IMPORT

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _firestore = FirebaseFirestore. instance;

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
      case 'wrong-password':
        return 'Wrong password provided. ';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'invalid-credential':
        return 'Invalid email or password.  Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred.  Please try again.';
    }
  }

  Future<void> _authenticate() async {
    if (!_formKey. currentState!.validate()) {
      return;
    }

    final auth = ref.read(firebaseAuthProvider);
    final email = _emailController.text.trim();
    final password = _passwordController. text. trim();

    if (!emailValidator(email)) {
      _showSnackBar('❌ Invalid Email', Colors.red);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Sign in with email and password
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // ✅ CHECK IF EMAIL IS VERIFIED
        if (! user.emailVerified) {
          // Sign out the user immediately
          await auth.signOut();

          if (mounted) {
            // Show dialog with resend option
            _showEmailVerificationDialog(email, password);
          }
          return;
        }

        // ✅ Email is verified - Update Firestore
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'emailVerified': true,
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } catch (firestoreError) {
          // If update fails, just log it - don't block login
          print('Firestore update error: $firestoreError');
        }

        if (mounted) {
          _showSnackBar('✅ Login Successful', Colors.green);
        }

        // authStateProvider will automatically detect login and navigate
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = getErrorMessage(e. code);
        _showSnackBar('❌ $errorMessage', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ An unexpected error occurred', Colors.red);
        print('Login error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Show dialog when email is not verified
  void _showEmailVerificationDialog(String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:  (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:  BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.mark_email_unread, color:  Color(0xFF1E3A5F), size: 28),
              SizedBox(width:  10),
              Text(
                'Email Not Verified',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please verify your email address before logging in.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8C87C).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:  Row(
                  children: [
                    const Icon(Icons. email, size: 20, color: Color(0xFF1E3A5F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style:  const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A5F),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Check your inbox for the verification link.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton. icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resendVerificationEmail(email, password);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              label: const Text(
                'Resend Email',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Resend verification email
  Future<void> _resendVerificationEmail(String email, String password) async {
    try {
      setState(() => _isLoading = true);

      final auth = ref.read(firebaseAuthProvider);

      // Sign in temporarily to resend email
      UserCredential credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null && ! credential.user! .emailVerified) {
        await credential.user!.sendEmailVerification();

        if (mounted) {
          _showSnackBar(
            '✅ Verification email sent! Please check your inbox.',
            Colors.green,
          );
        }

        // Sign out again
        await auth.signOut();
      } else if (credential.user != null && credential.user!.emailVerified) {
        // Email was verified in the meantime
        if (mounted) {
          _showSnackBar(
            '✅ Email already verified!  Please try logging in again.',
            Colors.green,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showSnackBar('❌ ${getErrorMessage(e.code)}', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to resend verification email', Colors. red);
        print('Resend error: $e');
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
    return Scaffold(
      backgroundColor: const Color(0xFFE8C87C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'GC',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE8C87C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Get Cars',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF1E3A5F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Email Field
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType:  TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'someone@example.com',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
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
                  const SizedBox(height: 20),

                  // Password Field
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Password',
                      hintStyle:  TextStyle(
                        color:  Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets. symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF1E3A5F),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator:  (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value. length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Forgot Password - ✅ UPDATED TO NAVIGATE TO RESET PASSWORD SCREEN
                  Align(
                    alignment:  Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to Reset Password Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResetPasswordScreen(),
                          ),
                        );
                      },
                      child:  const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Log In Button
                  SizedBox(
                    width:  double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _authenticate,
                      style: ElevatedButton. styleFrom(
                        backgroundColor:  const Color(0xFF1E3A5F),
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
                          : const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an Account?  ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
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
    _passwordController.dispose();
    super.dispose();
  }
}