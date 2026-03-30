import 'package:flutter/material.dart';
import 'package:dishari/src/doctor/doctor_home.dart';
import 'doctor_profile.dart';
import 'patient_records.dart';
import 'test_reports_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backend_client/backend_client.dart';

import '../routing/route_refresh.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard>
    with RouteRefreshMixin<DoctorDashboard> {
  int _currentIndex = 0;

  int? _reviewHighlightReportId;
  bool _reviewHighlightAllUnreviewed = false;
  DateTime? _reviewHighlightUnreviewedSinceUtc;

  // keep track of visited page history
  final List<int> _navigationHistory = [];

  // Pages are generated dynamically so we always pass the latest doctorId.
  List<Widget> get _pages => [
    DoctorHomePage(
      doctorId: _doctorId,
      refreshSeed: _refreshSeed,
      onOpenReviewReports: _openReviewReports,
    ),
    const PatientRecordsPage(),
    TestReportsView(
      doctorId: _doctorId,
      highlightReportId: _reviewHighlightReportId,
      highlightAllUnreviewed: _reviewHighlightAllUnreviewed,
      highlightUnreviewedSinceUtc: _reviewHighlightUnreviewedSinceUtc,
    ),
    const ProfilePage(),
  ];

  void _openReviewReports({
    int? highlightReportId,
    bool highlightAllUnreviewed = false,
    DateTime? highlightUnreviewedSinceUtc,
  }) {
    setState(() {
      _reviewHighlightReportId = highlightReportId;
      _reviewHighlightAllUnreviewed = highlightAllUnreviewed;
      _reviewHighlightUnreviewedSinceUtc = highlightUnreviewedSinceUtc;

      const reviewTabIndex = 2;
      if (_currentIndex != reviewTabIndex) {
        _navigationHistory.add(_currentIndex);
        _currentIndex = reviewTabIndex;
      }
    });
  }

  // Auth guard state
  bool _checkingAuth = true;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyDoctor();
    });
  }

  int _doctorId = 0;
  int _refreshSeed = 0;

  @override
  Future<void> refreshOnFocus() async {
    if (_checkingAuth || !_authorized) return;
    setState(() {
      _refreshSeed++;
    });
  }

  Future<void> _verifyDoctor() async {
    try {
      // ignore: deprecated_member_use
      final authKey = await client.authenticationKeyManager?.get();
      if (authKey == null || authKey.isEmpty) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('user_id');
      if (!mounted) return;
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
      _doctorId = numericId;
      String role = '';
      try {
        role = (await client.patient.getUserRole()).toUpperCase();
      } catch (e) {
        debugPrint('Failed to fetch user role: $e');
      }
      if (role == 'DOCTOR') {
        setState(() {
          _authorized = true;
          _checkingAuth = false;
        });
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
    } catch (e) {
      debugPrint('Doctor auth check failed: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_authorized) {
      // fallback
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: const Text('Unauthorized - Go to Login'),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_navigationHistory.isNotEmpty) {
          setState(() {
            _currentIndex = _navigationHistory.removeLast();
          });
          return false; // Don't exit app, just go back to previous tab
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Exit App Confirmation"),
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
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              if (index != _currentIndex) {
                _navigationHistory.add(_currentIndex); // save previous index
                _currentIndex = index;
              }
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: "Patients",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.upload_file),
              label: "Review Reports",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
