import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:backend_client/backend_client.dart';

import '../core/server_upload.dart';
import '../core/mail_phn_update_verify.dart';
import 'signature_background_processing.dart';
import 'doctor_signature_pad.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Initial doctor data (kept as sensible defaults until loaded)
  String initialName = "";
  String initialEmail = "";
  String initialPhone = "";
  String initialDesignation = "";
  String initialQualifications = "";

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _designationController;
  late final TextEditingController _qualificationsController;

  File? _profileImage;
  File? _signatureImage; // newly added signature image
  String? _profileImageUrl; // remote URL from server
  String? _signatureImageUrl;
  int? _doctorId;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _webProfileImageBytes; // web-only profile image
  Uint8List? _webSignatureImageBytes; // web-only signature image
  Uint8List? _signatureBytes; // processed PNG bytes (transparent background)

  bool _isProcessingSignature = false;

  bool _isChanged = false;
  bool _isLoading = true;
  bool _isSaving = false;

  // Verification state for changing contact info
  bool _emailChangeVerified = false;
  String? _emailVerifiedFor;
  String? _emailOtpTokenForSave;
  String? _emailOtpForSave;

  bool _phoneChangeVerified = false;
  String? _phoneVerifiedFor;

  String? _normalizePhoneLocal(String? phone) {
    if (phone == null) return null;
    final trimmed = phone.trim();

    final regex = RegExp(r'^(\+88)?0\d{10}$');
    if (!regex.hasMatch(trimmed)) return null;

    if (trimmed.startsWith('0')) {
      return '+88${trimmed.substring(1)}';
    }

    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: initialName);
    _emailController = TextEditingController(text: initialEmail);
    _phoneController = TextEditingController(text: initialPhone);
    _designationController = TextEditingController(text: initialDesignation);
    _qualificationsController = TextEditingController(
      text: initialQualifications,
    );

    _nameController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges); // listen for email changes
    _phoneController.addListener(_checkChanges);
    _qualificationsController.addListener(_checkChanges);
    _designationController.addListener(_checkChanges);
    // _ageController.addListener(_checkChanges); // listen for age changes

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

      if (role != 'DOCTOR') {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      await _loadProfile();
    } catch (e) {
      debugPrint('Doctor profile auth check failed: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _qualificationsController.dispose();
    // _shiftController.dispose();
    // _ageController.dispose(); // dispose age controller
    super.dispose();
  }

  void _checkChanges() {
    // Reset verification if the edited value changes again.
    final emailNow = _emailController.text.trim();
    final shouldKeepEmailVerified =
        _emailChangeVerified &&
        _emailVerifiedFor == emailNow &&
        emailNow != initialEmail;
    final shouldResetEmail =
        !shouldKeepEmailVerified &&
        (_emailChangeVerified ||
            _emailVerifiedFor != null ||
            _emailOtpTokenForSave != null ||
            _emailOtpForSave != null);

    final phoneNow = _phoneController.text.trim();
    final shouldKeepPhoneVerified =
        _phoneChangeVerified &&
        _phoneVerifiedFor == phoneNow &&
        phoneNow != initialPhone;
    final shouldResetPhone =
        !shouldKeepPhoneVerified &&
        (_phoneChangeVerified || _phoneVerifiedFor != null);

    if ((shouldResetEmail || shouldResetPhone) && mounted) {
      setState(() {
        if (shouldResetEmail) {
          _emailChangeVerified = false;
          _emailVerifiedFor = null;
          _emailOtpTokenForSave = null;
          _emailOtpForSave = null;
        }
        if (shouldResetPhone) {
          _phoneChangeVerified = false;
          _phoneVerifiedFor = null;
        }
      });
    }

    final changed =
        _nameController.text != initialName ||
        _emailController.text !=
            initialEmail || // include email in change detection
        _phoneController.text != initialPhone ||
        _designationController.text != initialDesignation ||
        _qualificationsController.text != initialQualifications ||
        // _ageController.text != initialAge || // include age in change detection
        _profileImage != null ||
        _webProfileImageBytes != null ||
        _signatureBytes != null ||
        _signatureImage != null ||
        _webSignatureImageBytes != null;

    if (changed != _isChanged) {
      if (!mounted) return;
      setState(() {
        _isChanged = changed;
      });
    }
  }

  bool get _emailChanged => _emailController.text.trim() != initialEmail;
  bool get _phoneChanged => _phoneController.text.trim() != initialPhone;

  bool get _emailVerifiedForCurrentValue {
    final current = _emailController.text.trim();
    return !_emailChanged ||
        (_emailChangeVerified &&
            _emailVerifiedFor == current &&
            (_emailOtpTokenForSave?.isNotEmpty ?? false) &&
            (_emailOtpForSave?.isNotEmpty ?? false));
  }

  bool get _phoneVerifiedForCurrentValue {
    final current = _phoneController.text.trim();
    return !_phoneChanged ||
        (_phoneChangeVerified && _phoneVerifiedFor == current);
  }

  bool get _canSave {
    if (!_isChanged || _isSaving) return false;
    if (!_emailVerifiedForCurrentValue) return false;
    if (!_phoneVerifiedForCurrentValue) return false;
    return true;
  }

  Future<void> _verifyEmailChange() async {
    final newEmail = _emailController.text.trim();
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
      _checkChanges();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Email verification failed: $e')));
    }
  }

  Future<void> _verifyPhoneChangeDummy() async {
    final currentPhone = _phoneController.text.trim();
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
    setState(() {
      _phoneChangeVerified = true;
      _phoneVerifiedFor = currentPhone;
    });
    _checkChanges();
  }

  // Build avatar showing local file (mobile), memory bytes (web), or remote URL.
  Widget _buildAvatar({double radius = 52}) {
    if (_profileImage != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        backgroundImage: FileImage(_profileImage!),
      );
    }

    if (_webProfileImageBytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        backgroundImage: MemoryImage(_webProfileImageBytes!),
      );
    }

    if (_profileImageUrl != null && _profileImageUrl!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(_profileImageUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: const Icon(Icons.person, size: 56, color: Colors.grey),
    );
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('user_id');
      final id = int.tryParse(stored ?? '');
      if (id == null) {
        setState(() => _isLoading = false);
        return;
      }

      _doctorId = id;

      // Backend resolves doctorId from authenticated session
      final DoctorProfile? profile = await client.doctor.getDoctorProfile(0);
      if (profile != null) {
        initialName = profile.name ?? '';
        initialEmail = profile.email ?? '';
        // Inside _loadProfileFromServer, when setting the phone text:
        if (profile.phone != null && profile.phone!.startsWith('+88')) {
          _phoneController.text = profile.phone!;
        } else {
          _phoneController.text = profile.phone ?? '';
        }
        initialPhone =
            _phoneController.text; // Update initial state for change detection
        initialDesignation = profile.designation ?? '';
        initialQualifications = profile.qualification ?? '';

        _profileImageUrl = profile.profilePictureUrl;
        _signatureImageUrl = profile.signatureUrl;
        _signatureBytes = null;
        _signatureImage = null;
        _webSignatureImageBytes = null;

        if (!mounted) return;
        setState(() {
          _nameController.text = initialName;
          _emailController.text = initialEmail;
          _phoneController.text = initialPhone;
          _designationController.text = initialDesignation;
          _qualificationsController.text = initialQualifications;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }

  Future<String?> _uploadDoctorImageToCloudinary({
    required Uint8List bytes,
    required String folder,
    required String filePrefix,
    String fileExtension = 'jpg',
  }) {
    final ext = fileExtension.trim().isEmpty ? 'jpg' : fileExtension.trim();
    final fileName =
        '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    return ServerUpload.uploadBytes(
      bytes: bytes,
      folder: folder,
      fileName: fileName,
      isPdf: false,
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _profileImage = null;
          _profileImageUrl = null;
          _webProfileImageBytes = bytes;
        });
      } else {
        final file = File(image.path);
        final int bytes = await file.length();
        if (bytes > 2 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image exceeds 2 MB')),
          );
          return;
        }
        if (!mounted) return;
        setState(() {
          _profileImage = file;
          _profileImageUrl = null;
        });
      }
      // Ensure change detection runs after state updated
      if (!mounted) return;
      _checkChanges();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _pickSignatureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        // Keep quality high for clean edge detection in background removal.
        imageQuality: 100,
      );
      if (image == null) return;

      setState(() {
        _isProcessingSignature = true;
      });

      final rawBytes = await image.readAsBytes();
      if (rawBytes.lengthInBytes > 2 * 1024 * 1024) {
        if (!mounted) return;
        setState(() {
          _isProcessingSignature = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected signature exceeds 2 MB')),
        );
        return;
      }

      // Convert to ink-only transparent PNG (also crops around the writing).
      final processed = await processSignatureToTransparentPng(rawBytes);
      if (processed.lengthInBytes > 2 * 1024 * 1024) {
        if (!mounted) return;
        setState(() {
          _isProcessingSignature = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Processed signature exceeds 2 MB. Try a smaller image.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        // Always keep signature as processed PNG bytes so alpha is preserved.
        _signatureBytes = processed;
        _signatureImage = null;
        _webSignatureImageBytes = null;
        _signatureImageUrl = null;
        _isProcessingSignature = false;
      });
      _checkChanges();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingSignature = false;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick signature: $e')));
    }
  }

  Future<void> _drawSignature() async {
    if (_isProcessingSignature || _isSaving) return;

    final bytes = await showSignaturePadDialog(
      context,
      title: 'Draw signature',
      width: 420,
      height: 160,
    );

    if (bytes == null) return;
    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature exceeds 2 MB. Try drawing smaller.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isProcessingSignature = true;
    });

    // Even though the pad exports a transparent PNG, we still crop it tightly.
    final processed = await processSignatureToTransparentPng(bytes);
    if (processed.lengthInBytes > 2 * 1024 * 1024) {
      if (!mounted) return;
      setState(() {
        _isProcessingSignature = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processed signature exceeds 2 MB. Draw smaller.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _signatureBytes = processed;
      _signatureImage = null;
      _webSignatureImageBytes = null;
      _signatureImageUrl = null;
      _isProcessingSignature = false;
    });
    _checkChanges();
  }

  Future<void> _saveProfile() async {
    if (_doctorId == null) return;
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

    setState(() {
      _isSaving = true;
    });

    try {
      // Email validation
      final email = _emailController.text.trim();
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid email address')));
        setState(() => _isSaving = false);
        return;
      }

      // If email changed, update it first (requires OTP proof).
      if (_emailChanged) {
        final res = await client.auth.updateMyEmailWithOtp(
          _emailController.text.trim(),
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
          final newEmail = _emailController.text.trim();
          if (newEmail.isNotEmpty) {
            await prefs.setString('user_email', newEmail);
            await prefs.setString('email', newEmail);
          }
        } catch (_) {}
      }

      // Phone normalization
      final normalizedPhone = _normalizePhoneLocal(_phoneController.text);
      if (normalizedPhone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone must be 14 digits (+88017XXXXXXXX)'),
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      String? profileUrl = _profileImageUrl;
      String? signatureUrl = _signatureImageUrl;
      // Profile upload
      if (_profileImage != null) {
        final bytes = await _profileImage!.readAsBytes();
        profileUrl = await _uploadDoctorImageToCloudinary(
          bytes: bytes,
          folder: 'doctor_profiles',
          filePrefix: 'doctor_profile',
        );
        if (profileUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload profile image')),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }
      } else if (_webProfileImageBytes != null) {
        profileUrl = await _uploadDoctorImageToCloudinary(
          bytes: _webProfileImageBytes!,
          folder: 'doctor_profiles',
          filePrefix: 'doctor_profile',
        );
        if (profileUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload profile image')),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      // Signature upload
      if (_signatureBytes != null) {
        signatureUrl = await _uploadDoctorImageToCloudinary(
          bytes: _signatureBytes!,
          folder: 'doctor_signatures',
          filePrefix: 'doctor_signature',
          fileExtension: 'png',
        );
        if (signatureUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload signature')),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }
      } else if (_signatureImage != null) {
        // Legacy path: still process to transparent PNG.
        final bytes = await _signatureImage!.readAsBytes();
        final processed = await processSignatureToTransparentPng(bytes);
        signatureUrl = await _uploadDoctorImageToCloudinary(
          bytes: processed,
          folder: 'doctor_signatures',
          filePrefix: 'doctor_signature',
          fileExtension: 'png',
        );
        if (signatureUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload signature')),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }
      } else if (_webSignatureImageBytes != null) {
        // Legacy web path: process to transparent PNG.
        final processed = await processSignatureToTransparentPng(
          _webSignatureImageBytes!,
        );
        signatureUrl = await _uploadDoctorImageToCloudinary(
          bytes: processed,
          folder: 'doctor_signatures',
          filePrefix: 'doctor_signature',
          fileExtension: 'png',
        );
        if (signatureUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload signature')),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      bool ok = false;
      try {
        ok = await client.doctor.updateDoctorProfile(
          _doctorId!,
          _nameController.text.trim(),
          _emailController.text.trim(),
          normalizedPhone,
          profileUrl!,
          _designationController.text.trim(),
          _qualificationsController.text.trim(),
          signatureUrl,
        );
      } catch (err) {
        final emsg = err.toString();
        if (emsg.contains('Phone number already registered')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number already registered')),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }
        rethrow;
      }

      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: Colors.green,
          ),
        );
        // reload
        _profileImage = null;
        _signatureImage = null;
        _webProfileImageBytes = null;
        _webSignatureImageBytes = null;
        _signatureBytes = null;
        await _loadProfile();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isChanged = false;
      });
    }
  }

  // Navigate to rostering system

  Future<void> _performLogout() async {
    try {
      try {
        await client.auth.logout();
      } catch (_) {}

      try {
        // ignore: deprecated_member_use
        await client.authenticationKeyManager?.remove();
      } catch (_) {}

      try {
        final prefs = await SharedPreferences.getInstance();
        // Preserve device id so login doesn't require OTP again
        // just because user logged out.
        final preservedDeviceId = prefs.getString('device_id');
        await prefs.clear();
        if (preservedDeviceId != null && preservedDeviceId.trim().isNotEmpty) {
          await prefs.setString('device_id', preservedDeviceId.trim());
        }
      } catch (_) {}

      // Defensive: ensure any in-memory auth state is cleared too.
      try {
        initServerpodClient();
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logout failed')));
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await _performLogout();
  }

  Widget safeNetworkImage({
    required String? url,
    double radius = 40,
    IconData fallbackIcon = Icons.person,
  }) {
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        child: Icon(fallbackIcon, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, _) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Doctor Profile",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),

        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top card with avatar and basic info
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade200,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar and edit overlay (shows web/local/remote image)
                    Stack(
                      children: [
                        _buildAvatar(radius: 52),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.deepPurple,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Name and role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                _designationController.text,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Personal Information Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name
                      TextField(
                        controller: _nameController,
                        readOnly: false,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.deepPurple,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Email (now editable)
                      TextField(
                        controller: _emailController,
                        readOnly: false, // made editable
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: [
                          MailPhnUpdateVerify.denyWhitespaceFormatter,
                        ],
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Colors.deepPurple,
                          ),
                          suffixIcon:
                              (_emailChanged && !_emailVerifiedForCurrentValue)
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _verifySuffixButton(
                                    _verifyEmailChange,
                                  ),
                                )
                              : null,
                          suffixIconConstraints:
                              (_emailChanged && !_emailVerifiedForCurrentValue)
                              ? const BoxConstraints(minHeight: 36, minWidth: 0)
                              : null,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          // keep or remove lock icon as desired
                        ),
                        style: TextStyle(color: Colors.grey[700]),
                      ),

                      const SizedBox(height: 12),

                      // Phone
                      TextField(
                        controller: _phoneController,
                        readOnly: false,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          MailPhnUpdateVerify
                              .phoneDigitsAndOptionalLeadingPlusFormatter,
                          LengthLimitingTextInputFormatter(14),
                        ],
                        // Remove digitsOnly and length limit to allow +88
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.deepPurple,
                          ),
                          suffixIcon:
                              (_phoneChanged && !_phoneVerifiedForCurrentValue)
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _verifySuffixButton(
                                    _verifyPhoneChangeDummy,
                                  ),
                                )
                              : null,
                          suffixIconConstraints:
                              (_phoneChanged && !_phoneVerifiedForCurrentValue)
                              ? const BoxConstraints(minHeight: 36, minWidth: 0)
                              : null,
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // designation (moved before Qualifications)
                      TextField(
                        controller: _designationController,
                        readOnly: false,
                        decoration: InputDecoration(
                          labelText: "Designation",
                          prefixIcon: const Icon(
                            Icons.medical_services,
                            color: Colors.deepPurple,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Qualifications (moved after Designation)
                      TextField(
                        controller: _qualificationsController,
                        readOnly: false,
                        decoration: InputDecoration(
                          labelText: "Qualifications",
                          prefixIcon: const Icon(
                            Icons.school,
                            color: Colors.deepPurple,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Signature row with preview
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Signature',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 12),
                                      _signatureBytes != null
                                          ? _TransparentSignaturePreview(
                                              bytes: _signatureBytes!,
                                              width: 120,
                                              height: 44,
                                            )
                                          : (_signatureImage != null)
                                          ? Image.file(
                                              _signatureImage!,
                                              height: 44,
                                              width: 120,
                                              fit: BoxFit.cover,
                                            )
                                          : (_webSignatureImageBytes != null)
                                          ? Image.memory(
                                              _webSignatureImageBytes!,
                                              height: 44,
                                              width: 120,
                                              fit: BoxFit.cover,
                                            )
                                          : (_signatureImageUrl != null &&
                                                _signatureImageUrl!.startsWith(
                                                  'http',
                                                ))
                                          ? Image.network(
                                              _signatureImageUrl!,
                                              height: 44,
                                              width: 120,
                                              fit: BoxFit.contain,
                                            )
                                          : const Text('No signature uploaded'),

                                      const Spacer(),
                                      OutlinedButton.icon(
                                        onPressed: _isProcessingSignature
                                            ? null
                                            : _drawSignature,
                                        icon: const Icon(Icons.draw, size: 18),
                                        label: const Text('Draw'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.deepPurple,
                                          side: const BorderSide(
                                            color: Colors.deepPurple,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: _isProcessingSignature
                                            ? null
                                            : _pickSignatureImage,
                                        icon: _isProcessingSignature
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.upload_file,
                                                size: 18,
                                              ),
                                        label: Text(
                                          _isProcessingSignature
                                              ? 'Processing'
                                              : 'Upload',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Action buttons (Change Password, Save)
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
                          "Change Password",
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
                        onPressed: (_canSave && !_isSaving)
                            ? _saveProfile
                            : null,
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
                                "Save Changes",
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

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Logout",
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

              const SizedBox(height: 18),
            ],
          ),
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

class _TransparentSignaturePreview extends StatelessWidget {
  final Uint8List bytes;
  final double width;
  final double height;

  const _TransparentSignaturePreview({
    required this.bytes,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _CheckerboardPainter()),
            Image.memory(
              bytes,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 8.0;
    final paint1 = Paint()..color = const Color(0xFFE5E7EB); // grey-200
    final paint2 = Paint()..color = const Color(0xFFF3F4F6); // grey-100

    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final isEven = (((x / cell).floor() + (y / cell).floor()) % 2 == 0);
        canvas.drawRect(
          Rect.fromLTWH(x, y, cell, cell),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
