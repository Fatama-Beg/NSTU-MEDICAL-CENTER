import 'package:serverpod/serverpod.dart';
import '../../generated/protocol.dart';
import '../../auth/auth_user.dart';

class DoctorEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Doctor home dashboard data
// ----------------------------
  Future<DoctorHomeData> getDoctorHomeData(Session session) async {
    try {
      final resolvedDoctorId = requireAuthenticatedUserId(session);

      final doctorRow = await session.db.unsafeQuery(
        'SELECT name, role::text AS role, profile_picture_url FROM users WHERE user_id = @id LIMIT 1',
        parameters: QueryParameters.named({'id': resolvedDoctorId}),
      );

      String doctorName;
      String doctorProfilePictureUrl;
      String doctorRoleRaw;

      if (doctorRow.isNotEmpty) {
        doctorName = _decode(doctorRow.first.toColumnMap()['name']);
        doctorProfilePictureUrl =
            _decode(doctorRow.first.toColumnMap()['profile_picture_url']);
        doctorRoleRaw = _decode(doctorRow.first.toColumnMap()['role']);
      } else {
        doctorName = '';
        doctorProfilePictureUrl = '';
        doctorRoleRaw = '';
      }

      String friendlyRole(String raw) {
        final r = raw.trim().toUpperCase();
        switch (r) {
          case 'DOCTOR':
            return 'Doctor';
          case 'LABSTAFF':
            return 'Lab Technician';
          case 'DISPENSER':
            return 'Dispenser';
          case 'ADMIN':
            return 'Admin';
          case 'STAFF':
            return 'Staff';
          case 'TEACHER':
            return 'Teacher';
          case 'STUDENT':
            return 'Student';
          case 'OUTSIDE':
            return 'Outside';
          default:
            return raw.trim().isEmpty ? '' : raw.trim();
        }
      }

      // Last month (rolling 1 month)
      final lastMonthRows = await session.db.unsafeQuery(
        r'''
        SELECT COUNT(*)::int AS total
        FROM prescriptions
        WHERE doctor_id = @id
          AND prescription_date >= (CURRENT_DATE - INTERVAL '1 month')
        ''',
        parameters: QueryParameters.named({'id': resolvedDoctorId}),
      );

      final lastMonthPrescriptions = lastMonthRows.isNotEmpty
          ? (lastMonthRows.first.toColumnMap()['total'] as int? ?? 0)
          : 0;

      // Last 7 days inclusive => CURRENT_DATE - 6 days
      final lastWeekRows = await session.db.unsafeQuery(
        r'''
        SELECT COUNT(*)::int AS total
        FROM prescriptions
        WHERE doctor_id = @id
          AND prescription_date >= (CURRENT_DATE - INTERVAL '6 days')
        ''',
        parameters: QueryParameters.named({'id': resolvedDoctorId}),
      );

      final lastWeekPrescriptions = lastWeekRows.isNotEmpty
          ? (lastWeekRows.first.toColumnMap()['total'] as int? ?? 0)
          : 0;

      final now = DateTime.now();

      // Recent activity: last 24 hours (for dashboard)
      final recentRows = await session.db.unsafeQuery(
        r'''
        SELECT prescription_id, name, created_at
        FROM prescriptions
        WHERE doctor_id = @id
          AND created_at IS NOT NULL
          AND created_at >= (NOW() - INTERVAL '24 hours')
        ORDER BY created_at DESC NULLS LAST, prescription_id DESC
        LIMIT 300
        ''',
        parameters: QueryParameters.named({'id': resolvedDoctorId}),
      );

      final recent = <DoctorHomeRecentItem>[];
      for (final r in recentRows) {
        final m = r.toColumnMap();
        final createdAt = m['created_at'] as DateTime?;

        if (createdAt == null) continue;

        recent.add(
          DoctorHomeRecentItem(
            title: 'Prescription created',
            subtitle: _s(m['name']),
            timeAgo: _timeAgo(createdAt, now),
            type: 'prescription',
            prescriptionId: m['prescription_id'] as int?,
          ),
        );
      }

      // Reviewed reports: last 24 hours (for dashboard)
      final reportRows = await session.db.unsafeQuery(
        r'''
        SELECT
          r.report_id,
          r.type,
          r.report_date,
          r.created_at,
          r.prescription_id,
          COALESCE(u.name, '') AS uploaded_by_name
        FROM UploadpatientR r
        LEFT JOIN users u ON u.user_id = r.uploaded_by
        WHERE r.prescribed_doctor_id = @id
          AND (
            (r.created_at IS NOT NULL AND r.created_at >= (NOW() - INTERVAL '24 hours'))
            OR (r.report_date IS NOT NULL AND r.report_date >= (CURRENT_DATE - INTERVAL '1 day'))
          )
        ORDER BY r.created_at DESC NULLS LAST, r.report_id DESC
        LIMIT 300
        ''',
        parameters: QueryParameters.named({'id': resolvedDoctorId}),
      );

      final reviewedReports = <DoctorHomeReviewedReport>[];
      for (final r in reportRows) {
        final m = r.toColumnMap();
        final createdAt =
            (m['created_at'] as DateTime?) ?? (m['report_date'] as DateTime?);

        if (createdAt == null) continue;

        reviewedReports.add(
          DoctorHomeReviewedReport(
            reportId: m['report_id'] as int?,
            type: _s(m['type']),
            uploadedByName: _s(m['uploaded_by_name']),
            prescriptionId: m['prescription_id'] as int?,
            timeAgo: _timeAgo(createdAt, now),
          ),
        );
      }

      return DoctorHomeData(
        doctorName: doctorName,
        doctorDesignation: friendlyRole(doctorRoleRaw),
        doctorProfilePictureUrl:
            doctorProfilePictureUrl.isEmpty ? null : doctorProfilePictureUrl,
        today: DateTime.now().toUtc(),
        lastMonthPrescriptions: lastMonthPrescriptions,
        lastWeekPrescriptions: lastWeekPrescriptions,
        recent: recent,
        reviewedReports: reviewedReports,
      );
    } catch (e, st) {
      session.log(
        'getDoctorHomeData failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );

      return DoctorHomeData(
        doctorName: '',
        doctorDesignation: '',
        doctorProfilePictureUrl: null,
        today: DateTime.now().toUtc(),
        lastMonthPrescriptions: 0,
        lastWeekPrescriptions: 0,
        recent: const [],
        reviewedReports: const [],
      );
    }
  }

  // Doctor info (name + signature)
  // ----------------------------
  Future<Map<String, String?>> getDoctorInfo(Session session) async {
    try {
      final resolvedDoctorId = requireAuthenticatedUserId(session);

      final res = await session.db.unsafeQuery(
        r'''
        SELECT u.name, s.signature_url
        FROM users u
        JOIN staff_profiles s ON u.user_id = s.user_id
        WHERE u.user_id = @id
        ''',
        parameters: QueryParameters.named({'id': resolvedDoctorId}),
      );

      if (res.isEmpty) return {'name': '', 'signature': ''};

      final row = res.first.toColumnMap();
      return {
        'name': _decode(row['name']),
        'signature': _decode(row['signature_url']),
      };
    } catch (_) {
      return {'name': '', 'signature': ''};
    }
  }

  /// ডাক্তারের আইডি দিয়ে তার সই এবং নাম খুঁজে বের করা
  Future<DoctorProfile?> getDoctorProfile(Session session, int doctorId) async {
    try {
      final resolvedDoctorId = requireAuthenticatedUserId(session);
      final res = await session.db.unsafeQuery('''
      SELECT u.user_id, u.name, u.email, u.phone, u.profile_picture_url,
             s.designation, s.qualification, s.signature_url
      FROM users u
      LEFT JOIN staff_profiles s ON u.user_id = s.user_id
      WHERE u.user_id = @id
      LIMIT 1
    ''', parameters: QueryParameters.named({'id': resolvedDoctorId}));

      if (res.isEmpty) return null;

      final row = res.first.toColumnMap();

      return DoctorProfile(
        userId: row['user_id'] as int?,
        name: _decode(row['name']),
        email: _decode(row['email']),
        phone: _decode(row['phone']),
        profilePictureUrl: _decode(row['profile_picture_url']),
        designation: _decode(row['designation']),
        qualification: _decode(row['qualification']),
        signatureUrl: _decode(row['signature_url']),
      );
    } catch (e, st) {
      session.log(
        'getDoctorProfile failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Update doctor's user and staff profile. If staff_profiles row doesn't exist, insert it.
  /// Expects profilePictureUrl and signatureUrl to be remote URLs (uploads happen on frontend).
  Future<bool> updateDoctorProfile(
    Session session,
    int doctorId,
    String name,
    String email,
    String phone,
    String? profilePictureUrl,
    String? designation,
    String? qualification,
    String? signatureUrl,
  ) async {
    try {
      final resolvedDoctorId = requireAuthenticatedUserId(session);
      // Pre-check for duplicate phone (different user)
      final dup = await session.db.unsafeQuery(
        'SELECT 1 FROM users WHERE phone = @ph AND user_id <> @id LIMIT 1',
        parameters:
            QueryParameters.named({'ph': phone, 'id': resolvedDoctorId}),
      );

      if (dup.isNotEmpty) {
        // Return a clear error to client by throwing - client will receive the message
        throw Exception('Phone number already registered');
      }

      String? normalizeUrl(String? value) {
        if (value == null) return null;
        final s = value.trim();
        if (s.isEmpty) return null;
        if (s.startsWith('http://') || s.startsWith('https://')) return s;
        return null;
      }

      final String? finalProfileUrl = normalizeUrl(profilePictureUrl);
      final String? finalSignatureUrl = normalizeUrl(signatureUrl);

      await session.db.unsafeExecute('BEGIN');

      // Update users table (name, phone, profile picture)
      await session.db.unsafeExecute('''
        UPDATE users
        SET name = @name,email = @email, phone = @phone, profile_picture_url = COALESCE(@pp, profile_picture_url)
        WHERE user_id = @id
      ''',
          parameters: QueryParameters.named({
            'name': name,
            'email': email.trim(),
            'phone': phone,
            'pp': finalProfileUrl,
            'id': resolvedDoctorId
          }));

      // Check if staff_profiles exists
      final exists = await session.db.unsafeQuery(
          'SELECT 1 FROM staff_profiles WHERE user_id = @id',
          parameters: QueryParameters.named({'id': resolvedDoctorId}));

      if (exists.isEmpty) {
        // insert
        await session.db.unsafeExecute('''
          INSERT INTO staff_profiles (user_id, designation, qualification, signature_url)
          VALUES (@id, @spec, @qual, @sig)
        ''',
            parameters: QueryParameters.named({
              'id': resolvedDoctorId,
              'spec': designation,
              'qual': qualification,
              'sig': finalSignatureUrl
            }));
      } else {
        await session.db.unsafeExecute('''
          UPDATE staff_profiles
          SET designation = @spec, qualification = @qual, signature_url = COALESCE(@sig, signature_url)
          WHERE user_id = @id
        ''',
            parameters: QueryParameters.named({
              'spec': designation,
              'qual': qualification,
              'sig': finalSignatureUrl,
              'id': resolvedDoctorId
            }));
      }

      await session.db.unsafeExecute('COMMIT');
      return true;
    } catch (e, st) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('updateDoctorProfile failed: $e',
          level: LogLevel.error, stackTrace: st);
      return false;
    }
  }

  Future<Map<String, String?>> getPatientByPhone(
      Session session, String phone) async {
    try {
      // Extract last 11 digits only
      final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final last11 = cleaned.length >= 11
          ? cleaned.substring(cleaned.length - 11)
          : cleaned;

      session.log('Searching for patient with last 11 digits: $last11',
          level: LogLevel.info);

      // Search: phone ends with last 11 digits
      final res = await session.db.unsafeQuery(
        '''
        SELECT
          u.user_id,
          u.name,
          p.gender,
          p.date_of_birth,
          EXTRACT(YEAR FROM age(CURRENT_DATE, p.date_of_birth))::int AS age
        FROM users u
        LEFT JOIN patient_profiles p ON p.user_id = u.user_id
        WHERE u.phone IS NOT NULL
          AND (
            REPLACE(REPLACE(u.phone, ' ', ''), '-', '') LIKE @pattern
            OR RIGHT(REPLACE(REPLACE(u.phone, ' ', ''), '-', ''), 11) = @num
          )
        LIMIT 1
        ''',
        parameters: QueryParameters.named({
          'pattern': '%$last11', // Ends with last11
          'num': last11, // Exact last 11
        }),
      );

      if (res.isEmpty) {
        session.log(
          'Patient not found with phone: $phone (last11: $last11)',
          level: LogLevel.warning,
        );
        return {'id': null, 'name': null};
      }

      final row = res.first.toColumnMap();
      final userId = row['user_id']?.toString();
      final name = _decode(row['name']);

      final dob = row['date_of_birth'];
      final dobStr = dob?.toString();

      final genderStr = row['gender']?.toString();

      final ageVal = row['age'];
      final ageStr = ageVal?.toString();

      session.log('Patient found: ID=$userId, Name=$name',
          level: LogLevel.info);

      return {
        'id': userId,
        'name': name,
        'gender': genderStr,
        'dateOfBirth': dobStr,
        'age': ageStr,
      };
    } catch (e) {
      session.log('Error in getPatientByPhone: $e', level: LogLevel.error);
      return {'id': null, 'name': null};
    }
  }

  /// নতুন প্রেসক্রিপশন সেভ করা
  Future<int> createPrescription(
    Session session,
    Prescription prescription,
    List<PrescribedItem> items,
    String patientPhone,
  ) async {
    try {
      final resolvedDoctorId = requireAuthenticatedUserId(session);
      // FIXED QUERY: Joining with 'users' because 'phone' isn't in 'patient_profiles'
      // createPrescription মেথডের ভেতরে এই অংশটুকু পরিবর্তন করতে পারেন:
      final patientData = await getPatientByPhone(session, patientPhone);

      int? foundPatientId;
      if (patientData['id'] != null) {
        foundPatientId = int.tryParse(patientData['id']!);
      }

      await session.db.unsafeExecute('BEGIN');

      // Insert prescription - Matches your SQL Table
      final res = await session.db.unsafeQuery('''
    INSERT INTO prescriptions (
      patient_id, doctor_id, name, age, mobile_number, gender,
      prescription_date, cc, oe, advice, test, next_visit, is_outside
    ) VALUES (
      @pid, @did, @name, @age, @mobile, @gender,
      @pdate, @cc, @oe, @advice, @test, @nextVisit, @iso
    ) RETURNING prescription_id
    ''',
          parameters: QueryParameters.named({
            'pid': foundPatientId,
            'did': resolvedDoctorId,
            'name': prescription.name,
            'age': prescription.age,
            'mobile': prescription.mobileNumber,
            'gender': prescription.gender,
            'pdate': prescription.prescriptionDate ?? DateTime.now(),
            'cc': prescription.cc,
            'oe': prescription.oe,
            'advice': prescription.advice,
            'test': prescription.test,
            'nextVisit': prescription.nextVisit,
            'iso': prescription.isOutside ?? false,
          }));

      if (res.isEmpty) {
        await session.db.unsafeExecute('ROLLBACK');
        return -1;
      }

      final prescriptionId = res.first.toColumnMap()['prescription_id'] as int;

      // Insert prescribed items
      for (var item in items) {
        await session.db.unsafeExecute('''
      INSERT INTO prescribed_items (
        prescription_id, medicine_name, dosage_times, meal_timing, duration
      ) VALUES (@preId, @mname, @dtimes, @mtiming, @dur)
      ''',
            parameters: QueryParameters.named({
              'preId': prescriptionId,
              'mname': item.medicineName,
              'dtimes': item.dosageTimes,
              'mtiming': item.mealTiming,
              'dur': item.duration, // Ensure this is passed as an int
            }));
      }

      await session.db.unsafeExecute('COMMIT');
      return prescriptionId;
    } catch (e, st) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('createPrescription failed: $e',
          level: LogLevel.error, stackTrace: st);
      return -1;
    }
  }

  // ডাক্তারের কাছে আসা রিপোর্টগুলো দেখার জন্য
  Future<List<PatientExternalReport>> getReportsForDoctor(
      Session session, int doctorId) async {
    try {
      final resolvedDoctorId = requireAuthenticatedUserId(session);
      final res = await session.db.unsafeQuery('''
      SELECT * FROM UploadpatientR 
      WHERE prescribed_doctor_id = @id 
      ORDER BY created_at DESC
    ''', parameters: QueryParameters.named({'id': resolvedDoctorId}));

      return res.map((row) {
        final map = row.toColumnMap();
        return PatientExternalReport(
          reportId: map['report_id'] as int?,
          patientId: map['patient_id'] as int,
          type: map['type'] as String,
          reportDate: map['report_date'] as DateTime,
          filePath: map['file_path'] as String,
          prescribedDoctorId: map['prescribed_doctor_id'] as int,
          prescriptionId: map['prescription_id'] as int?,
          uploadedBy: map['uploaded_by'] as int,
          reviewed: (map['reviewed'] as bool?) ?? false,
          createdAt: map['created_at'] as DateTime?,
        );
      }).toList();
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  /// Track if a test report was reviewed by the assigned doctor.
  Future<bool> markReportReviewed(Session session, int reportId) async {
    try {
      final resolvedDoctorId = requireAuthenticatedUserId(session);

      final updated = await session.db.unsafeExecute(
        '''
        UPDATE UploadpatientR
        SET reviewed = TRUE
        WHERE report_id = @rid AND prescribed_doctor_id = @did
        ''',
        parameters:
            QueryParameters.named({'rid': reportId, 'did': resolvedDoctorId}),
      );

      return updated > 0;
    } catch (e, st) {
      session.log(
        'markReportReviewed failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return false;
    }
  }

//update Prescription
  Future<int> revisePrescription(
    Session session, {
    required int originalPrescriptionId,
    required String newAdvice,
    required List<PrescribedItem> newItems,
  }) async {
    try {
      final resolvedDoctorId = requireAuthenticatedUserId(session);
      await session.db.unsafeExecute('BEGIN');

      // ১. পুরনো প্রেসক্রিপশনের তথ্য কপি করা
      final oldPres = await session.db.unsafeQuery(
          'SELECT * FROM prescriptions WHERE prescription_id = @id',
          parameters: QueryParameters.named({'id': originalPrescriptionId}));
      if (oldPres.isEmpty) return -1;
      final pData = oldPres.first.toColumnMap();

      // Only allow revising prescriptions created by this doctor
      if (pData['doctor_id'] != resolvedDoctorId) {
        await session.db.unsafeExecute('ROLLBACK');
        return -1;
      }

      // ২. নতুন (Revised) প্রেসক্রিপশন তৈরি
      final res = await session.db.unsafeQuery('''
      INSERT INTO prescriptions (
        patient_id, doctor_id, name, age, mobile_number, gender,
        cc, oe, advice, test, revised_from_id
      ) VALUES (
        @pid, @did, @name, @age, @mobile, @gender,
        @cc, @oe, @advice, @test, @revisedId
      ) RETURNING prescription_id
    ''',
          parameters: QueryParameters.named({
            'pid': pData['patient_id'],
            'did': resolvedDoctorId,
            'name': pData['name'],
            'age': pData['age'],
            'mobile': pData['mobile_number'],
            'gender': pData['gender'],
            'cc': pData['cc'],
            'oe': pData['oe'],
            'advice': newAdvice,
            'test': pData['test'],
            'revisedId': originalPrescriptionId,
          }));

      final newId = res.first.toColumnMap()['prescription_id'] as int;

      // ৩. নতুন ওষুধগুলো যোগ করা
      for (var item in newItems) {
        await session.db.unsafeExecute('''
        INSERT INTO prescribed_items (prescription_id, medicine_name, dosage_times, meal_timing, duration)
        VALUES (@preId, @mname, @dtimes, @mtiming, @dur)
      ''',
            parameters: QueryParameters.named({
              'preId': newId,
              'mname': item.medicineName,
              'dtimes': item.dosageTimes,
              'mtiming': item.mealTiming,
              'dur': item.duration,
            }));
      }

      // ৪. পেশেন্টকে নোটিফিকেশন পাঠানো
      await session.db.unsafeExecute('''
      INSERT INTO notifications (user_id, title, message, is_read)
      VALUES (@pId, 'Prescription Updated', 'Your doctor has updated your prescription after reviewing your report.', false)
    ''', parameters: QueryParameters.named({'pId': pData['patient_id']}));

      await session.db.unsafeExecute('COMMIT');
      return newId;
    } catch (e) {
      await session.db.unsafeExecute('ROLLBACK');
      return -1;
    }
  }

  /// List page: all prescriptions (latest first) + optional search by name/phone
  Future<List<PatientPrescriptionListItem>> getPatientPrescriptionList(
    Session session, {
    String? query,
    int limit = 100,
    int offset = 0,
  }) async {
    final resolvedDoctorId = requireAuthenticatedUserId(session);
    final q = (query ?? '').trim();

    final rows = await session.db.unsafeQuery(r'''
      SELECT
        prescription_id,
        name,
        mobile_number,
        gender,
        age,
        prescription_date
      FROM prescriptions
      WHERE
        doctor_id = @did AND
        (@q = '' OR
         LOWER(name) LIKE LOWER(@likeQ) OR
         REPLACE(REPLACE(mobile_number, ' ', ''), '-', '') LIKE @phoneLike)
      ORDER BY prescription_id DESC
      LIMIT @limit OFFSET @offset
    ''',
        parameters: QueryParameters.named({
          'did': resolvedDoctorId,
          'q': q,
          'likeQ': '%$q%',
          'phoneLike': '%${q.replaceAll(RegExp(r'[^0-9]'), '')}%',
          'limit': limit,
          'offset': offset,
        }));

    return rows.map((r) {
      final m = r.toColumnMap();
      return PatientPrescriptionListItem(
        prescriptionId: m['prescription_id'] as int,
        name: _s(m['name']),
        mobileNumber: m['mobile_number']?.toString(),
        gender: m['gender']?.toString(),
        age: m['age'] as int?,
        prescriptionDate: m['prescription_date'] as DateTime?,
      );
    }).toList();
  }

  /// Bottom sheet: single prescription full details + medicines
  Future<PatientPrescriptionDetails?> getPrescriptionDetails(
    Session session, {
    required int prescriptionId,
  }) async {
    final resolvedDoctorId = requireAuthenticatedUserId(session);
    final presRows = await session.db.unsafeQuery(r'''
      SELECT
        prescription_id,
        name,
        mobile_number,
        gender,
        age,
        cc,
        oe,
        advice,
        test
      FROM prescriptions
      WHERE prescription_id = @id AND doctor_id = @did
      LIMIT 1
    ''',
        parameters: QueryParameters.named({
          'id': prescriptionId,
          'did': resolvedDoctorId,
        }));

    if (presRows.isEmpty) return null;

    final p = presRows.first.toColumnMap();

    final itemRows = await session.db.unsafeQuery(r'''
      SELECT medicine_name, dosage_times, meal_timing, duration
      FROM prescribed_items
      WHERE prescription_id = @id
      ORDER BY item_id ASC
    ''', parameters: QueryParameters.named({'id': prescriptionId}));

    final items = itemRows.map((r) {
      final m = r.toColumnMap();
      return PatientPrescribedItem(
        medicineName: _s(m['medicine_name']),
        dosageTimes: _s(m['dosage_times']),
        mealTiming: _s(m['meal_timing']),
        duration: m['duration'] as int?,
      );
    }).toList();

    return PatientPrescriptionDetails(
      prescriptionId: p['prescription_id'] as int,
      name: _s(p['name']),
      mobileNumber: p['mobile_number']?.toString(),
      gender: p['gender']?.toString(),
      age: p['age'] as int?,
      cc: p['cc']?.toString(),
      oe: p['oe']?.toString(),
      advice: p['advice']?.toString(),
      test: p['test']?.toString(),
      items: items,
    );
  }

  String _decode(dynamic v) {
    if (v == null) return '';
    if (v is List<int>) return String.fromCharCodes(v);
    return v.toString();
  }

  String _s(dynamic v) {
    if (v == null) return '';
    if (v is List<int>) return String.fromCharCodes(v);
    return v.toString();
  }

  String _timeAgo(DateTime? createdAtUtc, DateTime nowUtc) {
    if (createdAtUtc == null) return '';
    final diff = nowUtc.difference(createdAtUtc);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
