import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:backend_server/src/generated/protocol.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../mail/mail_service.dart' as mail;

class AuthEndpoint extends Endpoint {
  int? _authenticatedUserId(Session session) {
    final auth = session.authenticated;
    if (auth == null) return null;
    return int.tryParse(auth.userIdentifier);
  }

  String? _jwtSecret(Session session) {
    final fromPasswords = session.passwords['jwtSecret'];
    if (fromPasswords != null && fromPasswords.trim().isNotEmpty) {
      return fromPasswords.trim();
    }

    // Allow runtime env as fallback (useful for Railway).
    final fromEnv = Platform.environment['JWT_SECRET'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }

    // Fallback to Serverpod's service secret if a dedicated jwtSecret isn't configured.
    // This avoids extra config for local/Railway, while still keeping the value secret.
    final fromServiceSecret = session.passwords['serviceSecret'];
    if (fromServiceSecret != null && fromServiceSecret.trim().isNotEmpty) {
      return fromServiceSecret.trim();
    }

    return null;
  }

  // UUID generator for jti
  final Uuid _uuid = Uuid();

  static const Duration _otpTtl = Duration(minutes: 2);
  static const int _otpTtlSeconds = 120;

  String? _issueAuthToken(
    Session session, {
    required String email,
    required String userId,
    required String role,
  }) {
    final jwtSecret = _jwtSecret(session);
    if (jwtSecret == null) return null;

    return JWT(
      {
        'uid': int.tryParse(userId) ?? userId,
        'role': role,
        'jti': _uuid.v4(),
      },
      issuer: 'dishari',
      subject: email,
    ).sign(
      SecretKey(jwtSecret),
      expiresIn: const Duration(days: 30),
    );
  }

  Future<void> _ensureSecurityColumns(Session session) async {
    // This project uses unmanaged SQL tables; keep it resilient.
    // Postgres supports IF NOT EXISTS.
    // Track whether this email has been verified once via login email OTP.
    // After it's true, future logins will not require OTP again.
    try {
      await session.db.unsafeExecute(
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS email_otp_verified boolean NOT NULL DEFAULT FALSE',
      );
    } catch (_) {}
  }

  String _decodeDbValue(dynamic value) {
    if (value == null) return '';
    if (value is List<int>) return utf8.decode(value);
    return value.toString();
  }

  int? _decodeDbInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is List<int>) return int.tryParse(utf8.decode(value));
    return int.tryParse(value.toString());
  }

  int? _calculateAgeFromDob(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    final hasHadBirthdayThisYear = (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hasHadBirthdayThisYear) years -= 1;
    if (years < 0) return 0;
    return years;
  }

  Future<OtpChallengeResponse> _createOtpToken({
    required Session session,
    required String purpose,
    String? email,
    String? phone,
    int? userId,
  }) async {
    final jwtSecret = _jwtSecret(session);
    if (jwtSecret == null) {
      return OtpChallengeResponse(
        success: false,
        error: 'Server auth is not configured (missing JWT secret).',
      );
    }

    final otp = (Random().nextInt(900000) + 100000).toString();
    final jti = _uuid.v4();

    final payload = <String, dynamic>{
      'purpose': purpose,
      'otp': otp,
      'jti': jti,
    };
    if (email != null) payload['email'] = email;
    if (phone != null) payload['phone'] = phone;
    if (userId != null) payload['uid'] = userId;

    final token = JWT(
      payload,
      issuer: 'dishari',
      subject: email ?? phone ?? 'otp',
    ).sign(
      SecretKey(jwtSecret),
      expiresIn: _otpTtl,
    );

    // NOTE: returning OTP is ONLY for phone OTP dev-mode popup.
    return OtpChallengeResponse(
      success: true,
      token: token,
      debugOtp: otp,
      expiresInSeconds: _otpTtlSeconds,
    );
  }

  Future<String?> _validateOtpToken({
    required Session session,
    required String purpose,
    required String otp,
    required String token,
    String? email,
    String? phone,
    int? userId,
  }) async {
    final jwtSecret = _jwtSecret(session);
    if (jwtSecret == null) {
      return 'Server auth is not configured (missing JWT secret).';
    }

    try {
      final jwt = JWT.verify(token, SecretKey(jwtSecret));
      final payload = jwt.payload;
      if (payload['purpose'] != purpose) return 'Invalid or expired OTP';
      if ((payload['otp'] ?? '').toString() != otp) {
        return 'Invalid or expired OTP';
      }
      if (email != null && (payload['email'] ?? '').toString() != email) {
        return 'Invalid or expired OTP';
      }
      if (phone != null && (payload['phone'] ?? '').toString() != phone) {
        return 'Invalid or expired OTP';
      }
      if (userId != null) {
        final uidRaw = payload['uid'];
        final uid = uidRaw is int ? uidRaw : int.tryParse('${uidRaw ?? ''}');
        if (uid == null || uid != userId) return 'Invalid or expired OTP';
      }
      return null;
    } catch (e) {
      session.log('OTP JWT verification failed: $e', level: LogLevel.warning);
      return 'Invalid or expired OTP';
    }
  }

  // ---------------- PROFILE EMAIL CHANGE (VERIFY THEN SAVE) ----------------
  /// Sends an OTP to [newEmail] for verifying profile email change.
  /// Requires an authenticated user.
  Future<OtpChallengeResponse> requestProfileEmailChangeOtp(
    Session session,
    String newEmail,
  ) async {
    final uid = _authenticatedUserId(session);
    if (uid == null) {
      return OtpChallengeResponse(success: false, error: 'Not authenticated');
    }

    final normalizedEmail = newEmail.trim();
    if (normalizedEmail.isEmpty) {
      return OtpChallengeResponse(
        success: false,
        error: 'Email is required.',
      );
    }

    // Ensure the new email is not taken by another user.
    try {
      final existing = await session.db.unsafeQuery(
        '''
        SELECT 1
        FROM users
        WHERE lower(email) = lower(@e)
          AND user_id <> @uid
        LIMIT 1
        ''',
        parameters: QueryParameters.named({'e': normalizedEmail, 'uid': uid}),
      );
      if (existing.isNotEmpty) {
        return OtpChallengeResponse(
          success: false,
          error: 'Email already exists.',
        );
      }
    } catch (_) {}

    final challenge = await _createOtpToken(
      session: session,
      purpose: 'profile_email_change',
      email: normalizedEmail,
      userId: uid,
    );
    if (!challenge.success) return challenge;

    final sent = await _sendOtpWithResend(
      session,
      normalizedEmail,
      challenge.debugOtp ?? '',
      isReset: false,
    );
    if (!sent) {
      return OtpChallengeResponse(
        success: false,
        error: 'Failed to send OTP. Please try again later.',
      );
    }

    return OtpChallengeResponse(
      success: true,
      token: challenge.token,
      expiresInSeconds: _otpTtlSeconds,
    );
  }

  /// Verify OTP for profile email change (does not update DB).
  Future<bool> verifyProfileEmailChangeOtp(
    Session session,
    String newEmail,
    String otp,
    String otpToken,
  ) async {
    final uid = _authenticatedUserId(session);
    if (uid == null) return false;

    final normalizedEmail = newEmail.trim();
    final err = await _validateOtpToken(
      session: session,
      purpose: 'profile_email_change',
      otp: otp,
      token: otpToken,
      email: normalizedEmail,
      userId: uid,
    );
    return err == null;
  }

  /// Update the authenticated user's email, requiring OTP proof.
  /// Also marks `email_otp_verified = TRUE` because the new email was verified.
  Future<String> updateMyEmailWithOtp(
    Session session,
    String newEmail,
    String otp,
    String otpToken,
  ) async {
    final uid = _authenticatedUserId(session);
    if (uid == null) return 'Not authenticated';

    await _ensureSecurityColumns(session);

    final normalizedEmail = newEmail.trim();
    if (normalizedEmail.isEmpty) return 'Email is required.';

    final err = await _validateOtpToken(
      session: session,
      purpose: 'profile_email_change',
      otp: otp,
      token: otpToken,
      email: normalizedEmail,
      userId: uid,
    );
    if (err != null) return err;

    final existing = await session.db.unsafeQuery(
      '''
      SELECT 1
      FROM users
      WHERE lower(email) = lower(@e)
        AND user_id <> @uid
      LIMIT 1
      ''',
      parameters: QueryParameters.named({'e': normalizedEmail, 'uid': uid}),
    );
    if (existing.isNotEmpty) return 'Email already exists.';

    await session.db.unsafeExecute(
      '''
      UPDATE users
      SET email = @e,
          email_otp_verified = TRUE
      WHERE user_id = @uid
      ''',
      parameters: QueryParameters.named({'e': normalizedEmail, 'uid': uid}),
    );

    return 'OK';
  }

  static final Map<String, List<DateTime>> _rateLimit = {};
  static const int maxAttempts = 5;
  static const Duration window = Duration(minutes: 5);

  bool _isRateLimited(String key) {
    final now = DateTime.now();
    _rateLimit.putIfAbsent(key, () => []);

    // Remove expired attempts
    _rateLimit[key]!.removeWhere((t) => now.difference(t) > window);

    if (_rateLimit[key]!.length >= maxAttempts) {
      return true;
    }

    _rateLimit[key]!.add(now);
    return false;
  }

  //login
  Future<LoginResponse> login(
    Session session,
    String email,
    String password, {
    String? deviceId,
  }) async {
    final rateKey = 'login_$email';

    if (_isRateLimited(rateKey)) {
      return LoginResponse(
        success: false,
        error: 'Too many login attempts. Please try again later.',
      );
    }

    try {
      await _ensureSecurityColumns(session);

      final result = await session.db.unsafeQuery(
        '''
      SELECT u.user_id, u.name, u.email, u.password_hash, u.role::text AS role, u.is_active,
              u.phone, p.blood_group, p.date_of_birth, u.profile_picture_url,
             COALESCE(u.email_otp_verified, FALSE) AS email_otp_verified
      FROM users u
      LEFT JOIN patient_profiles p ON p.user_id = u.user_id
      WHERE u.email = @e
      ''',
        parameters: QueryParameters.named({'e': email}),
      );

      if (result.isEmpty) {
        return LoginResponse(success: false, error: 'User not found');
      }

      final row = result.first.toColumnMap();

      final storedHash = _decodeDbValue(row['password_hash']);
      final hashed = sha256.convert(utf8.encode(password)).toString();

      if (storedHash != hashed) {
        return LoginResponse(success: false, error: 'Invalid password');
      }

      if (row['is_active'] == false) {
        return LoginResponse(
            success: false, error: 'Account deactivated from Admin panel');
      }

      final decodedRole = _decodeDbValue(row['role']).toUpperCase();
      final userId = _decodeDbValue(row['user_id']);

      final emailOtpVerified = (row['email_otp_verified'] == true);

      // Require email OTP only until the email has been verified once.
      if (emailOtpVerified) {
        final token = _issueAuthToken(
          session,
          email: email,
          userId: userId,
          role: decodedRole,
        );
        if (token == null) {
          return LoginResponse(
            success: false,
            error: 'Server auth is not configured (missing JWT secret).',
          );
        }

        return LoginResponse(
          success: true,
          role: decodedRole,
          userId: userId,
          userName: _decodeDbValue(row['name']),
          phone: _decodeDbValue(row['phone']),
          bloodGroup: _decodeDbValue(row['blood_group']),
          profilePictureUrl: _decodeDbValue(row['profile_picture_url']),
          token: token,
        );
      }

      // First-ever login verification for this email.
      final challenge = await _createOtpToken(
        session: session,
        purpose: 'login_email',
        email: email,
      );
      if (!challenge.success) {
        return LoginResponse(success: false, error: challenge.error);
      }

      final sent = await _sendOtpWithResend(
        session,
        email,
        challenge.debugOtp!,
        isReset: false,
      );
      if (!sent) {
        return LoginResponse(
          success: false,
          error: 'Failed to send login OTP. Please try again later.',
        );
      }

      session
          .log('Login OTP sent to $email (userId=$userId role=$decodedRole)');
      return LoginResponse(
        success: true,
        requiresEmailOtp: true,
        otpToken: challenge.token,
      );
    } catch (e, stack) {
      session.log('Login failed: $e\n$stack', level: LogLevel.error);
      return LoginResponse(success: false, error: 'Internal server error');
    }
  }

  /// Signup requirement redesign: only phone verification (OTP) during signup.
  /// No email OTP is required here.
  /// Since no SMS API, OTP is returned as debugOtp for UI popup.
  Future<OtpChallengeResponse> startSignupPhoneOtp(
    Session session,
    String email,
    String phone,
  ) async {
    final rateKey = 'startSignupPhoneOtp_$email';
    if (_isRateLimited(rateKey)) {
      return OtpChallengeResponse(
        success: false,
        error: 'Too many attempts. Please wait.',
      );
    }

    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    if (normalizedEmail.isEmpty || normalizedPhone.isEmpty) {
      return OtpChallengeResponse(
        success: false,
        error: 'Email and phone are required.',
      );
    }

    // Ensure email uniqueness
    try {
      final existingEmail = await session.db.unsafeQuery(
        'SELECT 1 FROM users WHERE email = @e',
        parameters: QueryParameters.named({'e': normalizedEmail}),
      );
      if (existingEmail.isNotEmpty) {
        return OtpChallengeResponse(
          success: false,
          error: 'Email already registered.',
        );
      }
    } catch (_) {}

    // Ensure phone uniqueness
    try {
      final existingPhone = await session.db.unsafeQuery(
        'SELECT 1 FROM users WHERE phone = @ph',
        parameters: QueryParameters.named({'ph': normalizedPhone}),
      );
      if (existingPhone.isNotEmpty) {
        return OtpChallengeResponse(
          success: false,
          error: 'Phone number already registered.',
        );
      }
    } catch (_) {}

    final challenge = await _createOtpToken(
      session: session,
      purpose: 'signup_phone',
      email: normalizedEmail,
      phone: normalizedPhone,
    );
    if (!challenge.success) return challenge;

    session.log(
      'PHONE OTP for signup phone=$normalizedPhone email=$normalizedEmail: ${challenge.debugOtp}',
      level: LogLevel.warning,
    );
    return challenge;
  }

  /// Verify login OTP after password was correct but user required OTP.
  /// Returns a normal LoginResponse containing the session token.
  Future<LoginResponse> verifyLoginOtp(
    Session session,
    String email,
    String otp,
    String otpToken, {
    String? deviceId,
  }) async {
    final rateKey = 'verifyLoginOtp_$email';
    if (_isRateLimited(rateKey)) {
      return LoginResponse(
        success: false,
        error: 'Too many OTP attempts. Please wait.',
      );
    }

    try {
      await _ensureSecurityColumns(session);

      final err = await _validateOtpToken(
        session: session,
        purpose: 'login_email',
        otp: otp,
        token: otpToken,
        email: email,
      );
      if (err != null) return LoginResponse(success: false, error: err);

      final result = await session.db.unsafeQuery(
        '''
        SELECT user_id, name, email, role::text AS role, is_active, phone,
               COALESCE(email_otp_verified, FALSE) AS email_otp_verified
        FROM users
        WHERE email = @e
        LIMIT 1
        ''',
        parameters: QueryParameters.named({'e': email}),
      );
      if (result.isEmpty) {
        return LoginResponse(success: false, error: 'User not found');
      }
      final row = result.first.toColumnMap();
      if (row['is_active'] == false) {
        return LoginResponse(
          success: false,
          error: 'Account deactivated from Admin panel',
        );
      }

      final jwtSecret = _jwtSecret(session);
      if (jwtSecret == null) {
        return LoginResponse(
          success: false,
          error: 'Server auth is not configured (missing JWT secret).',
        );
      }

      // Mark email as verified now that login email OTP is verified.
      await session.db.unsafeExecute(
        'UPDATE users SET email_otp_verified = TRUE WHERE email = @e',
        parameters: QueryParameters.named({'e': email}),
      );

      final userId = _decodeDbValue(row['user_id']);
      final decodedRole = _decodeDbValue(row['role']).toUpperCase();

      final authToken = _issueAuthToken(
        session,
        email: email,
        userId: userId,
        role: decodedRole,
      );
      if (authToken == null) {
        return LoginResponse(
          success: false,
          error: 'Server auth is not configured (missing JWT secret).',
        );
      }

      return LoginResponse(
        success: true,
        role: decodedRole,
        userId: userId,
        userName: _decodeDbValue(row['name']),
        phone: _decodeDbValue(row['phone']),
        token: authToken,
      );
    } catch (e, st) {
      session.log('verifyLoginOtp failed: $e\n$st', level: LogLevel.error);
      return LoginResponse(success: false, error: 'Internal server error');
    }
  }

  /// Logout: client should delete its auth token.
  ///
  /// Note: we intentionally do not store per-session token revocation state.
  /// This keeps the DB minimal as requested (only tracks `email_otp_verified`).
  Future<bool> logout(Session session) async {
    try {
      await _ensureSecurityColumns(session);

      final auth = session.authenticated;
      if (auth == null) return false;
      return true;
    } catch (e, st) {
      session.log('logout failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  //REGISTER (Generate OTP)
  Future<String> register(Session session, String email, String password,
      String name, String role) async {
    final existing = await session.db.unsafeQuery(
      'SELECT 1 FROM users WHERE email = @email',
      parameters: QueryParameters.named({'email': email}),
    );

    if (existing.isNotEmpty) return 'Email already registered';

    return _sendOtp(session, email, password, name, role);
  }

  // RESEND OTP
  Future<String> resendOtp(Session session, String email, String password,
      String name, String role) async {
    return _sendOtp(session, email, password, name, role);
  }

  //COMMON OTP SENDING LOGIC
  Future<String> _sendOtp(Session session, String email, String password,
      String name, String role) async {
    final jwtSecret = _jwtSecret(session);
    if (jwtSecret == null) {
      return 'Server auth is not configured (missing JWT secret).';
    }
    // Generate OTP and JWT token (expires in 2 minutes)
    final otp = (Random().nextInt(900000) + 100000).toString();
    final jti = _uuid.v4();

    // Build JWT with claims: email, otp, jti
    final jwt = JWT(
      {
        'purpose': 'signup_email',
        'email': email,
        'otp': otp,
        'jti': jti,
      },
      issuer: 'dishari',
      subject: email,
    );

    final token = jwt.sign(SecretKey(jwtSecret), expiresIn: _otpTtl);

    final success = await _sendOtpWithResend(session, email, otp);

    if (success) {
      session.log('OTP $otp sent successfully via Resend to $email');
      // Return the token to the client; client must send it back when verifying
      return token;
    } else {
      return 'Failed to send OTP. Please try again later.';
    }
  }

  /// After signup email OTP verified, start phone verification.
  /// Since no SMS API, OTP is returned as debugOtp for UI popup.
  Future<OtpChallengeResponse> verifySignupEmailAndStartPhoneOtp(
    Session session,
    String email,
    String emailOtp,
    String emailOtpToken,
    String phone,
  ) async {
    final rateKey = 'verifySignupEmail_$email';
    if (_isRateLimited(rateKey)) {
      return OtpChallengeResponse(
        success: false,
        error: 'Too many OTP attempts. Please wait.',
      );
    }

    final err = await _validateOtpToken(
      session: session,
      purpose: 'signup_email',
      otp: emailOtp,
      token: emailOtpToken,
      email: email,
    );
    if (err != null) {
      return OtpChallengeResponse(success: false, error: err);
    }

    final phoneChallenge = await _createOtpToken(
      session: session,
      purpose: 'signup_phone',
      email: email,
      phone: phone,
    );
    if (!phoneChallenge.success) return phoneChallenge;

    // Print on backend (and also return to client for temporary popup).
    session
        .log('PHONE OTP for $phone (email=$email): ${phoneChallenge.debugOtp}');

    return phoneChallenge;
  }

  /// Finalize signup by verifying phone OTP, then creating the user.
  /// Returns LoginResponse with session token (auto-login after signup).
  Future<LoginResponse> completeSignupWithPhoneOtp(
    Session session,
    String email,
    String phone,
    String phoneOtp,
    String phoneOtpToken,
    String password,
    String name,
    String role,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? gender,
  ) async {
    final rateKey = 'completeSignup_$email';
    if (_isRateLimited(rateKey)) {
      return LoginResponse(
        success: false,
        error: 'Too many attempts. Please wait.',
      );
    }

    await _ensureSecurityColumns(session);

    final err = await _validateOtpToken(
      session: session,
      purpose: 'signup_phone',
      otp: phoneOtp,
      token: phoneOtpToken,
      email: email,
      phone: phone,
    );
    if (err != null) return LoginResponse(success: false, error: err);

    // Ensure phone uniqueness
    try {
      if (phone.trim().isNotEmpty) {
        final existingPhone = await session.db.unsafeQuery(
          'SELECT 1 FROM users WHERE phone = @ph',
          parameters: QueryParameters.named({'ph': phone}),
        );
        if (existingPhone.isNotEmpty) {
          return LoginResponse(
            success: false,
            error: 'Registration failed: Phone number already registered.',
          );
        }
      }
    } catch (_) {}

    final hashed = sha256.convert(utf8.encode(password)).toString();

    int? generatedId;

    try {
      await session.db.unsafeExecute('BEGIN');

      final insertResult = await session.db.unsafeQuery(
        '''
        INSERT INTO users (name, email, password_hash, phone, role, is_active)
        VALUES (@n, @e, @p, @ph, @r::user_role, TRUE)
        RETURNING user_id
        ''',
        parameters: QueryParameters.named({
          'n': name,
          'e': email,
          'p': hashed,
          'ph': phone,
          'r': role,
        }),
      );

      if (insertResult.isEmpty) {
        await session.db.unsafeExecute('ROLLBACK');
        return LoginResponse(
            success: false, error: 'Database error during account creation.');
      }
      final insertedRow = insertResult.first.toColumnMap();
      generatedId = _decodeDbInt(insertedRow['user_id']);
      if (generatedId == null) {
        await session.db.unsafeExecute('ROLLBACK');
        return LoginResponse(
            success: false, error: 'Database error during account creation.');
      }

      if (role == 'STUDENT' || role == 'TEACHER' || role == 'STAFF') {
        await session.db.unsafeExecute(
          '''
          INSERT INTO patient_profiles (user_id, blood_group, date_of_birth, gender)
          VALUES (@uid, @bg, @dob, @gender)
          ''',
          parameters: QueryParameters.named({
            'uid': generatedId,
            'bg': bloodGroup,
            'dob': dateOfBirth,
            'gender': gender,
          }),
        );
      }

      await session.db.unsafeExecute('COMMIT');
    } on DatabaseQueryException catch (e) {
      await session.db.unsafeExecute('ROLLBACK');

      final msg = e.message.toLowerCase();
      if (msg.contains('users_phone_key') || msg.contains('phone')) {
        return LoginResponse(
            success: false, error: 'Phone number already exists');
      }
      if (msg.contains('users_email_key') || msg.contains('email')) {
        return LoginResponse(success: false, error: 'Email already exists');
      }

      session.log('Database error during user creation: $e',
          level: LogLevel.error);
      return LoginResponse(
          success: false, error: 'Database error during account creation.');
    } catch (e) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('Unexpected error: $e', level: LogLevel.error);
      return LoginResponse(
          success: false,
          error: 'An unexpected error occurred during registration.');
    }

    // Auto-login after successful signup.
    final jwtSecret = _jwtSecret(session);
    if (jwtSecret == null) {
      return LoginResponse(
          success: false,
          error: 'Server auth is not configured (missing JWT secret).');
    }

    final authToken = _issueAuthToken(
      session,
      email: email,
      userId: generatedId.toString(),
      role: role.toUpperCase(),
    );
    if (authToken == null) {
      return LoginResponse(
        success: false,
        error: 'Server auth is not configured (missing JWT secret).',
      );
    }

    return LoginResponse(
      success: true,
      role: role.toUpperCase(),
      userId: generatedId.toString(),
      userName: name,
      phone: phone,
      bloodGroup: bloodGroup,
      age: _calculateAgeFromDob(dateOfBirth),
      token: authToken,
    );
  }

  // ---------------- RESEND EMAIL (delegated to mail service) ----------------
  Future<bool> _sendOtpWithResend(Session session, String email, String otp,
          {bool isReset = false}) =>
      mail.sendOtpWithResend(session, email, otp, isReset: isReset);

  /// Public helper: send a welcome email using Resend API. Returns true on success.
  Future<bool> sendWelcomeEmailViaResend(
          Session session, String email, String name) =>
      mail.sendWelcomeEmail(session, email, name);

  // VERIFY OTP
  Future<String> verifyOtp(
    Session session,
    String email,
    String otp,
    String token,
    String password,
    String name,
    String role,
    String? phone,
    String? bloodGroup,
    String? allergies,
  ) async {
    final rateKey = 'verifyOtp_$email';
    if (_isRateLimited(rateKey)) {
      return 'Too many OTP attempts. Please wait.';
    }

    // Backwards-compat: legacy verifyOtp flow (email only) kept for older clients.
    // New clients should use verifySignupEmailAndStartPhoneOtp + completeSignupWithPhoneOtp.
    final err = await _validateOtpToken(
      session: session,
      purpose: 'signup_email',
      otp: otp,
      token: token,
      email: email,
    );
    if (err != null) return err;

    // Ensure phone uniqueness if phone provided
    try {
      if (phone != null && phone.trim().isNotEmpty) {
        final existingPhone = await session.db.unsafeQuery(
          'SELECT 1 FROM users WHERE phone = @ph',
          parameters: QueryParameters.named({'ph': phone}),
        );
        if (existingPhone.isNotEmpty) {
          return 'Registration failed: Phone number already registered.';
        }
      }
    } catch (e) {
      session.log('Phone uniqueness check failed: $e', level: LogLevel.warning);
      // Continue - if DB check fails for unexpected reason, let insertion handle unique constraint
    }

    final hashed = sha256.convert(utf8.encode(password)).toString();
    // final String userId = email; // user_id should be auto-generated by DB

    try {
      // Start a transaction
      await session.db.unsafeExecute('BEGIN');

      // 1. Insert into users table and get generated user_id
      final insertResult = await session.db.unsafeQuery(
        '''
      INSERT INTO users (name, email, password_hash, phone, role, is_active)
      VALUES (@n, @e, @p, @ph, @r::user_role, TRUE)
      RETURNING user_id
      ''',
        parameters: QueryParameters.named({
          'n': name,
          'e': email,
          'p': hashed,
          'ph': phone,
          'r': role,
        }),
      );

      if (insertResult.isEmpty) {
        await session.db.unsafeExecute('ROLLBACK');
        return 'Database error during account creation.';
      }

      final insertedRow = insertResult.first.toColumnMap();
      final dynamic generatedId = insertedRow['user_id'];

      // 2. Insert into patient_profiles table ONLY for STUDENT, TEACHER, STAFF
      if (role == 'STUDENT' || role == 'TEACHER' || role == 'STAFF') {
        await session.db.unsafeExecute(
          '''
        INSERT INTO patient_profiles (user_id, blood_group, date_of_birth)
        VALUES (@uid, @bg, NULL)
        ''',
          parameters: QueryParameters.named({
            'uid': generatedId,
            'bg': bloodGroup,
          }),
        );
      }

      // Commit transaction
      await session.db.unsafeExecute('COMMIT');
    } on DatabaseQueryException catch (e) {
      await session.db.unsafeExecute('ROLLBACK');

      final msg = e.message.toLowerCase();

      if (msg.contains('users_phone_key') || msg.contains('phone')) {
        return 'Phone number already exists';
      }

      if (msg.contains('users_email_key') || msg.contains('email')) {
        return 'Email already exists';
      }

      session.log('Database error during user creation: $e',
          level: LogLevel.error);
      return 'Database error during account creation.';
    } catch (e) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('Unexpected error: $e', level: LogLevel.error);
      return 'An unexpected error occurred during registration.';
    }

    return 'Account created successfully';
  }

  // ---------------- FORGOT PASSWORD / RESET FLOW ----------------
  /// Request a password reset: generate OTP and JWT token (expires in 2 minutes)
  /// Returns the token if email was sent successfully, otherwise an error message.
  Future<String> requestPasswordReset(Session session, String email) async {
    final rateKey = 'reset_$email';
    if (_isRateLimited(rateKey)) {
      return 'Too many reset requests. Please try later.';
    }

    try {
      // Check if user exists in the database; if not, return explicit "User not found" per request
      final exists = await session.db.unsafeQuery(
        'SELECT 1 FROM users WHERE email = @e',
        parameters: QueryParameters.named({'e': email}),
      );

      if (exists.isEmpty) {
        return 'User not found';
      }

      // Generate OTP and token (even if user does not exist, generate & attempt send to keep timing similar)
      final otp = (Random().nextInt(900000) + 100000).toString();
      final jti = _uuid.v4();

      final jwt = JWT(
        {
          'email': email,
          'otp': otp,
          'jti': jti,
        },
        issuer: 'dishari',
        subject: email,
      );

      final jwtSecret = _jwtSecret(session);
      if (jwtSecret == null) {
        return 'Server auth is not configured (missing JWT secret).';
      }

      final token =
          jwt.sign(SecretKey(jwtSecret), expiresIn: Duration(minutes: 2));

      // Try to send email. If user doesn't exist, _sendOtpWithResend will still be called but not harmful.
      final sent = await _sendOtpWithResend(session, email, otp, isReset: true);

      if (sent) {
        session.log('Password reset OTP $otp sent to $email');
        return token;
      } else {
        return 'Failed to send password reset email. Please try again later.';
      }
    } catch (e, st) {
      session.log('requestPasswordReset failed: $e\n$st',
          level: LogLevel.error);
      return 'Internal server error';
    }
  }

  /// Verify password reset OTP using the client-provided token.
  /// Returns 'OK' on success or an error message on failure.
  Future<String> verifyPasswordReset(
      Session session, String email, String otp, String token) async {
    try {
      final jwtSecret = _jwtSecret(session);
      if (jwtSecret == null) {
        return 'Server auth is not configured (missing JWT secret).';
      }

      final jwt = JWT.verify(token, SecretKey(jwtSecret));
      final payload = jwt.payload;

      if (payload['email'] != email || payload['otp'] != otp) {
        return 'Invalid or expired OTP';
      }

      return 'OK';
    } catch (e) {
      session.log('verifyPasswordReset JWT verification failed: $e',
          level: LogLevel.warning);
      return 'Invalid or expired OTP';
    }
  }

  /// Reset the user's password. Token must be a valid JWT created by requestPasswordReset.
  Future<String> resetPassword(
      Session session, String email, String token, String newPassword) async {
    try {
      final jwtSecret = _jwtSecret(session);
      if (jwtSecret == null) {
        return 'Server auth is not configured (missing JWT secret).';
      }

      final jwt = JWT.verify(token, SecretKey(jwtSecret));
      final payload = jwt.payload;

      if (payload['email'] != email) {
        return 'Invalid token';
      }

      final hashed = sha256.convert(utf8.encode(newPassword)).toString();

      // Update password if user exists
      await session.db.unsafeExecute(
        '''
        UPDATE users SET password_hash = @p WHERE email = @e
        ''',
        parameters: QueryParameters.named({'p': hashed, 'e': email}),
      );

      // unsafeExecute does not return affected rows; do a quick check
      final check = await session.db.unsafeQuery(
        'SELECT 1 FROM users WHERE email = @e',
        parameters: QueryParameters.named({'e': email}),
      );

      if (check.isEmpty) {
        return 'User not found';
      }

      session.log('Password reset successful for $email');
      return 'Password reset successful';
    } catch (e, st) {
      session.log('resetPassword failed: $e\n$st', level: LogLevel.error);
      return 'Internal server error';
    }
  }

  // ---------- Universal Change Password (Logged-in) ----------

  String? _validateNewPassword(String p) {
    final s = p.trim();
    if (s.isEmpty) return 'New password is required';
    if (s.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// Universal: all roles can change password with the same rules.
  /// Identifies user by email (same as your login uses email).
  Future<String> changePasswordUniversal(
    Session session,
    String email,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      if (email.trim().isEmpty) return 'Email is required';
      if (currentPassword.trim().isEmpty) return 'Current password is required';

      final err = _validateNewPassword(newPassword);
      if (err != null) return err;

      final result = await session.db.unsafeQuery(
        'SELECT passwordhash FROM users WHERE email = e LIMIT 1',
        parameters: QueryParameters.named({'e': email.trim()}),
      );
      if (result.isEmpty) return 'User not found';

      final row = result.first.toColumnMap();
      final ph = row['passwordhash'];

      String storedHash = '';
      if (ph == null) {
        storedHash = '';
      } else if (ph is List<int>) {
        storedHash = String.fromCharCodes(ph);
      } else {
        storedHash = ph.toString();
      }

      final currHash = sha256.convert(utf8.encode(currentPassword)).toString();
      if (storedHash != currHash) return 'Incorrect current password';

      final newHash = sha256.convert(utf8.encode(newPassword)).toString();
      await session.db.unsafeExecute(
        'UPDATE users SET passwordhash = p WHERE email = e',
        parameters: QueryParameters.named({'p': newHash, 'e': email.trim()}),
      );

      return 'OK';
    } catch (e, st) {
      session.log('changePasswordUniversal failed: $e',
          level: LogLevel.error, stackTrace: st);
      return 'Failed to change password';
    }
  }
}
