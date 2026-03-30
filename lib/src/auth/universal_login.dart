import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart'; // Import from package
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  // Focus nodes to support keyboard 'Enter' behavior
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // New: control password visibility
  bool _obscurePassword = true;

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('device_id');
    if (existing != null && existing.trim().isNotEmpty) return existing.trim();

    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final id = base64UrlEncode(bytes);
    await prefs.setString('device_id', id);
    return id;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final email = value.trim();
    // Basic format check
    final emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}");
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address';

    // Domain restriction: only NSTU domain or gmail allowed
    if (email.endsWith('nstu.edu.bd') || email.endsWith('@gmail.com')) {
      return null;
    }

    return 'Use a valid institution email domain.';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  // Helper method to show dialogs
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, textAlign: TextAlign.center),
          content: Text(message, textAlign: TextAlign.center),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // No-op for now, but keep so focus nodes can be prepared if needed
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _idController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final deviceId = await _getOrCreateDeviceId();
        // Use the client that's initialized in the package
        // The 'client' variable is available from backend_client package
        final response = await client.auth.login(
          email,
          password,
          deviceId: deviceId,
        );

        if (!response.success) {
          _showDialog('Login Failed', response.error ?? 'Unknown error');
        } else if (response.requiresEmailOtp == true &&
            (response.otpToken?.isNotEmpty ?? false)) {
          // Login requires email OTP only when:
          // - user explicitly logged out before, or
          // - first login on this device/browser.
          // IMPORTANT: stop the page-level loading spinner, otherwise the dialog
          // buttons are disabled (since they were wired to _isLoading).
          if (mounted) setState(() => _isLoading = false);
          await _showLoginOtpDialog(
            email: email,
            otpToken: response.otpToken!,
            password: password,
            deviceId: deviceId,
          );
        } else {
          // Save auth token so Serverpod sends it on every request.
          try {
            final token = response.token;
            if (token != null && token.isNotEmpty) {
              // ignore: deprecated_member_use
              await client.authenticationKeyManager?.put(token);
            }
          } catch (e) {
            // non-fatal; user can still navigate but authenticated calls may fail
            debugPrint('Failed to persist auth token: $e');
          }

          // Use profile data included in LoginResponse to avoid an extra DB query
          final name = response.userName ?? '';
          final profilePictureUrl = response.profilePictureUrl;

          // persist profile info locally so page refresh / hot restart can restore
          try {
            // Persist only the user_id so pages fetch fresh profile data from backend.
            final prefs = await SharedPreferences.getInstance();
            if (response.userId != null) {
              await prefs.setString('user_id', response.userId!);
            }
            // Also persist the email to allow pages to load profile by email
            if (email.isNotEmpty) {
              await prefs.setString('user_email', email);
            }
          } catch (e) {
            // non-fatal local storage error, continue navigation
            debugPrint('Failed to persist profile: $e');
          }

          _navigateToDashboard(
            role: response.role ?? '',
            name: name,
            email: email,
            phone: response.phone,
            bloodGroup: response.bloodGroup,
            allergies: response.age?.toString(),
            profilePictureUrl: profilePictureUrl,
          );
        }
      } catch (e) {
        debugPrint('Login error: $e');

        _showDialog('Login Error', 'An error occurred during login: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _navigateToDashboard({
    required String role,
    required String name,
    required String email,
    String? phone,
    String? bloodGroup,
    String? allergies,
    String? profilePictureUrl,
  }) async {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        Navigator.pushNamed(context, '/admin-dashboard');
        break;

      case 'STUDENT':
      case 'TEACHER':
      case 'STAFF':
        // Navigate without passing profile data — the dashboard will query the backend
        // for fresh profile information using the stored user_id.
        Navigator.pushNamed(context, '/patient-dashboard');
        break;

      case 'DOCTOR':
        Navigator.pushNamed(context, '/doctor-dashboard');
        break;

      case 'DISPENSER':
        Navigator.pushNamed(context, '/dispenser-dashboard');
        break;

      case 'LABSTAFF':
        Navigator.pushNamed(context, '/lab-dashboard');
        break;

      default:
        _showDialog('Unknown Role', 'Role $role not recognized');
    }
  }

  Future<void> _showLoginOtpDialog({
    required String email,
    required String otpToken,
    required String password,
    required String deviceId,
  }) async {
    final ctrl = TextEditingController();

    int countdownSeconds = 120;
    bool canResend = false;
    bool verifying = false;
    bool resending = false;
    String currentOtpToken = otpToken;
    Timer? timer;

    String formatTime(int totalSeconds) {
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    void startTimer(StateSetter setStateDialog) {
      timer?.cancel();
      countdownSeconds = 120;
      canResend = false;
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        // Cancel if dialog is gone (important for web hot restart).
        if (!context.mounted) {
          t.cancel();
          return;
        }
        if (!mounted) {
          t.cancel();
          return;
        }
        if (countdownSeconds <= 1) {
          t.cancel();
          setStateDialog(() {
            countdownSeconds = 0;
            canResend = true;
          });
        } else {
          setStateDialog(() {
            countdownSeconds -= 1;
          });
        }
      });
    }

    Future<void> verify(StateSetter setStateDialog) async {
      final otp = ctrl.text.trim();
      if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
        _showDialog('Invalid Code', 'Enter the 6-digit code from your email.');
        return;
      }
      if (verifying) return;

      setStateDialog(() => verifying = true);
      try {
        final res = await client.auth.verifyLoginOtp(
          email,
          otp,
          currentOtpToken,
          deviceId: deviceId,
        );
        if (res.success != true) {
          _showDialog(
            'Verification Failed',
            res.error?.toString() ?? 'Invalid or expired code',
          );
          return;
        }

        final token = res.token;
        if (token != null && token.isNotEmpty) {
          // ignore: deprecated_member_use
          await client.authenticationKeyManager?.put(token);
        }

        // Persist identifiers for dashboards that rely on them.
        try {
          final prefs = await SharedPreferences.getInstance();
          if (res.userId != null && (res.userId?.isNotEmpty ?? false)) {
            await prefs.setString('user_id', res.userId!);
          }
          if (email.isNotEmpty) {
            await prefs.setString('user_email', email);
          }
        } catch (e) {
          debugPrint('Failed to persist login prefs: $e');
        }

        timer?.cancel();
        if (!mounted) return;
        Navigator.of(context).pop();

        _navigateToDashboard(
          role: res.role ?? '',
          name: res.userName ?? '',
          email: email,
          phone: res.phone,
        );
      } catch (e) {
        _showDialog('Error', 'OTP verification failed: $e');
      } finally {
        if (mounted) setStateDialog(() => verifying = false);
      }
    }

    Future<void> resend(StateSetter setStateDialog) async {
      if (!canResend || resending) return;
      setStateDialog(() => resending = true);
      try {
        final response = await client.auth.login(
          email,
          password,
          deviceId: deviceId,
        );
        if (response.success != true || response.otpToken == null) {
          _showDialog(
            'Resend Failed',
            response.error?.toString() ?? 'Failed to resend code',
          );
          return;
        }
        setStateDialog(() {
          currentOtpToken = response.otpToken!;
          ctrl.clear();
        });
        startTimer(setStateDialog);
      } catch (e) {
        _showDialog('Resend Failed', 'Failed to resend code: $e');
      } finally {
        if (mounted) setStateDialog(() => resending = false);
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool started = false;
        return AlertDialog(
          title: const Text('Verify Email'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              if (!started) {
                started = true;
                startTimer(setStateDialog);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A 6-digit OTP has been sent to $email.'),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Time remaining:'),
                      Text(
                        formatTime(countdownSeconds),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: canResend ? Colors.red : Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: Icon(Icons.key),
                      counterText: ' ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: canResend && !resending
                          ? () => resend(setStateDialog)
                          : null,
                      child: Text(
                        canResend
                            ? (resending ? 'Resending...' : 'RESEND OTP')
                            : 'Resend available in ${formatTime(countdownSeconds)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: canResend ? Colors.teal : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: verifying
                  ? null
                  : () {
                      timer?.cancel();
                      Navigator.of(dialogContext).pop();
                    },
              child: const Text('Cancel'),
            ),
            StatefulBuilder(
              builder: (context, setStateDialog) {
                return TextButton(
                  onPressed: verifying ? null : () => verify(setStateDialog),
                  child: Text(verifying ? 'VERIFYING...' : 'VERIFY'),
                );
              },
            ),
          ],
        );
      },
    );

    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double horizontalPadding;
    if (screenWidth < 600) {
      horizontalPadding = 20.0;
    } else {
      horizontalPadding = screenWidth * 0.3;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 30,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50),
                // Icon with shadow
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Icon(
                    Icons.local_hospital,
                    size: 60,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 20),
                // Title
                Text(
                  'NSTU Medical Center', //e-Campus care //
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.blue.shade700,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 30),

                // ID/Email Field
                TextFormField(
                  controller: _idController,
                  focusNode: _emailFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    // Move focus to password field when user presses Enter/Next
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                  obscureText: false,
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Enter your Email',
                    hintText: 'user@example.nstu.edu.bd',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: _validateEmail,
                ),

                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) async {
                    // Submit form when user presses Enter/Done on keyboard
                    await _login();
                  },
                  obscureText: _obscurePassword,
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Enter Your Password',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                    // Suffix icon to toggle password visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 50,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: Colors.blue.shade200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Log In',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 16,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // Forget Password Row
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Forget Password?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgotpassword');
                      },
                      child: const Text('Click here'),
                    ),
                  ],
                ),

                // SignUp Row
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Not yet registered?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/patient-signup');
                      },
                      child: const Text('SignUp'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
