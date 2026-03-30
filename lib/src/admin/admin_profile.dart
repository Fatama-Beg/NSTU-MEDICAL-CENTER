import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backend_client/backend_client.dart';
import 'package:flutter/services.dart';
import '../core/server_upload.dart';
import '../core/mail_phn_update_verify.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  // Fields populated from backend
  String name = '';
  String email = '';
  String phone = '';
  String designation = '';
  String qualification = '';
  String? _profilePictureUrl;
  bool _isLoading = true;

  // Removed unused _pickedFile; keep image bytes only
  Uint8List? _imageBytes;

  // Editable controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _designationCtrl;
  late final TextEditingController _qualificationCtrl;

  bool _isChanged = false;
  bool _isSaving = false;

  // Verification state for changing contact info
  bool _emailChangeVerified = false;
  String? _emailVerifiedFor;
  String? _emailOtpTokenForSave;
  String? _emailOtpForSave;

  bool _phoneChangeVerified = false;
  String? _phoneVerifiedFor;

  final TextEditingController _oldPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _designationCtrl = TextEditingController();
    _qualificationCtrl = TextEditingController();

    _nameCtrl.addListener(_onChanged);
    _phoneCtrl.addListener(_onChanged);
    _emailCtrl.addListener(_onChanged);
    _designationCtrl.addListener(_onChanged);
    _qualificationCtrl.addListener(_onChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _verifyAndLoad();
    });
  }

  Future<void> _verifyAndLoad() async {
    try {
      // ignore: deprecated_member_use
      final authKey = await client.authenticationKeyManager?.get();
      if (authKey == null || authKey.isEmpty) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      String role = '';
      try {
        role = (await client.patient.getUserRole()).toUpperCase();
      } catch (e) {
        debugPrint('Failed to fetch user role: $e');
      }

      if (role != 'ADMIN') {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      await _loadProfile();
    } catch (e) {
      debugPrint('Admin profile auth check failed: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _designationCtrl.dispose();
    _qualificationCtrl.dispose();
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _onChanged() {
    // Reset verification if user edits email/phone again.
    final emailNow = _emailCtrl.text.trim();
    if (emailNow != email) {
      if (!_emailChangeVerified || _emailVerifiedFor != emailNow) {
        _emailChangeVerified = false;
        _emailVerifiedFor = null;
        _emailOtpTokenForSave = null;
        _emailOtpForSave = null;
      }
    } else {
      _emailChangeVerified = false;
      _emailVerifiedFor = null;
      _emailOtpTokenForSave = null;
      _emailOtpForSave = null;
    }

    final phoneNow = _phoneCtrl.text.trim();
    final phoneInitial = phone;
    final phoneNowNormalized =
        MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(phoneNow) ??
        phoneNow;
    final phoneInitialNormalized =
        MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(phoneInitial) ??
        phoneInitial;
    final phoneChanged = phoneNowNormalized != phoneInitialNormalized;
    if (phoneChanged) {
      if (!_phoneChangeVerified || _phoneVerifiedFor != phoneNowNormalized) {
        _phoneChangeVerified = false;
        _phoneVerifiedFor = null;
      }
    } else {
      _phoneChangeVerified = false;
      _phoneVerifiedFor = null;
    }

    final changed =
        _nameCtrl.text.trim() != name ||
        phoneNowNormalized != phoneInitialNormalized ||
        _emailCtrl.text.trim() != email ||
        _designationCtrl.text.trim() != designation ||
        _qualificationCtrl.text.trim() != qualification ||
        _imageBytes != null;

    if (changed != _isChanged && mounted) {
      setState(() => _isChanged = changed);
    }
  }

  bool get _emailChanged => _emailCtrl.text.trim() != email;
  bool get _phoneChanged {
    final now = _phoneCtrl.text.trim();
    final initial = phone;
    final nowNormalized =
        MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(now) ?? now;
    final initialNormalized =
        MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(initial) ??
        initial;
    return nowNormalized != initialNormalized;
  }

  bool get _emailVerifiedForCurrentValue {
    final current = _emailCtrl.text.trim();
    return !_emailChanged ||
        (_emailChangeVerified &&
            _emailVerifiedFor == current &&
            (_emailOtpTokenForSave?.isNotEmpty ?? false) &&
            (_emailOtpForSave?.isNotEmpty ?? false));
  }

  bool get _phoneVerifiedForCurrentValue {
    final currentRaw = _phoneCtrl.text.trim();
    final currentNormalized =
        MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(currentRaw) ??
        currentRaw;
    return !_phoneChanged ||
        (_phoneChangeVerified && _phoneVerifiedFor == currentNormalized);
  }

  bool get _canSave {
    if (!_isChanged || _isSaving) return false;
    if (!_emailVerifiedForCurrentValue) return false;
    if (!_phoneVerifiedForCurrentValue) return false;
    return true;
  }

  Future<void> _verifyEmailChange() async {
    final newEmail = _emailCtrl.text.trim();
    if (newEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter an email first')));
      return;
    }
    if (!_emailChanged) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email is not changed')));
      return;
    }

    try {
      final payload = await MailPhnUpdateVerify.verifyEmailChange(
        context: context,
        client: client,
        newEmail: newEmail,
      );
      if (payload == null || !mounted) return;
      setState(() {
        _emailChangeVerified = true;
        _emailVerifiedFor = newEmail;
        _emailOtpTokenForSave = payload.otpToken;
        _emailOtpForSave = payload.otp;
      });
      _onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Email verification failed: $e')));
    }
  }

  Future<void> _verifyPhoneChangeDummy() async {
    final currentPhone = _phoneCtrl.text.trim();
    if (currentPhone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a phone number first')),
      );
      return;
    }
    if (!_phoneChanged) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phone is not changed')));
      return;
    }

    final ok = await MailPhnUpdateVerify.verifyPhoneDummy(
      context: context,
      newPhone: currentPhone,
    );
    if (ok != true || !mounted) return;

    final normalized = MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(
      currentPhone,
    );
    if (normalized == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone must be +8801XXXXXXXXX (14 chars including +)'),
        ),
      );
      return;
    }
    setState(() {
      // Keep canonical +8801XXXXXXXXX after verification.
      _phoneCtrl.text = normalized;
      _phoneChangeVerified = true;
      _phoneVerifiedFor = normalized;
    });
    _onChanged();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      // Try common keys for stored email
      final storedEmail =
          prefs.getString('email') ??
          prefs.getString('user_email') ??
          prefs.getString('userId');
      if (storedEmail == null || storedEmail.isEmpty) {
        // fallback to dummy data (previous behaviour)
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        setState(() {
          _profilePictureUrl = '';

          _nameCtrl.text = name;
          _phoneCtrl.text = phone;
          _emailCtrl.text = email;

          _isLoading = false;
        });
        return;
      }

      // Fetch from backend using generated client endpoint reference
      final AdminProfileRespond? profile = await client.adminEndpoints
          .getAdminProfile(storedEmail);

      if (profile != null) {
        setState(() {
          name = profile.name;
          email = profile.email;
          final normalizedPhone =
              MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(
                profile.phone.trim(),
              ) ??
              profile.phone.trim();
          phone = normalizedPhone;
          _profilePictureUrl = profile.profilePictureUrl ?? '';
          designation = profile.designation ?? '';
          qualification = profile.qualification ?? '';

          _nameCtrl.text = name;
          _emailCtrl.text = email;
          _phoneCtrl.text = normalizedPhone;
          _designationCtrl.text = designation;
          _qualificationCtrl.text = qualification;
          _isLoading = false;
        });
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Failed to load admin profile: $e');
      if (!mounted) return;
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final int length = await pickedFile.length();
      if (length > 2 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image exceeds 2 MB limit'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final Uint8List bytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
      });
      _onChanged();
    }
  }

  Future<void> _saveProfile() async {
    if (!_isChanged) return;
    if (!mounted) return;

    if (!_emailVerifiedForCurrentValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verify your new email before saving')),
      );
      return;
    }
    if (!_phoneVerifiedForCurrentValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verify your new phone before saving')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail =
          prefs.getString('email') ??
          prefs.getString('user_email') ??
          prefs.getString('userId');
      if (storedEmail == null || storedEmail.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No signed-in user')));
        setState(() => _isSaving = false);
        return;
      }

      String? profileData;
      if (_imageBytes != null) {
        final uploadedUrl = await ServerUpload.uploadBytes(
          bytes: _imageBytes!,
          folder: 'admin_profiles',
          fileName:
              'admin_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          isPdf: false,
        );
        if (uploadedUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload profile image'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSaving = false);
          return;
        }
        profileData = uploadedUrl;
      }

      // Call backend update using generated client endpoint
      final phoneToSend =
          MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(
            _phoneCtrl.text.trim(),
          );
      if (phoneToSend == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Phone must be +8801XXXXXXXXX (14 chars including +)',
            ),
          ),
        );
        setState(() => _isSaving = false);
        return;
      }
      final res = await client.adminEndpoints.updateAdminProfile(
        storedEmail,
        _nameCtrl.text.trim(),
        phoneToSend,
        profileData,
        _designationCtrl.text.trim(),
        _qualificationCtrl.text.trim(),
      );

      // Update email after saving other fields (admin endpoint identifies by old email).
      if (_emailChanged) {
        final newEmail = _emailCtrl.text.trim();
        final emailRes = await client.auth.updateMyEmailWithOtp(
          newEmail,
          _emailOtpForSave ?? '',
          _emailOtpTokenForSave ?? '',
        );
        if (emailRes != 'OK') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email update failed: $emailRes')),
          );
          setState(() => _isSaving = false);
          return;
        }
        try {
          await prefs.setString('user_email', newEmail);
          await prefs.setString('email', newEmail);
        } catch (_) {}
        email = newEmail;
      }

      if (res == 'OK') {
        // refresh
        await _loadProfile();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $res')));
      }
    } catch (e) {
      debugPrint('Save failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save changes'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  Future<void> _performLogout() async {
    try {
      try {
        await client.auth.logout();
      } catch (_) {}

      try {
        await client.authenticationKeyManager?.remove();
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      final preservedDeviceId = prefs.getString('device_id');
      await prefs.clear();

      if (preservedDeviceId != null && preservedDeviceId.isNotEmpty) {
        await prefs.setString('device_id', preservedDeviceId);
      }

      // Reset Serverpod client state
      initServerpodClient();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Logout failed")));
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // close dialog first

              await _performLogout(); // then logout safely
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double responsiveWidth(double w) => size.width * w / 375;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF00695C),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsiveWidth(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopCard(),
                    const SizedBox(height: 20),
                    _buildDetailsCard(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF4DB6AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withAlpha(30),
                  backgroundImage: _imageBytes != null
                      ? MemoryImage(_imageBytes!) as ImageProvider
                      : (_profilePictureUrl != null &&
                            _profilePictureUrl!.isNotEmpty)
                      ? NetworkImage(_profilePictureUrl!) as ImageProvider
                      : null,
                  child:
                      (_imageBytes == null &&
                          (_profilePictureUrl == null ||
                              _profilePictureUrl!.isEmpty))
                      ? const Icon(Icons.person, size: 36, color: Colors.white)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Tooltip(
                  message: 'Edit photo',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _pickProfileImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Color(0xFF00695C),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _nameCtrl.text.isNotEmpty
                ? _nameCtrl.text
                : (name.isNotEmpty ? name : 'Unnamed'),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email.isNotEmpty ? email : '',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEditableField(_nameCtrl, Icons.person, 'Full Name'),
            const SizedBox(height: 12),

            _buildEditableField(
              _phoneCtrl,
              Icons.phone,
              'Phone',
              suffix: (_phoneChanged && !_phoneVerifiedForCurrentValue)
                  ? _verifySuffixButton(_verifyPhoneChangeDummy)
                  : null,
            ),
            const SizedBox(height: 12),

            _buildEditableField(
              _emailCtrl,
              Icons.email,
              'Email',
              suffix: (_emailChanged && !_emailVerifiedForCurrentValue)
                  ? _verifySuffixButton(_verifyEmailChange)
                  : null,
            ),
            const SizedBox(height: 12),

            _buildEditableField(_designationCtrl, Icons.badge, 'Designation'),
            const SizedBox(height: 12),

            _buildEditableField(
              _qualificationCtrl,
              Icons.school,
              'Qualification',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/change-password'),
                  icon: const Icon(
                    Icons.lock_reset_rounded,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  label: const Text(
                    'Change Password',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.deepPurple.withOpacity(0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_canSave && !_isSaving) ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: _canSave ? 3 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: TextStyle(
                            color: _canSave
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(
    TextEditingController ctrl,
    IconData icon,
    String label, {
    Widget? suffix,
  }) {
    final lower = label.toLowerCase();
    final keyboardType = lower.contains('phone')
        ? TextInputType.phone
        : (lower.contains('email') ? TextInputType.emailAddress : null);

    final inputFormatters = lower.contains('phone')
        ? <TextInputFormatter>[
            MailPhnUpdateVerify.phoneDigitsAndOptionalLeadingPlusFormatter,
            LengthLimitingTextInputFormatter(14),
          ]
        : (lower.contains('email')
              ? <TextInputFormatter>[
                  MailPhnUpdateVerify.denyWhitespaceFormatter,
                ]
              : null);

    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onTap: () {
        if (!lower.contains('phone')) return;

        final raw = ctrl.text.trim();
        if (raw.isEmpty) {
          ctrl.value = const TextEditingValue(
            text: '+',
            selection: TextSelection.collapsed(offset: 1),
          );
          return;
        }

        if (!raw.startsWith('+')) {
          final normalized =
              MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(raw);
          if (normalized != null) {
            ctrl.value = TextEditingValue(
              text: normalized,
              selection: TextSelection.collapsed(offset: normalized.length),
            );
          }
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00695C)),
        suffixIcon: suffix == null
            ? null
            : Padding(padding: const EdgeInsets.only(right: 8), child: suffix),
        suffixIconConstraints: suffix == null
            ? null
            : const BoxConstraints(minHeight: 36, minWidth: 0),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00695C), width: 2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: const TextStyle(fontWeight: FontWeight.w500),
      inputFormatters: inputFormatters,
    );
  }

  Widget _verifySuffixButton(VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Verify'),
    );
  }
}
