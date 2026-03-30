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
import 'dart:typed_data' as _i2;

abstract class ExternalReportFile
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ExternalReportFile._({
    this.bytes,
    this.contentType,
    this.fileName,
  });

  factory ExternalReportFile({
    _i2.ByteData? bytes,
    String? contentType,
    String? fileName,
  }) = _ExternalReportFileImpl;

  factory ExternalReportFile.fromJson(Map<String, dynamic> jsonSerialization) {
    return ExternalReportFile(
      bytes: jsonSerialization['bytes'] == null
          ? null
          : _i1.ByteDataJsonExtension.fromJson(jsonSerialization['bytes']),
      contentType: jsonSerialization['contentType'] as String?,
      fileName: jsonSerialization['fileName'] as String?,
    );
  }

  _i2.ByteData? bytes;

  String? contentType;

  String? fileName;

  /// Returns a shallow copy of this [ExternalReportFile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ExternalReportFile copyWith({
    _i2.ByteData? bytes,
    String? contentType,
    String? fileName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ExternalReportFile',
      if (bytes != null) 'bytes': bytes?.toJson(),
      if (contentType != null) 'contentType': contentType,
      if (fileName != null) 'fileName': fileName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ExternalReportFile',
      if (bytes != null) 'bytes': bytes?.toJson(),
      if (contentType != null) 'contentType': contentType,
      if (fileName != null) 'fileName': fileName,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ExternalReportFileImpl extends ExternalReportFile {
  _ExternalReportFileImpl({
    _i2.ByteData? bytes,
    String? contentType,
    String? fileName,
  }) : super._(
         bytes: bytes,
         contentType: contentType,
         fileName: fileName,
       );

  /// Returns a shallow copy of this [ExternalReportFile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ExternalReportFile copyWith({
    Object? bytes = _Undefined,
    Object? contentType = _Undefined,
    Object? fileName = _Undefined,
  }) {
    return ExternalReportFile(
      bytes: bytes is _i2.ByteData? ? bytes : this.bytes?.clone(),
      contentType: contentType is String? ? contentType : this.contentType,
      fileName: fileName is String? ? fileName : this.fileName,
    );
  }
}
