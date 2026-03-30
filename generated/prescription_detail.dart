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
import 'prescription.dart' as _i2;
import 'PrescribedItem.dart' as _i3;
import 'package:backend_server/src/generated/protocol.dart' as _i4;

abstract class PrescriptionDetail
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PrescriptionDetail._({
    required this.prescription,
    required this.items,
    this.doctorName,
    this.doctorSignatureUrl,
  });

  factory PrescriptionDetail({
    required _i2.Prescription prescription,
    required List<_i3.PrescribedItem> items,
    String? doctorName,
    String? doctorSignatureUrl,
  }) = _PrescriptionDetailImpl;

  factory PrescriptionDetail.fromJson(Map<String, dynamic> jsonSerialization) {
    return PrescriptionDetail(
      prescription: _i4.Protocol().deserialize<_i2.Prescription>(
        jsonSerialization['prescription'],
      ),
      items: _i4.Protocol().deserialize<List<_i3.PrescribedItem>>(
        jsonSerialization['items'],
      ),
      doctorName: jsonSerialization['doctorName'] as String?,
      doctorSignatureUrl: jsonSerialization['doctorSignatureUrl'] as String?,
    );
  }

  _i2.Prescription prescription;

  List<_i3.PrescribedItem> items;

  String? doctorName;

  String? doctorSignatureUrl;

  /// Returns a shallow copy of this [PrescriptionDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PrescriptionDetail copyWith({
    _i2.Prescription? prescription,
    List<_i3.PrescribedItem>? items,
    String? doctorName,
    String? doctorSignatureUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PrescriptionDetail',
      'prescription': prescription.toJson(),
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      if (doctorName != null) 'doctorName': doctorName,
      if (doctorSignatureUrl != null) 'doctorSignatureUrl': doctorSignatureUrl,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PrescriptionDetail',
      'prescription': prescription.toJsonForProtocol(),
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (doctorName != null) 'doctorName': doctorName,
      if (doctorSignatureUrl != null) 'doctorSignatureUrl': doctorSignatureUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PrescriptionDetailImpl extends PrescriptionDetail {
  _PrescriptionDetailImpl({
    required _i2.Prescription prescription,
    required List<_i3.PrescribedItem> items,
    String? doctorName,
    String? doctorSignatureUrl,
  }) : super._(
         prescription: prescription,
         items: items,
         doctorName: doctorName,
         doctorSignatureUrl: doctorSignatureUrl,
       );

  /// Returns a shallow copy of this [PrescriptionDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PrescriptionDetail copyWith({
    _i2.Prescription? prescription,
    List<_i3.PrescribedItem>? items,
    Object? doctorName = _Undefined,
    Object? doctorSignatureUrl = _Undefined,
  }) {
    return PrescriptionDetail(
      prescription: prescription ?? this.prescription.copyWith(),
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      doctorName: doctorName is String? ? doctorName : this.doctorName,
      doctorSignatureUrl: doctorSignatureUrl is String?
          ? doctorSignatureUrl
          : this.doctorSignatureUrl,
    );
  }
}
