import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:backend_client/backend_client.dart';

import '../core/date_time_utils.dart';
import '../routing/route_refresh.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with RouteRefreshMixin<HistoryScreen> {
  final Color primaryColor = const Color(0xFF00796B); // Deep Teal
  static const int _initialLoadCount = 10;
  static const int _loadMoreCount = 50;

  final List<InventoryAuditLog> _inventoryLogs = [];
  final List<AuditEntry> _allGeneralLogs = [];
  int _generalVisibleCount = 0;

  int _inventoryOffset = 0;
  bool _inventoryHasMore = true;
  bool _inventoryLoadingMore = false;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  Future<void> refreshOnFocus() async {
    await _refreshAll(showSpinner: false);
  }

  Future<void> _refreshAll({bool showSpinner = true}) async {
    if (!mounted) return;
    if (showSpinner) {
      setState(() {
        _loading = true;
        _inventoryLogs.clear();
        _allGeneralLogs.clear();
        _generalVisibleCount = 0;
        _inventoryOffset = 0;
        _inventoryHasMore = true;
        _inventoryLoadingMore = false;
      });
    }

    await Future.wait([_loadInitialInventory(), _loadAllGeneralLogs()]);

    if (!mounted) return;
    if (showSpinner) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadInitialInventory() async {
    try {
      final res = await client.adminInventoryEndpoints.getInventoryAuditLogs(
        _initialLoadCount,
        0,
      );
      res.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (!mounted) return;
      setState(() {
        _inventoryLogs
          ..clear()
          ..addAll(res);
        _inventoryOffset = _inventoryLogs.length;
        _inventoryHasMore = res.length == _initialLoadCount;
      });
    } catch (e) {
      debugPrint('Failed to load inventory logs: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load inventory history')),
      );
    }
  }

  Future<void> _loadMoreInventory() async {
    if (_inventoryLoadingMore || !_inventoryHasMore) return;
    if (!mounted) return;
    setState(() => _inventoryLoadingMore = true);

    try {
      final res = await client.adminInventoryEndpoints.getInventoryAuditLogs(
        _loadMoreCount,
        _inventoryOffset,
      );
      res.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (!mounted) return;
      setState(() {
        _inventoryLogs.addAll(res);
        _inventoryOffset = _inventoryLogs.length;
        _inventoryHasMore = res.length == _loadMoreCount;
      });
    } catch (e) {
      debugPrint('Failed to load more inventory logs: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load more inventory history')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _inventoryLoadingMore = false);
    }
  }

  Future<void> _loadAllGeneralLogs() async {
    try {
      final res = await client.adminEndpoints.getAuditLogs();
      res.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _allGeneralLogs
          ..clear()
          ..addAll(res);
        _generalVisibleCount = _allGeneralLogs.length < _initialLoadCount
            ? _allGeneralLogs.length
            : _initialLoadCount;
      });
    } catch (e) {
      debugPrint('General Audit load failed: $e');
    }
  }

  void _loadMoreGeneralLogs() {
    if (!mounted) return;
    setState(() {
      final next = _generalVisibleCount + _loadMoreCount;
      _generalVisibleCount = next > _allGeneralLogs.length
          ? _allGeneralLogs.length
          : next;
    });
  }

  // অ্যাকশন অনুযায়ী সহজ নাম দেওয়া
  String _mapActionType(String action) {
    switch (action) {
      case 'CREATE_ITEM':
        return 'create';
      case 'ADD_STOCK':
        return 'stock_in';
      case 'REMOVE_STOCK':
        return 'stock_out';
      case 'EDIT_MIN_THRESHOLD':
        return 'update';
      default:
        return 'admin_action';
    }
  }

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit_note;
      case 'stock_in':
        return Icons.arrow_circle_up;
      case 'stock_out':
        return Icons.arrow_circle_down;
      default:
        return Icons.history;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'stock_in':
        return Colors.lightGreen;
      case 'stock_out':
        return Colors.red;
      default:
        return primaryColor;
    }
  }

  String _toTitleCaseWords(String input) {
    final parts = input
        .trim()
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    return parts
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _prettyAction(String action) {
    // Keep existing readable actions as-is, otherwise prettify codes like EXPORT_PDF.
    if (action.contains(' ')) return action;
    return _toTitleCaseWords(action);
  }

  String _relativeTime(DateTime when) {
    final now = DateTime.now();
    final localWhen = when.toLocal();
    final diff = now.difference(localWhen);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd MMM yyyy').format(localWhen);
  }

  Widget _ssTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required DateTime time,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _relativeTime(time),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          backgroundColor: const Color(0xFF00695C), // AppBar color
          foregroundColor: Colors.white,
          centerTitle: true,

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white, //TabBar background
              child: const TabBar(
                labelColor: Color(0xFF00695C), // selected tab text
                unselectedLabelColor: Color(0xFF00695C),
                indicatorColor: Color(0xFF00695C), // indicator color
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Inventory Logs'),
                  Tab(text: 'General Logs'),
                ],
              ),
            ),
          ),
        ),

        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [_buildInventoryTab(), _buildGeneralAuditTab()],
              ),
      ),
    );
  }

  Widget _buildGeneralAuditTab() {
    if (_allGeneralLogs.isEmpty) {
      return const Center(child: Text("No general logs found"));
    }

    final hasMore = _generalVisibleCount < _allGeneralLogs.length;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _generalVisibleCount + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (hasMore && index == _generalVisibleCount) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: OutlinedButton(
                  onPressed: _loadMoreGeneralLogs,
                  child: const Text('Load more'),
                ),
              ),
            );
          }

          final log = _allGeneralLogs[index];

          final title = _prettyAction(log.action);
          final admin = (log.adminName?.trim().isNotEmpty ?? false)
              ? log.adminName!.trim()
              : 'Unknown';
          final target = (log.targetName?.trim().isNotEmpty ?? false)
              ? AppDateTime.formatMaybeIsoRange(log.targetName!.trim())
              : '';

          final subtitle = target.isEmpty
              ? 'By $admin'
              : 'By $admin • Target: $target';

          return _ssTile(
            icon: Icons.history,
            iconColor: const Color(0xFF00796B),
            iconBg: const Color(0xFF00796B).withOpacity(0.12),
            title: title,
            subtitle: subtitle,
            time: log.createdAt,
          );
        },
      ),
    );
  }

  Widget _buildInventoryTab() {
    if (_inventoryLogs.isEmpty) {
      return const Center(child: Text('No inventory history found'));
    }
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _inventoryLogs.length + (_inventoryHasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (_inventoryHasMore && index == _inventoryLogs.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _inventoryLoadingMore
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: _loadMoreInventory,
                        child: const Text('Load more'),
                      ),
              ),
            );
          }

          final item = _inventoryLogs[index];
          final action = item.action;
          final type = _mapActionType(action);

          final who = (item.userName?.trim().isNotEmpty ?? false)
              ? item.userName!.trim()
              : 'System Admin';

          final title = _toTitleCaseWords(type);
          final changeText =
              (item.oldQuantity != null && item.newQuantity != null)
              ? ' • Change: ${item.oldQuantity} → ${item.newQuantity}'
              : '';
          final subtitle = 'By $who$changeText';

          return _ssTile(
            icon: _getActionIcon(type),
            iconColor: _getIconColor(type),
            iconBg: _getIconColor(type).withOpacity(0.12),
            title: title,
            subtitle: subtitle,
            time: item.timestamp,
          );
        },
      ),
    );
  }
}
