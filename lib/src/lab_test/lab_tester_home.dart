// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'lab_test_create_and_upload.dart';
import 'lab_staff_profile.dart';
import 'manage_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backend_client/backend_client.dart';

import '../routing/route_refresh.dart';

class LabTesterHome extends StatefulWidget {
  const LabTesterHome({super.key});

  @override
  State<LabTesterHome> createState() => _LabTesterHomeState();
}

class _LabTesterHomeState extends State<LabTesterHome>
    with RouteRefreshMixin<LabTesterHome> {
  final GlobalKey<ManageTestState> _manageTestKey =
      GlobalKey<ManageTestState>();
  final GlobalKey<LabTestCreateAndUploadState> _uploadKey =
      GlobalKey<LabTestCreateAndUploadState>();
  int _selectedIndex = 0;
  final Color primaryColor = Colors.blueAccent;
  final List<int> _navigationHistory = [];

  // Lazy-load tabs to avoid duplicate network calls at startup.
  Widget? _uploadPage;
  Widget? _managePage;
  Widget? _profilePage;

  String name = '';
  String designation = '';
  String? profilePictureUrl;
  int _yearPendingCount = 0;
  int _yearSubmittedCount = 0;
  bool _homeLoading = false;
  String? _homeError;

  DateTime _summaryFrom = DateTime.now().subtract(const Duration(days: 365));
  DateTime _summaryTo = DateTime.now();

  List<_LabTestSummaryRow> _summaryRows = const [];

  bool _summaryRangeSelectedByUser = false;

  // Auth guard
  bool _checkingAuth = true;
  bool _authorized = false;

  int? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _verifyLabStaff();
    });
  }

  Future<void> _verifyLabStaff() async {
    if (!mounted) return;
    try {
      final authKey = await client.authenticationKeyManager?.get();
      if (authKey == null || authKey.isEmpty) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('user_id');
      if (storedUserId == null || storedUserId.isEmpty) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      final int? numericId = int.tryParse(storedUserId);
      if (numericId == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      String role = '';
      try {
        role = (await client.patient.getUserRole()).toUpperCase();
      } catch (e) {
        debugPrint('Failed to fetch user role: $e');
      }

      if (role == 'LABSTAFF' || role == 'LAB') {
        if (!mounted) return;
        setState(() {
          _authorized = true;
          _checkingAuth = false;
        });
        _userId = numericId;
        await _loadBasicProfile(numericId);
        await _loadHomeData();
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
    } catch (e) {
      debugPrint('Lab staff auth failed: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
      return;
    }
  }

  Future<void> _loadBasicProfile(int userId) async {
    if (!mounted) return;
    try {
      final profile = await client.lab.getStaffProfile();

      if (profile != null && mounted) {
        setState(() {
          name = profile.name;
          designation = profile.designation;
          profilePictureUrl = profile.profilePictureUrl;
        });
      }
    } catch (e) {
      debugPrint('Failed to load basic profile: $e');
    }
  }

  Future<void> _loadHomeData() async {
    await _loadHomeDataInternal(silent: false);
  }

  Future<void> _loadHomeDataInternal({required bool silent}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _homeLoading = true;
        _homeError = null;
      });
    }

    try {
      final allResults = await client.lab.getAllTestResults();
      final allTests = await client.lab.getAllLabTests();

      final range = _effectiveSummaryRange();

      int pending = 0;
      int submitted = 0;
      final Map<int, _LabTestCounts> byTest = <int, _LabTestCounts>{};

      for (final r in allResults) {
        final created = r.createdAt;
        final tid = r.testId;
        if (created == null) continue;
        if (created.isBefore(range.start) || created.isAfter(range.end)) {
          continue;
        }

        final counts = byTest.putIfAbsent(tid, () => _LabTestCounts());
        counts.total++;
        if (r.submittedAt == null) {
          counts.pending++;
          pending++;
        } else {
          counts.submitted++;
          submitted++;
        }
      }

      final Map<int, String> testNameById = <int, String>{
        for (final t in allTests)
          if (t.id != null)
            t.id!: (t.testName.isEmpty ? 'Test ${t.id}' : t.testName),
      };

      final rows = <_LabTestSummaryRow>[];
      for (final entry in byTest.entries) {
        final testId = entry.key;
        final c = entry.value;
        rows.add(
          _LabTestSummaryRow(
            testId: testId,
            testName: testNameById[testId] ?? 'Test $testId',
            total: c.total,
            pending: c.pending,
            submitted: c.submitted,
          ),
        );
      }

      rows.sort((a, b) {
        // pending first, then total desc, then name
        final p = b.pending.compareTo(a.pending);
        if (p != 0) return p;
        final t = b.total.compareTo(a.total);
        if (t != 0) return t;
        return a.testName.toLowerCase().compareTo(b.testName.toLowerCase());
      });

      if (!mounted) return;
      setState(() {
        _yearPendingCount = pending;
        _yearSubmittedCount = submitted;
        _summaryRows = rows;
        if (!silent) _homeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _homeError = e.toString();
          _homeLoading = false;
        });
      }
    }
  }

  @override
  Future<void> refreshOnFocus() async {
    if (_checkingAuth || !_authorized) return;
    final uid = _userId;
    if (uid != null) {
      await _loadBasicProfile(uid);
    }
    await _loadHomeDataInternal(silent: true);
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Home";
      case 1:
        return "Report Upload";
      case 2:
        return "Manage Test";
      case 3:
        return "Profile";
      default:
        return "";
    }
  }

  Widget _getBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _homeUI(),
        _uploadPage ?? const SizedBox.shrink(),
        _managePage ?? const SizedBox.shrink(),
        _profilePage ?? const SizedBox.shrink(),
      ],
    );
  }

  bool _ensureTabCreated(int index) {
    var created = false;
    if (index == 1 && _uploadPage == null) {
      _uploadPage = LabTestCreateAndUpload(key: _uploadKey);
      created = true;
    }
    if (index == 2 && _managePage == null) {
      _managePage = ManageTest(key: _manageTestKey);
      created = true;
    }
    if (index == 3 && _profilePage == null) {
      _profilePage = const LabTesterProfile();
      created = true;
    }
    return created;
  }

  Widget _homeUI() {
    final yearPending = _yearPendingCount.toString();
    final yearSubmitted = _yearSubmittedCount.toString();

    return RefreshIndicator(
      onRefresh: refreshFromPull,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.06 * 255).round()),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withAlpha(
                      (0.2 * 255).round(),
                    ),
                    backgroundImage:
                        (profilePictureUrl != null &&
                            profilePictureUrl!.isNotEmpty)
                        ? NetworkImage(profilePictureUrl!)
                        : null,
                    child:
                        (profilePictureUrl == null ||
                            profilePictureUrl!.isEmpty)
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Name',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          designation.isNotEmpty
                              ? designation
                              : 'Lab Technician',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              backgroundColor: Colors.brown,
                              label: Text(
                                'Today: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                return Wrap(
                  runSpacing: 12,
                  spacing: 12,
                  children: [
                    SizedBox(
                      width: isMobile
                          ? constraints.maxWidth
                          : constraints.maxWidth * 0.48,
                      child: _interactiveStat(
                        yearPending,
                        'Pending (Last 1 year)',
                        Icons.pending_actions,
                        Colors.red,
                        onTap: () =>
                            _openUploadAndHighlight(LabUploadFocus.pending),
                      ),
                    ),
                    SizedBox(
                      width: isMobile
                          ? constraints.maxWidth
                          : constraints.maxWidth * 0.48,
                      child: _interactiveStat(
                        yearSubmitted,
                        'Submitted (Last 1 year)',
                        Icons.task_alt,
                        Colors.blue,
                        onTap: () =>
                            _openUploadAndHighlight(LabUploadFocus.submitted),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 520;
                final controls = Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _homeLoading ? null : _pickSummaryFromDate,
                      child: Text('From: ${_formatDate(_summaryFrom)}'),
                    ),
                    TextButton(
                      onPressed: _homeLoading ? null : _pickSummaryToDate,
                      child: Text('To: ${_formatDate(_summaryTo)}'),
                    ),
                    IconButton(
                      tooltip: 'Export PDF',
                      onPressed: _homeLoading ? null : _exportSummaryPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      controls,
                    ],
                  );
                }

                return Row(
                  children: [
                    const Text(
                      'Test Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    controls,
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            if (_homeLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_homeError != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Failed: $_homeError',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _summaryRows.isEmpty
                    ? const ListTile(title: Text('No data found in this range'))
                    : Column(
                        children: _summaryRows
                            .map(
                              (row) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade50,
                                  child: const Icon(Icons.science),
                                ),
                                title: Text(
                                  row.testName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  'Total: ${row.total}   Pending: ${row.pending}   Submitted: ${row.submitted}',
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  DateTimeRange _effectiveSummaryRange() {
    final from = DateTime(
      _summaryFrom.year,
      _summaryFrom.month,
      _summaryFrom.day,
    );
    final to = DateTime(
      _summaryTo.year,
      _summaryTo.month,
      _summaryTo.day,
      23,
      59,
      59,
      999,
    );
    return DateTimeRange(start: from, end: to);
  }

  Future<void> _pickSummaryFromDate() async {
    DateTime? picked;
    try {
      picked = await showDatePicker(
        context: context,
        initialDate: _summaryFrom,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
    } catch (_) {
      return;
    }
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _summaryFrom = picked!;
      if (_summaryTo.isBefore(_summaryFrom)) {
        _summaryTo = _summaryFrom;
      }
      _summaryRangeSelectedByUser = true;
    });
    if (!mounted) return;
    await _loadHomeDataInternal(silent: true);
  }

  Future<void> _pickSummaryToDate() async {
    DateTime? picked;
    try {
      picked = await showDatePicker(
        context: context,
        initialDate: _summaryTo,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
    } catch (_) {
      return;
    }
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _summaryTo = picked!;
      if (_summaryTo.isBefore(_summaryFrom)) {
        _summaryFrom = _summaryTo;
      }
      _summaryRangeSelectedByUser = true;
    });
    if (!mounted) return;
    await _loadHomeDataInternal(silent: true);
  }

  Future<void> _exportSummaryPdf() async {
    if (!_summaryRangeSelectedByUser) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select From and To dates first')),
      );
      return;
    }

    final rows = List<_LabTestSummaryRow>.from(_summaryRows);
    final range = _effectiveSummaryRange();

    if (rows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data found in this date range')),
      );
      return;
    }

    final fontData = await rootBundle.load('assets/fonts/Kalpurush.ttf');
    if (!mounted) return;
    final baseFont = pw.Font.ttf(fontData);
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: baseFont,
        italic: baseFont,
        boldItalic: baseFont,
      ),
    );

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Lab Test Summary',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Range: ${_formatDate(range.start)} - ${_formatDate(range.end)}',
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: const ['Test', 'Total', 'Pending', 'Submitted'],
            data: rows
                .map(
                  (r) => [
                    r.testName,
                    r.total.toString(),
                    r.pending.toString(),
                    r.submitted.toString(),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    if (!mounted) return;
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: 'lab_test_summary.pdf');
    } else {
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'lab_test_summary.pdf',
      );
    }
  }

  void _openUploadAndHighlight(LabUploadFocus focus) {
    if (!mounted) return;

    final uploadWasCreated = _uploadPage != null;
    final createdNow = _ensureTabCreated(1);

    // Switch to Upload tab (reuse existing page)
    if (_selectedIndex != 1) {
      _navigationHistory.add(_selectedIndex);
    }
    setState(() {
      _selectedIndex = 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure latest data is present (avoid double fetch on first creation)
      if (uploadWasCreated && !createdNow) {
        _uploadKey.currentState?.fetchResults();
        _uploadKey.currentState?.fetchTests();
      }
      _uploadKey.currentState?.focusOn(focus);
    });
  }

  // Helper: interactive stat card
  Widget _interactiveStat(
    String count,
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withAlpha((0.12 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$count items',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.14 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_authorized) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    final scaffold = Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          if (_selectedIndex == 2) ...[
            IconButton(
              tooltip: "Add New Test",
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.blueAccent,
              ),
              onPressed: () {
                _manageTestKey.currentState?.openTestDialog();
              },
            ),
          ],
        ],
      ),

      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index != _selectedIndex) {
            _navigationHistory.add(_selectedIndex);
            final wasUploadCreated = _uploadPage != null;
            final wasManageCreated = _managePage != null;
            final wasProfileCreated = _profilePage != null;

            final createdNow = _ensureTabCreated(index);
            setState(() => _selectedIndex = index);

            // Auto-refresh the newly selected tab (no manual refresh icons).
            if (index == 0) {
              _loadHomeDataInternal(silent: true);
            } else if (index == 1) {
              // If first time created, its initState already fetches.
              if (wasUploadCreated && !createdNow) {
                _uploadKey.currentState?.fetchResults();
                _uploadKey.currentState?.fetchTests();
              }
            } else if (index == 2) {
              if (wasManageCreated && !createdNow) {
                _manageTestKey.currentState?.fetchData();
              }
            } else if (index == 3) {
              // Profile tab: RouteRefreshMixin will refresh on resume/return.
              // Lazy-loaded to avoid duplicate profile fetch at startup.
              if (wasProfileCreated && !createdNow) {
                // no-op
              }
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload),
            label: "Upload",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: "ManageTest",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );

    // Web: avoid PopScope/WillPopScope wrappers (browser back stack differs
    // and these wrappers sometimes contribute to disposed-view issues in debug).
    if (kIsWeb) {
      return scaffold;
    }

    return WillPopScope(
      onWillPop: () async {
        // If we have navigation history inside the bottom nav, consume the back
        // action by navigating to the previous index instead of exiting the app.
        if (_navigationHistory.isNotEmpty) {
          setState(() {
            _selectedIndex = _navigationHistory.removeLast();
          });
          return false; // handled
        }

        // No more internal history -> confirm exit
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit app'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        return shouldExit == true;
      },
      child: PopScope(
        canPop: _navigationHistory.isEmpty,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_navigationHistory.isNotEmpty) {
            setState(() {
              _selectedIndex = _navigationHistory.removeLast();
            });
          }
        },
        child: scaffold,
      ),
    );
  }
}

class _LabTestCounts {
  int total = 0;
  int pending = 0;
  int submitted = 0;
}

class _LabTestSummaryRow {
  const _LabTestSummaryRow({
    required this.testId,
    required this.testName,
    required this.total,
    required this.pending,
    required this.submitted,
  });

  final int testId;
  final String testName;
  final int total;
  final int pending;
  final int submitted;
}
