import 'package:flutter/material.dart';
import 'package:dishari/src/auth/universal_login.dart';
import 'package:backend_client/backend_client.dart';
import 'package:flutter/services.dart';
import '../core/date_time_utils.dart';

class PatientSignupPage extends StatefulWidget {
  const PatientSignupPage({super.key});

  @override
  State<PatientSignupPage> createState() => _PatientSignupPageState();
}

class _PatientSignupPageState extends State<PatientSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final Color kPrimaryColor = const Color(0xFF00796B); // Deep Teal
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  // Password criteria state
  bool _pwHasMinLength = false;
  bool _pwHasUpperAndLower = false;
  bool _pwHasNumber = false;
  bool _pwHasSpecial = false;

  // --- Controllers ---
  TextEditingController? _nameController;
  TextEditingController? _emailController;
  TextEditingController? _phoneController;
  TextEditingController? _passwordController;
  TextEditingController? _confirmPasswordController;
  TextEditingController? _bloodGroupController;

  DateTime? _dateOfBirth;

  String? _gender;

  String _patientType = 'STUDENT';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _bloodGroupController = TextEditingController();
    // live update of password criteria
    _passwordController!.addListener(_passwordCriteria);
  }

  void _passwordCriteria() {
    final value = _passwordController!.text;
    final hasMin = value.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasNum = RegExp(r'\d').hasMatch(value);
    final hasSpec = RegExp(r'[!@#\$%]').hasMatch(value);

    final upperAndLower = hasUpper && hasLower;

    if (hasMin != _pwHasMinLength ||
        upperAndLower != _pwHasUpperAndLower ||
        hasNum != _pwHasNumber ||
        hasSpec != _pwHasSpecial) {
      setState(() {
        _pwHasMinLength = hasMin;
        _pwHasUpperAndLower = upperAndLower;
        _pwHasNumber = hasNum;
        _pwHasSpecial = hasSpec;
      });
    }
  }

  // --- VALIDATORS ---
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your name';
    if (value.trim().length < 4) return 'Name must be at least 4 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a valid email';
    final email = value.trim();
    // Simple email format check
    final emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}");
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address';

    // Only allow institutional NSTU domain or gmail
    if (email.endsWith('nstu.edu.bd') || email.endsWith('@gmail.com')) {
      return null;
    }

    return 'Use a valid institution email domain.';
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter phone number';
    final phone = value.trim();
    // User should enter only 11 digits; UI shows +88 prefix.
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    final phoneRegex = RegExp(r'^\d{11}$');
    if (!phoneRegex.hasMatch(phoneDigits)) {
      return 'Enter 11 digits (e.g. 01XXXXXXXXX). +88 shown as prefix';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) return 'Include at least one number';
    // Require at least one of the following special characters: ! @ # $ %
    if (!RegExp(r'[!@#\$%]').hasMatch(value)) {
      return 'Include at least one special character from !@#\$%';
    }
    return null;
  }

  // Blood groups list
  final List<String> _bloodGroups = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown',
  ];
  String? _validateBloodGroup(String? value) {
    if (value == null || value.isEmpty) return 'Please select your blood group';
    return null;
  }

  String? _validateGender(String? value) {
    if (value == null || value.isEmpty) return 'Please select gender';
    return null;
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _emailController?.dispose();
    _phoneController?.dispose();
    _passwordController?.dispose();
    _confirmPasswordController?.dispose();
    _bloodGroupController?.dispose();
    super.dispose();
  }

  String _formatDob(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // Custom Input Decoration for better look
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kPrimaryColor.withAlpha(179)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryColor.withAlpha(77)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryColor.withAlpha(26)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kPrimaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );
  }

  Future<void> _startSignupPhoneOtpFlow() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    if (_passwordController!.text != _confirmPasswordController!.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final email = _emailController!.text.trim();
      final phoneToSend = _normalizePhoneForBackend(_phoneController!.text);

      final challenge = await client.auth.startSignupPhoneOtp(
        email,
        phoneToSend,
      );

      if (challenge.success != true) {
        final msg = challenge.error?.toString() ?? 'Unknown error';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start phone OTP: $msg')),
          );
        }
        return;
      }

      final phoneOtpToken = challenge.token;
      final debugOtp = challenge.debugOtp;
      if (phoneOtpToken == null || phoneOtpToken.isEmpty || debugOtp == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start phone verification.'),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      await _showPhoneOtpDialog(debugOtp: debugOtp, token: phoneOtpToken);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed. Check server connection: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showPhoneOtpDialog({
    required String debugOtp,
    required String token,
  }) async {
    final ctrl = TextEditingController(text: debugOtp);

    Future<void> submit() async {
      final phoneOtp = ctrl.text.trim();
      if (!RegExp(r'^\d{6}$').hasMatch(phoneOtp)) {
        _showErrorDialog('Invalid OTP', 'Enter a valid 6-digit OTP.');
        return;
      }

      setState(() => _isLoading = true);
      try {
        final email = _emailController!.text.trim();
        final phone = _normalizePhoneForBackend(_phoneController!.text);
        final password = _passwordController!.text;
        final name = _nameController!.text.trim();
        final role = _patientType;
        final bloodGroup = _bloodGroupController!.text.trim();
        final dob = _dateOfBirth == null
            ? null
            : AppDateTime.utcDateOnly(_dateOfBirth!);
        final gender = _gender;

        final res = await client.auth.completeSignupWithPhoneOtp(
          email,
          phone,
          phoneOtp,
          token,
          password,
          name,
          role,
          bloodGroup.isEmpty ? null : bloodGroup,
          dob,
          gender,
        );

        if (res.success != true) {
          _showErrorDialog(
            'Signup Failed',
            res.error?.toString() ?? 'Unknown error',
          );
          return;
        }

        final authToken = res.token;
        if (authToken != null && authToken.isNotEmpty) {
          // ignore: deprecated_member_use
          await client.authenticationKeyManager?.put(authToken);
        }

        if (!mounted) return;
        Navigator.of(context).pop(); // close phone otp dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (e) {
        _showErrorDialog('Error', 'Phone OTP verification failed: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Verify Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SMS API is not connected yet. Showing OTP here temporarily:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Phone OTP',
                hintText: '6 digits',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isLoading ? null : submit,
            child: const Text('Verify & Create Account'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, textAlign: TextAlign.center),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDobPicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
          firstDate: DateTime(1900, 1, 1),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _dateOfBirth = picked);
        }
      },
      child: InputDecorator(
        decoration: _inputDecoration('Date of Birth', Icons.cake),
        child: Text(_formatDob(_dateOfBirth)),
      ),
    );
  }

  String _normalizePhoneForBackend(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length == 11) return '+88$d';
    if (d.length == 13 && d.startsWith('88')) return '+$d';
    // fallback: return raw as-is (server-side should validate)
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // ... Header ...
              Text(
                'Create Patient Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Register with your institution details.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name', Icons.person),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 15),

                    // Email (with specific domain validation)
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        'Email Address (.nstu.edu.bd)',
                        Icons.email,
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 15),

                    // Phone Number: show +88 prefix; user types 11 digits only
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 11,
                      decoration: _inputDecoration(
                        'Phone Number',
                        Icons.phone,
                      ).copyWith(prefixText: '+88 ', counterText: ''),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 15),

                    // User Role (radio)
                    FormField<String>(
                      initialValue: _patientType,
                      builder: (field) {
                        return InputDecorator(
                          decoration: _inputDecoration(
                            'User Role',
                            Icons.person_search,
                          ),
                          child: Wrap(
                            spacing: 5,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: 'STUDENT',
                                    groupValue: field.value,
                                    onChanged: (v) {
                                      setState(() {
                                        _patientType = v ?? 'STUDENT';
                                      });
                                      field.didChange(v);
                                    },
                                  ),
                                  const Text('Student'),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: 'TEACHER',
                                    groupValue: field.value,
                                    onChanged: (v) {
                                      setState(() {
                                        _patientType = v ?? 'STUDENT';
                                      });
                                      field.didChange(v);
                                    },
                                  ),
                                  const Text('Teacher'),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: 'STAFF',
                                    groupValue: field.value,
                                    onChanged: (v) {
                                      setState(() {
                                        _patientType = v ?? 'STUDENT';
                                      });
                                      field.didChange(v);
                                    },
                                  ),
                                  const Text('Staff'),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 15),

                    // Blood Group
                    DropdownButtonFormField<String>(
                      initialValue: _bloodGroupController!.text.isEmpty
                          ? null
                          : _bloodGroupController!.text,
                      decoration: _inputDecoration(
                        'Blood Group',
                        Icons.bloodtype,
                      ),
                      items: _bloodGroups
                          .map(
                            (bg) =>
                                DropdownMenuItem(value: bg, child: Text(bg)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _bloodGroupController!.text = val ?? '';
                        });
                      },
                      validator: _validateBloodGroup,
                    ),
                    const SizedBox(height: 15),

                    // Gender
                    FormField<String>(
                      initialValue: _gender,
                      validator: _validateGender,
                      builder: (field) {
                        return InputDecorator(
                          decoration: _inputDecoration(
                            'Gender',
                            Icons.wc,
                          ).copyWith(errorText: field.errorText),
                          child: Wrap(
                            spacing: 18,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: 'male',
                                    groupValue: field.value,
                                    onChanged: (v) {
                                      setState(() {
                                        _gender = v;
                                      });
                                      field.didChange(v);
                                    },
                                  ),
                                  const Text('Male'),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: 'female',
                                    groupValue: field.value,
                                    onChanged: (v) {
                                      setState(() {
                                        _gender = v;
                                      });
                                      field.didChange(v);
                                    },
                                  ),
                                  const Text('Female'),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildDobPicker(),
                    const SizedBox(height: 20),

                    // Password Field (stronger validation)
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: _inputDecoration('Password', Icons.lock)
                          .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: kPrimaryColor.withAlpha(179),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                      validator: _validatePassword,
                    ),

                    // Removed the horizontal chips here to move them below Confirm Password
                    const SizedBox(height: 12),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isPasswordVisible,
                      decoration: _inputDecoration(
                        'Confirm Password',
                        Icons.lock_reset,
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController!.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // --- PASSWORD REQUIREMENTS LIST (vertical) ---
                    // This shows each requirement as a separate row after the Confirm Password field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCriteriaRow(
                          _pwHasMinLength,
                          'At least 8 characters',
                        ),
                        const SizedBox(height: 6),
                        _buildCriteriaRow(
                          _pwHasUpperAndLower,
                          'Contains uppercase and lowercase',
                        ),
                        const SizedBox(height: 6),
                        _buildCriteriaRow(
                          _pwHasNumber,
                          'Contains at least one number',
                        ),
                        const SizedBox(height: 6),
                        _buildCriteriaRow(
                          _pwHasSpecial,
                          'Contains a special character (!@#\$%)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startSignupPhoneOtpFlow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SIGN UP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Already registered?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already Registered?',
                    style: TextStyle(fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    },
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // helper for vertical list rows
  Widget _buildCriteriaRow(bool ok, String label) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: ok ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: ok ? Colors.green.shade800 : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
