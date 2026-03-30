import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart';

import '../routing/route_refresh.dart';

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement>
    with RouteRefreshMixin<InventoryManagement> {
  // Start with an empty inventory; real data will be loaded from backend in _loadInventory().
  List<Map<String, dynamic>> _inventory = [];

  @override
  void initState() {
    super.initState();
    // Load real inventory from backend on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInventory();
    });
  }

  @override
  Future<void> refreshOnFocus() async {
    await _loadInventory();
  }

  /// Refresh inventory list from backend
  Future<void> _loadInventory() async {
    try {
      final result = await client.dispenser.listInventoryItems();
      final mapped = result
          .map(
            (item) => {
              'id': item.itemId,
              'name': item.itemName,
              'unit': item.unit,
              'currentStock': item.currentQuantity,
              'minThreshold': item.minimumStock,
              'lastUpdate': DateTime.now(),
            },
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _inventory = mapped;
      });
    } catch (e) {
      debugPrint('Failed to load inventory from backend: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load inventory from server')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unique = _inventory; // use the raw inventory list (no deduplication)
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 520;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[50],

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshFromPull,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 🔸 LOW STOCK ALERT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final lowCount = unique
                              .where(
                                (item) =>
                                    (item['currentStock'] as int) <=
                                    (item['minThreshold'] as int),
                              )
                              .length;

                          if (constraints.maxWidth < 420) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning,
                                      color: Colors.orange,
                                      size: 26,
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Low Stock Alert',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.inventory_2,
                                      color: Colors.blue.shade700,
                                      size: 26,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    '$lowCount items below minimum',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Low Stock Alert:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$lowCount items',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.inventory_2,
                                color: Colors.blue.shade700,
                                size: 28,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // 🔸 INVENTORY COUNT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Total Medicines: ${unique.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              if (unique.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No inventory items found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = unique[index];
                      final currentStock = item['currentStock'] as int;
                      final minThreshold = item['minThreshold'] as int;
                      final isLowStock = currentStock <= minThreshold;
                      final lastUpdate = item['lastUpdate'] as DateTime;

                      Future<void> openRestockDialog() async {
                        final restockController = TextEditingController();

                        await showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Restock ${item['name']}'),
                            content: TextField(
                              controller: restockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                child: const Text('Restock'),
                                onPressed: () async {
                                  final qty =
                                      int.tryParse(restockController.text) ?? 0;
                                  if (qty <= 0) return;

                                  bool success = false;
                                  try {
                                    success = await client.dispenser
                                        .restockItem(
                                          itemId: item['id'],
                                          quantity: qty,
                                        );
                                  } catch (_) {
                                    success = false;
                                  }

                                  if (!context.mounted) return;
                                  Navigator.pop(context);

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✅ Stock updated successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    await _loadInventory();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '❌ Restock failed (permission or error)',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isNarrow
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isLowStock
                                                ? Colors.red.shade100
                                                : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: isLowStock
                                                  ? Colors.red
                                                  : Colors.green,
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.medication,
                                            color: isLowStock
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name'] as String,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isLowStock
                                                      ? Colors.red
                                                      : Colors.black,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '🕒 ${lastUpdate.day}/${lastUpdate.month}/${lastUpdate.year} ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isLowStock
                                              ? Icons.warning
                                              : Icons.check_circle,
                                          color: isLowStock
                                              ? Colors.orange
                                              : Colors.green,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Stock: $currentStock ${item['unit']} (Min: $minThreshold ${item['unit']})',
                                      style: TextStyle(
                                        color: isLowStock
                                            ? Colors.red
                                            : Colors.black87,
                                        fontWeight: isLowStock
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 40,
                                      child: OutlinedButton.icon(
                                        onPressed: openRestockDialog,
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Restock'),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: isLowStock
                                                ? Colors.orange
                                                : Colors.blue,
                                          ),
                                          foregroundColor: isLowStock
                                              ? Colors.orange
                                              : Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListTile(
                                isThreeLine: true,
                                dense: true,
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isLowStock
                                        ? Colors.red.shade100
                                        : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isLowStock
                                          ? Colors.red
                                          : Colors.green,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.medication,
                                    color: isLowStock
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                title: Text(
                                  item['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isLowStock
                                        ? Colors.red
                                        : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Stock: $currentStock ${item['unit']} (Min: $minThreshold ${item['unit']})',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isLowStock
                                              ? Colors.red
                                              : Colors.black,
                                          fontWeight: isLowStock
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '🕒 Last update: ${lastUpdate.day}/${lastUpdate.month}/${lastUpdate.year} ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 160,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isLowStock
                                              ? Icons.warning
                                              : Icons.check_circle,
                                          color: isLowStock
                                              ? Colors.orange
                                              : Colors.green,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            minimumSize: const Size(0, 32),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          onPressed: openRestockDialog,
                                          child: const Text(
                                            'Restock',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      );
                    }, childCount: unique.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
