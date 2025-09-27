import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _loading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    // Remove whitespace
    value = value.trim();

    // Check email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      try {
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: _emailController.text.trim());

        if (mounted) {
          setState(() {
            _loading = false;
            _emailSent = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(child: Text("📧 Password reset link sent to your email")),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          setState(() => _loading = false);

          String errorMessage;
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'No account found with this email address';
              break;
            case 'invalid-email':
              errorMessage = 'Please enter a valid email address';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later';
              break;
            default:
              errorMessage = e.message ?? 'An error occurred. Please try again';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(" $errorMessage")),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(" Network error. Please check your connection")),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildEmailField({required bool isTablet}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        validator: _validateEmail,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _resetPassword(),
        decoration: InputDecoration(
          labelText: "Email address",
          hintText: "Enter your email",
          helperText: "We'll send a password reset link to this email",
          helperStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Colors.brown.shade400,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.brown.shade300,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent({required bool isTablet, required bool isLandscape}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read,
            size: isTablet ? 80 : 60,
            color: Colors.green.shade400,
          ),
        ),
        SizedBox(height: isLandscape ? 15 : 30),

        // Success title
        Text(
          "Check Your Email!",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
            fontSize: isTablet ? 32 : null,
          ),
        ),
        SizedBox(height: isLandscape ? 8 : 12),

        // Success description
        Text(
          "We've sent a password reset link to\n${_emailController.text.trim()}",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
            height: 1.5,
            fontSize: isTablet ? 16 : null,
          ),
        ),
        SizedBox(height: isLandscape ? 20 : 30),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                "Please check your email and click the reset link to create a new password",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isLandscape ? 20 : 30),

        // Resend button
        TextButton.icon(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          icon: Icon(
            Icons.refresh,
            color: Colors.brown.shade600,
          ),
          label: Text(
            "Didn't receive email? Try again",
            style: TextStyle(
              color: Colors.brown.shade600,
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 16 : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.brown.shade50,
              Colors.orange.shade50,
              Colors.amber.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? screenWidth * 0.3 :
                           isTablet ? screenWidth * 0.2 : 24,
                vertical: isLandscape ? 16 : 24,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    elevation: 10,
                    shadowColor: Colors.brown.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 600 : isTablet ? 500 : double.infinity,
                      ),
                      padding: EdgeInsets.all(isTablet ? 40 : 32),
                      child: _emailSent
                          ? _buildSuccessContent(
                              isTablet: isTablet,
                              isLandscape: isLandscape,
                            )
                          : Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Back button
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: Icon(
                                        Icons.arrow_back_ios,
                                        color: Colors.brown.shade600,
                                        size: isTablet ? 28 : 24,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isLandscape ? 5 : 10),

                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.brown.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.lock_reset,
                                      size: isTablet ? 80 : 60,
                                      color: Colors.brown.shade400,
                                    ),
                                  ),
                                  SizedBox(height: isLandscape ? 20 : 30),

                                  // Title text
                                  Text(
                                    "Forgot Password?",
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown.shade800,
                                      fontSize: isTablet ? 32 : null,
                                    ),
                                  ),
                                  SizedBox(height: isLandscape ? 8 : 12),

                                  // Description text
                                  Text(
                                    "Don't worry! Enter your email address and we'll send you a reset link",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                      height: 1.5,
                                      fontSize: isTablet ? 16 : null,
                                    ),
                                  ),
                                  SizedBox(height: isLandscape ? 30 : 40),

                                  // Email field
                                  _buildEmailField(isTablet: isTablet),
                                  SizedBox(height: isLandscape ? 20 : 30),

                                  // Reset button
                                  _loading
                                      ? Container(
                                          height: 55,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.brown.shade300,
                                                Colors.brown.shade400,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          height: 55,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.brown.shade300,
                                                Colors.brown.shade400,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.brown.withOpacity(0.3),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _resetPassword,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                            ),
                                            child: Text(
                                              "Send Reset Link",
                                              style: TextStyle(
                                                fontSize: isTablet ? 18 : 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                  SizedBox(height: isLandscape ? 20 : 30),

                                  // Help text
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.help_outline,
                                          color: Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Check your spam folder if you don't receive the email within a few minutes",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: isTablet ? 14 : 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isLandscape ? 15 : 20),

                                  // Remember password section
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Remember your password? ",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: isTablet ? 16 : null,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: Text(
                                          "Back to Login",
                                          style: TextStyle(
                                            color: Colors.brown.shade600,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                            fontSize: isTablet ? 16 : null,
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}