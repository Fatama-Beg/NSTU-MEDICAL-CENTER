import 'package:serverpod/serverpod.dart';
import 'package:backend_server/src/generated/protocol.dart';

import '../../auth/auth_user.dart';

class PatientEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  DateTime? _safeDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is List<int>) {
      return DateTime.tryParse(String.fromCharCodes(value));
    }
    return DateTime.tryParse(value.toString());
  }

  // Fetch patient profile
  Future<PatientProfile?> getPatientProfile(Session session) async {
    try {
      final resolvedUserId = requireAuthenticatedUserId(session);

      final result = await session.db.unsafeQuery(
        '''
      SELECT 
        u.name,
        u.email,
        u.phone,
        u.profile_picture_url,
        p.blood_group,
        p.date_of_birth,
        p.gender
      FROM users u
      LEFT JOIN patient_profiles p
        ON p.user_id = u.user_id
      WHERE u.user_id = @userId
        AND u.role IN ('STUDENT','TEACHER','STAFF','OUTSIDE')
      ''',
        parameters: QueryParameters.named({'userId': resolvedUserId}),
      );

      if (result.isEmpty) return null;

      final row = result.first.toColumnMap();

      return PatientProfile(
        name: _safeString(row['name']),
        email: _safeString(row['email']),
        phone: _safeString(row['phone']),
        bloodGroup: row['blood_group']?.toString(),
        dateOfBirth: _safeDateTime(row['date_of_birth']),
        gender: row['gender']?.toString(),
        profilePictureUrl: row['profile_picture_url']?.toString(),
      );
    } catch (e, stack) {
      session.log(
        'Error getting patient profile: $e',
        level: LogLevel.error,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// List lab tests from the `tests` table. Returns a list of maps with keys:
  /// test_name, description, student_fee, teacher_fee, outside_fee, available
  Future<List<LabTests>> listTests(Session session) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
        SELECT test_name, description, student_fee, teacher_fee, outside_fee, available
        FROM lab_tests
        ORDER BY test_name
        ''',
      );

      session.log('listTests: DB returned ${result.length} rows',
          level: LogLevel.info);

      // Map each row to a simple Map<String, dynamic>

      return result.map((r) {
        final row = r.toColumnMap();
        return LabTests(
          id: null, // backend will replace this
          testName: _safeString(row['test_name']),
          description: _safeString(row['description']),
          studentFee: _toDouble(row['student_fee']),
          teacherFee: _toDouble(row['teacher_fee']),
          outsideFee: _toDouble(row['outside_fee']),
          available: _toBool(row['available']),
        );
      }).toList();
    } catch (e, stack) {
      session.log('Error listing tests: $e\n$stack', level: LogLevel.error);
      return [];
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    if (v is List<int>) return double.tryParse(String.fromCharCodes(v)) ?? 0.0;
    return 0.0;
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = _safeString(v).toLowerCase();
    return s == 't' || s == 'true' || s == '1';
  }

  /// Return the role of a user (stored as text in users.role) by email/userId.
  /// Returns uppercase role string or empty string if not found.
  Future<String> getUserRole(Session session) async {
    try {
      final resolvedUserId = requireAuthenticatedUserId(session);
      final result = await session.db.unsafeQuery(
        '''
        SELECT role::text as role FROM users WHERE user_id= @userId LIMIT 1
        ''',
        parameters: QueryParameters.named({'userId': resolvedUserId}),
      );

      if (result.isEmpty) return '';
      final row = result.first.toColumnMap();
      final roleVal = _safeString(row['role']).toUpperCase();
      return roleVal;
    } catch (e, stack) {
      session.log('Error fetching user role: $e\n$stack',
          level: LogLevel.error);
      return '';
    }
  }

// 2. Update Patient Profile
  Future<String> updatePatientProfile(
    Session session,
    String name,
    String phone,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
  ) async {
    try {
      final resolvedUserId = requireAuthenticatedUserId(session);

      return await session.db.transaction((transaction) async {
        await session.db.unsafeExecute(
          '''
        UPDATE users
        SET name = @name,
            phone = @phone,
            profile_picture_url = COALESCE(@url, profile_picture_url)
        WHERE user_id = @id
        ''',
          parameters: QueryParameters.named({
            'id': resolvedUserId,
            'name': name,
            'phone': phone,
            'url': profileImageUrl,
          }),
        );

        await session.db.unsafeExecute(
          '''
        INSERT INTO patient_profiles
          (user_id, blood_group, date_of_birth, gender)
        VALUES
          (@id, NULLIF(@bg, ''), @dob, @gender)
        ON CONFLICT (user_id)
        DO UPDATE SET
          blood_group = COALESCE(EXCLUDED.blood_group, patient_profiles.blood_group),
          date_of_birth = EXCLUDED.date_of_birth,
          gender = COALESCE(EXCLUDED.gender, patient_profiles.gender)
        ''',
          parameters: QueryParameters.named({
            'id': resolvedUserId,
            'bg': bloodGroup,
            'dob': dateOfBirth,
            'gender': gender,
          }),
        );

        return 'Profile updated successfully';
      });
    } catch (e, stack) {
      session.log(
        'Update profile failed: $e',
        level: LogLevel.error,
        stackTrace: stack,
      );
      return 'Failed to update profile';
    }
  }

  /// Fetch logged-in patient's lab reports using phone number
  Future<List<PatientReportDto>> getMyLabReports(
    Session session,
  ) async {
    try {
      final resolvedUserId = requireAuthenticatedUserId(session);
      final result = await session.db.unsafeQuery(
        '''
      SELECT 
        tr.result_id,
        lt.test_name,
        tr.created_at,
        tr.is_uploaded,
        tr.attachment_path
      FROM users u
      JOIN test_results tr 
        ON tr.mobile_number = u.phone
      JOIN lab_tests lt 
        ON lt.test_id = tr.test_id
      WHERE u.user_id = @userId
      ORDER BY tr.created_at DESC
      ''',
        parameters: QueryParameters.named({'userId': resolvedUserId}),
      );

      return result.map((r) {
        final row = r.toColumnMap();
        return PatientReportDto(
          id: row['result_id'] as int,
          testName: _safeString(row['test_name']),
          date: row['created_at'] as DateTime,
          isUploaded: _toBool(row['is_uploaded']),
          fileUrl: _safeString(row['attachment_path']),
        );
      }).toList();
    } catch (e, stack) {
      session.log(
        'Error fetching lab reports: $e',
        level: LogLevel.error,
        stackTrace: stack,
      );
      return [];
    }
  }

// ১. ড্রপডাউনে দেখানোর জন্য রোগীর আগের প্রেসক্রিপশন লিস্ট আনা
  Future<List<PrescriptionList>> getMyPrescriptionList(Session session) async {
    final resolvedUserId = requireAuthenticatedUserId(session);
    final query = '''
      SELECT
        p.prescription_id,
        p.prescription_date,
        u.name as doctor_name,
        p.revised_from_id AS revised_from_prescription_id,
        (
          SELECT r.report_id
          FROM UploadpatientR r
          WHERE r.patient_id = p.patient_id
            AND p.revised_from_id IS NOT NULL
            AND r.prescription_id = p.revised_from_id
          ORDER BY r.created_at DESC
          LIMIT 1
        ) AS source_report_id,
        (
          SELECT r.type
          FROM UploadpatientR r
          WHERE r.patient_id = p.patient_id
            AND p.revised_from_id IS NOT NULL
            AND r.prescription_id = p.revised_from_id
          ORDER BY r.created_at DESC
          LIMIT 1
        ) AS source_report_type,
        (
          SELECT r.created_at
          FROM UploadpatientR r
          WHERE r.patient_id = p.patient_id
            AND p.revised_from_id IS NOT NULL
            AND r.prescription_id = p.revised_from_id
          ORDER BY r.created_at DESC
          LIMIT 1
        ) AS source_report_created_at
      FROM prescriptions p
      JOIN users u ON p.doctor_id = u.user_id
      WHERE p.patient_id = @userId
      ORDER BY p.prescription_date DESC
      LIMIT 5;
    ''';

    final result = await session.db.unsafeQuery(
      query,
      parameters: QueryParameters.named({'userId': resolvedUserId}),
    );

    return result.map((r) {
      final map = r.toColumnMap();
      return PrescriptionList(
        prescriptionId: map['prescription_id'],
        date: map['prescription_date'] as DateTime,
        doctorName: _safeString(map['doctor_name']),
        revisedFromPrescriptionId: map['revised_from_prescription_id'] as int?,
        sourceReportId: map['source_report_id'] as int?,
        sourceReportType: map['source_report_type'] as String?,
        sourceReportCreatedAt: map['source_report_created_at'] as DateTime?,
      );
    }).toList();
  }

  // ২. ক্লাউডিনারি আপলোডসহ রিপোর্ট ডাটা সেভ এবং নোটিফিকেশন পাঠানো
  Future<bool> finalizeReportUpload(
    Session session, {
    required int prescriptionId,
    required String reportType,
    required String fileUrl,
  }) async {
    try {
      final int resolvedPatientId = requireAuthenticatedUserId(session);

      final secureUrl = fileUrl.trim();
      if (!(secureUrl.startsWith('http://') ||
          secureUrl.startsWith('https://'))) {
        return false;
      }

      // ১২ ঘণ্টা রিপ্লেস লজিক: চেক করুন এই প্রেসক্রিপশনের জন্য কোনো রিপোর্ট অলরেডি আছে কি না
      final existing = await session.db.unsafeQuery(
        '''SELECT report_id, created_at FROM UploadpatientR
           WHERE patient_id = @pId AND prescription_id = @refId 
           ORDER BY created_at DESC LIMIT 1''',
        parameters: QueryParameters.named(
          {'pId': resolvedPatientId, 'refId': prescriptionId},
        ),
      );

      if (existing.isNotEmpty) {
        final row = existing.first.toColumnMap();
        final DateTime createdAt = row['created_at'];
        if (DateTime.now().difference(createdAt).inHours < 12) {
          // ১২ ঘণ্টার কম হলে আপডেট করুন
          await session.db.unsafeExecute(
            'UPDATE UploadpatientR SET file_path = @path, type = @type WHERE report_id = @report_id ',
            parameters: QueryParameters.named({
              'report_id': existing.first.toColumnMap()['report_id'],
              'path': secureUrl,
              'type': reportType,
            }),
          );
          return true;
        }
      }

      // প্রেসক্রিপশন থেকে ডাক্তার আইডি বের করা (নতুন আপলোডের জন্য)
      final docResult = await session.db.unsafeQuery(
        'SELECT doctor_id FROM prescriptions WHERE prescription_id = @pId',
        parameters: QueryParameters.named({'pId': prescriptionId}),
      );
      if (docResult.isEmpty) return false;
      int doctorId = docResult.first.toColumnMap()['doctor_id'];

      // ডাটাবেসে নতুন রিপোর্ট সেভ
      await session.db.unsafeExecute('''
        INSERT INTO UploadpatientR
        (patient_id, type, report_date, file_path, prescribed_doctor_id, prescription_id, uploaded_by, created_at)
        VALUES (@pId, @type, CURRENT_DATE, @path, @docId, @refId, @pId, NOW())
      ''',
          parameters: QueryParameters.named({
            'pId': resolvedPatientId,
            'type': reportType,
            'path': secureUrl,
            'docId': doctorId,
            'refId': prescriptionId,
          }));

      // ডাক্তারকে নোটিফিকেশন
      await session.db.unsafeExecute('''
        INSERT INTO notifications (user_id, title, message, is_read, created_at)
        VALUES (@docId, 'New Report', 'Patient uploaded a $reportType report.', false, NOW())
      ''', parameters: QueryParameters.named({'docId': doctorId}));

      return true;
    } catch (e, stackTrace) {
      session.log('Error: $e', level: LogLevel.error, stackTrace: stackTrace);
      return false;
    }
  }

  // আপনার আপলোড করা রিপোর্টগুলোর লিস্ট দেখার জন্য নতুন মেথড
  Future<List<PatientExternalReport>> getMyExternalReports(
      Session session) async {
    try {
      final resolvedUserId = requireAuthenticatedUserId(session);
      // এখানে আপনার টেবিলের নাম অনুযায়ী কুয়েরি হবে (ধরে নিচ্ছি 'upload_patient_reports')
      final result = await session.db.unsafeQuery(
        '''
        SELECT 
          report_id,
          patient_id, type, report_date, file_path, 
          prescribed_doctor_id, prescription_id, uploaded_by, reviewed, created_at
        FROM UploadpatientR
        WHERE patient_id = @userId
        ORDER BY created_at DESC
        ''',
        parameters: QueryParameters.named({'userId': resolvedUserId}),
      );

      return result.map((r) {
        final row = r.toColumnMap();
        return PatientExternalReport(
          reportId: row['report_id'] as int?,
          patientId: row['patient_id'],
          type: _safeString(row['type']),
          reportDate: row['report_date'] as DateTime,
          filePath: _safeString(row['file_path']),
          prescribedDoctorId: row['prescribed_doctor_id'],
          prescriptionId: row['prescription_id'],
          uploadedBy: row['uploaded_by'],
          reviewed: (row['reviewed'] as bool?) ?? false,
          createdAt: row['created_at'] as DateTime?,
        );
      }).toList();
    } catch (e, stack) {
      session.log('Error fetching external reports: $e',
          level: LogLevel.error, stackTrace: stack);
      return [];
    }
  }

  /// ১. রোগীর সব প্রেসক্রিপশনের লিস্ট আনা
  Future<List<PrescriptionList>> getPrescriptionList(
    Session session,
    int patientId,
  ) async {
    try {
      // এখানে 'prescription' টেবিল এবং 'users' টেবিল জয়েন করে ডাক্তারের নামসহ লিস্ট আনা হচ্ছে
      final rows = await session.db.unsafeQuery(
        '''
        SELECT
          p.prescription_id,
          p.prescription_date,
          u.name AS doctor_name,
          p.revised_from_id AS revised_from_prescription_id,
          (
            SELECT r.report_id
            FROM UploadpatientR r
            WHERE r.patient_id = p.patient_id
              AND p.revised_from_id IS NOT NULL
              AND r.prescription_id = p.revised_from_id
            ORDER BY r.created_at DESC
            LIMIT 1
          ) AS source_report_id,
          (
            SELECT r.type
            FROM UploadpatientR r
            WHERE r.patient_id = p.patient_id
              AND p.revised_from_id IS NOT NULL
              AND r.prescription_id = p.revised_from_id
            ORDER BY r.created_at DESC
            LIMIT 1
          ) AS source_report_type,
          (
            SELECT r.created_at
            FROM UploadpatientR r
            WHERE r.patient_id = p.patient_id
              AND p.revised_from_id IS NOT NULL
              AND r.prescription_id = p.revised_from_id
            ORDER BY r.created_at DESC
            LIMIT 1
          ) AS source_report_created_at
        FROM prescriptions p
        JOIN users u ON u.user_id = p.doctor_id
        WHERE p.patient_id = @pid
        ORDER BY p.prescription_date DESC
        ''',
        parameters: QueryParameters.named({'pid': patientId}),
      );

      return rows.map((r) {
        final map = r.toColumnMap();
        return PrescriptionList(
          prescriptionId: map['prescription_id'] as int,
          date: map['prescription_date'] as DateTime,
          doctorName: _safeString(map['doctor_name']),
          revisedFromPrescriptionId:
              map['revised_from_prescription_id'] as int?,
          sourceReportId: map['source_report_id'] as int?,
          sourceReportType: map['source_report_type'] as String?,
          sourceReportCreatedAt: map['source_report_created_at'] as DateTime?,
        );
      }).toList();
    } catch (e, stack) {
      session.log('Error fetching prescription list: $e',
          level: LogLevel.error, stackTrace: stack);
      return [];
    }
  }

  /// সরাসরি Patient ID (User ID) দিয়ে প্রেসক্রিপশন লিস্ট আনা
  Future<List<PrescriptionList>> getPrescriptionsByPatientId(
    Session session,
    int patientId,
  ) async {
    try {
      // db.sql onujayi table er nam 'prescriptions' (not 'prescription')
      // ebong kolyamer nam 'prescription_id'
      final rows = await session.db.unsafeQuery(
        '''
        SELECT 
          p.prescription_id, 
          p.prescription_date,
          u.name AS doctor_name,
          p.revised_from_id AS revised_from_prescription_id,
          (
            SELECT r.report_id
            FROM UploadpatientR r
            WHERE r.patient_id = p.patient_id
              AND p.revised_from_id IS NOT NULL
              AND r.prescription_id = p.revised_from_id
            ORDER BY r.created_at DESC
            LIMIT 1
          ) AS source_report_id,
          (
            SELECT r.type
            FROM UploadpatientR r
            WHERE r.patient_id = p.patient_id
              AND p.revised_from_id IS NOT NULL
              AND r.prescription_id = p.revised_from_id
            ORDER BY r.created_at DESC
            LIMIT 1
          ) AS source_report_type,
          (
            SELECT r.created_at
            FROM UploadpatientR r
            WHERE r.patient_id = p.patient_id
              AND p.revised_from_id IS NOT NULL
              AND r.prescription_id = p.revised_from_id
            ORDER BY r.created_at DESC
            LIMIT 1
          ) AS source_report_created_at
        FROM prescriptions p
        JOIN users u ON u.user_id = p.doctor_id
        WHERE p.patient_id = @pid
        ORDER BY p.prescription_date DESC
        ''',
        parameters: QueryParameters.named({'pid': patientId}),
      );

      return rows.map((r) {
        final map = r.toColumnMap();
        return PrescriptionList(
          prescriptionId: map['prescription_id'] as int,
          date: map['prescription_date'] as DateTime,
          doctorName: _safeString(map['doctor_name']),
          revisedFromPrescriptionId:
              map['revised_from_prescription_id'] as int?,
          sourceReportId: map['source_report_id'] as int?,
          sourceReportType: map['source_report_type'] as String?,
          sourceReportCreatedAt: map['source_report_created_at'] as DateTime?,
        );
      }).toList();
    } catch (e, stack) {
      session.log('Error: $e', level: LogLevel.error, stackTrace: stack);
      return [];
    }
  }
  // আপনার দেওয়া getPrescriptionDetail মেথডটি এর সাথেই থাকবে (PDF এর জন্য)

  /// ২. একটি নির্দিষ্ট প্রেসক্রিপশনের বিস্তারিত তথ্য (PDF এর জন্য)
  Future<PrescriptionDetail?> getPrescriptionDetail(
    Session session,
    int prescriptionId,
  ) async {
    try {
      // ---- 1. Fetch prescription and doctor info ----
      final presRows = await session.db.unsafeQuery(
        '''
      SELECT
        p.*,
        u.name AS doctor_name,
        s.signature_url
      FROM prescriptions p
      JOIN users u ON u.user_id = p.doctor_id
      LEFT JOIN staff_profiles s ON s.user_id = p.doctor_id
      WHERE p.prescription_id = @id
      ''',
        parameters: QueryParameters.named({'id': prescriptionId}),
      );

      if (presRows.isEmpty) return null;
      final p = presRows.first.toColumnMap();

      final prescription = Prescription(
        id: p['prescription_id'],
        patientId: p['patient_id'],
        doctorId: p['doctor_id'],
        name: _safeString(p['name']),
        age: p['age'],
        mobileNumber: _safeString(p['mobile_number']),
        gender: _safeString(p['gender']),
        prescriptionDate: p['prescription_date'],
        cc: _safeString(p['cc']),
        oe: _safeString(p['oe']),
        advice: _safeString(p['advice']),
        test: _safeString(p['test']),
        nextVisit: _safeString(p['next_visit']),
        isOutside: _toBool(p['is_outside']),
        createdAt: p['created_at'],
      );

      // ---- 2. Fetch prescribed items ----
      final itemRows = await session.db.unsafeQuery(
        '''
      SELECT *
      FROM prescribed_items
      WHERE prescription_id = @pid
      ORDER BY item_id
      ''',
        parameters: QueryParameters.named({'pid': prescriptionId}),
      );

      final items = itemRows.map((i) {
        final row = i.toColumnMap();
        return PrescribedItem(
          id: row['item_id'],
          prescriptionId: row['prescription_id'],
          medicineName: _safeString(row['medicine_name']),
          dosageTimes: _safeString(row['dosage_times']),
          mealTiming: _safeString(row['meal_timing']),
          duration: row['duration'],
        );
      }).toList();

      // ---- 3. Return complete PrescriptionDetail ----
      return PrescriptionDetail(
        prescription: prescription,
        items: items,
        doctorName: _safeString(p['doctor_name']),
        doctorSignatureUrl: _safeString(p['signature_url']),
      );
    } catch (e, stack) {
      session.log('Error fetching prescription detail: $e',
          level: LogLevel.error, stackTrace: stack);
      return null;
    }
  }

  /// Fetch all active medical staff (Admin, Doctor, Dispenser, Labstaff)
  /// Fetch all active medical staff (Admin, Doctor, Dispenser, Labstaff)
  Future<List<StaffInfo>> getMedicalStaff(Session session) async {
    try {
      final results = await session.db.unsafeQuery('''
      SELECT 
        u.name,
        u.phone,
        u.profile_picture_url,
        s.designation,
        s.qualification
      FROM users u
      LEFT JOIN staff_profiles s
        ON u.user_id = s.user_id
      WHERE u.role IN ('ADMIN', 'DOCTOR', 'DISPENSER', 'LABSTAFF')
        AND u.is_active = TRUE
      ORDER BY u.role, u.name;
      ''');

      return results.map((row) {
        final map = row.toColumnMap();

        return StaffInfo(
          name: map['name']?.toString() ?? '',
          phone: map['phone']?.toString() ?? '',
          designation: map['designation']?.toString(),
          profilePictureUrl: map['profile_picture_url']?.toString(),
          qualification: map['qualification']?.toString(),
        );
      }).toList();
    } catch (e, stack) {
      session.log(
        'Error fetching medical staff: $e',
        level: LogLevel.error,
        stackTrace: stack,
      );
      return [];
    }
  }

  Future<List<AmbulanceContact>> getAmbulanceContacts(Session session) async {
    try {
      final result = await session.db.unsafeQuery('''
      SELECT
        id,
        title,
        phone_bn || ' || ' || phone_en AS phone_combined,
        is_primary
      FROM ambulance_contact
      WHERE is_active = true
      ORDER BY is_primary DESC, id ASC
      ''');

      return result.map((row) {
        final map = row.toColumnMap();
        final phoneCombined = (map['phone_combined'] as String).split(' || ');
        final phoneBn = phoneCombined.isNotEmpty ? phoneCombined[0] : '';
        final phoneEn = phoneCombined.length > 1 ? phoneCombined[1] : '';

        return AmbulanceContact(
          contactId: map['id'] as int,
          contactTitle: map['title'] as String,
          phoneBn: phoneBn,
          phoneEn: phoneEn,
          isPrimary: map['is_primary'] as bool? ?? false,
        );
      }).toList();
    } catch (e, stack) {
      session.log('Error fetching ambulance contacts: $e',
          level: LogLevel.error, stackTrace: stack);
      return [];
    }
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List<int>) return String.fromCharCodes(value);
    return value.toString();
  }

  Future<List<OndutyStaff>> getOndutyStaff(
    Session session,
  ) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
      SELECT
        staff_id,
        staff_name,
        staff_role::text AS staff_role,
        shift_date,
        shift::text AS shift
      FROM staff_roster
      WHERE is_deleted = FALSE
      ORDER BY shift_date DESC, shift, staff_role, staff_name
      ''',
      );

      return result.map((r) {
        final row = r.toColumnMap();
        return OndutyStaff(
          staffId: row['staff_id'] as int,
          staffName: row['staff_name']?.toString() ?? '',
          staffRole: RosterUserRole.values.firstWhere(
            (e) =>
                e.name == (row['staff_role']?.toString().toUpperCase() ?? ''),
            orElse: () => RosterUserRole.STAFF,
          ),
          shiftDate: row['shift_date'] as DateTime,
          shift: ShiftType.values.firstWhere(
            (e) => e.name == (row['shift']?.toString().toUpperCase() ?? ''),
            orElse: () => ShiftType.MORNING,
          ),
        );
      }).toList();
    } catch (e, st) {
      session.log('getOndutyStaff failed: $e',
          level: LogLevel.error, stackTrace: st);
      return [];
    }
  }
}
