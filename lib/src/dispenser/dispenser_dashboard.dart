import 'package:flutter/material.dart';
import 'dispenser_medicine_item.dart';
import 'dispenser_profile.dart';
import 'dispenser_inventory.dart';
import 'package:backend_client/backend_client.dart';

import '../core/date_time_utils.dart';
import '../routing/route_refresh.dart';
import 'package:intl/intl.dart';

// Use Map-based structures for prescriptions and logs to avoid custom classes
typedef PrescriptionMap = Map<String, dynamic>;
typedef DispenseLogMap = Map<String, dynamic>;

class DispenserDashboard extends StatefulWidget {
  const DispenserDashboard({super.key});

  @override
  State<DispenserDashboard> createState() => _DispenserDashboardState();
}

class _DispenserDashboardState extends State<DispenserDashboard>
    with RouteRefreshMixin<DispenserDashboard> {
  final _searchController = TextEditingController();
  final ScrollController _homeScrollController = ScrollController();
  final GlobalKey _recentHeaderKey = GlobalKey();
  PrescriptionMap? _currentPrescription;
  bool _isLoading = false;
  int _selectedIndex = 0;
  String _searchQuery = '';
  bool _authChecked = false;
  bool _authorized = false;

  final List<int> _navigationHistory = [0]; // Track tab navigation

  static const _brandTeal = Color(0xFF1F9E98);

  DispenserProfileR? _profile;
  bool _homeLoading = false;
  List<DispenseHistoryEntry> _dispenseHistory = [];
  List<InventoryAuditLog> stockHistory = [];
  bool stockHistoryLoading = false;

  static const int _initialHistoryVisibleCount = 10;
  static const int _readMoreStep = 20;
  int _visibleRecentCount = _initialHistoryVisibleCount;
  int _visibleStockCount = _initialHistoryVisibleCount;

  bool _highlightTodayInRecent = false;

  final List<PrescriptionMap> _allPrescriptions = [];

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();

    final s = v.toString().trim();
    if (s.isEmpty) return 0;

    // New DB format: 1+0+1 => sum = 2
    if (s.contains('+')) {
      final parts = s.split('+').map((p) => p.trim()).toList();
      if (parts.isNotEmpty && parts.every((p) => p == '0' || p == '1')) {
        return parts.fold<int>(0, (sum, p) => sum + (p == '1' ? 1 : 0));
      }
    }

    // Legacy/text format: count occurrences
    final lower = s.toLowerCase();
    var count = 0;
    if (lower.contains('সকাল') || lower.contains('morning')) count++;
    if (lower.contains('দুপুর') || lower.contains('noon')) count++;
    if (lower.contains('রাত') || lower.contains('night')) count++;
    if (count > 0) return count;

    // Fallback: first integer in string
    final m = RegExp(r'\d+').firstMatch(s);
    if (m != null) {
      return int.tryParse(m.group(0)!) ?? 0;
    }

    return 0;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await _verifyDispenser();
      if (!mounted) return;

      setState(() {
        _authorized = ok;
        _authChecked = true;
      });

      if (ok) {
        await Future.wait([_loadPendingPrescriptions(), _loadHome()]);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  bool _isSameLocalDay(DateTime a, DateTime b) {
    final aa = a.toLocal();
    final bb = b.toLocal();
    return aa.year == bb.year && aa.month == bb.month && aa.day == bb.day;
  }

  void _highlightTodayDispenses() {
    if (!mounted) return;

    final now = DateTime.now();
    final todayCount = _last7DaysDispenses()
        .where((d) => _isSameLocalDay(d.dispensedAt, now))
        .length;

    setState(() {
      _highlightTodayInRecent = true;
      final minVisible = todayCount > _initialHistoryVisibleCount
          ? todayCount
          : _initialHistoryVisibleCount;
      if (_visibleRecentCount < minVisible) {
        _visibleRecentCount = minVisible;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _recentHeaderKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    });
  }

  void _openDispenseFromHome() {
    if (!mounted) return;
    if (_selectedIndex == 1) return;

    if (_navigationHistory.isEmpty || _navigationHistory.last != 1) {
      _navigationHistory.add(1);
    }
    setState(() {
      _selectedIndex = 1;
      _currentPrescription = null; // always show the list first
    });
  }

  void _showDispenseHistoryDetails(DispenseHistoryEntry entry) {
    final when = AppDateTime.formatLocalDateTime(
      entry.dispensedAt,
      pattern: 'dd/MM/yyyy HH:mm',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rx #${entry.prescriptionId}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.patientName} (${entry.mobileNumber})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text('Dispensed: $when'),
                const SizedBox(height: 12),
                const Text(
                  'Medicines',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (entry.items.isEmpty)
                  Text(
                    'No items',
                    style: TextStyle(color: Colors.grey.shade700),
                  )
                else
                  Column(
                    children: List.generate(entry.items.length, (index) {
                      final it = entry.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.medicineName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (it.isAlternative)
                                        Text(
                                          'Alternative',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '× ${it.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (index != entry.items.length - 1)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Divider(height: 1),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool> _verifyDispenser() async {
    try {
      final authKey = await client.authenticationKeyManager?.get();
      // সেশন না থাকলে সাথে সাথে বের হয়ে যাবে, কোনো এরর মেসেজ দেখাবে না
      if (authKey == null || authKey.isEmpty) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
        return false;
      }

      String role = '';
      try {
        role = (await client.patient.getUserRole()).toUpperCase();
      } catch (_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
        return false;
      }

      if (role == 'DISPENSER' || role == 'NURSE') return true;

      if (mounted) Navigator.pushReplacementNamed(context, '/');
      return false;
    } catch (_) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      return false;
    }
  }

  Future<void> _loadHome({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() => _homeLoading = true);
    }

    try {
      final results = await Future.wait([
        client.dispenser.getDispenserProfile(),
        client.dispenser.getDispenserDispenseHistory(limit: 30),
        client.dispenser.getDispenserHistory(),
      ]);

      final profile = results[0] as DispenserProfileR?;
      final dispenseHistory = results[1] as List<DispenseHistoryEntry>;
      final logs = results[2] as List<InventoryAuditLog>;

      final since = DateTime.now().subtract(const Duration(days: 30));
      final filtered = logs.where((x) => x.timestamp.isAfter(since)).toList();

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _dispenseHistory = dispenseHistory;
        stockHistory = filtered;
        stockHistoryLoading = false;
        _homeLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load home data: $e');
      if (!mounted) return;
      if (!silent) {
        setState(() => _homeLoading = false);
      }
    }
  }

  // Fetch pending prescriptions from backend
  Future<void> _loadPendingPrescriptions({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final serverList = await client.dispenser.getPendingPrescriptions();

      // Map exactly what backend sends
      final mapped = serverList.map((p) {
        return <String, dynamic>{
          'id': (p.id ?? 0).toString(),
          'patientId': p.patientId,
          'name': p.name ?? '',
          'doctorId': p.doctorId,
          'doctorName': p.doctorName ?? '',
          'mobileNumber': p.mobileNumber ?? '',
          'prescriptionDate': p.prescriptionDate,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _allPrescriptions
          ..clear()
          ..addAll(mapped);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load pending prescriptions: $e');
      if (!mounted) return;
      if (!silent) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load prescriptions from server'),
          ),
        );
      }
    }
  }

  @override
  Future<void> refreshOnFocus() async {
    if (!_authChecked || !_authorized) return;

    // Clear any one-off highlight when coming back to this screen.
    if (mounted && _highlightTodayInRecent) {
      setState(() => _highlightTodayInRecent = false);
    }
    await Future.wait([
      _loadPendingPrescriptions(silent: true),
      _loadHome(silent: true),
    ]);
  }

  Future<void> _selectPrescription(PrescriptionMap localPres) async {
    setState(() => _isLoading = true);

    try {
      final presId = int.parse(localPres['id']);
      final detail = await client.dispenser.getPrescriptionDetail(presId);

      if (detail == null || detail.items.isEmpty) {
        debugPrint('No prescription items found for ID $presId');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No prescription items found')),
        );
        return;
      }

      final List<Medicine> meds = [];

      for (final it in detail.items) {
        final int dosage = _toInt(it.dosageTimes);
        final int duration = _toInt(it.duration);
        final int prescribedQty = dosage * duration;

        // getStockByFirstWord দিয়ে inventory match
        final stockInfo = await client.dispenser.getStockByFirstWord(
          it.medicineName,
        );
        // Only set originalItemId if it exists in inventory
        final int? originalId = stockInfo != null ? it.itemId : null;
        meds.add(
          Medicine(
            itemId: stockInfo?.itemId, // match পেলে itemId, না পেলে null
            name: it.medicineName,
            stock: stockInfo?.currentQuantity ?? 0,
            dose: '$dosage × $duration',
            prescribedQty: prescribedQty,
            dispenseQty: prescribedQty,
            isAlternative: false,
            originalItemId: originalId, // মূল prescription এর id
          ),
        );
      }

      setState(() {
        localPres['medicines'] = meds;
        localPres['status'] = 'pending';
        _currentPrescription = localPres;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> loadStockHistory() async {
    if (!mounted) return;
    setState(() => stockHistoryLoading = true);

    try {
      final logs = await client.dispenser.getDispenserHistory();
      final since = DateTime.now().subtract(const Duration(days: 30));
      final filtered = logs.where((x) => x.timestamp.isAfter(since)).toList();

      if (!mounted) return;
      setState(() {
        stockHistory = filtered;
        stockHistoryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => stockHistoryLoading = false);
      debugPrint('Failed to load stock history: $e');
    }
  }

  Future<void> _dispensePrescription() async {
    final meds = _currentPrescription!['medicines'] as List<Medicine>;

    String _cleanServerMessage(Object e) {
      final s = e.toString();
      // Common wrappers: "Exception: ..." / "ServerpodClientException: ..."
      final idx = s.indexOf('Exception:');
      if (idx >= 0) return s.substring(idx + 'Exception:'.length).trim();
      return s.trim();
    }

    final List<DispenseItemRequest> items = [];
    final List<String> issues = [];

    for (var m in meds) {
      if (m.dispenseQty <= 0) {
        continue;
      }

      if (m.itemId == null) {
        issues.add('No stock available for ${m.name}');
        continue;
      }

      // Local stock check (server will still verify with locking).
      if (m.stock < m.dispenseQty) {
        issues.add(
          'Insufficient stock for ${m.name} (available ${m.stock}, need ${m.dispenseQty})',
        );
        continue;
      }

      int? originalId;

      if (m.originalItemId != null) {
        // check inventory before assigning FK
        final stockCheck = await client.dispenser.getStockByFirstWord(m.name);
        if (stockCheck != null && stockCheck.itemId == m.originalItemId) {
          originalId = m.originalItemId;
        } else {
          originalId = null; // inventory তে নেই → FK skip
        }
      }

      items.add(
        DispenseItemRequest(
          itemId: m.itemId!,
          medicineName: m.name,
          quantity: m.dispenseQty,
          isAlternative: m.isAlternative,
          originalMedicineId: originalId, // only safe ID
        ),
      );
    }

    if (issues.isNotEmpty) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot dispense'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: issues
                    .take(8)
                    .map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $t'),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medicines selected for dispensing')),
      );
      return;
    }

    try {
      final success = await client.dispenser.dispensePrescription(
        prescriptionId: int.parse(_currentPrescription!['id']),
        // Backend uses authenticated session userId; do not send device/userId.
        dispenserId: 0,
        items: items,
      );

      if (success) {
        await Future.wait([_loadPendingPrescriptions(), _loadHome()]);
        if (mounted) setState(() => _currentPrescription = null);
      } else {
        // Should be rare now (backend throws on failure), but keep a fallback.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispense failed. Please try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = _cleanServerMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Dispense failed' : msg)),
      );
    }
  }

  void _updateMedicine(Medicine updatedMed) {
    final meds = (_currentPrescription!['medicines'] as List<Medicine>);
    final index = meds.indexWhere((m) => m.itemId == updatedMed.itemId);

    if (index != -1) {
      setState(() => meds[index] = updatedMed);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _visibleRecentCount = _initialHistoryVisibleCount;
      _visibleStockCount = _initialHistoryVisibleCount;
      _highlightTodayInRecent = false;
    });
    await Future.wait([_loadPendingPrescriptions(), _loadHome()]);
    // ensure stock history also refreshes
    await loadStockHistory();
  }

  int _countDispensedToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _dispenseHistory
        .where(
          (d) => d.dispensedAt.isAfter(start) && d.dispensedAt.isBefore(end),
        )
        .length;
  }

  List<DispenseHistoryEntry> _last7DaysDispenses() {
    final since = DateTime.now().subtract(const Duration(days: 7));
    return _dispenseHistory.where((d) => d.dispensedAt.isAfter(since)).toList();
  }

  Widget _statCard({
    required String text,
    required IconData icon,
    required Color background,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: card,
      ),
    );
  }

  Widget _buildHome() {
    final profile = _profile;
    final pending = _allPrescriptions.length;
    final dispensedToday = _countDispensedToday();
    final recentAll = _last7DaysDispenses()
      ..sort((a, b) => b.dispensedAt.compareTo(a.dispensedAt));
    final recentVisible = recentAll.take(_visibleRecentCount).toList();
    final canReadMoreRecent = recentVisible.length < recentAll.length;

    final stockAll = List<InventoryAuditLog>.from(stockHistory)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final stockVisible = stockAll.take(_visibleStockCount).toList();
    final canReadMoreStock = stockVisible.length < stockAll.length;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        controller: _homeScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 110),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage:
                        (profile?.profilePictureUrl != null &&
                            (profile!.profilePictureUrl!.isNotEmpty))
                        ? NetworkImage(profile.profilePictureUrl!)
                        : null,
                    child:
                        (profile?.profilePictureUrl == null ||
                            profile!.profilePictureUrl!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (profile?.name ?? 'Dispenser'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (profile?.email ?? ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_homeLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              ),

            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 720;
                if (stack) {
                  return Column(
                    children: [
                      _statCard(
                        text: 'Pending Prescriptions $pending',
                        icon: Icons.access_time,
                        background: const Color(0xFFF7F1E6),
                        iconBg: const Color(0xFFF3DDB1),
                        iconColor: const Color(0xFFF59E0B),
                        onTap: _openDispenseFromHome,
                      ),

                      const SizedBox(height: 12),
                      _statCard(
                        text: 'Dispensed Today $dispensedToday',
                        icon: Icons.check_circle,
                        background: const Color(0xFFEAF7EF),
                        iconBg: const Color(0xFFBFE8CC),
                        iconColor: const Color(0xFF16A34A),
                        onTap: _highlightTodayDispenses,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        text: 'Pending Prescriptions   $pending',
                        icon: Icons.access_time,
                        background: const Color(0xFFF7F1E6),
                        iconBg: const Color(0xFFF3DDB1),
                        iconColor: const Color(0xFFF59E0B),
                        onTap: _openDispenseFromHome,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        text: 'Dispensed Today   $dispensedToday',
                        icon: Icons.check_circle,
                        background: const Color(0xFFEAF7EF),
                        iconBg: const Color(0xFFBFE8CC),
                        iconColor: const Color.fromARGB(255, 86, 86, 86),
                        onTap: _highlightTodayDispenses,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),
            Text(
              key: _recentHeaderKey,
              'Recent History (Last 7 Days)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 10),

            if (recentAll.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'No activity in last 7 days',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentVisible.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final d = recentVisible[index];
                    final isToday = _isSameLocalDay(
                      d.dispensedAt,
                      DateTime.now(),
                    );
                    final highlight = _highlightTodayInRecent && isToday;
                    const highlightBg = Color(0xFFFFF3B0); // strong yellow
                    final itemsText = d.items.isEmpty
                        ? 'No items'
                        : d.items
                              .take(3)
                              .map((i) => '${i.medicineName} × ${i.quantity}')
                              .join(', ');
                    final moreCount = d.items.length - 3;
                    final subtitle = moreCount > 0
                        ? '$itemsText +$moreCount more'
                        : itemsText;

                    return Material(
                      color: highlight ? highlightBg : Colors.transparent,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: highlight
                              ? const Color(0xFFFFE08A)
                              : Colors.orange.withOpacity(0.12),
                          child: Icon(
                            Icons.outbox,
                            color: highlight
                                ? const Color(0xFF8A5B00)
                                : Colors.orange,
                          ),
                        ),
                        title: Text(
                          d.patientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Rx #${d.prescriptionId} • $subtitle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(d.dispensedAt.toLocal()),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        onTap: () => _showDispenseHistoryDetails(d),
                      ),
                    );
                  },
                ),
              ),

            if (canReadMoreRecent) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _visibleRecentCount =
                          (_visibleRecentCount + _readMoreStep).clamp(
                            0,
                            recentAll.length,
                          );
                    });
                  },
                  child: const Text('Read more'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Stock History (Last 1 Month)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 10),

            if (stockHistoryLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (stockHistory.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'No stock activity in last 30 days',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stockVisible.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final h = stockVisible[index];

                    final title = h.userName ?? 'Unknown Item';
                    final action = h.action;
                    final oldQ = h.oldQuantity ?? 0;
                    final newQ = h.newQuantity ?? 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.12),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '$action • $oldQ → $newQ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        DateFormat('dd/MM/yyyy').format(h.timestamp.toLocal()),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  },
                ),
              ),

            if (canReadMoreStock) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _visibleStockCount = (_visibleStockCount + _readMoreStep)
                          .clamp(0, stockAll.length);
                    });
                  },
                  child: const Text('Read more'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_navigationHistory.isNotEmpty) {
      setState(() {
        _selectedIndex = _navigationHistory.removeLast();
      });
      return false;
    } else {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            "Exit App Confirmation",
            textAlign: TextAlign.center,
          ),
          content: const Text("Do you want to exit?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes"),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
  }

  Widget _buildSearchSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final contentWidth = maxWidth > 920 ? 920.0 : maxWidth;

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: contentWidth,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by patient name or mobile',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.trim().isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  final q = v.trim();
                  if (q == _searchQuery) return;
                  setState(() => _searchQuery = q);
                },
                onSubmitted: (_) => _searchPrescription(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispenseControls() {
    final q = _searchQuery.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final contentWidth = maxWidth > 920 ? 920.0 : maxWidth;

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: contentWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (q.isNotEmpty)
                    ActionChip(
                      label: const Text('Clear Search'),
                      avatar: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageHeader({
    required String title,
    String? subtitle,
    List<Widget> actions = const [],
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final contentWidth = maxWidth > 920 ? 920.0 : maxWidth;

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: contentWidth,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_brandTeal, Color(0xFF38B8B2)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDispenseTab() {
    final pending = _allPrescriptions.length;
    final subtitle = pending == 0
        ? 'No pending prescriptions'
        : '$pending pending prescriptions';

    return SafeArea(
      child: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            _buildPageHeader(
              title: 'Dispense',
              subtitle: subtitle,
              actions: const [],
            ),
            _buildSearchSection(),
            _buildDispenseControls(),
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _currentPrescription != null
                    ? KeyedSubtree(
                        key: const ValueKey('details'),
                        child: _buildPrescriptionView(),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('list'),
                        child: _buildAllPrescriptionsList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  Widget _prescriptionCard(PrescriptionMap prescription) {
    final id = prescription['id'];
    final patient = (prescription['name'] ?? '').toString();
    final doctor = (prescription['doctorName'] ?? '').toString();
    final mobile = (prescription['mobileNumber'] ?? '').toString();
    final date = _tryParseDate(prescription['prescriptionDate']);

    final dateText = date == null
        ? ''
        : '${date.day}/${date.month}/${date.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _selectPrescription(prescription),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Prescription #$id',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          _pill(
                            icon: Icons.schedule,
                            label: 'Pending',
                            bg: const Color(0xFFFFF7ED),
                            fg: const Color(0xFFEA580C),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Patient: $patient',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      Text(
                        'Doctor: $doctor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      if (mobile.isNotEmpty)
                        Text(
                          'Mobile: $mobile',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      if (dateText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateText,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navIconWithBadge(IconData icon, int badgeCount) {
    if (badgeCount <= 0) return Icon(icon);

    final text = badgeCount > 99 ? '99+' : badgeCount.toString();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -10,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _searchPrescription() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search by prescription ID, patient name, or mobile'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = searchTerm;
    });

    // Filter locally first; server-side search not implemented in endpoint
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _isLoading = false);
  }

  Widget _buildPrescriptionView() {
    if (_currentPrescription == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a prescription to begin dispensing',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add a back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    _currentPrescription = null; // go back to list
                  });
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Prescription Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prescription #${_currentPrescription!['id']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(
                          _currentPrescription!['status']
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor:
                            _currentPrescription!['status'] == 'completed'
                            ? Colors.green
                            : Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Patient: ${_currentPrescription!['name']}'),
                  Text('Doctor: ${_currentPrescription!['doctorName']}'),
                  if (_currentPrescription!['prescriptionDate'] != null)
                    Builder(
                      builder: (_) {
                        final d = _currentPrescription!['prescriptionDate'];
                        if (d is DateTime) {
                          return Text('Date: ${AppDateTime.formatDateOnly(d)}');
                        }
                        return Text('Date: ${d.toString()}');
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_currentPrescription!['status'] == 'pending') ...[
            const Text(
              'Medicines to Dispense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(_currentPrescription!['medicines'] as List<Medicine>)
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final med = entry.value;
                  return MedicineItem(
                    client: client,
                    key: ValueKey('${med.itemId}-$index'),
                    medicine: med,
                    onChanged: _updateMedicine,
                  );
                }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _dispensePrescription,
                icon: const Icon(Icons.medication, color: Colors.white),
                label: const Text(
                  'Dispense Prescription',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.green[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'This prescription has been dispensed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllPrescriptionsList() {
    final q = _searchQuery.trim().toLowerCase();
    final prescriptions =
        (q.isEmpty
                ? _allPrescriptions
                : _allPrescriptions.where((prescription) {
                    final id = (prescription['id'] ?? '')
                        .toString()
                        .toLowerCase();
                    final name = (prescription['name'] ?? '')
                        .toString()
                        .toLowerCase();
                    final doctor = (prescription['doctorName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final mobile = (prescription['mobileNumber'] ?? '')
                        .toString()
                        .toLowerCase();
                    return id.contains(q) ||
                        name.contains(q) ||
                        doctor.contains(q) ||
                        mobile.contains(q);
                  }))
            .toList();

    if (prescriptions.isEmpty) {
      return Center(
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No prescriptions found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: prescriptions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final prescription = prescriptions[index];
          return _prescriptionCard(prescription);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_authorized) {
      return const Scaffold(); // empty, redirect already done
    }

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,

        body: IndexedStack(
          index: _selectedIndex,
          children: [
            SafeArea(child: _buildHome()),
            _buildDispenseTab(),
            const InventoryManagement(),
            const DispenserProfile(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (_navigationHistory.isEmpty ||
                _navigationHistory.last != index) {
              _navigationHistory.add(index);
            }

            setState(() {
              _selectedIndex = index;
              // If user navigates away and returns, don't keep highlight stuck.
              _highlightTodayInRecent = false;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _brandTeal,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _navIconWithBadge(
                Icons.medical_services,
                _allPrescriptions.length,
              ),
              label: 'Dispense',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Inventory',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
