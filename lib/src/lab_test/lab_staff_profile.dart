import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:backend_client/backend_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/server_upload.dart';
import '../core/mail_phn_update_verify.dart';
import 'package:flutter/services.dart';
import '../routing/route_refresh.dart';

class LabTesterProfile extends StatefulWidget {
  const LabTesterProfile({super.key});

  @override
  State<LabTesterProfile> createState() => _LabTesterProfileState();
}

class _LabTesterProfileState extends State<LabTesterProfile>
    with SingleTickerProviderStateMixin, RouteRefreshMixin<LabTesterProfile> {
  // Fields populated from backend
  String name = '';
  String email = '';
  String phone = '';
  String designation = '';
  String qualification = '';
  String? _profilePictureUrl;
  bool _isLoading = true;

  XFile? _pickedFile; // File? এর পরিবর্তে XFile?
  Uint8List? _imageBytes; // প্রিভিউ এবং আপলোডের জন্য বাইটস

  // Editable controllers and initial copies for change detection
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl; // added
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _qualCtrl;
  // String? _initialProfileUrl; // removed unused
  bool _isChanged = false;
  bool _isSaving = false;

  // Verification state for changing contact info
  bool _emailChangeVerified = false;
  String? _emailVerifiedFor;
  String? _emailOtpTokenForSave;
  String? _emailOtpForSave;

  bool _phoneChangeVerified = false;
  String? _phoneVerifiedFor;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController(); // init
    _phoneCtrl = TextEditingController();
    _specCtrl = TextEditingController();
    _qualCtrl = TextEditingController();

    _nameCtrl.addListener(_onChanged);
    _emailCtrl.addListener(_onChanged); // listen
    _phoneCtrl.addListener(_onChanged);
    _specCtrl.addListener(_onChanged);
    _qualCtrl.addListener(_onChanged);

    _loadProfile();
  }

  @override
  Future<void> refreshOnFocus() async {
    if (_isSaving) return;
    if (_isChanged) return;
    await _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose(); // dispose
    _phoneCtrl.dispose();
    _specCtrl.dispose();
    _qualCtrl.dispose();
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
    final phoneNowNormalized =
        MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(phoneNow) ??
        phoneNow;
    final phoneInitialNormalized =
        MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(phone) ?? phone;
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

    final currentPhone = phoneNowNormalized;

    final changed =
        _nameCtrl.text.trim() != name ||
        _emailCtrl.text.trim() != email ||
        currentPhone != phoneInitialNormalized ||
        _specCtrl.text.trim() != designation ||
        _qualCtrl.text.trim() != qualification ||
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
      final uidStr = prefs.getString('user_id') ?? '';
      final uid = int.tryParse(uidStr);

      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }

      // ✅ FIX: Use the typed class instead of Map<String, dynamic>
      // Note: Use 'client.lab.getStaffProfile' (the endpoint you showed in the previous message)
      StaffProfileDto? profile = await client.lab.getStaffProfile();

      if (profile != null) {
        if (!mounted) return;
        setState(() {
          // ✅ Access fields directly like an object, not a Map
          name = profile.name;
          email = profile.email;
          final normalizedPhone =
              MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(
                profile.phone.trim(),
              ) ??
              profile.phone.trim();
          phone = normalizedPhone;
          designation = profile.designation;
          qualification = profile.qualification;
          _profilePictureUrl = profile.profilePictureUrl;

          _nameCtrl.text = name;
          _emailCtrl.text = email; // set email
          _phoneCtrl.text = normalizedPhone;
          _specCtrl.text = designation;
          _qualCtrl.text = qualification;
          // _initialProfileUrl = _profilePictureUrl;

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Failed to load staff profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      // ২ মেগাবাইট চেক (মোবাইল ও ওয়েব উভয়ের জন্য কাজ করবে)
      final int length = await pickedFile.length();
      if (length > 2 * 1024 * 1024) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image exceeds 2 MB limit'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // ইমেজ বাইটস রিড করা (প্রিভিউ এবং আপলোডের জন্য)
      final Uint8List bytes = await pickedFile.readAsBytes();

      setState(() {
        _pickedFile = pickedFile;
        _imageBytes = bytes;
      });
      _onChanged();
    }
  }

  // Save changes locally and upload image; backend persistence not implemented here
  Future<void> _saveProfile() async {
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
    String emailText = _emailCtrl.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid email'),
          backgroundColor: Colors.red,
        ),
      );
      if (mounted) setState(() => _isSaving = false);
      return; // stop saving
    }
    String? finalImageUrl = _profilePictureUrl;
    try {
      // ১. যদি নতুন ইমেজ পিক করা থাকে (মোবাইল বা ওয়েব যেটাই হোক)
      if (_imageBytes != null && _pickedFile != null) {
        try {
          final uploadedUrl = await ServerUpload.uploadBytes(
            bytes: _imageBytes!,
            folder: 'staff_profiles',
            fileName:
                'staff_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            isPdf: false,
          );
          if (uploadedUrl == null || uploadedUrl.isEmpty) {
            throw Exception('Upload failed');
          }
          finalImageUrl = uploadedUrl;
        } catch (e) {
          debugPrint('Upload error: $e');
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image upload error'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSaving = false);
          return;
        }
      }

      // ২. সার্ভার থেকে User ID নেওয়া
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('user_id') ?? '';
      final uid = int.tryParse(stored);

      if (uid == null) {
        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(const SnackBar(content: Text('Not signed in')));
        setState(() => _isSaving = false);
        return;
      }

      // ৩. ব্যাকএন্ডে ডেটা সেভ করা
      final normalized = MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(
        _phoneCtrl.text.trim(),
      );
      if (normalized == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Phone must be +8801XXXXXXXXX (14 chars including +)',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      // If email changed, update user email first using verified OTP.
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

      final success = await client.lab.updateStaffProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: normalized,
        designation: _specCtrl.text.trim(),
        qualification: _qualCtrl.text.trim(),
        profilePictureUrl: finalImageUrl,
      );

      if (success) {
        setState(() {
          name = _nameCtrl.text.trim();
          phone = normalized;
          _phoneCtrl.text = normalized;
          designation = _specCtrl.text.trim();
          qualification = _qualCtrl.text.trim();
          _profilePictureUrl = finalImageUrl;
          _isChanged = false;
          // _initialProfileUrl = _profilePictureUrl;
          _imageBytes = null; // সেভ হয়ে গেলে লোকাল বাইটস ক্লিয়ার করে দিন
          _pickedFile = null;
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Server update failed');
      }
    } catch (e) {
      debugPrint('Save failed: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save changes'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _performLogout() async {
    try {
      // 1. Server logout
      try {
        await client.auth.logout();
      } catch (_) {}

      // 2. Destroy session locally
      await client.authenticationKeyManager?.remove();

      // 3. Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      final preservedDeviceId = prefs.getString('device_id');
      await prefs.clear();
      if (preservedDeviceId != null && preservedDeviceId.trim().isNotEmpty) {
        await prefs.setString('device_id', preservedDeviceId.trim());
      }

      if (!mounted) return;

      // 4. Navigate to login/root
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

      // 5. Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully"),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog first
              await _performLogout();
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
      backgroundColor: Colors.grey[100],

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: refreshFromPull,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(responsiveWidth(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top gradient card with avatar and basic info
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7DFF), Color(0xFF6A9CFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            // Avatar with overlay edit icon
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white.withAlpha(30),
                                  backgroundImage: _imageBytes != null
                                      ? MemoryImage(_imageBytes!)
                                            as ImageProvider // নতুন পিক করা ইমেজ
                                      : (_profilePictureUrl != null &&
                                            _profilePictureUrl!.isNotEmpty)
                                      ? NetworkImage(_profilePictureUrl!)
                                            as ImageProvider // সার্ভারের ইমেজ
                                      : null,
                                  child:
                                      (_imageBytes == null &&
                                          (_profilePictureUrl == null ||
                                              _profilePictureUrl!.isEmpty))
                                      ? const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
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
                                              color: Colors.black.withAlpha(30),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 16),

                            // Name + designation badge + quick info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nameCtrl.text.isNotEmpty
                                        ? _nameCtrl.text
                                        : (name.isNotEmpty ? name : 'Unnamed'),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // removed header designation badge (designation is editable below)
                                  const SizedBox.shrink(),
                                  const SizedBox(height: 10),
                                  Text(
                                    email.isNotEmpty ? email : '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Details Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact & Professional',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Editable fields
                              _buildEditableField(
                                _nameCtrl,
                                Icons.person,
                                'Full Name',
                              ),
                              const SizedBox(height: 12),
                              _buildEditableField(
                                _emailCtrl,
                                Icons.email,
                                'Email',
                                suffix:
                                    (_emailChanged &&
                                        !_emailVerifiedForCurrentValue)
                                    ? _verifySuffixButton(_verifyEmailChange)
                                    : null,
                              ), // Email field
                              const SizedBox(height: 12),
                              _buildEditableField(
                                _phoneCtrl,
                                Icons.phone,
                                'Phone',
                                suffix:
                                    (_phoneChanged &&
                                        !_phoneVerifiedForCurrentValue)
                                    ? _verifySuffixButton(
                                        _verifyPhoneChangeDummy,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _buildEditableField(
                                _qualCtrl,
                                Icons.school,
                                'Qualification',
                              ),
                              const SizedBox(height: 12),
                              _buildEditableField(
                                _specCtrl,
                                Icons.work,
                                'Designation',
                              ),
                              const SizedBox(height: 12),

                              // joined date field and code removed as requested
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Buttons: Change Password, Save Changes, Logout
                      Column(
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
                              onPressed: _logout,
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

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
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
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        suffixIcon: suffix == null
            ? null
            : Padding(padding: const EdgeInsets.only(right: 8), child: suffix),
        suffixIconConstraints: suffix == null
            ? null
            : const BoxConstraints(minHeight: 36, minWidth: 0),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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

  // Ensure phone field uses digits only and shows +88 prefix in UI
  // Update where _buildEditableField is called for phone: it uses _phoneCtrl already; no change needed to call site.
}
