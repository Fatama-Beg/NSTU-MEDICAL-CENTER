import 'package:flutter/material.dart';
import 'dart:async';
import 'package:backend_client/backend_client.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  int currentStep = 1;
  late PageController _pageController;

  // Form controllers
  final _emailController = TextEditingController();
  final _codeControllers = List<TextEditingController>.generate(
    6,
    (_) => TextEditingController(),
  );
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State variables
  int resendTimer = 0;
  Timer? _timerObj;
  bool showPasswordRequirements = false;
  String? emailError;
  String? codeError;
  String? passwordError;
  String? confirmError;

  // Backend flow state
  String? _resetToken;
  bool _isSending = false; // sending OTP
  bool _isVerifying = false; // verifying OTP
  bool _isResetting = false; // resetting password

  static const int _resetTokenExpirySeconds =
      120; // matches backend (2 minutes)

  final tealColor = const Color(0xFF218085);
  final errorColor = const Color(0xFFC0152F);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timerObj = null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    _timerObj?.cancel();
    super.dispose();
  }

  // Email validation
  bool isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  // Password validation
  // Simplified: only require at least 6 characters as requested
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  bool _looksLikeJwt(String value) {
    final parts = value.split('.');
    if (parts.length != 3) return false;
    return parts.every((p) => p.isNotEmpty);
  }

  // Step 1: Handle email submission
  void handleStep1() {
    if (_emailController.text.isEmpty) {
      setState(() => emailError = 'Email is required');
      return;
    }

    if (!isValidEmail(_emailController.text)) {
      setState(() => emailError = 'Please enter a valid email address');
      return;
    }

    setState(() => emailError = null);

    // Call backend to request reset token + OTP (token returned)
    _sendResetRequest(_emailController.text.trim(), navigateToOtpPage: true);
  }

  Future<void> _sendResetRequest(
    String email, {
    required bool navigateToOtpPage,
  }) async {
    setState(() {
      _isSending = true;
      emailError = null;
    });

    try {
      // Server returns JWT token string on success, or an error message string.
      final res = await client.auth.requestPasswordReset(email);

      // Backend returns token (JWT) string on success, or an error message string.
      if (_looksLikeJwt(res)) {
        _resetToken = res;

        // Always clear old OTP when issuing a new token/OTP
        _codeControllers[0].clear();
        setState(() => codeError = null);

        // Start/refresh timer
        startResendTimer();

        // Only navigate to OTP page for the initial request from Step 1.
        if (navigateToOtpPage && currentStep != 2) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() => currentStep = 2);
        }

        _showMessage('Verification code sent to your email');
      } else if (res == 'User not found') {
        // Show inline error on email field so user can correct it
        setState(() {
          emailError = 'User not found';
        });
      } else {
        final errorMsg = res.isNotEmpty
            ? res
            : 'Failed to send verification code';
        _showMessage(errorMsg);
      }
    } catch (e) {
      _showMessage('Failed to send verification code: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  // Step 2: Handle verification code
  void handleStep2() {
    final code = _codeControllers[0].text.trim(); // single field now

    if (code.length != 6) {
      setState(() => codeError = 'Please enter all 6 digits');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => codeError = 'Code must contain only numbers');
      return;
    }

    setState(() => codeError = null);

    // Verify using backend
    _verifyOtp(code);
  }

  Future<void> _verifyOtp(String code) async {
    if (_resetToken == null) {
      _showMessage('No verification token found. Please resend the code.');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final email = _emailController.text.trim();
      final res = await client.auth.verifyPasswordReset(
        email,
        code,
        _resetToken!,
      );
      if (res == 'OK') {
        // proceed to reset password
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => currentStep = 3);
        _showMessage('Code verified. You may now reset your password.');
      } else {
        _showMessage(
          res.toString().isNotEmpty
              ? res.toString()
              : 'Invalid or expired code',
        );
      }
    } catch (e) {
      _showMessage('Verification failed: $e');
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  // Step 3: Handle password reset
  void handleStep3() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      setState(() => passwordError = 'Password is required');
      return;
    }

    if (!isValidPassword(newPassword)) {
      setState(() => passwordError = 'Password does not meet requirements');
      return;
    }

    setState(() => passwordError = null);

    if (newPassword != confirmPassword) {
      setState(() => confirmError = 'Passwords do not match');
      return;
    }

    setState(() => confirmError = null);

    // Call backend to perform reset
    _performPasswordReset(_newPasswordController.text);
  }

  Future<void> _performPasswordReset(String newPassword) async {
    if (_resetToken == null) {
      _showMessage('No valid token. Please request a new code.');
      return;
    }
    setState(() => _isResetting = true);
    try {
      final email = _emailController.text.trim();
      final res = await client.auth.resetPassword(
        email,
        _resetToken!,
        newPassword,
      );
      if (res.toLowerCase().contains('success')) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => currentStep = 4);
      } else {
        _showMessage(res.isNotEmpty ? res : 'Failed to reset password');
      }
    } catch (e) {
      _showMessage('Reset failed: $e');
    } finally {
      setState(() => _isResetting = false);
    }
  }

  // Navigate to previous step
  void goToPrevious() {
    if (currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        currentStep--;
      });
    }
  }

  // Reset form
  void resetForm() {
    _emailController.clear();
    for (var controller in _codeControllers) {
      controller.clear();
    }
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      currentStep = 1;
      emailError = null;
      codeError = null;
      passwordError = null;
      confirmError = null;
    });
    _pageController.jumpToPage(0);
    _timerObj?.cancel();
    resendTimer = 0;
  }

  // Start resend timer
  void startResendTimer() {
    setState(() => resendTimer = _resetTokenExpirySeconds);
    _timerObj?.cancel();
    _timerObj = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (resendTimer > 0) {
          resendTimer--;
        }
        if (resendTimer <= 0) {
          resendTimer = 0;
          timer.cancel();
        }
      });
    });
  }

  // Resend code
  void resendCode() {
    if (resendTimer <= 0) {
      _sendResetRequest(_emailController.text.trim(), navigateToOtpPage: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Step 1: Email Input
            _buildStep1(),
            // Step 2: Verification Code
            _buildStep2(),
            // Step 3: Password Reset
            _buildStep3(),
            // Success Screen
            _buildSuccessScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return _buildFormContainer(
      title: 'Forgot Password?',
      subtitle:
          'Enter your email address and we\'ll send you a verification code to reset your password.',
      stepNumber: 1,
      child: Column(
        children: [
          // Email input
          _buildFormGroup(
            label: 'Email Address',
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tealColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: errorColor),
                ),
              ),
            ),
            error: emailError,
          ),
          const SizedBox(height: 24),
          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : handleStep1,
              style: ElevatedButton.styleFrom(
                backgroundColor: tealColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Verification Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Back button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isSending
                  ? null
                  : () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      }
                    },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tealColor, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tealColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _buildFormContainer(
      title: 'Verify Code',
      subtitle: 'Enter the 6-digit verification code sent to your email.',
      stepNumber: 2,
      child: Column(
        children: [
          // Single Code input field
          _buildFormGroup(
            label: 'Verification Code',
            child: TextField(
              // Using the first controller from your list or create a new single one
              // For this implementation, I recommend using _codeControllers[0]
              // or defining a new 'final _otpController = TextEditingController();'
              controller: _codeControllers[0],
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (_) {
                if (codeError != null) {
                  setState(() => codeError = null);
                }
              },
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '', // Hides the character counter
                hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tealColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: errorColor),
                ),
              ),
            ),
            error: codeError,
          ),
          const SizedBox(height: 16),
          // Resend button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Didn\'t receive the code? ',
                style: TextStyle(color: Color(0xFF626C7C), fontSize: 14),
              ),
              TextButton(
                onPressed: (resendTimer <= 0 && !_isSending)
                    ? resendCode
                    : null,
                child: Text(
                  'Resend ${_isSending ? '(sending...)' : (resendTimer > 0 ? '(${resendTimer}s)' : '')}',
                  style: TextStyle(
                    color: tealColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Verify button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : handleStep2,
              style: ElevatedButton.styleFrom(
                backgroundColor: tealColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Verify Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Back button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: goToPrevious,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tealColor, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tealColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _buildFormContainer(
      title: 'Reset Password',
      subtitle: 'Create a new strong password for your account.',
      stepNumber: 3,
      child: Column(
        children: [
          // New password
          _buildFormGroup(
            label: 'New Password',
            child: TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter new password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tealColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: errorColor),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            error: passwordError,
          ),
          const SizedBox(height: 16),
          // Confirm password
          _buildFormGroup(
            label: 'Confirm Password',
            child: TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm your password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tealColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: errorColor),
                ),
              ),
            ),
            error: confirmError,
          ),
          const SizedBox(height: 16),
          // Password requirements
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password Requirements:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildRequirementItem(
                  'At least 6 characters',
                  _newPasswordController.text.length >= 6,
                ),
                _buildRequirementItem(
                  'Contains uppercase and lowercase',
                  _newPasswordController.text.contains(RegExp(r'[A-Z]')) &&
                      _newPasswordController.text.contains(RegExp(r'[a-z]')),
                ),
                _buildRequirementItem(
                  'Contains at least one number',
                  _newPasswordController.text.contains(RegExp(r'[0-9]')),
                ),
                _buildRequirementItem(
                  'Contains special character (!@#\$%)',
                  _newPasswordController.text.contains(RegExp(r'[!@#$%^&*]')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Reset button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isResetting ? null : handleStep3,
              style: ElevatedButton.styleFrom(
                backgroundColor: tealColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isResetting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Back button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: goToPrevious,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tealColor, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tealColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return _buildFormContainer(
      title: 'Password Reset Successful!',
      subtitle:
          'Your password has been successfully reset. You can now sign in with your new password.',
      stepNumber: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text('✓', style: TextStyle(fontSize: 60, color: tealColor)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate back to the universal login page and clear the stack
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tealColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Back to Sign In',
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
    );
  }

  Widget _buildFormContainer({
    required String title,
    required String subtitle,
    required int stepNumber,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Step indicator
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 10 : 0),
                  decoration: BoxDecoration(
                    color: index < stepNumber - 1
                        ? tealColor
                        : (index == stepNumber - 1
                              ? tealColor
                              : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Card container
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  // Header
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF134252),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF626C7C),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  // Form content
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormGroup({
    required String label,
    required Widget child,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF134252),
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(error, style: TextStyle(color: errorColor, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? tealColor : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? tealColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
