import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olxapp/providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _emailSent = false;

  final _firestore = FirebaseFirestore.instance;

  // Email Validator
  bool emailValidator(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Get Error Message
  String getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Operation not allowed.  Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your connection. ';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = ref.read(firebaseAuthProvider);
    final name = _nameController.text. trim();
    final email = _emailController.text.trim();
    final password = _passwordController. text. trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate email
    if (!emailValidator(email)) {
      _showSnackBar('❌ Invalid Email', Colors.red);
      return;
    }

    // Check if passwords match
    if (password != confirmPassword) {
      _showSnackBar('❌ Passwords do not match', Colors.red);
      return;
    }

    // Check if password is not empty
    if (password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('❌ Password cannot be empty', Colors. red);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Create user with email and password
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        try {
          // Update display name
          await user.updateDisplayName(name);

          // Send email verification BEFORE saving to Firestore
          await user.sendEmailVerification();

          // Save to Firestore with emailVerified = false initially
          await _firestore.collection('users').doc(user.uid).set({
            'uid':  user.uid,
            'name': name,
            'email':  email,
            'emailVerified': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            setState(() {
              _emailSent = true;
            });

            _showSnackBar(
              '✅ Verification email sent to $email\nPlease check your inbox and verify.',
              Colors.green,
            );
          }

          // Sign out the user until they verify their email
          await auth.signOut();

        } on FirebaseException catch (firestoreError) {
          // Firestore specific error
          if (mounted) {
            _showSnackBar('❌ Database Error:  ${firestoreError.message}', Colors.red);
          }
          // Delete the created auth user since Firestore failed
          await user. delete();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = getErrorMessage(e.code);
        _showSnackBar('❌ $errorMessage', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Error: ${e.toString()}', Colors.red);
        print('SignUp Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      setState(() => _isLoading = true);

      final auth = ref.read(firebaseAuthProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Sign in temporarily to resend email
      UserCredential credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null && ! credential.user! .emailVerified) {
        await credential.user!.sendEmailVerification();

        if (mounted) {
          _showSnackBar('✅ Verification email resent! ', Colors.green);
        }

        // Sign out again
        await auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showSnackBar('❌ ${getErrorMessage(e.code)}', Colors.red);
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
          borderRadius:  BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If email verification sent, show different UI
    if (_emailSent) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8C87C),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'We sent a verification link to: ',
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.info_outline, color: Color(0xFF1E3A5F), size: 30),
                        SizedBox(height: 12),
                        Text(
                          'Please check your email and click the verification link to activate your account.',
                          style: TextStyle(
                            fontSize:  14,
                            color:  Color(0xFF1E3A5F),
                          ),
                          textAlign:  TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'After verifying, return to the app and log in.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Resend Email Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _resendVerificationEmail,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color:  Color(0xFF1E3A5F), width: 2),
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
                        'Resend Verification Email',
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
                      style: ElevatedButton. styleFrom(
                        backgroundColor:  const Color(0xFF1E3A5F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Back to Login',
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
        ),
      );
    }

    // Original signup form
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
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color:  const Color(0xFF1E3A5F),
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
                  const SizedBox(height: 40),

                  // Name Field
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller:  _nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Name',
                      hintStyle:  TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:  BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Email Field
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled:  true,
                      fillColor:  Colors.white,
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:  BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
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
                  const SizedBox(height: 15),

                  // Password Field
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
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
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
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
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Confirm Password Field
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Confirm Password',
                      style:  TextStyle(
                        fontSize:  14,
                        color:  Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller:  _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration:  InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Confirm Password',
                      hintStyle: TextStyle(color: Colors. grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius. circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons. visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF1E3A5F),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        disabledBackgroundColor:
                        const Color(0xFF1E3A5F).withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          :  const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:  FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Log In Link
                  Row(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an Account? ',
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}