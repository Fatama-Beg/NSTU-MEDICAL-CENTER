import 'package:serverpod/serverpod.dart';
import 'package:backend_server/src/generated/protocol.dart';

import '../../auth/auth_user.dart';

class DispenserEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<DispenserProfileR?> getDispenserProfile(
    Session session,
  ) async {
    try {
      final resolvedUserId = requireAuthenticatedUserId(session);
      final result = await session.db.unsafeQuery(
        '''
        SELECT 
          u.name,
          u.email,
          u.phone,
          u.profile_picture_url,
          s.designation,
          s.qualification
        FROM users u
        LEFT JOIN staff_profiles s 
          ON s.user_id = u.user_id
        WHERE u.user_id = @userId
          AND u.role = 'DISPENSER'
        ''',
        parameters: QueryParameters.named({'userId': resolvedUserId}),
      );

      if (result.isEmpty) return null;

      final row = result.first.toColumnMap();

      return DispenserProfileR(
        name: _safeString(row['name']),
        email: _safeString(row['email']),
        phone: _safeString(row['phone']),
        qualification: _safeString(row['qualification']),
        designation: _safeString(row['designation']),
        profilePictureUrl: _safeString(row['profile_picture_url']),
      );
    } catch (e, stack) {
      session.log(
        'Error fetching dispenser profile: $e',
        level: LogLevel.error,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// 2️⃣ Update dispenser profile
  Future<String> updateDispenserProfile(
    Session session, {
    required String name,
    required String phone,
    required String qualification,
    required String designation,
    String? profilePictureUrl,
  }) async {
    try {
      final resolvedUserId = requireAuthenticatedUserId(session);
      final imageUrl = (profilePictureUrl != null &&
              (profilePictureUrl.startsWith('http://') ||
                  profilePictureUrl.startsWith('https://')))
          ? profilePictureUrl
          : null;

      return await session.db.transaction((transaction) async {
        await session.db.unsafeExecute(
          '''
        UPDATE users
        SET 
          name = @name,
          phone = @phone,
          profile_picture_url = COALESCE(@url, profile_picture_url)
        WHERE user_id = @id
          AND role = 'DISPENSER'
        ''',
          parameters: QueryParameters.named({
            'id': resolvedUserId,
            'name': name,
            'phone': phone,
            'url': imageUrl,
          }),
        );

        await session.db.unsafeExecute(
          '''
        INSERT INTO staff_profiles (user_id, qualification, designation)
        VALUES (@id, @qualification, @designation)
        ON CONFLICT (user_id)
        DO UPDATE SET qualification = EXCLUDED.qualification,
         designation = EXCLUDED.designation
        ''',
          parameters: QueryParameters.named({
            'id': resolvedUserId,
            'qualification': qualification,
            'designation': designation,
          }),
        );

        return 'Dispenser profile updated successfully';
      });
    } catch (e, stack) {
      session.log('Error updating dispenser profile: $e',
          level: LogLevel.error, stackTrace: stack);
      return 'Failed to update dispenser profile';
    }
  }

  /// Fetch only inventory items that the dispenser can restock
  Future<List<InventoryItemInfo>> listInventoryItems(Session session) async {
    try {
      final result = await session.db.unsafeQuery('''
      SELECT
        i.item_id,
        i.item_name,
        i.unit,
        i.minimum_stock,
        c.category_name,
        s.current_quantity
      FROM inventory_item i
      JOIN inventory_category c ON c.category_id = i.category_id
      JOIN inventory_stock s ON s.item_id = i.item_id
      WHERE i.can_restock_dispenser = TRUE
    ''');

      return result.map((row) {
        final map = row.toColumnMap();

        int toInt(dynamic v) {
          if (v == null) return 0;
          if (v is int) return v;
          if (v is num) return v.toInt();
          return int.tryParse(v.toString()) ?? 0;
        }

        return InventoryItemInfo(
          itemId: toInt(map['item_id']),
          itemName: map['item_name']?.toString() ?? '',
          unit: map['unit']?.toString() ?? '',
          minimumStock: toInt(map['minimum_stock']),
          categoryName: map['category_name']?.toString() ?? '',
          currentQuantity: toInt(map['current_quantity']),
          canRestockDispenser: true, // always true
        );
      }).toList();
    } catch (e, st) {
      session.log('dispenser.listInventoryItems failed: $e\n$st',
          level: LogLevel.error);
      return [];
    }
  }

  Future<bool> restockItem(
    Session session, {
    required int itemId,
    required int quantity,
  }) async {
    if (quantity <= 0) return false;

    try {
      final resolvedUserId = requireAuthenticatedUserId(session);
      // Start transaction
      await session.db.unsafeExecute('BEGIN');

      // 1️⃣ Lock current stock row
      final stockRes = await session.db.unsafeQuery(
        '''
      SELECT current_quantity
      FROM inventory_stock
      WHERE item_id = @id
      FOR UPDATE
      ''',
        parameters: QueryParameters.named({'id': itemId}),
      );

      if (stockRes.isEmpty) {
        await session.db.unsafeExecute('ROLLBACK');
        return false;
      }

      final oldQty = stockRes.first.toColumnMap()['current_quantity'] as int;
      final newQty = oldQty + quantity;

      // 2️⃣ Update stock
      await session.db.unsafeExecute(
        '''
      UPDATE inventory_stock
      SET current_quantity = @newQty,
          last_updated = CURRENT_TIMESTAMP
      WHERE item_id = @id
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'newQty': newQty,
        }),
      );

      // 3️⃣ Transaction log (IN)
      await session.db.unsafeExecute(
        '''
      INSERT INTO inventory_transaction
        (item_id, transaction_type, quantity, performed_by)
      VALUES
        (@id, 'IN', @qty, @uid)
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'qty': quantity,
          'uid': resolvedUserId,
        }),
      );

      // 4️⃣ Audit log
      await session.db.unsafeExecute(
        '''
      INSERT INTO inventory_audit_log
        (item_id, old_quantity, new_quantity, action, changed_by)
      VALUES
        (@id, @old, @new, 'ADD_STOCK', @uid)
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'old': oldQty,
          'new': newQty,
          'uid': resolvedUserId,
        }),
      );

      // 5️⃣ Commit transaction
      await session.db.unsafeExecute('COMMIT');
      return true;
    } catch (e, st) {
      // Rollback on error
      await session.db.unsafeExecute('ROLLBACK');
      session.log('restockItem failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  Future<List<InventoryAuditLog>> getDispenserHistory(
    Session session,
  ) async {
    try {
      final resolvedUserId = requireAuthenticatedUserId(session);
      final result = await session.db.unsafeQuery(
        '''
      SELECT
        a.audit_id,
        a.action,
        a.old_quantity,
        a.new_quantity,
        a.changed_at,
        u.name AS user_name,
        i.item_name
      FROM inventory_audit_log a
      LEFT JOIN users u ON u.user_id = a.changed_by
      LEFT JOIN inventory_item i ON i.item_id = a.item_id
      WHERE a.changed_by = @uid
      ORDER BY a.changed_at DESC
      ''',
        parameters: QueryParameters.named({
          'uid': resolvedUserId,
        }),
      );

      return result.map((r) {
        final m = r.toColumnMap();
        return InventoryAuditLog(
          id: m['audit_id'] as int,
          action: m['action'] as String,
          oldQuantity: m['old_quantity'] as int?,
          newQuantity: m['new_quantity'] as int?,
          userName: m['item_name'] as String? ??
              'Unknown Item', //userName diya itemName ke retrieve kora holo
          timestamp: m['changed_at'] as DateTime,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch all prescriptions that have not yet been dispensed
  /// Fetch pending prescriptions (not dispensed, not outside)
  Future<List<Prescription>> getPendingPrescriptions(Session session) async {
    try {
      final result = await session.db.unsafeQuery('''
      SELECT p.prescription_id, p.patient_id, p.doctor_id,u.name AS doctor_name, p.name, p.mobile_number, p.prescription_date
      FROM prescriptions p
      LEFT JOIN users u ON u.user_id = p.doctor_id
      WHERE NOT EXISTS (
          SELECT 1
          FROM prescription_dispense pd
          WHERE pd.prescription_id = p.prescription_id
      )
      AND p.is_outside = FALSE
      ORDER BY p.created_at DESC
      ''');

      int toInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString()) ?? 0;
      }

      int? toNullableInt(dynamic v) {
        if (v == null) return null;
        if (v is int) return v;
        if (v is num) return v.toInt();
        final parsed = int.tryParse(v.toString());
        return parsed;
      }

      DateTime? toDate(dynamic v) {
        if (v == null) return null;
        if (v is DateTime) return v;
        return DateTime.tryParse(v.toString());
      }

      return result.map((row) {
        final map = row.toColumnMap();

        return Prescription(
          id: toInt(map['prescription_id']),
          patientId: toNullableInt(map['patient_id']),
          doctorId: toInt(map['doctor_id']),
          doctorName: map['doctor_name']?.toString(),
          name: map['name']?.toString(),
          mobileNumber: map['mobile_number']?.toString(),
          prescriptionDate: toDate(map['prescription_date']),
        );
      }).toList();
    } catch (e, stack) {
      session.log(
        'Error fetching pending prescriptions: $e',
        level: LogLevel.error,
        stackTrace: stack,
      );
      return [];
    }
  }
  // dispenser_endpoints.dart

  // ১. প্রেসক্রিপশন ডিটেইল এবং স্টক আনা (Raw SQL)
  Future<PrescriptionDetail?> getPrescriptionDetail(
      Session session, int prescriptionId) async {
    try {
      final presResult = await session.db.unsafeQuery('''
        SELECT p.*, u.name as doctor_name 
        FROM prescriptions p
        JOIN users u ON p.doctor_id = u.user_id
        WHERE p.prescription_id = @id
      ''', parameters: QueryParameters.named({'id': prescriptionId}));

      if (presResult.isEmpty) return null;
      final row = presResult.first.toColumnMap();

      final itemsResult = await session.db.unsafeQuery('''
  SELECT 
    pi.*,
    COALESCE(s.current_quantity, 0) AS stock
  FROM prescribed_items pi
  LEFT JOIN inventory_stock s ON s.item_id = pi.item_id
  WHERE pi.prescription_id = @id
''', parameters: QueryParameters.named({'id': prescriptionId}));

      return PrescriptionDetail(
        doctorName: row['doctor_name'],
        prescription: Prescription(
          id: row['prescription_id'],
          patientId: row['patient_id'],
          doctorId: row['doctor_id'],
          doctorName: row['doctor_name'],
          name: row['name'],
          age: row['age'],
          mobileNumber: row['mobile_number'],
          gender: row['gender'],
          prescriptionDate: row['prescription_date'],
        ),
        items: itemsResult.map((r) {
          final d = r.toColumnMap();
          return PrescribedItem(
            id: d['prescribed_item_id'],
            prescriptionId: d['prescription_id'],
            itemId: d['item_id'], // YAML এ এটি অবশ্যই থাকতে হবে
            medicineName: d['medicine_name'],
            dosageTimes: d['dosage_times'],
            duration: d['duration'],
            stock: d['stock'],
          );
        }).toList(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<InventoryItemInfo?> getStockByFirstWord(
      Session session, String medicineName) async {
    try {
      String firstWord = medicineName.split(' ')[0];
      final result = await session.db.unsafeQuery('''
      SELECT i.item_id, i.item_name, s.current_quantity, i.unit, c.category_name
      FROM inventory_item i
      JOIN inventory_category c ON c.category_id = i.category_id
      JOIN inventory_stock s ON s.item_id = i.item_id
      WHERE i.item_name ILIKE @query
        AND c.category_name ILIKE 'medicine%'
      LIMIT 1;
    ''', parameters: QueryParameters.named({'query': '$firstWord%'}));

      if (result.isEmpty) return null;
      final row = result.first.toColumnMap();
      return InventoryItemInfo(
        itemId: row['item_id'],
        itemName: row['item_name'],
        currentQuantity: row['current_quantity'],
        unit: row['unit'] ?? '',
        minimumStock: 0,
        categoryName: row['category_name']?.toString() ?? '',
        canRestockDispenser: true,
      );
    } catch (e) {
      return null;
    }
  }

// ইনভেন্টরি থেকে ঔষধ সার্চ করার জন্য (নতুন)
  Future<List<InventoryItemInfo>> searchInventoryItems(
      Session session, String query) async {
    try {
      final result = await session.db.unsafeQuery('''
      SELECT 
        i.item_id, i.item_name, i.unit, s.current_quantity, c.category_name
      FROM inventory_item i
      JOIN inventory_category c ON c.category_id = i.category_id
      JOIN inventory_stock s ON s.item_id = i.item_id
      WHERE i.item_name ILIKE @query
        AND c.category_name ILIKE 'medicine%'
      LIMIT 10
    ''', parameters: QueryParameters.named({'query': '%$query%'}));

      return result.map((row) {
        final map = row.toColumnMap();
        return InventoryItemInfo(
          itemId: map['item_id'],
          itemName: map['item_name'],
          unit: map['unit'] ?? '',
          currentQuantity: map['current_quantity'] ?? 0,
          minimumStock: 0,
          categoryName: map['category_name']?.toString() ?? '',
          canRestockDispenser: true,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// ডিসপেন্স করার মেইন ট্রানজ্যাকশন (Atomic Transaction)
  Future<bool> dispensePrescription(
    Session session, {
    required int prescriptionId,
    required int dispenserId,
    required List<DispenseItemRequest> items,
  }) async {
    final resolvedUserId = requireAuthenticatedUserId(session);
    if (dispenserId != resolvedUserId) {
      session.log(
        'dispensePrescription: ignoring client dispenserId=$dispenserId; using session userId=$resolvedUserId',
        level: LogLevel.warning,
      );
    }

    return await session.db.transaction((transaction) async {
      try {
        if (items.isEmpty) {
          throw Exception('No medicines selected for dispensing');
        }
        // ১. মেইন ডিসপেন্স রেকর্ড তৈরি
        final dispenseResult = await session.db.unsafeQuery('''
          INSERT INTO prescription_dispense (prescription_id, dispenser_id, status)
          VALUES (@pid, @did, TRUE)
          RETURNING dispense_id, dispensed_at
        ''',
            parameters: QueryParameters.named({
              'pid': prescriptionId,
              'did': resolvedUserId,
            }));

        final dispenseRow = dispenseResult.first.toColumnMap();
        final int dispenseId = dispenseRow['dispense_id'] as int;
        final DateTime dispensedAt = dispenseRow['dispensed_at'] as DateTime;

        String formatYmdHm(DateTime dt) {
          final local = dt.toLocal();
          final y = local.year.toString().padLeft(4, '0');
          final mo = local.month.toString().padLeft(2, '0');
          final d = local.day.toString().padLeft(2, '0');
          final h = local.hour.toString().padLeft(2, '0');
          final mi = local.minute.toString().padLeft(2, '0');
          return '$y-$mo-$d $h:$mi';
        }

        // ২. প্রতিটি আইটেম প্রসেস করা
        for (var item in items) {
          // স্টক চেক এবং লক করা (Race Condition রোখার জন্য)
          final stockCheck = await session.db.unsafeQuery('''
                    SELECT current_quantity 
                    FROM inventory_stock
                    WHERE item_id = @id
                  FOR UPDATE
              ''', parameters: QueryParameters.named({'id': item.itemId}));

          if (stockCheck.isEmpty) {
            throw Exception('No stock available for ${item.medicineName}');
          }

          final stockRow = stockCheck.first.toColumnMap();
          final currentStock = (stockRow['current_quantity'] as int?) ?? 0;

          if (currentStock <= 0) {
            throw Exception('No stock available for ${item.medicineName}');
          }
          if (item.quantity <= 0) {
            throw Exception('Invalid quantity for ${item.medicineName}');
          }
          if (currentStock < item.quantity) {
            throw Exception(
              'Insufficient stock for ${item.medicineName} (available $currentStock, need ${item.quantity})',
            );
          }

          // ৩. ডিসপেন্সড আইটেম ইনসার্ট (অল্টারনেটিভ সহ)
          await session.db.unsafeExecute('''
            INSERT INTO dispensed_items (
              dispense_id, item_id, medicine_name, quantity, is_alternative, original_medicine_id
            ) VALUES (@did, @iid, @name, @qty, @isAlt, @origId)
          ''',
              parameters: QueryParameters.named({
                'did': dispenseId,
                'iid': item.itemId,
                'name': item.medicineName,
                'qty': item.quantity,
                'isAlt': item.isAlternative,
                'origId': item.originalMedicineId,
              }));

          // ৪. ইনভেন্টরি আপডেট
          final int newStock = currentStock - item.quantity;
          await session.db.unsafeExecute('''
          UPDATE inventory_stock SET current_quantity = @newQty WHERE item_id = @id
          ''',
              parameters: QueryParameters.named({
                'newQty': newStock,
                'id': item.itemId,
              }));

          // ৫. অডিট লগ তৈরি
          await session.db.unsafeExecute('''
            INSERT INTO inventory_audit_log (item_id, old_quantity, new_quantity, action, changed_by)
            VALUES (@id, @old, @new, 'DISPENSE', @uid)
          ''',
              parameters: QueryParameters.named({
                'id': item.itemId,
                'old': currentStock,
                'new': newStock,
                'uid': resolvedUserId,
              }));
        }

        // ৬. Patient notification (if patient_id exists)
        try {
          final presRows = await session.db.unsafeQuery(
            '''
            SELECT patient_id, name, mobile_number
            FROM prescriptions
            WHERE prescription_id = @pid
            LIMIT 1
            ''',
            parameters: QueryParameters.named({'pid': prescriptionId}),
          );

          if (presRows.isNotEmpty) {
            final p = presRows.first.toColumnMap();
            final int? patientId = p['patient_id'] as int?;

            if (patientId != null) {
              final itemsText = items
                  .map((i) => '• ${i.medicineName} × ${i.quantity}')
                  .join('\n');

              final title = 'Medicines dispensed';
              final message =
                  'Your medicines have been dispensed.\nDispensed at: ${formatYmdHm(dispensedAt)}\nPrescription ID: $prescriptionId\nItems:\n$itemsText';

              await session.db.unsafeExecute(
                '''
                INSERT INTO notifications (user_id, title, message, is_read, created_at)
                VALUES (@uid, @t, @m, FALSE, NOW())
                ''',
                parameters: QueryParameters.named({
                  'uid': patientId,
                  't': title,
                  'm': message,
                }),
              );
            }
          }
        } catch (e) {
          session.log('Notification insert skipped/failed: $e');
        }

        return true; // সব সফল হলে ট্রানজ্যাকশন কমিট হবে
      } catch (e, st) {
        session.log('Transaction failed: $e',
            level: LogLevel.error, stackTrace: st);
        rethrow; // rollback + propagate reason to client
      }
    });
  }

  /// Detailed dispense history (patient + items) for current dispenser
  Future<List<DispenseHistoryEntry>> getDispenserDispenseHistory(
    Session session, {
    int limit = 50,
  }) async {
    try {
      final resolvedUserId = requireAuthenticatedUserId(session);

      final dispenses = await session.db.unsafeQuery(
        '''
        SELECT
          pd.dispense_id,
          pd.prescription_id,
          pd.dispensed_at,
          p.patient_id,
          COALESCE(NULLIF(u.name, ''), NULLIF(p.name, ''), 'Unknown') AS patient_name,
          COALESCE(u.phone, p.mobile_number, '') AS mobile_number
        FROM prescription_dispense pd
        JOIN prescriptions p ON p.prescription_id = pd.prescription_id
        LEFT JOIN users u ON u.user_id = p.patient_id
        WHERE pd.dispenser_id = @uid
        ORDER BY pd.dispensed_at DESC
        LIMIT @lim
        ''',
        parameters:
            QueryParameters.named({'uid': resolvedUserId, 'lim': limit}),
      );

      final entries = <DispenseHistoryEntry>[];
      for (final row in dispenses) {
        final m = row.toColumnMap();
        final int dispenseId = (m['dispense_id'] as int);

        final itemRows = await session.db.unsafeQuery(
          '''
          SELECT medicine_name, quantity, is_alternative
          FROM dispensed_items
          WHERE dispense_id = @did
          ORDER BY dispensed_item_id ASC
          ''',
          parameters: QueryParameters.named({'did': dispenseId}),
        );

        final items = itemRows.map((ir) {
          final im = ir.toColumnMap();
          return DispensedItemSummary(
            medicineName: _safeString(im['medicine_name']),
            quantity: (im['quantity'] as int?) ?? 0,
            isAlternative: (im['is_alternative'] as bool?) ?? false,
          );
        }).toList();

        entries.add(
          DispenseHistoryEntry(
            dispenseId: dispenseId,
            prescriptionId: (m['prescription_id'] as int),
            patientId: m['patient_id'] as int?,
            patientName: _safeString(m['patient_name']),
            mobileNumber: _safeString(m['mobile_number']),
            dispensedAt: (m['dispensed_at'] as DateTime),
            items: items,
          ),
        );
      }

      return entries;
    } catch (e) {
      return [];
    }
  }

  /// 3️⃣ Helper
  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List<int>) return String.fromCharCodes(value);
    return value.toString();
  }
}
