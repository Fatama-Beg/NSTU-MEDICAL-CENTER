/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class OtpChallengeResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  OtpChallengeResponse._({
    required this.success,
    this.error,
    this.token,
    this.debugOtp,
    this.expiresInSeconds,
  });

  factory OtpChallengeResponse({
    required bool success,
    String? error,
    String? token,
    String? debugOtp,
    int? expiresInSeconds,
  }) = _OtpChallengeResponseImpl;

  factory OtpChallengeResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return OtpChallengeResponse(
      success: jsonSerialization['success'] as bool,
      error: jsonSerialization['error'] as String?,
      token: jsonSerialization['token'] as String?,
      debugOtp: jsonSerialization['debugOtp'] as String?,
      expiresInSeconds: jsonSerialization['expiresInSeconds'] as int?,
    );
  }

  bool success;

  String? error;

  String? token;

  String? debugOtp;

  int? expiresInSeconds;

  /// Returns a shallow copy of this [OtpChallengeResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtpChallengeResponse copyWith({
    bool? success,
    String? error,
    String? token,
    String? debugOtp,
    int? expiresInSeconds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OtpChallengeResponse',
      'success': success,
      if (error != null) 'error': error,
      if (token != null) 'token': token,
      if (debugOtp != null) 'debugOtp': debugOtp,
      if (expiresInSeconds != null) 'expiresInSeconds': expiresInSeconds,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OtpChallengeResponse',
      'success': success,
      if (error != null) 'error': error,
      if (token != null) 'token': token,
      if (debugOtp != null) 'debugOtp': debugOtp,
      if (expiresInSeconds != null) 'expiresInSeconds': expiresInSeconds,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OtpChallengeResponseImpl extends OtpChallengeResponse {
  _OtpChallengeResponseImpl({
    required bool success,
    String? error,
    String? token,
    String? debugOtp,
    int? expiresInSeconds,
  }) : super._(
         success: success,
         error: error,
         token: token,
         debugOtp: debugOtp,
         expiresInSeconds: expiresInSeconds,
       );

  /// Returns a shallow copy of this [OtpChallengeResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtpChallengeResponse copyWith({
    bool? success,
    Object? error = _Undefined,
    Object? token = _Undefined,
    Object? debugOtp = _Undefined,
    Object? expiresInSeconds = _Undefined,
  }) {
    return OtpChallengeResponse(
      success: success ?? this.success,
      error: error is String? ? error : this.error,
      token: token is String? ? token : this.token,
      debugOtp: debugOtp is String? ? debugOtp : this.debugOtp,
      expiresInSeconds: expiresInSeconds is int?
          ? expiresInSeconds
          : this.expiresInSeconds,
    );
  }
}
