import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:backend_client/backend_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../core/server_upload.dart';
import '../core/mail_phn_update_verify.dart';
import '../core/date_time_utils.dart';
import '../routing/route_refresh.dart';

class PatientProfilePage extends StatefulWidget {
  final String? userId;
  const PatientProfilePage({super.key, this.userId});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage>
    with RouteRefreshMixin<PatientProfilePage> {
  // ================= Controllers & State =================
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bloodGroupController;

  DateTime? _dateOfBirth;
  String? _gender;
  String? _initialName;
  String? _initialEmail;
  String? _initialPhone;
  DateTime? _initialDob;
  String? _initialBloodGroup;
  String? _initialGender;

  // Verification state for changing contact info
  bool _emailChangeVerified = false;
  String? _emailVerifiedFor;
  String? _emailOtpTokenForSave;
  String? _emailOtpForSave;

  bool _phoneChangeVerified = false;
  String? _phoneVerifiedFor;

  Uint8List? _profileImageBytes;
  String? _profileImageBase64;
  final ImagePicker _picker = ImagePicker();

  bool _isChanged = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bloodGroupController = TextEditingController();

    _nameController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
    _bloodGroupController.addListener(_checkChanges);
    _loadProfileData();
  }

  @override
  Future<void> refreshOnFocus() async {
    // Don't clobber unsaved form edits.
    if (_isSaving) return;
    if (_isChanged) return;
    await _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }

  // ================= Logic Methods =================

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await client.patient.getPatientProfile();
      if (profile != null) {
        final normalizedGender = () {
          final raw = (profile.gender ?? '').trim().toLowerCase();
          if (raw == 'male') return 'male';
          if (raw == 'female') return 'female';
          return null;
        }();
        final normalizedPhone =
            MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(
              profile.phone.trim(),
            ) ??
            profile.phone.trim();
        _initialName = profile.name;
        _initialEmail = profile.email;
        _initialPhone = normalizedPhone;
        _initialDob = profile.dateOfBirth;
        _initialBloodGroup = profile.bloodGroup ?? '';
        _initialGender = normalizedGender;

        setState(() {
          _nameController.text = profile.name;
          _emailController.text = profile.email;
          _phoneController.text = normalizedPhone;
          _bloodGroupController.text = profile.bloodGroup ?? '';
          _dateOfBirth = profile.dateOfBirth;
          _gender = normalizedGender;
          _profileImageBase64 = profile.profilePictureUrl;

          // Reset verification state after refresh.
          _emailChangeVerified = false;
          _emailVerifiedFor = null;
          _emailOtpTokenForSave = null;
          _emailOtpForSave = null;
          _phoneChangeVerified = false;
          _phoneVerifiedFor = null;

          _isLoading = false;
        });
      }
    } catch (e) {
      _showDialog('Error', 'Failed to load profile: $e');
      setState(() => _isLoading = false);
    }
  }

  bool get _emailChanged {
    final current = _emailController.text.trim();
    final initial = (_initialEmail ?? '').trim();
    return current != initial;
  }

  bool get _phoneChanged {
    final current = _phoneController.text.trim();
    final initial = (_initialPhone ?? '').trim();
    return current != initial;
  }

  bool get _emailVerifiedForCurrentValue {
    if (!_emailChanged) return true;
    final current = _emailController.text.trim();
    return _emailChangeVerified &&
        (_emailVerifiedFor?.trim() == current) &&
        (_emailOtpTokenForSave?.trim().isNotEmpty ?? false) &&
        (_emailOtpForSave?.trim().isNotEmpty ?? false);
  }

  bool get _phoneVerifiedForCurrentValue {
    if (!_phoneChanged) return true;
    final normalized = MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(
      _phoneController.text.trim(),
    );
    if (normalized == null) return false;
    return _phoneChangeVerified && (_phoneVerifiedFor?.trim() == normalized);
  }

  bool get _canSave {
    if (!_isChanged) return false;
    if (!_emailVerifiedForCurrentValue) return false;
    if (!_phoneVerifiedForCurrentValue) return false;
    return true;
  }

  void _checkChanges() {
    final currentName = _nameController.text.trim();
    final currentEmail = _emailController.text.trim();
    final currentPhone = _phoneController.text.trim();
    final currentBlood = _bloodGroupController.text.trim();

    final nameChanged = currentName != (_initialName ?? '').trim();
    final emailChanged = currentEmail != (_initialEmail ?? '').trim();
    final phoneChanged = currentPhone != (_initialPhone ?? '').trim();
    final bloodChanged = currentBlood != (_initialBloodGroup ?? '').trim();

    bool sameDateOnly(DateTime? a, DateTime? b) {
      if (a == null || b == null) return a == b;
      final au = a.toUtc();
      final bu = b.toUtc();
      return au.year == bu.year && au.month == bu.month && au.day == bu.day;
    }

    final dobChanged = !sameDateOnly(_dateOfBirth, _initialDob);
    final genderChanged =
        (_gender ?? '').trim().toLowerCase() !=
        (_initialGender ?? '').trim().toLowerCase();
    final imageChanged = _profileImageBytes != null;

    // If user edits contact fields after verification, invalidate verification.
    if (emailChanged && (_emailVerifiedFor?.trim() != currentEmail)) {
      _emailChangeVerified = false;
      _emailVerifiedFor = null;
      _emailOtpTokenForSave = null;
      _emailOtpForSave = null;
    }

    final normalizedPhone =
        MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(currentPhone);
    if (phoneChanged &&
        (_phoneVerifiedFor?.trim() != normalizedPhone?.trim())) {
      _phoneChangeVerified = false;
      _phoneVerifiedFor = null;
    }

    final changed =
        nameChanged ||
        emailChanged ||
        phoneChanged ||
        bloodChanged ||
        dobChanged ||
        genderChanged ||
        imageChanged;

    if (!mounted) return;
    setState(() {
      _isChanged = changed;
    });
  }

  Future<void> _verifyEmailChange() async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      _showDialog('Email Required', 'Please enter an email address first.');
      return;
    }
    if (!_emailChanged) {
      _showDialog('No Change', 'Email is not changed.');
      return;
    }
    if (!MailPhnUpdateVerify.isValidEmailForProfile(newEmail)) {
      _showDialog(
        'Invalid Email',
        'Email must be a valid address ending with gmail.com or nstu.edu.bd, and contain no spaces.',
      );
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
      _checkChanges();
    } catch (e) {
      _showDialog('Error', 'Failed to verify email: $e');
    }
  }

  Future<void> _verifyPhoneChangeDummy() async {
    final currentPhone = _phoneController.text.trim();
    if (currentPhone.isEmpty) {
      _showDialog('Phone Required', 'Please enter a phone number first.');
      return;
    }
    if (!_phoneChanged) {
      _showDialog('No Change', 'Phone number is not changed.');
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
      _showDialog(
        'Invalid Phone',
        'Phone must be +8801XXXXXXXXX (14 chars including +).',
      );
      return;
    }
    setState(() {
      // After verification, keep phone in canonical +8801XXXXXXXXX format.
      _phoneController.text = normalized;
      _phoneChangeVerified = true;
      _phoneVerifiedFor = normalized;
    });
    _checkChanges();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      _showDialog('Image Too Large', 'Please select an image < 2MB');
      return;
    }
    setState(() => _profileImageBytes = bytes);
    _checkChanges();
  }

  Future<String?> _uploadProfileToCloudinary(Uint8List bytes) {
    return ServerUpload.uploadBytes(
      bytes: bytes,
      folder: 'patient_profiles',
      fileName: 'patient_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      isPdf: false,
    );
  }

  Future<void> _saveProfile() async {
    if (!_isChanged) return;
    if (!_emailVerifiedForCurrentValue) {
      _showDialog(
        'Verify Email',
        'Please verify your new email before saving.',
      );
      return;
    }
    if (!_phoneVerifiedForCurrentValue) {
      _showDialog(
        'Verify Phone',
        'Please verify your new phone before saving.',
      );
      return;
    }

    final normalizedPhone =
        MailPhnUpdateVerify.normalizeBangladeshPhoneForProfile(
          _phoneController.text.trim(),
        );
    if (normalizedPhone == null) {
      _showDialog(
        'Invalid Phone',
        'Phone must be +8801XXXXXXXXX (14 chars including +).',
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      // If email changed, update email first (requires OTP proof).
      if (_emailChanged) {
        final res = await client.auth.updateMyEmailWithOtp(
          _emailController.text.trim(),
          _emailOtpForSave ?? '',
          _emailOtpTokenForSave ?? '',
        );
        if (res != 'OK') {
          throw Exception(res);
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          final newEmail = _emailController.text.trim();
          if (newEmail.isNotEmpty) {
            await prefs.setString('user_email', newEmail);
            await prefs.setString('email', newEmail);
          }
        } catch (_) {}
      }

      String? imageUrl = _profileImageBase64;
      if (_profileImageBytes != null) {
        imageUrl = await _uploadProfileToCloudinary(_profileImageBytes!);
        if (imageUrl == null) throw Exception("Image upload failed");
      }

      final dobToSend = _dateOfBirth == null
          ? null
          : AppDateTime.utcDateOnly(_dateOfBirth!);
      await client.patient.updatePatientProfile(
        _nameController.text.trim(),
        normalizedPhone,
        _bloodGroupController.text.isEmpty ? null : _bloodGroupController.text,
        dobToSend,
        _gender,
        imageUrl,
      );

      _profileImageBytes = null;
      await _loadProfileData();
      setState(() {
        _isChanged = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      _showDialog('Error', 'Update failed: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    try {
      await client.auth.logout();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    // Preserve the device id so this device remains trusted and won't require
    // email OTP again on the next login.
    final preservedDeviceId = prefs.getString('device_id');
    await prefs.clear();
    if (preservedDeviceId != null && preservedDeviceId.trim().isNotEmpty) {
      await prefs.setString('device_id', preservedDeviceId.trim());
    }
    // Also clear the persisted auth key explicitly (redundant if prefs.clear() ran,
    // but safe for future refactors).
    try {
      // ignore: deprecated_member_use
      await client.authenticationKeyManager?.remove();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  String _formatDob(DateTime? d) {
    if (d == null) return 'Not set';
    return AppDateTime.formatDateOnly(d, pattern: 'dd/MM/yyyy');
  }

  // ================= UI Components =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshFromPull,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Personal Information',
                      children: [
                        _buildModernField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        _buildModernField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: [
                            MailPhnUpdateVerify.denyWhitespaceFormatter,
                          ],
                          suffix:
                              (_emailChanged && !_emailVerifiedForCurrentValue)
                              ? _verifySuffixButton(_verifyEmailChange)
                              : null,
                        ),
                        _buildModernField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_android_outlined,
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
                        _buildModernField(
                          controller: _bloodGroupController,
                          label: 'Blood Group',
                          icon: Icons.water_drop_outlined,
                        ),
                        _buildGenderDropdown(),
                        _buildDobDisplay(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A86F7), Color(0xFF2D63D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A86F7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatarStack(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty ? 'User' : _nameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _emailController.text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _modernChip(
                      Icons.bloodtype,
                      _bloodGroupController.text.isEmpty
                          ? 'N/A'
                          : _bloodGroupController.text,
                    ),
                    _modernChip(Icons.phone, _phoneController.text),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    ImageProvider? image;
    if (_profileImageBytes != null) {
      image = MemoryImage(_profileImageBytes!);
    } else if (_profileImageBase64 != null &&
        _profileImageBase64!.startsWith('http'))
      image = NetworkImage(_profileImageBase64!);

    return Stack(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: Colors.white,
          backgroundImage: image,
          child: image == null
              ? const Icon(Icons.person, size: 40, color: Colors.grey)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Color(0xFF4A86F7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !readOnly,
          readOnly: readOnly,
          onChanged: (_) => _checkChanges(),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? const Color(0xFFF3F4F7) : Colors.white,
            prefixIcon: Icon(
              icon,
              color: readOnly ? Colors.grey : const Color(0xFF4A86F7),
              size: 20,
            ),
            suffixIcon: suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: suffix,
                  ),
            suffixIconConstraints: suffix == null
                ? null
                : const BoxConstraints(minHeight: 36, minWidth: 0),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
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

  Widget _buildDobDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Date of Birth",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final now = DateTime.now();
            final initial = _dateOfBirth ?? DateTime(now.year - 18, 1, 1);
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(1900, 1, 1),
              lastDate: now,
            );
            if (picked == null) return;
            if (!mounted) return;
            setState(() {
              _dateOfBirth = picked;
            });
            _checkChanges();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cake_outlined,
                  color: Color(0xFF4A86F7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDob(_dateOfBirth),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(0xFF4A86F7),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    final current = (_gender ?? '').trim().toLowerCase();
    final value = (current == 'male' || current == 'female') ? current : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
          ],
          onChanged: (v) {
            if (!mounted) return;
            setState(() {
              _gender = v;
            });
            _checkChanges();
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            prefixIcon: const Icon(
              Icons.wc_outlined,
              color: Color(0xFF4A86F7),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _modernChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
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
                    Icons.lock_reset,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  label: const Text(
                    'Change Password',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.deepPurple.withOpacity(0.35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    elevation: _canSave ? 3 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _canSave
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontSize: 16,
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

  void _showDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
