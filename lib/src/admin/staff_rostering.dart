import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../routing/route_refresh.dart';

class StaffRostering extends StatefulWidget {
  const StaffRostering({super.key});

  @override
  State<StaffRostering> createState() => _StaffRosteringState();
}

class _StaffRosteringState extends State<StaffRostering>
    with RouteRefreshMixin<StaffRostering> {
  // ---------------- Tables ----------------
  final List<Map<String, dynamic>> _doctorTable = [];
  final List<Map<String, dynamic>> _nurseTable = [];
  final List<Map<String, dynamic>> _staffTable = [];

  // ---------------- Staff Users ----------------
  final List<Map<String, dynamic>> _doctorUsers = [];
  final List<Map<String, dynamic>> _nurseUsers = [];
  final List<Map<String, dynamic>> _staffUsers = [];

  // Name -> ID maps
  final Map<String, String> _doctorNameToId = {};
  final Map<String, String> _nurseNameToId = {};
  final Map<String, String> _staffNameToId = {};

  // Controllers and FocusNodes
  final Map<String, List<TextEditingController>> _controllers = {
    'doctor': [],
    'nurse': [],
    'staff': [],
  };
  final Map<String, List<FocusNode>> _focusNodes = {
    'doctor': [],
    'nurse': [],
    'staff': [],
  };

  Future<int> _getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    final idStr = prefs.getString('user_id') ?? '0';
    return int.tryParse(idStr) ?? 0;
  }

  // Loading and error states
  bool _loading = true;
  String? _loadError;

  // Track unsaved changes per table
  final Map<String, bool> _changed = {
    'doctor': false,
    'nurse': false,
    'staff': false,
  };

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  Future<void> refreshOnFocus() async {
    // Best-effort refresh. Keep existing in-memory edits intact.
    if (_changed.values.any((v) => v)) return;
    await _initData();
  }

  Future<void> _initData() async {
    await _fetchStaffUsers();
    if (!mounted) return;
    await _fetchRoster();
  }

  @override
  void dispose() {
    for (var list in _controllers.values) {
      for (var c in list) {
        try {
          c.dispose();
        } catch (_) {}
      }
    }
    for (var list in _focusNodes.values) {
      for (var f in list) {
        try {
          f.dispose();
        } catch (_) {}
      }
    }
    super.dispose();
  }

  // ---------------- Fetch Roster ----------------

  Future<void> _fetchStaffUsers() async {
    final List<Rosterlists> staff = await client.adminEndpoints.listStaff(1000);

    // Debug: print fetched staff summary and a small sample
    try {
      debugPrint('DEBUG_FETCH: listStaff returned ${staff.length} items');
      final sample = staff.take(10).map((s) {
        return {'name': s.name, 'userId': s.userId, 'role': s.role};
      }).toList();
      debugPrint('DEBUG_FETCH: listStaff sample: $sample');
    } catch (e) {
      debugPrint('DEBUG_FETCH: listStaff debug print failed: $e');
    }

    _doctorUsers.clear();
    _nurseUsers.clear();
    _staffUsers.clear();

    _doctorNameToId.clear();
    _nurseNameToId.clear();
    _staffNameToId.clear();

    for (final s in staff) {
      final label = '${s.name} (${s.userId})';

      final idStr = s.userId.toString();
      if (s.role.toUpperCase().contains('DOCTOR')) {
        _doctorUsers.add({'label': label, 'id': idStr});
        _doctorNameToId[label] = idStr;
      } else if (s.role.toUpperCase().contains('NURSE') ||
          s.role.toUpperCase().contains('DISPENSER')) {
        _nurseUsers.add({'label': label, 'id': idStr});
        _nurseNameToId[label] = idStr;
      } else {
        _staffUsers.add({'label': label, 'id': idStr});
        _staffNameToId[label] = idStr;
      }
    }
  }

  Future<void> _fetchRoster() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      _doctorTable.clear();
      _nurseTable.clear();
      _staffTable.clear();

      // keep suggestion user lists/maps populated by _fetchStaffUsers()
      // _doctorUsers/_nurseUsers/_staffUsers and name->id maps are not cleared here

      final List<Roster> rosterRows = await client.adminEndpoints.getRosters(
        null,
        null,
        null,
        includeDeleted: false,
      );

      // Debug: print fetched roster summary and a small sample
      try {
        final rSample = rosterRows.take(10).map((r) {
          return {
            'rosterId': r.rosterId,
            'staffId': r.staffId,
            'staffName': r.staffName,
            'staffRole': r.staffRole,
            'shiftDate': r.shiftDate.toString(),
          };
        }).toList();
        debugPrint('DEBUG_FETCH: getRosters sample: $rSample');
      } catch (e) {
        debugPrint('DEBUG_FETCH: getRosters debug print failed: $e');
      }

      for (final r in rosterRows) {
        final row = {
          'roster_id': r.rosterId?.toString(),
          'staff_id': r.staffId.toString(),
          'staff_name': r.staffName,
          'staff_role': r.staffRole.toUpperCase(),
          'shift_date': r.shiftDate,
          // normalize backend shift (MORNING, AFTERNOON, NIGHT) to UI values 'Day'/'Night'
          'shift': r.shift.toString().toUpperCase(),
        };

        if (r.staffRole == 'DOCTOR') {
          _doctorTable.add(row);
        } else if (r.staffRole == 'NURSE') {
          _nurseTable.add(row);
        } else {
          _staffTable.add(row);
        }
      }

      // Safely replace controllers/focusNodes: create new lists, set them, then dispose old ones
      final Map<String, List<TextEditingController>?> oldControllers = {};
      final Map<String, List<FocusNode>?> oldFocusNodes = {};

      for (var id in ['doctor', 'nurse', 'staff']) {
        oldControllers[id] = _controllers[id];
        oldFocusNodes[id] = _focusNodes[id];

        final table = _getTableById(id);
        final newControllers = table
            .map((r) => TextEditingController(text: r['staff_name'] ?? ''))
            .toList();
        final newFocusNodes = List.generate(
          newControllers.length,
          (_) => FocusNode(),
        );

        // Immediately assign new lists so the build will pick them up on next frame
        _controllers[id] = newControllers;
        _focusNodes[id] = newFocusNodes;
      }

      // Let the framework rebuild with new controllers, then dispose old ones to avoid used-after-dispose
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (var id in ['doctor', 'nurse', 'staff']) {
          final oldC = oldControllers[id];
          final oldF = oldFocusNodes[id];
          if (oldC != null) {
            for (final c in oldC) {
              try {
                c.dispose();
              } catch (_) {}
            }
          }
          if (oldF != null) {
            for (final f in oldF) {
              try {
                f.dispose();
              } catch (_) {}
            }
          }
        }
      });

      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  // ---------------- Helper Functions ----------------
  List<Map<String, dynamic>> _getTableById(String id) {
    if (id == 'doctor') return _doctorTable;
    if (id == 'nurse') return _nurseTable;
    return _staffTable;
  }

  List<String> _getSuggestions(String id) {
    if (id == 'doctor') {
      return _doctorUsers.map((e) => e['label'].toString()).toList();
    }
    if (id == 'nurse') {
      return _nurseUsers.map((e) => e['label'].toString()).toList();
    }
    return _staffUsers.map((e) => e['label'].toString()).toList();
  }

  void _updateRowData(String id, int idx, String label) {
    final table = _getTableById(id);
    if (idx >= table.length) return;

    debugPrint('DEBUG: Updating row $idx in $id with label: $label');

    String? staffId;
    if (id == 'doctor') staffId = _doctorNameToId[label];
    if (id == 'nurse') staffId = _nurseNameToId[label];
    if (id == 'staff') staffId = _staffNameToId[label];

    debugPrint('DEBUG: Extracted staffId: $staffId');

    table[idx]['staff_name'] = label;
    table[idx]['staff_id'] = staffId;
    _changed[id] = true;

    // UI রিফ্রেশ করতে setState কল করুন
    if (mounted) {
      setState(() {});
    }
  }

  // ---------------- Build Table Widget ----------------
  Widget _buildTable(String title, String id) {
    final tableData = _getTableById(id);
    final controllers = _controllers[id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(color: Colors.grey.shade400, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(3), // Name
            1: FlexColumnWidth(1), // (Morning)
            2: FlexColumnWidth(1), // (Afternoon)
            3: FlexColumnWidth(1), // র(Night)
            4: FixedColumnWidth(45), // Delete
          },
          children: [
            // Table Header
            const TableRow(
              decoration: BoxDecoration(color: Colors.blueGrey),
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'সকাল',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'বিকাল',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'রাত',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox.shrink(),
              ],
            ),
            // Rows
            ...tableData.asMap().entries.map((entry) {
              int idx = entry.key;
              var row = entry.value;
              String currentShift =
                  row['shift']?.toString().toUpperCase() ?? 'MORNING';

              return TableRow(
                children: [
                  // 1. Name Autocomplete Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue value) {
                        final suggestions = _getSuggestions(id);
                        // Always show all suggestions if field is empty
                        return suggestions.where((option) {
                          return option.toLowerCase().contains(
                            value.text.toLowerCase(),
                          );
                        });
                      },
                      onSelected: (String selection) {
                        controllers![idx].text = selection;
                        _updateRowData(id, idx, selection);
                      },
                      fieldViewBuilder:
                          (
                            context,
                            fieldController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            // Show suggestions immediately when field gains focus
                            focusNode.addListener(() {
                              if (focusNode.hasFocus) {
                                // hack: call setState to open options overlay
                                setState(() {});
                              }
                            });

                            // sync main controller
                            if (fieldController.text !=
                                controllers![idx].text) {
                              fieldController.text = controllers[idx].text;
                              fieldController.selection =
                                  TextSelection.collapsed(
                                    offset: fieldController.text.length,
                                  );
                            }

                            return TextField(
                              controller: fieldController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search staff...',
                              ),
                              onChanged: (val) {
                                controllers[idx].text = val;
                                _changed[id] = true;
                                setState(() {}); // refresh options overlay
                              },
                            );
                          },
                    ),
                  ),

                  // Morning Checkbox
                  _buildShiftCheckbox(id, idx, 'MORNING', currentShift),
                  // Afternoon Checkbox
                  _buildShiftCheckbox(id, idx, 'AFTERNOON', currentShift),
                  // Night Checkbox
                  _buildShiftCheckbox(id, idx, 'NIGHT', currentShift),
                  // Delete Button
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle,
                      color: Colors.redAccent,
                    ),
                    onPressed: () async {
                      final rosterId = row['roster_id'];
                      if (rosterId != null) {
                        final ok = await client.adminEndpoints.deleteRoster(
                          int.parse(rosterId),
                        );
                        if (ok) {
                          // --- অডিট লগ যোগ করুন ---
                          final currentAdminId = await _getAdminId();
                          await client.adminEndpoints.createAuditLog(
                            adminId: currentAdminId,
                            action: 'ROSTER_DELETED',
                            targetId:
                                rosterId as String, // কার রোস্টার কাটা হলো
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to delete from database'),
                            ),
                          );
                          return;
                        }
                      }
                      setState(() {
                        // Dispose and remove controller/focus corresponding to the row
                        final removedController = controllers!.removeAt(idx);
                        try {
                          removedController.dispose();
                        } catch (_) {}
                        final removedFocus = _focusNodes[id]!.removeAt(idx);
                        try {
                          removedFocus.dispose();
                        } catch (_) {}

                        tableData.removeAt(idx);
                        _changed[id] = true;
                      });
                    },
                  ),
                ],
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _changed[id]! ? () => _saveTable(id) : null,
              icon: const Icon(Icons.save),
              label: const Text('Save Roster'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                tableData.add({
                  'staff_name': '',
                  'shift': 'MORNING',
                  'staff_id': null,
                  'roster_id': null,
                  'shift_date': DateTime.now(),
                });
                controllers!.add(TextEditingController());
                _focusNodes[id]!.add(FocusNode());
                _changed[id] = true;
              }),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Staff'),
            ),
          ],
        ),
      ],
    );
  }

  // Helper to build checkboxes for shifts
  Widget _buildShiftCheckbox(
    String tableId,
    int rowIdx,
    String shiftValue,
    String currentShift,
  ) {
    return Checkbox(
      value: currentShift == shiftValue,
      activeColor: Colors.blue,
      onChanged: (val) {
        if (val == true) {
          setState(() {
            _getTableById(tableId)[rowIdx]['shift'] = shiftValue;
            _changed[tableId] = true;
          });
        }
      },
    );
  }

  // ---------------- Save Table ----------------
  Future<void> _saveTable(String id) async {
    final tableData = _getTableById(id);
    bool anyError = false;
    int savedCount = 0;

    for (final r in tableData) {
      final rosterId = r['roster_id']?.toString() ?? '';
      String? staffId = (r['staff_id'] ?? '')?.toString();
      final shiftType = (r['shift'] ?? 'MORNING').toString().toUpperCase();
      final shiftDate = r['shift_date'] is DateTime
          ? r['shift_date']
          : DateTime.tryParse(r['shift_date'].toString()) ?? DateTime.now();

      if ((staffId == null || staffId.isEmpty) &&
          r['staff_name'] != null &&
          r['staff_name'].toString().isNotEmpty) {}

      if (staffId == null || staffId.isEmpty) {
        anyError = true;
        continue;
      }

      try {
        final ok = await client.adminEndpoints.saveRoster(
          rosterId,
          staffId,
          shiftType,
          shiftDate,
          '',
          'SCHEDULED',
          null,
        );
        if (ok) {
          savedCount++;
          // --- অডিট লগ যোগ করুন ---
          final currentAdminId = await _getAdminId();
          await client.adminEndpoints.createAuditLog(
            adminId: currentAdminId,
            action: rosterId.isEmpty ? 'ROSTER_CREATED' : 'ROSTER_UPDATED',
            targetId: staffId, // কার ডিউটি দেওয়া হলো তার আইডি
          );
        } else {
          anyError = true;
        }
      } catch (_) {
        anyError = true;
      }
    }

    setState(() => _changed[id] = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          anyError
              ? '$id saved $savedCount rows, some failed'
              : '$id saved successfully',
        ),
      ),
    );

    await _fetchRoster();
  }

  // ---------------- Main Build ----------------
  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Staff Rostering'),
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_loadError != null)
                      Text(
                        _loadError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    _buildTable('Doctor Table', 'doctor'),
                    _buildTable('Nurse Table', 'nurse'),
                    _buildTable('Staff Table', 'staff'),
                  ],
                ),
              ),
      );
    } catch (e, st) {
      // Log detailed error to console for debugging
      debugPrint('BUILD ERROR in StaffRostering.build: $e\n$st');
      // Show user-friendly error in UI
      return Scaffold(
        appBar: AppBar(title: const Text('Staff Rostering - Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Render error: ${e.toString()}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (!mounted) return;
                  _fetchStaffUsers();
                  _fetchRoster();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
