import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

/// Resolve the Resend API key from Serverpod passwords or env.
String? getResendApiKey(Session session) {
  final fromPasswords = session.passwords['resendApiKey'];
  if (fromPasswords != null && fromPasswords.trim().isNotEmpty) {
    return fromPasswords.trim();
  }
  final fromEnv = Platform.environment['RESEND_API_KEY'];
  if (fromEnv == null || fromEnv.trim().isEmpty) return null;
  return fromEnv.trim();
}

/// Sends an OTP email using the Resend API.
/// If [isReset] is true, the email content/subject will be for password reset;
/// otherwise it's for registration.
Future<bool> sendOtpWithResend(
  Session session,
  String email,
  String otp, {
  bool isReset = false,
}) async {
  final resendApiKey = getResendApiKey(session);
  if (resendApiKey == null) {
    session.log('Missing RESEND_API_KEY (or passwords.resendApiKey).',
        level: LogLevel.warning);
    return false;
  }
  // Subject and email body content
  final String subject = isReset
      ? 'NSTU Medical Center Password Reset Code'
      : 'NSTU Medical Center Verification Code';

  final String plainTextBody = isReset
      ? 'Your NSTU Medical Center password reset code is: $otp\n'
          'This code will expire in 2 minutes.\n\n'
          'If you did not request this, you can ignore this email.'
      : 'Your NSTU Medical Center registration code is: $otp\n'
          'This code will expire in 2 minutes.\n\n'
          'If you did not request this, you can ignore this email.';

  final String htmlBody = """
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>$subject</title>
  </head>
  <body style="font-family: Arial, sans-serif; line-height:1.6; color:#333;">
    <h2 style="color:#1a1a1a;">$subject</h2>
    <p>Hello,</p>
    <p>We received a request to verify your email for NSTU Medical Center.</p>
    <p>Your one-time code is:</p>
    <h1 style="margin:0; font-size:28px; letter-spacing:1.5px;">$otp</h1>
    <p>This code will expire in <strong>2 minutes</strong>.</p>
    <p>Please do not share this code with anyone.</p>
    <p>If you did not request ${isReset ? 'a password reset' : 'this verification'}, you can safely ignore this email.</p>
    <br>
    <p>Thank you,<br>NSTU Medical Center</p>
  </body>
</html>
""";

  // Resend API payload
  const String fromEmail = "NSTU Medical Center <onboarding@sabbir.qzz.io>";

  final Map<String, dynamic> emailData = {
    "from": fromEmail,
    "to": [email],
    "subject": subject,
    // Include both plain text and HTML
    "text": plainTextBody,
    "html": htmlBody,
  };

  try {
    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $resendApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(emailData),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      session.log('Email ($subject) sent successfully to $email via Resend',
          level: LogLevel.info);
      return true;
    } else {
      session.log('Resend API Error (${response.statusCode}): ${response.body}',
          level: LogLevel.warning);
      return false;
    }
  } catch (e) {
    session.log('Resend API connection error: $e', level: LogLevel.warning);
    return false;
  }
}

/// Send a welcome email using Resend API. Returns true on success.
Future<bool> sendWelcomeEmail(
  Session session,
  String email,
  String name,
) async {
  final resendApiKey = getResendApiKey(session);
  if (resendApiKey == null) {
    session.log('Missing RESEND_API_KEY', level: LogLevel.warning);
    return false;
  }

  final String subject = 'Welcome to NSTU Medical Center';
  final String mailBody =
      'Hi $name,\n\nYour account has been created. You can log in using your email.';

  const String verifiedFromEmail =
      "Welcome to NSTU Medical Center <onboarding@sabbir.qzz.io>";

  final Map<String, dynamic> emailData = {
    "from": verifiedFromEmail,
    "to": [email],
    "subject": subject,
    "text": mailBody,
  };

  try {
    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $resendApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(emailData),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      session.log('Welcome email sent to $email');
      return true;
    } else {
      session.log('Resend error: ${response.body}', level: LogLevel.warning);
      return false;
    }
  } catch (e) {
    session.log('Resend API connection error: $e', level: LogLevel.warning);
    return false;
  }
}
