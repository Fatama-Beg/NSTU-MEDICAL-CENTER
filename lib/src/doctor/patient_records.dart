import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:backend_client/backend_client.dart';
import 'package:dishari/src/doctor/prescription_page.dart';
import 'dosage_times.dart';

import '../routing/route_refresh.dart';

class PatientRecordsPage extends StatefulWidget {
  const PatientRecordsPage({super.key});

  @override
  State<PatientRecordsPage> createState() => _PatientRecordsPageState();
}

class _PatientRecordsPageState extends State<PatientRecordsPage>
    with RouteRefreshMixin<PatientRecordsPage> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;
  int _fetchToken = 0;

  bool _loading = false;
  String? _error;

  List<PatientPrescriptionListItem> _patients = [];
  List<PatientPrescriptionListItem> _filteredPatients = [];

  final TextEditingController _newPatientPhoneController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Don't show any records until user searches.
    _patients = [];
    _filteredPatients = [];
  }

  @override
  Future<void> refreshOnFocus() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    await _fetchPatients(showSpinner: false);
  }

  @override
  void dispose() {
    try {
      _searchController.removeListener(_onSearchChanged);
    } catch (_) {}
    try {
      _searchController.dispose();
    } catch (_) {}
    try {
      _searchDebounce?.cancel();
    } catch (_) {}
    try {
      _newPatientPhoneController.dispose();
    } catch (_) {}
    super.dispose();
  }

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

  String _last11Digits(String raw) {
    final d = _digitsOnly(raw);
    if (d.length <= 11) return d;
    return d.substring(d.length - 11);
  }

  bool _isValidBdMobile11(String digits11) {
    return digits11.length == 11 && digits11.startsWith('01');
  }

  bool _phonesMatchByLast11(String? a, String? b) {
    final da = _digitsOnly(a ?? '');
    final db = _digitsOnly(b ?? '');
    if (da.isEmpty || db.isEmpty) return false;
    final lastA = da.length >= 11 ? da.substring(da.length - 11) : da;
    final lastB = db.length >= 11 ? db.substring(db.length - 11) : db;
    return lastA == lastB;
  }

  int _calculateAgeFromDob(DateTime dob, DateTime now) {
    var age = now.year - dob.year;
    final hasHadBirthdayThisYear =
        (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hasHadBirthdayThisYear) age -= 1;
    if (age < 0) return 0;
    return age;
  }

  Future<void> _fetchPatients({
    String? queryOverride,
    bool showSpinner = true,
  }) async {
    final token = ++_fetchToken;

    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final data = await client.doctor.getPatientPrescriptionList(
        query: (queryOverride ?? _searchController.text).trim(),
        limit: 200,
        offset: 0,
      );

      if (!mounted) return;
      if (token != _fetchToken) return; // ignore stale responses

      setState(() {
        _patients = data;
        _filterPatients();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (token != _fetchToken) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged() {
    if (!mounted) return;
    _filterPatients();

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      // Live server-side search so number-based search works beyond initial 200.
      _fetchPatients(
        queryOverride: _searchController.text.trim(),
        showSpinner: false,
      );
    });
  }

  void _filterPatients() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase().trim();

    final queryDigits = _digitsOnly(query);

    // backend search already supported, কিন্তু UI instant filter রাখলাম
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = [];
      } else {
        _filteredPatients = _patients.where((p) {
          final mobileDigits = _digitsOnly(p.mobileNumber ?? '');
          if (queryDigits.isEmpty) return false;
          return mobileDigits.contains(queryDigits);
        }).toList();
      }
    });
  }

  Future<void> _viewPatientDetails(PatientPrescriptionListItem patient) async {
    try {
      final details = await client.doctor.getPrescriptionDetails(
        prescriptionId: patient.prescriptionId,
      );

      if (!mounted || details == null) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => PatientDetailsSheet(details: details),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _continueFromSearchNumber() async {
    final raw = _searchController.text.trim();
    final last11 = _last11Digits(raw);
    if (last11.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a phone number first')),
      );
      return;
    }

    // Search supports partial numbers, but creating a prescription requires
    // a full BD mobile (11 digits, starting with 01).
    if (!_isValidBdMobile11(last11)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'To create prescription, enter 11-digit mobile starting with 01',
          ),
        ),
      );
      return;
    }

    try {
      final res = await client.doctor.getPatientByPhone(last11);
      final nameFromAccount = (res['name'] ?? '').trim();

      // Backend returns these keys when patient exists:
      // - age: computed integer age (string)
      // - dateOfBirth: ISO date string (optional)
      final ageStr = (res['age'] ?? '').trim();
      final dobStr = (res['dateOfBirth'] ?? '').trim();
      final genderFromBackend = (res['gender'] ?? '').trim();

      int? ageFromBackend;
      if (ageStr.isNotEmpty) {
        ageFromBackend = int.tryParse(ageStr);
      }

      int? ageFromDob;
      if (ageFromBackend == null && dobStr.isNotEmpty) {
        final dob = DateTime.tryParse(dobStr);
        if (dob != null) {
          ageFromDob = _calculateAgeFromDob(dob, DateTime.now());
        }
      }

      // Try to auto-fill gender/age from the most recent record (if any)
      PatientPrescriptionListItem? bestRecord;
      for (final r in _patients) {
        if (_phonesMatchByLast11(r.mobileNumber, last11)) {
          bestRecord = r;
          break;
        }
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PrescriptionPage(
            initialPatientName: nameFromAccount.isNotEmpty
                ? nameFromAccount
                : (bestRecord?.name.isNotEmpty == true
                      ? bestRecord!.name
                      : null),
            // Pass normalized digits so PrescriptionPage doesn't receive '+88', spaces, etc.
            initialPatientNumber: last11,
            initialPatientGender: genderFromBackend.isNotEmpty
                ? genderFromBackend
                : bestRecord?.gender,
            initialPatientAge: ageFromBackend ?? ageFromDob ?? bestRecord?.age,
          ),
        ),
      );

      if (!mounted) return;
      await _fetchPatients();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Patients Record",
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blueAccent),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                // Allow partial phone input, including +88 / spaces / dashes.
                // Also allow '*' since some users type it by habit.
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+* -]')),
              ],
              decoration: InputDecoration(
                hintText: 'Search by phone number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            )
          else if (query.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Search by phone number to see records',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            )
          else if (_filteredPatients.isEmpty && query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'No Record Found for "$query"',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredPatients.length,
                itemBuilder: (context, index) {
                  final patient = _filteredPatients[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.person, color: Colors.blue),
                      ),
                      title: Text(patient.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Number: ${patient.mobileNumber ?? '-'}'),
                          Text(
                            'Gender: ${patient.gender ?? '-'}  •  Age: ${patient.age ?? '-'}',
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () => _viewPatientDetails(patient),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _continueFromSearchNumber,
        tooltip: 'New Prescription',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PatientDetailsSheet extends StatelessWidget {
  final PatientPrescriptionDetails details;

  const PatientDetailsSheet({super.key, required this.details});

  Widget _buildInfoRow(String label, String value) {
    final v = value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(v.isEmpty ? '-' : v)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.98, // ✅ almost full screen
      minChildSize: 0.50,
      maxChildSize: 1.0, // ✅ top পর্যন্ত
      builder: (context, scrollController) {
        return SafeArea(
          top: true,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                // ✅ scrollable content
                SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // handle
                      Center(
                        child: Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // header row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  details.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Number: ${details.mobileNumber ?? '-'}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'Gender: ${details.gender ?? '-'} • Age: ${details.age ?? '-'}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // requirement: first row OE then advice,test,medicine
                      _buildInfoRow('OE', details.oe ?? ''),
                      _buildInfoRow('Advice', details.advice ?? ''),
                      _buildInfoRow('Test', details.test ?? ''),
                      _buildInfoRow('CC', details.cc ?? ''),

                      const SizedBox(height: 12),
                      const Text(
                        'Medicine',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (details.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('-')),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: details.items.length,
                          itemBuilder: (context, i) {
                            final m = details.items[i];
                            final dt = dosageTimesDisplayBangla(
                              m.dosageTimes ?? '',
                            );
                            return Card(
                              child: ListTile(
                                title: Text(
                                  m.medicineName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Dosage: ${dt.isEmpty ? '-' : dt}'),
                                    Text('Meal: ${m.mealTiming ?? '-'}'),
                                    Text(
                                      'Duration: ${m.duration?.toString() ?? '-'}',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // ✅ close button (top-right)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
