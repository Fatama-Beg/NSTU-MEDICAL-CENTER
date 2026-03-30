import 'dart:async';
import 'dart:math';

import 'package:backend_client/backend_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmailOtpVerificationPayload {
  final String otp;
  final String otpToken;
  const EmailOtpVerificationPayload({
    required this.otp,
    required this.otpToken,
  });
}

class MailPhnUpdateVerify {
  static const Duration otpValidity = Duration(minutes: 2);

  /// Disallows any whitespace characters in email input.
  static final TextInputFormatter denyWhitespaceFormatter =
      FilteringTextInputFormatter.deny(RegExp(r'\s'));

  /// Allows only digits and an optional leading `+`.
  ///
  /// - Removes any non-digit characters.
  /// - Keeps a single `+` only if it's the first character.
  static final TextInputFormatter phoneDigitsAndOptionalLeadingPlusFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final raw = newValue.text;
        final hasLeadingPlus = raw.startsWith('+');
        final digits = raw.replaceAll(RegExp(r'\D'), '');
        final nextText = hasLeadingPlus ? '+$digits' : digits;

        return TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
        );
      });

  static bool isValidBangladeshPhoneForProfile(String value) {
    return normalizeBangladeshPhoneForProfile(value) != null;
  }

  /// Normalizes the phone to `+8801XXXXXXXXX` or returns null if invalid.
  /// Accepts:
  /// - `+8801XXXXXXXXX`
  /// - `8801XXXXXXXXX`
  /// - `01XXXXXXXXX`
  static String? normalizeBangladeshPhoneForProfile(String value) {
    final raw = value.trim().replaceAll(' ', '');
    if (raw.isEmpty) return null;

    if (RegExp(r'^\+8801\d{9}$').hasMatch(raw)) return raw;
    if (RegExp(r'^8801\d{9}$').hasMatch(raw)) return '+$raw';
    if (RegExp(r'^01\d{9}$').hasMatch(raw)) return '+88$raw';
    return null;
  }

  static bool isValidEmailForProfile(String value) {
    final email = value.trim().toLowerCase();
    if (email.isEmpty) return false;
    if (email.contains(' ')) return false;
    final at = email.indexOf('@');
    if (at <= 0 || at == email.length - 1) return false;

    final domain = email.substring(at + 1);
    if (domain == 'gmail.com') return true;
    if (domain == 'nstu.edu.bd') return true;
    if (domain.endsWith('.nstu.edu.bd')) return true;
    return false;
  }

  static Future<EmailOtpVerificationPayload?> verifyEmailChange({
    required BuildContext context,
    required Client client,
    required String newEmail,
  }) async {
    final email = newEmail.trim();
    if (!isValidEmailForProfile(email)) {
      await _showInfo(
        context,
        title: 'Invalid Email',
        message: 'Email must end with gmail.com or .nstu.edu.bd',
      );
      return null;
    }

    OtpChallengeResponse? challenge;
    DateTime? issuedAt;

    Future<bool> requestOtp() async {
      final c = await client.auth.requestProfileEmailChangeOtp(email);
      if (c.success != true || (c.token?.isNotEmpty != true)) {
        await _showInfo(
          context,
          title: 'Failed',
          message: c.error ?? 'Failed to send OTP.',
        );
        return false;
      }
      challenge = c;
      issuedAt = DateTime.now();
      return true;
    }

    final ok = await requestOtp();
    if (!ok) return null;

    final otpCtrl = TextEditingController();
    final result = await showDialog<EmailOtpVerificationPayload>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Timer? timer;
        int remaining = _effectiveTtlSeconds(challenge);
        bool verifying = false;
        bool started = false;

        void startTimer(StateSetter setStateDialog) {
          if (started) return;
          started = true;
          timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!ctx.mounted) {
              timer?.cancel();
              return;
            }
            final start = issuedAt;
            if (start == null) return;
            final elapsed = DateTime.now().difference(start).inSeconds;
            final ttl = _effectiveTtlSeconds(challenge);
            final left = (ttl - elapsed).clamp(0, ttl);
            setStateDialog(() => remaining = left);
          });
        }

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            startTimer(setStateDialog);

            Future<void> resend() async {
              setStateDialog(() => verifying = true);
              try {
                final sent = await requestOtp();
                if (sent) {
                  otpCtrl.clear();
                  if (!ctx.mounted) return;
                  setStateDialog(
                    () => remaining = _effectiveTtlSeconds(challenge),
                  );
                }
              } finally {
                if (!ctx.mounted) return;
                setStateDialog(() => verifying = false);
              }
            }

            Future<void> verify() async {
              if (remaining <= 0) {
                await _showInfo(
                  ctx,
                  title: 'Expired',
                  message: 'OTP expired (2 minutes). Please resend OTP.',
                );
                return;
              }
              final otp = otpCtrl.text.trim();
              if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                await _showInfo(
                  ctx,
                  title: 'Invalid Code',
                  message: 'Enter the 6-digit OTP.',
                );
                return;
              }
              final token = challenge?.token;
              if (token == null || token.isEmpty) {
                await _showInfo(
                  ctx,
                  title: 'Failed',
                  message: 'OTP token missing. Please resend OTP.',
                );
                return;
              }

              setStateDialog(() => verifying = true);
              try {
                final verified = await client.auth.verifyProfileEmailChangeOtp(
                  email,
                  otp,
                  token,
                );
                if (verified != true) {
                  await _showInfo(
                    ctx,
                    title: 'Failed',
                    message: 'Invalid or expired OTP. Please resend OTP.',
                  );
                  return;
                }
                timer?.cancel();
                Navigator.pop(
                  ctx,
                  EmailOtpVerificationPayload(otp: otp, otpToken: token),
                );
              } finally {
                if (!ctx.mounted) return;
                setStateDialog(() => verifying = false);
              }
            }

            return WillPopScope(
              onWillPop: () async {
                if (verifying) return false;
                timer?.cancel();
                return true;
              },
              child: AlertDialog(
                title: const Text('Verify Email'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A 6-digit code was sent to $email.'),
                    const SizedBox(height: 8),
                    Text(
                      remaining > 0
                          ? 'Expires in ${_mmss(remaining)}'
                          : 'Expired. Please resend OTP.',
                      style: TextStyle(
                        color: remaining > 0 ? Colors.black54 : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Enter OTP',
                        border: OutlineInputBorder(),
                        counterText: ' ',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: verifying
                        ? null
                        : () {
                            timer?.cancel();
                            Navigator.pop(ctx);
                          },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: verifying ? null : resend,
                    child: Text(verifying ? 'PLEASE WAIT...' : 'Resend'),
                  ),
                  TextButton(
                    onPressed: verifying ? null : verify,
                    child: Text(verifying ? 'VERIFYING...' : 'Verify'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result;
  }

  static Future<bool> verifyPhoneDummy({
    required BuildContext context,
    required String newPhone,
  }) async {
    final normalizedPhone = normalizeBangladeshPhoneForProfile(newPhone);
    if (normalizedPhone == null) {
      await _showInfo(
        context,
        title: 'Invalid Phone',
        message: 'Phone must be like +8801XXXXXXXXX (or enter 01XXXXXXXXX).',
      );
      return false;
    }

    final rand = Random.secure();
    String code = (rand.nextInt(900000) + 100000).toString();
    DateTime issuedAt = DateTime.now();
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Timer? timer;
        int remaining = otpValidity.inSeconds;
        bool verifying = false;
        bool started = false;

        void startTimer(StateSetter setStateDialog) {
          if (started) return;
          started = true;
          timer = Timer.periodic(const Duration(seconds: 1), (_) {
            final elapsed = DateTime.now().difference(issuedAt).inSeconds;
            final left = (otpValidity.inSeconds - elapsed).clamp(
              0,
              otpValidity.inSeconds,
            );
            setStateDialog(() => remaining = left);
          });
        }

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            startTimer(setStateDialog);

            void resend() {
              setStateDialog(() {
                code = (rand.nextInt(900000) + 100000).toString();
                issuedAt = DateTime.now();
                remaining = otpValidity.inSeconds;
                ctrl.clear();
              });
            }

            Future<void> verify() async {
              if (remaining <= 0) {
                await _showInfo(
                  ctx,
                  title: 'Expired',
                  message:
                      'Verification expired (2 minutes). Please resend code.',
                );
                return;
              }

              final entered = ctrl.text.trim();
              if (!RegExp(r'^\d{6}$').hasMatch(entered)) {
                await _showInfo(
                  ctx,
                  title: 'Invalid Code',
                  message: 'Enter the 6-digit code.',
                );
                return;
              }

              setStateDialog(() => verifying = true);
              try {
                if (entered != code) {
                  await _showInfo(
                    ctx,
                    title: 'Invalid Code',
                    message: 'Incorrect code. Try again.',
                  );
                  return;
                }

                timer?.cancel();
                Navigator.pop(ctx, true);
              } finally {
                setStateDialog(() => verifying = false);
              }
            }

            return WillPopScope(
              onWillPop: () async {
                if (verifying) return false;
                timer?.cancel();
                return true;
              },
              child: AlertDialog(
                title: const Text('Verify Phone'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dummy verification (no SMS API configured).'),
                    const SizedBox(height: 6),
                    Text('Phone: $normalizedPhone'),
                    const SizedBox(height: 6),
                    Text(
                      'Code: $code',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      remaining > 0
                          ? 'Expires in ${_mmss(remaining)}'
                          : 'Expired. Please resend code.',
                      style: TextStyle(
                        color: remaining > 0 ? Colors.black54 : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Enter Code',
                        border: OutlineInputBorder(),
                        counterText: ' ',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: verifying
                        ? null
                        : () {
                            timer?.cancel();
                            Navigator.pop(ctx);
                          },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: verifying ? null : resend,
                    child: const Text('Resend'),
                  ),
                  TextButton(
                    onPressed: verifying ? null : verify,
                    child: Text(verifying ? 'VERIFYING...' : 'Verify'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return ok == true;
  }

  static int _effectiveTtlSeconds(OtpChallengeResponse? challenge) {
    final ttl = challenge?.expiresInSeconds;
    final v = (ttl == null || ttl <= 0) ? otpValidity.inSeconds : ttl;
    return v > otpValidity.inSeconds ? otpValidity.inSeconds : v;
  }

  static String _mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static Future<void> _showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
