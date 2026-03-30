import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backend_client/backend_client.dart';
import 'package:pdf/widgets.dart' as pw;

import 'export_service.dart';
import '../core/date_time_utils.dart';
import '../routing/route_refresh.dart';

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement>
    with RouteRefreshMixin<InventoryManagement> {
  final Color primaryColor = const Color(0xFF00796B); // Deep Teal
  final Color lowStockColor = Colors.orange.shade700;
  final Color criticalStockColor = Colors.red.shade700;

  pw.Font? _englishFont;
  bool _exportingPdf = false;

  Future<void> _ensurePdfFontLoaded() async {
    if (_englishFont != null) return;
    final data = await rootBundle.load(
      'assets/fonts/OpenSans-VariableFont.ttf',
    );
    _englishFont = pw.Font.ttf(data);
  }

  DateTime _dateOnly(DateTime d) => AppDateTime.startOfLocalDay(d);

  Future<void> _exportInventoryTransactionsPdf() async {
    if (_exportingPdf) return;

    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: _dateOnly(now.subtract(const Duration(days: 7))),
        end: _dateOnly(now),
      ),
      helpText: 'Select date range for inventory transactions',
      confirmText: 'EXPORT',
    );

    if (picked == null) return;

    final fromLocal = AppDateTime.startOfLocalDay(picked.start);
    final toLocal = AppDateTime.startOfLocalDay(picked.end);
    final toExclusiveLocal = AppDateTime.startOfNextLocalDay(toLocal);

    final fromUtc = fromLocal.toUtc();
    final toExclusiveUtc = toExclusiveLocal.toUtc();

    if (!mounted) return;
    setState(() => _exportingPdf = true);

    try {
      await _ensurePdfFontLoaded();
      final font = _englishFont;
      if (font == null) {
        throw Exception('PDF font not available');
      }

      if (products.isEmpty) {
        await _loadInventory();
      }

      final Map<int, Map<String, String>> itemLookup = {
        for (final p in products)
          (p['id'] as int): {
            'name': (p['name'] ?? '').toString(),
            'unit': (p['unit'] ?? '').toString(),
          },
      };

      final itemIds = itemLookup.keys.toList()..sort();
      final rows = <InventoryTransactionReportRow>[];

      // Fetch transactions in small batches to avoid hammering the server.
      const int batchSize = 10;
      for (int i = 0; i < itemIds.length; i += batchSize) {
        final batch = itemIds.sublist(
          i,
          (i + batchSize) > itemIds.length ? itemIds.length : (i + batchSize),
        );

        final results = await Future.wait(
          batch.map((id) async {
            try {
              return await client.adminInventoryEndpoints.getItemTransactions(
                id,
              );
            } catch (_) {
              return <InventoryTransactionInfo>[];
            }
          }),
        );

        for (final txs in results) {
          for (final tx in txs) {
            final createdAt = tx.createdAt;
            final createdUtc = createdAt.toUtc();
            if (createdUtc.isBefore(fromUtc) ||
                !createdUtc.isBefore(toExclusiveUtc)) {
              continue;
            }
            final meta = itemLookup[tx.itemId];
            rows.add(
              ExportService.inventoryTxRow(
                time: createdAt,
                itemName: meta?['name'] ?? 'Item #${tx.itemId}',
                unit: meta?['unit'] ?? '',
                type: tx.transactionType,
                quantity: tx.quantity,
              ),
            );
          }
        }
      }

      if (!mounted) return;
      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No transactions found in this date range'),
          ),
        );
        return;
      }

      await ExportService.exportInventoryTransactionsRangeAsPDF(
        rows: rows,
        from: fromLocal,
        to: toLocal,
        font: font,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _exportingPdf = false);
    }
  }

  List<InventoryCategory> categories = [];
  int? selectedCategoryId;

  Future<void> _loadCategories() async {
    try {
      final result = await client.adminInventoryEndpoints
          .listInventoryCategories();
      setState(() {
        categories = result; // store full map with id and name
      });
    } catch (e) {
      debugPrint('Category Load Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load categories')),
      );
    }
  }

  List<Map<String, dynamic>> products = [];
  bool loading = true;

  Future<void> _loadInventory() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      // result is a List<InventoryItemInfo> (generated from YAML)
      final result = await client.adminInventoryEndpoints.listInventoryItems();

      setState(() {
        products = result
            .map(
              (item) => {
                'id': item.itemId,
                'name': item.itemName,
                'unit': item.unit,
                'minThreshold': item.minimumStock,
                'stock': item.currentQuantity,
                'category': item.categoryName,
                'canRestockDispenser': item.canRestockDispenser,
                'transactions': [],
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Inventory Load Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load inventory')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<List<InventoryTransactionInfo>> _loadTransactions(int itemId) async {
    final transactions = await client.adminInventoryEndpoints
        .getItemTransactions(itemId);

    // 🔥 Flutter print
    // debugPrint('Transactions for item $itemId: $transactions');

    return transactions;
  }

  // NEW: Calculate total stock (now directly stored in product['stock'])
  int _getTotalStock(Map<String, dynamic> product) {
    return (product['stock'] ?? 0) as int;
  }

  // Function to determine stock status color and message (uses total stock)
  Map<String, dynamic> _getStockStatus(Map<String, dynamic> product) {
    final stock = _getTotalStock(product);
    final threshold = product['minThreshold'];

    if (stock <= 0) {
      return {"color": criticalStockColor, "text": "Out of Stock"};
    } else if (stock < threshold) {
      return {"color": lowStockColor, "text": "Low Stock Alert!"};
    }
    // use withAlpha to avoid withOpacity deprecation warnings
    return {
      "color": primaryColor.withAlpha((0.7 * 255).round()),
      "text": "In Stock",
    };
  }

  // --- Dialogs & Actions ---

  void updateItem(
    Map<String, dynamic> product, {
    String? name,
    String? unit,
    int? minThreshold,
    String? category,
  }) {
    setState(() {
      if (name != null) product['name'] = name;
      if (unit != null) product['unit'] = unit;
      if (minThreshold != null) product['minThreshold'] = minThreshold;
      if (category != null) product['category'] = category;
    });
  }

  // inventory_management.dart এর ভিতরে একটি নতুন ডায়ালগ ফাংশন
  void _showEditThresholdDialog(Map<String, dynamic> product) {
    final controller = TextEditingController(
      text: product['minThreshold'].toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Threshold for ${product['name']}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'New Minimum Level',
              hintText: 'e.g. 10',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newMin = int.tryParse(controller.text.trim());
              if (newMin == null) return;

              final adminUserId = await _getAdminUserIdFromPrefs();
              if (adminUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Admin ID not found. Please sign in again.'),
                  ),
                );
                return;
              }

              // ব্যাকএন্ড কল করা (সার্ভারপড জেনারেট করার পর এই মেথড পাবেন)
              final success = await client.adminInventoryEndpoints
                  .updateMinimumThreshold(
                    itemId: product['id'],
                    newThreshold: newMin,
                  );

              if (success) {
                await _loadInventory(); // লিস্ট রিফ্রেশ করা
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Threshold updated!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Shows detailed item dialog where user can increase/decrease stock
  /// Function renamed to be clearer for beginners.
  void _showItemDetails(Map<String, dynamic> product) {
    final rootContext = context;
    final TextEditingController quantityController = TextEditingController();
    String? errorText;

    // Ensure transactions list exists on the product
    product['transactions'] ??= <Map<String, dynamic>>[];
    bool txLoading = true;
    bool txFetchStarted = false;
    bool canRestockDispenser = product['canRestockDispenser'] ?? false;
    bool originalRestockFlag = canRestockDispenser; // store original value

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            Future<void> fetchTransactions() async {
              final data = await _loadTransactions(product['id']);
              if (!context.mounted) return;
              setStateDialog(() {
                product['transactions'] = data;
                txLoading = false;
              });
            }

            // 👉 dialog build হওয়ার সাথে সাথে একবার call
            if (!txFetchStarted) {
              txFetchStarted = true;
              fetchTransactions();
            }

            final status = _getStockStatus(product);

            Future<void> _applyStockChange(int delta) async {
              final qty = int.tryParse(quantityController.text.trim());
              if (qty == null || qty <= 0) {
                setStateDialog(() => errorText = 'Enter valid quantity');
                return;
              }
              final adminUserId = await _getAdminUserIdFromPrefs();
              if (adminUserId == null) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Error: Admin user ID not found. Please sign in again.',
                    ),
                  ),
                );
                return;
              }

              final success = await client.adminInventoryEndpoints
                  .updateInventoryStock(
                    itemId: product['id'],
                    quantity: qty,
                    type: delta > 0 ? 'IN' : 'OUT',
                  );

              if (!success) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(content: Text('Stock update failed')),
                );
                return;
              }

              // Update canRestockDispenser only if it changed
              if (canRestockDispenser != originalRestockFlag) {
                final restockSuccess = await client.adminInventoryEndpoints
                    .updateDispenserRestockFlag(
                      itemId: product['id'],
                      canRestock: canRestockDispenser,
                    );

                if (!restockSuccess) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update dispenser flag'),
                    ),
                  );
                  return;
                }

                // update the local product to reflect new value
                product['canRestockDispenser'] = canRestockDispenser;
              }

              // Refresh list from backend
              await _loadInventory();

              FocusScope.of(dialogContext).unfocus();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(rootContext).showSnackBar(
                SnackBar(
                  content: Text(delta > 0 ? 'Stock added' : 'Stock removed'),
                  backgroundColor: delta > 0 ? Colors.green : Colors.orange,
                ),
              );
            }

            final mediaQuery = MediaQuery.of(dialogContext);
            final bottomInset = mediaQuery.viewInsets.bottom;
            final availableHeight = mediaQuery.size.height - bottomInset;
            final dialogHeight = (availableHeight * 0.9).clamp(
              320.0,
              mediaQuery.size.height * 0.9,
            );

            return AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SizedBox(
                    height: dialogHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: CustomScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Icon(Icons.inventory_2, color: primaryColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    product['name'] ?? 'Item',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Close',
                                ),
                              ],
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          SliverToBoxAdapter(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Status',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: status['color'].withAlpha(
                                            (0.12 * 255).round(),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          status['text'],
                                          style: TextStyle(
                                            color: status['color'],
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Current Stock',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        '${_getTotalStock(product)} ${product['unit'] ?? ''}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Minimum Threshold',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        '${product['minThreshold'] ?? 0} ${product['unit'] ?? ''}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Category',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        product['category'] ?? 'Unassigned',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 14)),
                          SliverToBoxAdapter(
                            child: CheckboxListTile(
                              title: const Text('Dispenser can restock'),
                              value: canRestockDispenser,
                              activeColor: primaryColor,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                setStateDialog(() {
                                  canRestockDispenser = val ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          SliverToBoxAdapter(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Update Stock Quantity',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          SliverToBoxAdapter(
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter quantity (e.g. 10)',
                                labelText: 'Quantity',
                                helperText: 'Enter a positive whole number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                errorText: errorText,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _applyStockChange(1),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Stock'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _applyStockChange(-1),
                                    icon: const Icon(Icons.remove, size: 18),
                                    label: const Text('Remove Stock'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 14)),
                          SliverToBoxAdapter(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Recent Transactions',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          if (txLoading)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            )
                          else if ((product['transactions'] as List).isEmpty)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text('No recent transactions'),
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final t =
                                      (product['transactions']
                                          as List<
                                            InventoryTransactionInfo
                                          >)[index];
                                  final qty = t.quantity;
                                  final type = t.transactionType;
                                  final dt = t.createdAt;
                                  final signedQty = type == 'OUT' ? -qty : qty;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          signedQty > 0
                                              ? '+$signedQty'
                                              : signedQty.toString(),
                                          style: TextStyle(
                                            color: signedQty < 0
                                                ? Colors.red
                                                : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                childCount:
                                    (product['transactions']
                                            as List<InventoryTransactionInfo>)
                                        .length,
                              ),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final rootContext = context;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController(); // NEW

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Category'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    hintText: 'e.g. Medicine',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Short note about this category',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim();

              if (name.isEmpty) return;

              final success = await client.adminInventoryEndpoints
                  .addInventoryCategory(name, desc);

              if (success) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  rootContext,
                ).showSnackBar(const SnackBar(content: Text('Category added')));
                await _loadCategories(); // <-- refresh categories dynamically
              } else {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(content: Text('Failed to add category')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadInventory();
    _ensurePdfFontLoaded();
  }

  @override
  Future<void> refreshOnFocus() async {
    await Future.wait([_loadCategories(), _loadInventory()]);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final minStockController = TextEditingController(text: '10');
    bool canRestockDispenser = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Validation: Check if all fields have valid data
            final bool isNameValid = nameController.text.trim().isNotEmpty;
            final bool isCategoryValid = selectedCategoryId != null;
            final bool isUnitValid = unitController.text.trim().isNotEmpty;
            final bool isMinStockValid =
                int.tryParse(minStockController.text) != null;

            final bool canAdd =
                isNameValid &&
                isCategoryValid &&
                isUnitValid &&
                isMinStockValid;

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Add New Item'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        onChanged: (_) => setStateDialog(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        items: categories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat.categoryId,
                                child: Text(cat.categoryName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setStateDialog(() => selectedCategoryId = v);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: unitController,
                        onChanged: (_) => setStateDialog(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Type of medicine',
                          hintText: 'e.g. tablet / Liquid / Capsule',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: minStockController,
                        onChanged: (_) => setStateDialog(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Stock Level',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: CheckboxListTile(
                          title: const Text('Dispenser can restock'),
                          value: canRestockDispenser,
                          activeColor: primaryColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          onChanged: (val) {
                            setStateDialog(() {
                              canRestockDispenser = val ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: canAdd
                      ? () async {
                          final adminUserId = await _getAdminUserIdFromPrefs();
                          if (adminUserId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Admin ID not found. Please sign in again.',
                                ),
                              ),
                            );
                            return;
                          }
                          final success = await client.adminInventoryEndpoints
                              .addInventoryItem(
                                categoryId: selectedCategoryId!,
                                itemName: nameController.text.trim(),
                                unit: unitController.text.trim(),
                                minimumStock: int.parse(
                                  minStockController.text,
                                ),
                                initialStock: 0, // Defaulted to 0
                                canRestockDispenser: canRestockDispenser,
                              );

                          if (success) {
                            await _loadInventory();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Item added successfully'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to add item'),
                              ),
                            );
                          }
                        }
                      : null, // Button is disabled if validation fails
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAdd ? primaryColor : Colors.grey,
                  ),
                  child: const Text('Add Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper: resolve admin user id from SharedPreferences robustly.
  Future<int?> _getAdminUserIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Check common keys and both string/int types
    final candidateKeys = ['user_id', 'userId', 'admin_id', 'adminId'];
    for (final key in candidateKeys) {
      // try string first
      final s = prefs.getString(key);
      if (s != null && s.isNotEmpty) {
        final n = int.tryParse(s);
        if (n != null) return n;
      }
      // try int
      final i = prefs.getInt(key);
      if (i != null) return i;
    }

    // Fallback: sometimes stored under 'user' as json or email; try parsing 'user_id' as dynamic
    try {
      final dynamic raw = prefs.get('user_id');
      if (raw is int) return raw;
      if (raw is String) {
        final n = int.tryParse(raw);
        if (n != null) return n;
      }
    } catch (_) {}

    return null;
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    const double cardHeight = 110.0;
    return Container(
      width: width,
      height: cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha((0.06 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha((0.18 * 255).round()),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: Icon(icon, size: 26, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(
    Map<String, dynamic> product,
    int index, {
    bool highlight = false,
  }) {
    final status = _getStockStatus(product);
    final bgColor = highlight
        ? status['color'].withAlpha((0.08 * 255).round())
        : Colors.white;

    final isNarrow = MediaQuery.of(context).size.width < 520;

    if (isNarrow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: status['color'].withAlpha(
                        (0.12 * 255).round(),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: status['color'],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        product['name'] ?? 'Unnamed',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status['color'].withAlpha((0.12 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status['text'],
                        style: TextStyle(
                          color: status['color'],
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Min Stock: ${product['minThreshold']}    Category: ${product['category']}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_getTotalStock(product)} ${product['unit']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showEditThresholdDialog(product),
                      icon: const Icon(
                        Icons.settings_backup_restore,
                        color: Colors.blueGrey,
                      ),
                      tooltip: 'Update threshold',
                    ),
                    IconButton(
                      onPressed: () => _showItemDetails(product),
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.blueGrey,
                      ),
                      tooltip: 'View details & update stock',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // // left color stripe
            // Container(
            //   width: 6,
            //   height: double.infinity,
            //   decoration: BoxDecoration(
            //     color: status['color'],
            //     borderRadius: const BorderRadius.only(
            //       topLeft: Radius.circular(12),
            //       bottomLeft: Radius.circular(12),
            //     ),
            //   ),
            // ),
            const SizedBox(width: 8),

            // icon and index
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: status['color'].withAlpha(
                  (0.12 * 255).round(),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: status['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // main info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'] ?? 'Unnamed',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status['color'].withAlpha(
                              (0.12 * 255).round(),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status['text'],
                            style: TextStyle(
                              color: status['color'],
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ' Min Stock: ${product['minThreshold']}    Category: ${product['category']}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // small gap before the right-side controls
            const SizedBox(width: 16),

            // quantity controls and info
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_getTotalStock(product)} ${product['unit']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),

                  IconButton(
                    onPressed: () => _showEditThresholdDialog(
                      product,
                    ), // এখানে সরাসরি কল করুন
                    icon: const Icon(
                      Icons.settings_backup_restore,
                      color: Colors.blueGrey,
                    ),
                    tooltip: 'Update threshold',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showItemDetails(product),
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.blueGrey,
                    ),
                    tooltip: 'View details & update stock',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No header category filter (dropdown removed). Use full products list.
    final displayedProducts = products;

    // Filter based on total stock from displayed products
    final lowStockItems = displayedProducts
        .where((p) => _getTotalStock(p) < p['minThreshold'])
        .toList();

    // Summary counts
    final int totalItems = products.length;
    final int outOfStock = products.where((p) => _getTotalStock(p) <= 0).length;
    final int lowStockCount = products
        .where(
          (p) => _getTotalStock(p) > 0 && _getTotalStock(p) < p['minThreshold'],
        )
        .length;
    final int inStock = totalItems - lowStockCount - outOfStock;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Export transactions as PDF',
            onPressed: _exportingPdf ? null : _exportInventoryTransactionsPdf,
            icon: _exportingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header controls: category filter and add buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 520;

                  final addCategoryBtn = ElevatedButton.icon(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                    ),
                  );

                  final addItemBtn = ElevatedButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        addCategoryBtn,
                        const SizedBox(height: 8),
                        addItemBtn,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      addCategoryBtn,
                      const SizedBox(width: 8),
                      addItemBtn,
                    ],
                  );
                },
              ),
            ),
          ),

          // Summary Cards (Total, In Stock, Low Stock, Out of Stock)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate a column-aware width. Keep all summary cards same width/height.
                  final double maxWidth = constraints.maxWidth;
                  // Prefer 2 cards per row on small screens, 4 on wide screens.
                  int columns = maxWidth >= 900 ? 4 : 2;
                  final double totalSpacing = (columns - 1) * 12;
                  double cardWidth = (maxWidth - totalSpacing) / columns;
                  // Clamp to reasonable bounds so cards look consistent
                  cardWidth = cardWidth.clamp(120.0, 320.0);

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildSummaryCard(
                        "Total Items",
                        totalItems.toString(),
                        Icons.inventory_2,
                        Colors.teal,
                        cardWidth,
                      ),
                      _buildSummaryCard(
                        "In Stock",
                        inStock.toString(),
                        Icons.check_circle_outline,
                        Colors.green,
                        cardWidth,
                      ),
                      _buildSummaryCard(
                        "Low Stock",
                        lowStockCount.toString(),
                        Icons.warning_amber_rounded,
                        Colors.orange,
                        cardWidth,
                      ),
                      _buildSummaryCard(
                        "Out of Stock",
                        outOfStock.toString(),
                        Icons.close_rounded,
                        Colors.red,
                        cardWidth,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Low Stock Alerts Section
          if (lowStockItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🔴 Low Stock Alerts (${lowStockItems.length})",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: criticalStockColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...lowStockItems.map((product) {
                      return _buildProductRow(
                        product,
                        lowStockItems.indexOf(product),
                        highlight: true,
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Main Inventory List Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                "All Inventory Items",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),

          // Main Inventory List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];

              return _buildProductRow(product, index);
            }, childCount: products.length),
          ),
        ],
      ),
    );
  }
}
