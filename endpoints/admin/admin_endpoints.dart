import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'dart:async'; // added for fire-and-forget scheduling
import '../../mail/mail_service.dart' as mail;
import '../../generated/protocol.dart';

/// AdminEndpoints: server-side methods used by the admin UI to manage users,
/// inventory, rosters, audit logs and notifications.
class AdminEndpoints extends Endpoint {
  /// Helper: map a DB row to a serializable map for the client.
  Map<String, dynamic> _rowToUserMap(Map<String, dynamic> row) {
    String decode(dynamic v) {
      if (v == null) return '';
      if (v is List<int>) return String.fromCharCodes(v);
      return v.toString();
    }

    return {
      'userId': decode(row['user_id']),
      'name': decode(row['name']),
      'email': decode(row['email']),
      'role': decode(row['role']).toUpperCase(),
      'phone': decode(row['phone']),
      // Normalize profile picture column (nullable)
      'profilePictureUrl': decode(row['profile_picture_url']),
      'active': row['is_active'] == true,
    };
  }

  /// List users filtered by role. Use role = 'ALL' to fetch all users.
  Future<List<UserListItem>> listUsersByRole(
      Session session, String role, int limit) async {
    try {
      final isAll = role.trim().toUpperCase() == 'ALL' || role.trim().isEmpty;
      final sql = isAll
          ? '''SELECT user_id, name, email, role::text, phone, profile_picture_url, is_active FROM users ORDER BY name LIMIT @lim'''
          : '''SELECT user_id, name, email, role::text, phone, profile_picture_url, is_active FROM users WHERE (lower(role::text) LIKE @role || '%' OR @role LIKE lower(role::text) || '%') ORDER BY name LIMIT @lim''';

      final params = isAll
          ? QueryParameters.named({'lim': limit})
          : QueryParameters.named({'role': role.toLowerCase(), 'lim': limit});

      final result = await session.db.unsafeQuery(sql, parameters: params);
      final list = <UserListItem>[];
      for (final r in result) {
        final row = r.toColumnMap();
        final decoded = _rowToUserMap(row);
        list.add(UserListItem(
          userId: decoded['userId'] ?? '',
          name: decoded['name'] ?? '',
          email: decoded['email'] ?? '',
          role: decoded['role'] ?? '',
          phone: decoded['phone'] ?? '',
          profilePictureUrl: decoded['profilePictureUrl'] ?? '',
          active: decoded['active'] == true,
        ));
      }
      return list;
    } catch (e, st) {
      session.log('listUsersByRole failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  /// Toggle user's active flag. Returns true on success.
  Future<bool> toggleUserActive(Session session, String userId) async {
    try {
      await session.db.unsafeExecute(
        'UPDATE users SET is_active = NOT is_active WHERE user_id = @uid',
        parameters: QueryParameters.named({'uid': userId}),
      );
      return true;
    } catch (e, st) {
      session.log('UserActive failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  /// Normalize and validate a phone number. Accepts various input forms and
  /// returns normalized form like '+88XXXXXXXXXXX' where X... is 11 digits.
  /// Returns null if invalid.

  /// Create a new user record. Expects passwordHash to already be hashed by the caller.
  Future<String> createUser(Session session, String name, String email,
      String passwordHash, String role, String? phone) async {
    final existing = await session.db.unsafeQuery(
      'SELECT email, phone FROM users WHERE email = @e OR phone = @ph LIMIT 1',
      parameters: QueryParameters.named({'e': email, 'ph': phone}),
    );

    if (existing.isNotEmpty) {
      final row = existing.first.toColumnMap();
      if (row['email']?.toString().toLowerCase() == email.toLowerCase()) {
        return 'Email already registered';
      }
      if (row['phone']?.toString() == phone) {
        return 'Phone number already registered';
      }
      return 'User already exists';
    }

    try {
      await session.db.unsafeExecute('BEGIN');
      final insertResult = await session.db.unsafeQuery(
        '''
      INSERT INTO users (name, email, password_hash, phone, role, is_active)
      VALUES (@name, @email, @pass, @phone, @role::user_role, TRUE)
      RETURNING user_id
      ''',
        parameters: QueryParameters.named({
          'name': name,
          'email': email,
          'pass': passwordHash,
          'phone': phone,
          'role': role.toUpperCase(),
        }),
      );

      if (insertResult.isEmpty) throw Exception('Insert failed');

      final newUserId = insertResult.first.toColumnMap()['user_id'];
      if (newUserId == null) throw Exception('Insert returned null');

      await session.db.unsafeExecute('COMMIT');
      return newUserId.toString();
    } catch (e) {
      try {
        await session.db.unsafeExecute('ROLLBACK');
      } catch (_) {}
      return 'Database error: $e';
    }
  }

  /// Create user by hashing the provided raw password server-side.
  Future<String> createUserWithPassword(Session session, String name,
      String email, String password, String role, String? phone) async {
    try {
      final hashed = sha256.convert(utf8.encode(password)).toString();
      final res = await createUser(session, name, email, hashed, role, phone);

      final newUserId = int.tryParse(res);
      if (newUserId != null) {
        // Send welcome email for these roles when created via admin UI.
        try {
          final allowed = <String>{'ADMIN', 'DOCTOR', 'DISPENSER', 'LABSTAFF'};
          final r = role.toUpperCase();
          if (allowed.contains(r)) {
            // Fire-and-forget so user creation is not blocked by email sending.
            await Future.microtask(() async {
              try {
                await mail.sendWelcomeEmail(session, email, name);
              } catch (e, st) {
                session.log('Failed to send welcome email (async): $e\n$st',
                    level: LogLevel.warning);
              }
            });
          }
        } catch (e) {
          session.log('Failed to schedule welcome email: $e',
              level: LogLevel.warning);
        }
      }
      return res;
    } catch (e, st) {
      session.log('createUserWithPassword failed: $e\n$st',
          level: LogLevel.error);
      return 'Internal error';
    }
  }

  // ------------------ Rosters ------------------
  Future<bool> _initRostersTable(Session session) async {
    try {
      await session.db.unsafeExecute(r'''
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'roster_user_role') THEN
          CREATE TYPE roster_user_role AS ENUM ('DOCTOR','NURSE','STAFF');
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shift_type') THEN
          CREATE TYPE shift_type AS ENUM ('MORNING','AFTERNOON','NIGHT');
        END IF;
      END
      $$;
    ''');

      await session.db.unsafeExecute(r'''
      CREATE TABLE IF NOT EXISTS staff_roster (
        roster_id BIGSERIAL PRIMARY KEY,
        staff_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
        staff_name VARCHAR(100) NOT NULL,
        staff_role roster_user_role NOT NULL,
        shift_date DATE NOT NULL,
        shift shift_type NOT NULL,
        is_deleted BOOLEAN DEFAULT FALSE, -- নতুন কলাম: ডাটা সংরক্ষণের জন্য
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (staff_id, shift_date, shift) 
      )
    ''');
      return true;
    } catch (e, st) {
      session.log('initRostersTable failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

// শুধুমাত্র active (is_deleted = false) রস্টারগুলো আনবে
  Future<List<Roster>> getRosters(
      Session session, String? staffId, DateTime? fromDate, DateTime? toDate,
      {bool includeDeleted = false}) async {
    try {
      await _initRostersTable(session);

      final buffer = StringBuffer(
          'SELECT roster_id, staff_id, staff_name, staff_role::text AS staff_role, '
          'shift::text AS shift, shift_date '
          'FROM staff_roster WHERE 1=1');

      final params = <String, dynamic>{};

      if (!includeDeleted) {
        buffer.write(' AND is_deleted = FALSE');
      }

      if (staffId != null && staffId.isNotEmpty) {
        buffer.write(' AND staff_id = @staff::bigint');
        params['staff'] = staffId;
      }

      if (fromDate != null) {
        buffer.write(' AND shift_date >= @fromd');
        params['fromd'] = DateTime(fromDate.year, fromDate.month, fromDate.day);
      }

      if (toDate != null) {
        buffer.write(' AND shift_date <= @tod');
        params['tod'] = toDate;
      }

      buffer.write(' ORDER BY shift_date');

      final result = await session.db.unsafeQuery(
        buffer.toString(),
        parameters: QueryParameters.named(params),
      );

      return result.map((r) {
        final row = r.toColumnMap();
        return Roster(
          rosterId: row['roster_id'] as int?,
          staffId: row['staff_id'] as int,
          staffName: row['staff_name'] as String,
          staffRole: row['staff_role'] as String,
          shift: row['shift'] as String,
          shiftDate: row['shift_date'] as DateTime,
        );
      }).toList();
    } catch (e, st) {
      session.log('getRosters failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

// সফট ডিলিট ফাংশন
  Future<bool> deleteRoster(Session session, int rosterId) async {
    try {
      // ডাটা ডিলিট না করে শুধুমাত্র ফ্ল্যাগ আপডেট করা হচ্ছে
      await session.db.unsafeExecute(
        'UPDATE staff_roster SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP WHERE roster_id = @rid',
        parameters: QueryParameters.named({'rid': rosterId}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveRoster(
      Session session,
      String rosterId,
      String staffId,
      String shiftType,
      DateTime shiftDate,
      String timeRange,
      String status,
      String? approvedBy) async {
    try {
      await _initRostersTable(session);

      // Validate staffId presence
      if (staffId.trim().isEmpty) {
        // Do not insert rows without a valid staff id
        session.log('saveRoster rejected: empty staffId', level: LogLevel.info);
        return false;
      }

      // Fetch user's name and role to populate staff_name and staff_role
      final ures = await session.db.unsafeQuery(
        'SELECT name, role::text AS role FROM users WHERE user_id = @uid::bigint LIMIT 1',
        parameters: QueryParameters.named({'uid': staffId}),
      );

      if (ures.isEmpty) {
        // No user found with provided id -> reject
        session.log('saveRoster rejected: user not found for staffId=$staffId',
            level: LogLevel.info);
        return false;
      }

      final userRow = ures.first.toColumnMap();
      final staffName = userRow['name']?.toString() ?? '';

      String staffRole() {
        final r = (userRow['role'] ?? '').toString().toLowerCase();
        if (r.contains('doctor')) return 'DOCTOR';
        if (r.contains('nurse')) return 'NURSE';
        if (r.contains('dispenser')) return 'NURSE';
        return 'STAFF';
      }

      final shift = shiftType.toUpperCase();
      final srole = staffRole();

      // If rosterId parseable -> UPDATE, else INSERT
      if (rosterId.isNotEmpty) {
        final parsed = int.tryParse(rosterId);
        if (parsed != null && parsed > 0) {
          await session.db.unsafeExecute('''
            UPDATE staff_roster SET
              staff_id = @sid::bigint,
              staff_name = @sname,
              staff_role = @srole::roster_user_role,
              shift = @shift::shift_type,
              shift_date = @sdate,
              updated_at = CURRENT_TIMESTAMP
            WHERE roster_id = @rid::bigint
          ''',
              parameters: QueryParameters.named({
                'sid': staffId,
                'sname': staffName,
                'srole': srole,
                'shift': shift,
                'sdate': shiftDate,
                'rid': rosterId,
              }));
          return true;
        }
      }

      // Insert new roster row. Unique constraint (staff_id, shift_date) will prevent duplicates.
      final insertRes = await session.db.unsafeQuery('''
        INSERT INTO staff_roster (staff_id, staff_name, staff_role, shift, shift_date)
        VALUES (@sid::bigint, @sname, @srole::roster_user_role, @shift::shift_type, @sdate)
        RETURNING roster_id
      ''',
          parameters: QueryParameters.named({
            'sid': staffId,
            'sname': staffName,
            'srole': srole,
            'shift': shift,
            'sdate': shiftDate,
          }));

      return insertRes.isNotEmpty;
    } on DatabaseQueryException catch (e) {
      // DB constraint failure (e.g., unique) -> return false
      session.log('saveRoster DB error: $e', level: LogLevel.error);
      return false;
    } catch (e, st) {
      session.log('saveRoster failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  // ------------------ Staff Profiles ------------------

  Future<List<Rosterlists>> listStaff(Session session, int limit) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
      SELECT u.user_id, u.name, u.role::text AS role
      FROM users u
      WHERE lower(u.role::text) IN ('doctor','dispenser','labstaff','staff')
      ORDER BY u.name
      LIMIT @lim
      ''',
        parameters: QueryParameters.named({'lim': limit}),
      );

      final list = <Rosterlists>[];

      for (final r in result) {
        final row = r.toColumnMap();

        list.add(
          Rosterlists(
            userId: row['user_id'].toString(),
            name: row['name'].toString(),
            role: row['role'].toString(),
          ),
        );
      }

      return list;
    } catch (e, st) {
      session.log('listStaff failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  // ------------------ Admin Profile / Password Management ------------------
  /// Get admin profile (name, email, phone, profilePictureUrl) by email (userId)
  Future<AdminProfileRespond?> getAdminProfile(
    Session session,
    String userId,
  ) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
  SELECT 
    u.name,
    u.email,
    u.phone,
    u.profile_picture_url,
    sp.designation,
    sp.qualification
  FROM users u
  LEFT JOIN staff_profiles sp ON sp.user_id = u.user_id
  WHERE u.email = @e
  ''',
        parameters: QueryParameters.named({'e': userId}),
      );

      if (result.isEmpty) return null;

      final row = result.first.toColumnMap();

      return AdminProfileRespond(
        name: row['name']?.toString() ?? '',
        email: row['email']?.toString() ?? '',
        phone: row['phone']?.toString() ?? '',
        profilePictureUrl: row['profile_picture_url']?.toString(),
        designation: row['designation']?.toString(),
        qualification: row['qualification']?.toString(),
      );
    } catch (e, st) {
      session.log('getAdminProfile failed: $e\n$st', level: LogLevel.error);
      return null;
    }
  }

  /// Update admin profile: name, phone, optional profilePictureData.
  /// Accepts:
  /// - null: no change to picture
  /// - an http(s) URL: stored as-is
  Future<String> updateAdminProfile(
      Session session,
      String userId,
      String name,
      String phone,
      String? profilePictureData,
      String? designation,
      String? qualification) async {
    try {
      await session.db.unsafeExecute('BEGIN');

      String? profilePictureUrl;

      if (profilePictureData != null && profilePictureData.isNotEmpty) {
        final data = profilePictureData.trim();

        if (data.startsWith('http://') || data.startsWith('https://')) {
          profilePictureUrl = data;
        } else {
          await session.db.unsafeExecute('ROLLBACK');
          return 'Invalid profile picture URL';
        }
      }

      await session.db.unsafeExecute(
        '''
        UPDATE users
        SET name = @name,
            phone = @phone,
            profile_picture_url = COALESCE(@ppurl, profile_picture_url)
        WHERE email = @e
        ''',
        parameters: QueryParameters.named({
          'e': userId,
          'name': name,
          'phone': phone,
          'ppurl': profilePictureUrl,
        }),
      );
      await session.db.unsafeExecute('''
            INSERT INTO staff_profiles (user_id, designation, qualification)
            VALUES ((SELECT user_id FROM users WHERE email = @e), @d, @q)
            ON CONFLICT (user_id)
            DO UPDATE SET
            designation = EXCLUDED.designation,
            qualification = EXCLUDED.qualification
            ''',
          parameters: QueryParameters.named({
            'e': userId,
            'd': designation,
            'q': qualification,
          }));

      await session.db.unsafeExecute('COMMIT');
      return 'OK';
    } catch (e, st) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('updateAdminProfile failed: $e\n$st', level: LogLevel.error);
      return 'Failed to update profile';
    }
  }

  /// Change password for given user (identified by email/userId). Verifies current password before updating.
  Future<String> changePassword(Session session, String userId,
      String currentPassword, String newPassword) async {
    try {
      final result = await session.db.unsafeQuery(
        '''SELECT password_hash FROM users WHERE email = @e''',
        parameters: QueryParameters.named({'e': userId}),
      );

      if (result.isEmpty) return 'User not found';

      final row = result.first.toColumnMap();
      String storedHash;
      final ph = row['password_hash'];
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
        'UPDATE users SET password_hash = @p WHERE email = @e',
        parameters: QueryParameters.named({'p': newHash, 'e': userId}),
      );

      return 'OK';
    } catch (e, st) {
      session.log('changePassword failed: $e\n$st', level: LogLevel.error);
      return 'Failed to change password';
    }
  }

  // জেনেরিক অডিট লগ ফাংশন
  Future<void> createAuditLog(
    Session session, {
    required int adminId, // বর্তমানে লগইন থাকা অ্যাডমিনের আইডি
    required String action, // কি কাজ করা হয়েছে (উদা: 'CREATE_USER')
    String? targetId, // কার ওপর কাজ করা হয়েছে (ঐ ইউজারের আইডি)
  }) async {
    try {
      await session.db.unsafeExecute(
        '''
        INSERT INTO audit_log (user_id, action, target_id)
        VALUES (@uid, @act, @tid)
        ''',
        parameters: QueryParameters.named({
          'uid': adminId,
          'act': action,
          'tid': targetId,
        }),
      );
    } catch (e, st) {
      session.log('Audit Log failed: $e',
          level: LogLevel.error, stackTrace: st);
    }
  }

  Future<List<AuditEntry>> getAuditLogs(Session session) async {
    try {
      final result = await session.db.unsafeQuery("""
      SELECT 
        al.audit_id, 
        al.action, 
        al.target_id, 
        al.created_at, 
        u1.name as admin_name,
        u2.name as target_name  -- যার ওপর অ্যাকশন নেওয়া হয়েছে তার নাম
      FROM audit_log al
      JOIN users u1 ON CAST(al.user_id AS bigint) = u1.user_id 
      LEFT JOIN users u2 ON (
        CASE WHEN al.target_id ~ '^[0-9]+\$' THEN al.target_id::bigint END
      ) = u2.user_id -- target_id numeric হলে নাম খোঁজা
      ORDER BY al.created_at DESC
      LIMIT 100
      """);

      return result.map((row) {
        final map = row.toColumnMap();
        return AuditEntry(
          auditId: map['audit_id'] as int,
          action: map['action'] as String,
          targetName:
              map['target_name']?.toString() ?? map['target_id']?.toString(),
          // নাম থাকলে নাম দেখাবে, না থাকলে আইডি
          createdAt: map['created_at'] as DateTime,
          adminName: map['admin_name']?.toString() ?? 'Unknown Admin',
        );
      }).toList();
    } catch (e, st) {
      session.log('getAuditLogs failed: $e',
          level: LogLevel.error, stackTrace: st);
      return [];
    }
  }

  /// Fetch recent audit logs within the last [hours] hours.
  /// Used by Admin Dashboard Recent Activity (last 24h).
  Future<List<AuditEntry>> getRecentAuditLogs(
    Session session,
    int hours,
    int limit,
  ) async {
    try {
      final safeHours = hours <= 0 ? 24 : hours.clamp(1, 168);
      final safeLimit = limit <= 0 ? 20 : limit.clamp(1, 200);

      final result = await session.db.unsafeQuery(
        """
      SELECT 
        al.audit_id, 
        al.action, 
        al.target_id, 
        al.created_at, 
        u1.name as admin_name,
        u2.name as target_name
      FROM audit_log al
      JOIN users u1 ON CAST(al.user_id AS bigint) = u1.user_id 
      LEFT JOIN users u2 ON (
        CASE WHEN al.target_id ~ '^[0-9]+\$' THEN al.target_id::bigint END
      ) = u2.user_id
      WHERE al.created_at >= NOW() - (@h * INTERVAL '1 hour')
      ORDER BY al.created_at DESC
      LIMIT @lim
      """,
        parameters: QueryParameters.named({'h': safeHours, 'lim': safeLimit}),
      );

      return result.map((row) {
        final map = row.toColumnMap();
        return AuditEntry(
          auditId: map['audit_id'] as int,
          action: map['action'] as String,
          targetName:
              map['target_name']?.toString() ?? map['target_id']?.toString(),
          createdAt: map['created_at'] as DateTime,
          adminName: map['admin_name']?.toString() ?? 'Unknown Admin',
        );
      }).toList();
    } catch (e, st) {
      session.log(
        'getRecentAuditLogs failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      return [];
    }
  }

  // Add new ambulance contact
  Future<bool> addAmbulanceContact(Session session, String title,
      String phoneBn, String phoneEn, bool isPrimary) async {
    try {
      await session.db.unsafeExecute(
        '''
      INSERT INTO ambulance_contact (title, phone_bn, phone_en, is_primary)
      VALUES (@title, @phoneBn, @phoneEn, @isPrimary)
      ''',
        parameters: QueryParameters.named({
          'title': title,
          'phoneBn': phoneBn,
          'phoneEn': phoneEn,
          'isPrimary': isPrimary,
        }),
      );
      return true;
    } catch (e, stack) {
      session.log(
        'Error adding ambulance contact: $e',
        level: LogLevel.error,
        stackTrace: stack,
      );
      return false;
    }
  }

// Update existing ambulance contact
  Future<bool> updateAmbulanceContact(Session session, int id, String title,
      String phoneBn, String phoneEn, bool isPrimary) async {
    try {
      await session.db.unsafeExecute(
        '''
      UPDATE ambulance_contact
      SET title = @title,
          phone_bn = @phoneBn,
          phone_en = @phoneEn,
          is_primary = @isPrimary,
          updated_at = NOW()
      WHERE id = @id
      ''',
        parameters: QueryParameters.named({
          'id': id,
          'title': title,
          'phoneBn': phoneBn,
          'phoneEn': phoneEn,
          'isPrimary': isPrimary,
        }),
      );
      return true;
    } catch (e, stack) {
      session.log(
        'Error updating ambulance contact: $e',
        level: LogLevel.error,
        stackTrace: stack,
      );
      return false;
    }
  }
}
