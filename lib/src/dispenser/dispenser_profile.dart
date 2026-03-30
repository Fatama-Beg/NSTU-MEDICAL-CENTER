import 'package:backend_client/backend_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/server_upload.dart';
import '../core/mail_phn_update_verify.dart';
import '../routing/route_refresh.dart';

class DispenserProfile extends StatefulWidget {
  const DispenserProfile({super.key});

  @override
  State<DispenserProfile> createState() => _DispenserProfileState();
}

class _DispenserProfileState extends State<DispenserProfile>
    with RouteRefreshMixin<DispenserProfile> {
  String name = '';
  String email = '';
  String phone = '';
  String qualification = '';
  String designation = '';
  String profileImageUrl = '';

  String _initialEmail = '';
  String _initialPhoneEdit = '';

  bool _emailChangeVerified = false;
  String? _emailVerifiedFor;
  String? _emailOtpTokenForSave;
  String? _emailOtpForSave;

  bool _phoneChangeVerified = false;
  String? _phoneVerifiedFor;

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _designationCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _qualificationCtrl;

  bool _isChanged = false;
  bool _isSaving = false;

  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // Password controllers
  final _oldPass = TextEditingController();
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _designationCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _qualificationCtrl = TextEditingController();

    _nameCtrl.addListener(_onChanged);
    _emailCtrl.addListener(_onChanged);
    _designationCtrl.addListener(_onChanged);
    _phoneCtrl.addListener(_onChanged);
    _qualificationCtrl.addListener(_onChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyAndLoad();
    });
  }

  @override
  Future<void> refreshOnFocus() async {
    if (_isSaving) return;
    if (_isChanged) return;
    await _verifyAndLoad();
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

      if (role != 'DISPENSER' && role != 'NURSE') {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      await _loadProfile();
    } catch (e) {
      debugPrint('Dispenser profile auth check failed: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _designationCtrl.dispose();
    _phoneCtrl.dispose();
    _qualificationCtrl.dispose();
    _oldPass.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  void _onChanged() {
    // Reset verification state if the edited value changes again.
    final emailNow = _emailCtrl.text.trim();
    if (emailNow != _initialEmail) {
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
    if (phoneNow != _initialPhoneEdit) {
      if (!_phoneChangeVerified || _phoneVerifiedFor != phoneNow) {
        _phoneChangeVerified = false;
        _phoneVerifiedFor = null;
      }
    } else {
      _phoneChangeVerified = false;
      _phoneVerifiedFor = null;
    }

    final changed =
        _nameCtrl.text.trim() != name ||
        _emailCtrl.text.trim() != email ||
        _phoneCtrl.text.trim() != phone ||
        _qualificationCtrl.text.trim() != qualification ||
        _designationCtrl.text.trim() != designation ||
        _imageBytes != null;

    if (changed != _isChanged) {
      setState(() => _isChanged = changed);
    }
  }

  bool get _emailChanged => _emailCtrl.text.trim() != _initialEmail;
  bool get _phoneChanged => _phoneCtrl.text.trim() != _initialPhoneEdit;

  bool get _emailVerifiedForCurrentValue {
    final current = _emailCtrl.text.trim();
    return !_emailChanged ||
        (_emailChangeVerified &&
            _emailVerifiedFor == current &&
            (_emailOtpTokenForSave?.isNotEmpty ?? false) &&
            (_emailOtpForSave?.isNotEmpty ?? false));
  }

  bool get _phoneVerifiedForCurrentValue {
    final current = _phoneCtrl.text.trim();
    return !_phoneChanged ||
        (_phoneChangeVerified && _phoneVerifiedFor == current);
  }

  bool get _canSave {
    if (!_isChanged || _isSaving) return false;
    if (!_emailVerifiedForCurrentValue) return false;
    if (!_phoneVerifiedForCurrentValue) return false;
    return true;
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await client.dispenser.getDispenserProfile();
      if (profile == null) return;

      if (!mounted) return;

      setState(() {
        name = profile.name;
        email = profile.email;
        final normalizedPhone =
            MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(
              profile.phone.trim(),
            ) ??
            profile.phone.trim();
        phone = normalizedPhone;
        qualification = profile.qualification;
        designation = profile.designation;
        profileImageUrl = profile.profilePictureUrl ?? '';

        _initialEmail = email;
        _initialPhoneEdit = normalizedPhone;

        _nameCtrl.text = name;
        _emailCtrl.text = email;
        _phoneCtrl.text = normalizedPhone;
        _qualificationCtrl.text = qualification;
        _designationCtrl.text = designation;

        _emailChangeVerified = false;
        _emailVerifiedFor = null;
        _emailOtpTokenForSave = null;
        _emailOtpForSave = null;
        _phoneChangeVerified = false;
        _phoneVerifiedFor = null;

        _isChanged = false;
      });
    } catch (e) {
      debugPrint('Failed to load dispenser profile: $e');
    }
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
      _phoneCtrl.text = normalized;
      _phoneChangeVerified = true;
      _phoneVerifiedFor = normalized;
    });
    _onChanged();
  }

  void _confirmLogout() {
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
              Navigator.pop(dialogContext);

              try {
                await client.authenticationKeyManager?.remove();
                try {
                  await client.auth.logout();
                } catch (_) {}

                // ৩. SharedPreferences ক্লিয়ার করা
                final prefs = await SharedPreferences.getInstance();
                final deviceId = prefs.getString('device_id');
                await prefs.clear();
                if (deviceId != null)
                  await prefs.setString('device_id', deviceId);

                // ৪. অ্যাপ রিসেট এবং লগইন পেজে পাঠানো
                // rootNavigator: true নিশ্চিত করে যে পুরো অ্যাপ রিলোড হচ্ছে
                if (mounted) {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              } catch (e) {
                debugPrint("Logout error: $e");
                if (mounted) Navigator.pushReplacementNamed(context, '/');
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image must be under 2MB')),
        );
        return;
      }

      setState(() => _imageBytes = bytes);
      _onChanged();
    }
  }

  Future<void> _saveProfile() async {
    if (!_isChanged) return;

    if (!_emailVerifiedForCurrentValue) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verify your new email before saving')),
      );
      return;
    }
    if (!_phoneVerifiedForCurrentValue) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verify your new phone before saving')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Update email first if changed.
    if (_emailChanged) {
      try {
        final res = await client.auth.updateMyEmailWithOtp(
          _emailCtrl.text.trim(),
          _emailOtpForSave ?? '',
          _emailOtpTokenForSave ?? '',
        );
        if (res != 'OK') {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(res)));
          setState(() => _isSaving = false);
          return;
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          final newEmail = _emailCtrl.text.trim();
          if (newEmail.isNotEmpty) {
            await prefs.setString('user_email', newEmail);
            await prefs.setString('email', newEmail);
          }
        } catch (_) {}
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update email: $e')));
        setState(() => _isSaving = false);
        return;
      }
    }

    final normalizedPhone =
        MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(
          _phoneCtrl.text.trim(),
        );
    if (normalizedPhone == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Phone must be +8801XXXXXXXXX (14 chars including +)',
            ),
          ),
        );
        setState(() => _isSaving = false);
      }
      return;
    }

    String? profileUrl = profileImageUrl.isEmpty ? null : profileImageUrl;
    if (_imageBytes != null) {
      final uploadedUrl = await ServerUpload.uploadBytes(
        bytes: _imageBytes!,
        folder: 'dispenser_profiles',
        fileName:
            'dispenser_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        isPdf: false,
      );
      if (uploadedUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile image')),
        );
        setState(() => _isSaving = false);
        return;
      }
      profileUrl = uploadedUrl;
    }

    try {
      await client.dispenser.updateDispenserProfile(
        name: _nameCtrl.text.trim(),
        phone: normalizedPhone,
        qualification: _qualificationCtrl.text.trim(),
        designation: _designationCtrl.text.trim(), // ✅ Pass designation
        profilePictureUrl: profileUrl,
      );

      await _loadProfile();

      setState(() {
        _imageBytes = null;
        _isChanged = false;
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshFromPull,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.blueAccent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _imageBytes != null
                                ? MemoryImage(_imageBytes!)
                                : (profileImageUrl.isNotEmpty
                                          ? NetworkImage(profileImageUrl)
                                          : null)
                                      as ImageProvider<Object>?,
                            child:
                                (_imageBytes == null && profileImageUrl.isEmpty)
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.edit, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameCtrl.text.isEmpty
                                  ? 'Dispenser'
                                  : _nameCtrl.text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _emailCtrl.text.isEmpty
                                  ? 'Dispenser'
                                  : _emailCtrl.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            if (designation.isNotEmpty)
                              Text(
                                designation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _field(_nameCtrl, Icons.person, 'Name'),
                        const SizedBox(height: 12),
                        _field(
                          _emailCtrl,
                          Icons.email,
                          'Email',
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: [
                            MailPhnUpdateVerify.denyWhitespaceFormatter,
                          ],
                          suffix:
                              (_emailChanged && !_emailVerifiedForCurrentValue)
                              ? _verifySuffixButton(_verifyEmailChange)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _field(_designationCtrl, Icons.work, 'Designation'),
                        const SizedBox(height: 12),
                        _field(
                          _phoneCtrl,
                          Icons.phone,
                          'Phone',
                          hintText: '+8801XXXXXXXXX',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            MailPhnUpdateVerify
                                .phoneDigitsAndOptionalLeadingPlusFormatter,
                            LengthLimitingTextInputFormatter(14),
                          ],
                          suffix:
                              (_phoneChanged && !_phoneVerifiedForCurrentValue)
                              ? _verifySuffixButton(_verifyPhoneChangeDummy)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          _qualificationCtrl,
                          Icons.school,
                          'Qualification',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final contentWidth = maxWidth > 520 ? 520.0 : maxWidth;
                    return SizedBox(
                      width: contentWidth,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/change-password',
                                    ),
                                    icon: const Icon(
                                      Icons.lock_reset,
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
                                        color: Colors.deepPurple.withOpacity(
                                          0.35,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
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
                                    onPressed: (_canSave && !_isSaving)
                                        ? _saveProfile
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _canSave
                                          ? Colors.deepPurple
                                          : Colors.grey.shade300,
                                      disabledBackgroundColor:
                                          Colors.grey.shade300,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
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
                              onPressed: _confirmLogout,
                              icon: const Icon(Icons.logout, color: Colors.red),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    IconData i,
    String l, {
    bool readOnly = false,
    String? prefixText,
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        prefixText: prefixText,
        hintText: hintText,
        suffixIcon: suffix == null
            ? null
            : Padding(padding: const EdgeInsets.only(right: 8), child: suffix),
        suffixIconConstraints: suffix == null
            ? null
            : const BoxConstraints(minHeight: 36, minWidth: 0),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
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
