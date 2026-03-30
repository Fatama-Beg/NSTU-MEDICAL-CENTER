import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routing/route_refresh.dart';

class PatientLabTestAvailability extends StatefulWidget {
  const PatientLabTestAvailability({super.key});

  @override
  State<PatientLabTestAvailability> createState() =>
      _PatientLabTestAvailabilityState();
}

class _PatientLabTestAvailabilityState extends State<PatientLabTestAvailability>
    with RouteRefreshMixin<PatientLabTestAvailability> {
  final Color kPrimaryColor = const Color(0xFF00796B);

  // Fetched from backend (generated DTO LabTests)
  List<LabTests> labTestsDB = [];

  String _role = ''; // uppercase role: STUDENT, TEACHER, etc.
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Future<void> refreshOnFocus() async {
    await _loadData(showSnackBar: false);
  }

  Future<void> _loadData({bool showSnackBar = true}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('user_id');

      // Fetch role: client.patient.getUserRole expects an int (numeric DB user_id).
      // If we have a numeric id stored, use it; otherwise treat as OUTSIDE.
      if (storedUserId != null && storedUserId.isNotEmpty) {
        final int? numericId = int.tryParse(storedUserId);
        if (numericId != null) {
          try {
            final role = await client.patient.getUserRole();
            _role = role.isEmpty ? '' : role.toUpperCase();
          } catch (e) {
            debugPrint('Failed to fetch role using numeric id: $e');
            _role = '';
          }
        } else {
          // Non-numeric stored id (maybe legacy email). Treat as OUTSIDE.
          debugPrint('Stored user_id is not numeric; treating as OUTSIDE.');
          _role = '';
        }
      } else {
        _role = '';
      }

      // Fetch tests from backend (returns List<LabTests>)
      final tests = await client.patient.listTests();
      if (!mounted) return;

      setState(() {
        labTestsDB = tests;
      });

      // Provide immediate visible feedback so it's clear something happened
      if (showSnackBar) {
        try {
          final fetchedCount = tests.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fetched $fetchedCount tests (role: ${_role.isEmpty ? 'OUTSIDE' : _role})',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {
          // ignore if context unavailable
        }
      }
    } catch (e, st) {
      debugPrint('Failed to load tests: $e\n$st');
      if (mounted && showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tests: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        _error = 'Failed to load tests. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Lab Test Costs",
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshFromPull,
              child: _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Center(child: Text(_error!)),
                      ],
                    )
                  : labTestsDB.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No tests found',
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Role: ${_role.isEmpty ? 'UNKNOWN/OUTSIDE' : _role}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fetched: ${labTestsDB.length} tests',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  await _loadData();
                                },
                                child: const Text('Retry'),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  debugPrint(
                                    'DEBUG: labTestsDB content => ${labTestsDB.toString()}',
                                  );
                                },
                                child: const Text('Show debug in console'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: labTestsDB.length,
                      itemBuilder: (context, index) {
                        final LabTests test = labTestsDB[index];
                        final String name = test.testName;
                        final String description = test.description;
                        final bool available = test.available;

                        double feeVal;
                        if (_role.contains('STUDENT')) {
                          feeVal = test.studentFee;
                        } else if (_role.contains('TEACHER') ||
                            _role.contains('STAFF')) {
                          feeVal = test.teacherFee;
                        } else {
                          feeVal = test.outsideFee;
                        }

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Test name
                                Text(
                                  "${index + 1}. $name",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (description.isNotEmpty)
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                // Fee row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Fee: ${feeVal.toStringAsFixed(2)} taka',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      available ? 'Available' : 'Unavailable',
                                      style: TextStyle(
                                        color: available
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: available
                                        ? () {
                                            final instructions =
                                                'This feature is not implemented in the app yet.\n\n'
                                                'Please visit the NSTU bank, pay the required fee, and obtain a payment token. '
                                                'Then go to the Lab Test Center (2nd floor of the NSTU Medical Center) and present the token to receive the service.';

                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(
                                                  'Test Name - $name',
                                                ),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Fee: ${feeVal.toStringAsFixed(2)} taka',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        available
                                                            ? 'Status: Available'
                                                            : 'Status: Unavailable',
                                                        style: TextStyle(
                                                          color: available
                                                              ? Colors.green
                                                              : Colors.red,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      SelectableText(
                                                        instructions,
                                                        showCursor: true,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    label: const Text(
                                      "Details",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
