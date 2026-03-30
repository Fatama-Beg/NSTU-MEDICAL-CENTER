import 'package:serverpod/database.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import '../../generated/InventoryCategory.dart';
import '../../generated/InventoryItemInfo.dart';
import '../../generated/inventory_audit_log.dart';
import '../../generated/inventory_transaction.dart';

import '../../auth/auth_user.dart';

class AdminInventoryEndpoints extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<bool> addInventoryCategory(
    Session session,
    String name,
    String? description,
  ) async {
    try {
      await session.db.unsafeExecute(
        '''
      INSERT INTO inventory_category (category_name, description)
      VALUES (@n, @d)
      ''',
        parameters: QueryParameters.named({
          'n': name.trim(),
          'd': description,
        }),
      );
      return true;
    } catch (e, st) {
      session.log('addInventoryCategory failed: $e\n$st',
          level: LogLevel.error);
      return false;
    }
  }

  Future<List<InventoryCategory>> listInventoryCategories(
      Session session) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
      SELECT category_id, category_name, description
      FROM inventory_category
      ORDER BY category_name
      ''',
      );

      // Map the database rows directly to your generated InventoryCategory objects
      return result.map((row) {
        final map = row.toColumnMap();
        return InventoryCategory(
          categoryId: map['category_id'] as int,
          categoryName: map['category_name'] as String,
          description: map['description'] as String?,
        );
      }).toList();
    } catch (e) {
      session.log('listInventoryCategories failed: $e', level: LogLevel.error);
      return [];
    }
  }

  Future<bool> addInventoryItem(
    Session session, {
    required int categoryId,
    required String itemName,
    required String unit,
    required int minimumStock,
    int initialStock = 0,
    bool canRestockDispenser = false,
  }) async {
    try {
      final resolvedAdminUserId = requireAuthenticatedUserId(session);
      await session.db.unsafeExecute('BEGIN');

      // 1️⃣ Insert item
      final itemRes = await session.db.unsafeQuery(
        '''
      INSERT INTO inventory_item
        (category_id, item_name, unit, minimum_stock, can_restock_dispenser)
      VALUES
        (@cid, @name, @unit, @min, @restock)
      RETURNING item_id
      ''',
        parameters: QueryParameters.named({
          'cid': categoryId,
          'name': itemName,
          'unit': unit,
          'min': minimumStock,
          'restock': canRestockDispenser,
        }),
      );

      final itemId = itemRes.first.toColumnMap()['item_id'];

      // 2️⃣ Insert stock
      await session.db.unsafeExecute(
        '''
      INSERT INTO inventory_stock (item_id, current_quantity)
      VALUES (@id, @qty)
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'qty': initialStock,
        }),
      );

      // 3️⃣ Audit log
      await session.db.unsafeExecute(
        '''
      INSERT INTO inventory_audit_log
        (item_id, old_quantity, new_quantity, action, changed_by)
      VALUES
        (@id, 0, @qty, 'CREATE_ITEM', @uid)
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'qty': initialStock,
          'uid': resolvedAdminUserId,
        }),
      );

      await session.db.unsafeExecute('COMMIT');
      return true;
    } catch (e, st) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('addInventoryItem failed: $e\n$st', level: LogLevel.error);
      return false;
    }
  }

  Future<bool> updateInventoryStock(
    Session session, {
    required int itemId,
    required int quantity,
    required String type, // IN or OUT
  }) async {
    try {
      if (quantity <= 0) return false;

      final resolvedUserId = requireAuthenticatedUserId(session);

      await session.db.unsafeExecute('BEGIN');

      // Get current stock
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

      final int newQty = type == 'IN' ? oldQty + quantity : oldQty - quantity;

      if (newQty < 0) {
        await session.db.unsafeExecute('ROLLBACK');
        return false;
      }

      // Update stock
      await session.db.unsafeExecute(
        '''
      UPDATE inventory_stock
      SET current_quantity = @nq,
          last_updated = CURRENT_TIMESTAMP
      WHERE item_id = @id
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'nq': newQty,
        }),
      );

      // Transaction log
      await session.db.unsafeExecute(
        '''
      INSERT INTO inventory_transaction
        (item_id, transaction_type, quantity, performed_by)
      VALUES
        (@id, @t, @q, @u)
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          't': type,
          'q': quantity,
          'u': resolvedUserId,
        }),
      );

      // Audit log
      await session.db.unsafeExecute(
        '''
      INSERT INTO inventory_audit_log
        (item_id, old_quantity, new_quantity, action, changed_by)
      VALUES
        (@id, @old, @new, @act, @u)
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'old': oldQty,
          'new': newQty,
          'act': type == 'IN' ? 'ADD_STOCK' : 'REMOVE_STOCK',
          'u': resolvedUserId,
        }),
      );

      await session.db.unsafeExecute('COMMIT');
      return true;
    } catch (e, st) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('updateInventoryStock failed: $e\n$st',
          level: LogLevel.error);
      return false;
    }
  }

  Future<bool> updateDispenserRestockFlag(
    Session session, {
    required int itemId,
    required bool canRestock,
  }) async {
    try {
      final resolvedAdminUserId = requireAuthenticatedUserId(session);
      await session.db.unsafeExecute('BEGIN');

      // Update the flag
      await session.db.unsafeExecute(
        '''
      UPDATE inventory_item
      SET can_restock_dispenser = @restock
      WHERE item_id = @id
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'restock': canRestock,
        }),
      );

      // Audit log
      await session.db.unsafeExecute(
        '''
      INSERT INTO inventory_audit_log
        (item_id, action, changed_by)
      VALUES
        (@id, 'EDIT_DISPENSER_FLAG', @uid)
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'uid': resolvedAdminUserId,
        }),
      );

      await session.db.unsafeExecute('COMMIT');
      return true;
    } catch (e, st) {
      await session.db.unsafeExecute('ROLLBACK');
      session.log('updateDispenserRestockFlag failed: $e\n$st',
          level: LogLevel.error);
      return false;
    }
  }

  Future<List<InventoryItemInfo>> listInventoryItems(Session session) async {
    try {
      final result = await session.db.unsafeQuery('''
      SELECT
        i.item_id,
        i.item_name,
        i.unit,
        i.minimum_stock,
        c.category_name,
        s.current_quantity,
        i.can_restock_dispenser
      FROM inventory_item i
      JOIN inventory_category c ON c.category_id = i.category_id
      JOIN inventory_stock s ON s.item_id = i.item_id
      ORDER BY i.item_name
      ''');

      return result.map((row) {
        final map = row.toColumnMap();

        // helper conversions
        int toInt(dynamic v) {
          if (v == null) return 0;
          if (v is int) return v;
          if (v is num) return v.toInt();
          return int.tryParse(v.toString()) ?? 0;
        }

        bool toBool(dynamic v) {
          if (v == null) return false;
          if (v is bool) return v;
          if (v is int) return v != 0;
          final s = v.toString().toLowerCase();
          return s == 't' || s == 'true' || s == '1';
        }

        return InventoryItemInfo(
          itemId: toInt(map['item_id']),
          itemName: map['item_name']?.toString() ?? '',
          unit: map['unit']?.toString() ?? '',
          minimumStock: toInt(map['minimum_stock']),
          categoryName: map['category_name']?.toString() ?? '',
          currentQuantity: toInt(map['current_quantity']),
          canRestockDispenser: toBool(map['can_restock_dispenser']),
        );
      }).toList();
    } catch (e, st) {
      session.log('listInventoryItems failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  Future<bool> updateMinimumThreshold(
    Session session, {
    required int itemId,
    required int newThreshold,
  }) async {
    try {
      final resolvedAdminUserId = requireAuthenticatedUserId(session);
      await session.db.unsafeExecute('BEGIN');

      await session.db.unsafeExecute(
        '''
      UPDATE inventory_item 
      SET minimum_stock = @min
      WHERE item_id = @id
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'min': newThreshold,
        }),
      );

      // ২. অডিট লগ রাখা
      await session.db.unsafeExecute(
        '''
      INSERT INTO inventory_audit_log 
        (item_id, action, changed_by) 
      VALUES (@id, 'EDIT_MIN_THRESHOLD', @uid)
      ''',
        parameters: QueryParameters.named({
          'id': itemId,
          'uid': resolvedAdminUserId,
        }),
      );

      await session.db.unsafeExecute('COMMIT');
      return true;
    } catch (e) {
      await session.db.unsafeExecute('ROLLBACK');
      return false;
    }
  }

  Future<List<InventoryTransactionInfo>> getItemTransactions(
    Session session,
    int itemId,
  ) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
      SELECT item_id, transaction_type, quantity, created_at
      FROM inventory_transaction
      WHERE item_id = @id
      ORDER BY created_at DESC
      LIMIT 10
      ''',
        parameters: QueryParameters.named({'id': itemId}),
      );

      return result.map((r) {
        final m = r.toColumnMap();
        return InventoryTransactionInfo(
          itemId: m['item_id'] as int,
          transactionType: m['transaction_type'] as String,
          quantity: m['quantity'] as int,
          createdAt: m['created_at'] as DateTime,
        );
      }).toList();
    } catch (e, st) {
      session.log('getItemTransactions failed: $e\n$st', level: LogLevel.error);
      return [];
    }
  }

  Future<List<InventoryAuditLog>> getInventoryAuditLogs(
    Session session,
    int limit,
    int offset,
  ) async {
    try {
      final result = await session.db.unsafeQuery(
        '''
      SELECT
        a.audit_id,
        a.action,
        a.old_quantity,
        a.new_quantity,
        a.changed_at,
        u.name AS user_name
      FROM inventory_audit_log a
      LEFT JOIN users u ON u.user_id = a.changed_by
      ORDER BY a.changed_at DESC
      LIMIT @limit OFFSET @offset
      ''',
        parameters: QueryParameters.named({
          'limit': limit,
          'offset': offset,
        }),
      );

      return result.map((r) {
        final m = r.toColumnMap();

        // changed_at কে DateTime হিসেবে নেওয়া
        final changedAt = m['changed_at'] as DateTime?;

        return InventoryAuditLog(
          id: m['audit_id'] as int,
          action: m['action'] as String,
          oldQuantity: m['old_quantity'] as int?,
          newQuantity: m['new_quantity'] as int?,
          userName: m['user_name'] as String? ?? 'System',
          timestamp: changedAt ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      //
      session.log('getInventoryAuditLogs failed: $e', level: LogLevel.error);
      return [];
    }
  }
}
