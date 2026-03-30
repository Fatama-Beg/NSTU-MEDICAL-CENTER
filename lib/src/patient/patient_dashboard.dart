import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backend_client/backend_client.dart';

import '../core/date_time_utils.dart';
import '../routing/route_refresh.dart';

class PatientDashboard extends StatefulWidget {
  final String name;
  final String email;
  final String? profilePictureUrl;

  const PatientDashboard({
    super.key,
    required this.name,
    required this.email,
    this.profilePictureUrl,
  });

  static Future<PatientDashboard> fromRouteArguments(
    Map<String, dynamic> arguments,
  ) async {
    // Do not read or return stored profile data here. The dashboard will
    // always query the backend for fresh profile data on init.
    return const PatientDashboard(name: '', email: '');
  }

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard>
    with RouteRefreshMixin<PatientDashboard> {
  late String name;
  late String email;
  late String? profilePictureUrl;
  bool _isLoading = true;
  // Auth guard (keeps behavior consistent with other dashboards)
  bool _checkingAuth = true;
  bool _authorized = false;
  List<OndutyStaff> onduty = [];
  bool loadingOnduty = true;

  String _shiftTimeRangeLabel(ShiftType shift) {
    switch (shift) {
      case ShiftType.MORNING:
        return '8:00 AM - 2:00 PM';
      case ShiftType.AFTERNOON:
        return '2:00 PM - 8:00 PM';
      case ShiftType.NIGHT:
        return '8:00 PM - 8:00 AM';
    }
  }

  @override
  void initState() {
    super.initState();
    name = '';
    email = '';
    profilePictureUrl = null;

    // Verify auth & role first, then fetch profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyAndFetch();
    });
  }

  Future<void> _fetchOnduty({bool silent = false}) async {
    if (!silent) {
      setState(() => loadingOnduty = true);
    }
    try {
      final data = await client.patient.getOndutyStaff();
      if (!mounted) return;
      setState(() {
        onduty = data;
        loadingOnduty = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() => loadingOnduty = false);
      }
    }
  }

  Future<void> _verifyAndFetch() async {
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

      final allowed = {'STUDENT', 'TEACHER', 'STAFF', 'OUTSIDE'};
      if (!allowed.contains(role)) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      setState(() {
        _authorized = true;
        _checkingAuth = false;
      });

      await _fetchProfile();
      await _fetchOnduty();
    } catch (e) {
      debugPrint('Auth verification failed: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
      return;
    }
  }

  Future<void> _fetchProfile({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      // Resolve numeric user id (stored as string). Client API expects int.
      String? stored = prefs.getString('user_id');
      int? numericId;
      if (stored != null && stored.isNotEmpty) {
        numericId = int.tryParse(stored);
      }

      if (numericId == null) {
        // No numeric id available - prompt sign in
        if (!silent) {
          setState(() {
            _isLoading = false;
          });
          _showDialog(
            'Not signed in',
            'Please sign in to view your dashboard.',
          );
        }
        return;
      }

      final profile = await client.patient.getPatientProfile();

      if (profile != null) {
        setState(() {
          name = profile.name;
          email = profile.email;
          profilePictureUrl = profile.profilePictureUrl;
          _isLoading = false;
        });
      } else {
        if (!silent) {
          setState(() {
            _isLoading = false;
          });
          _showDialog('No profile', 'No profile found for this user.');
        }
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
        _showDialog('Error', 'Failed to fetch profile: $e');
      }
    }
  }

  @override
  Future<void> refreshOnFocus() async {
    if (_checkingAuth || !_authorized) return;
    await Future.wait([
      _fetchProfile(silent: true),
      _fetchOnduty(silent: true),
    ]);
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Replaced buildActionCard with improved visual + ripple (keeps API)
  Widget buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color startColor = Colors.greenAccent,
    Color endColor = Colors.green,
    double width = 0,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [startColor, endColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: endColor.withOpacity(0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(icon, size: 28, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // show loader while checking auth or profile
    if (_checkingAuth || _isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_authorized) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: const Text('Unauthorized - Go to Login'),
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    double responsiveWidth(double w) => size.width * w / 375;
    double responsiveHeight(double h) => size.height * h / 812;

    // Build profile image widget (keeps existing decoding logic)
    Widget buildProfileImage() {
      if (profilePictureUrl == null || profilePictureUrl!.isEmpty) {
        return const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, size: 50, color: Colors.black54),
        );
      }

      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(profilePictureUrl!.trim()),
        // যদি URL কাজ না করে তবে এই আইকনটি দেখাবে
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint("Error loading profile image: $exception");
        },
        child: null,
      );
    }

    // Animated colorful header with avatar + name + email
    Widget buildHeader() {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7F00FF), Color(0xFF00C6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            // avatar
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: buildProfileImage(),
            ),
            const SizedBox(width: 16),
            // text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, ${name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : ''}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(email, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            // small quick action (notifications)
            IconButton(
              onPressed: () async {
                await Navigator.pushNamed(context, '/notifications');
              },
              icon: const Icon(Icons.notifications, color: Colors.white),
            ),
          ],
        ),
      );
    }

    Widget buildOnduty() {
      if (loadingOnduty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (onduty.isEmpty) {
        return const Text('No one is on duty right now.');
      }

      return Column(
        children: onduty.map((s) {
          final roleColor = s.staffRole == RosterUserRole.DOCTOR
              ? Colors.green
              : s.staffRole == RosterUserRole.NURSE
              ? Colors.blue
              : Colors.orange;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  // future: tap করলে details দেখাতে পারবেন
                  // showDialog(...);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Left: avatar with role color
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: roleColor.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Icon(Icons.person, color: roleColor, size: 26),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Middle: name + role + date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.staffName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${s.staffRole.name} • ${s.shift.name} • ${_shiftTimeRangeLabel(s.shift)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              // shiftDate কে সুন্দরভাবে দেখাতে পারেন
                              'Date: ${AppDateTime.formatDateOnly(s.shiftDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right: small shift chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.shift.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshFromPull,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(responsiveWidth(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: responsiveHeight(20)),

                // Header
                buildHeader(),

                SizedBox(height: responsiveHeight(20)),

                const Text(
                  "On Duty Medical Staff",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: responsiveHeight(12)),
                buildOnduty(),

                SizedBox(height: responsiveHeight(24)),

                // Quick Actions
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: responsiveHeight(12)),

                LayoutBuilder(
                  builder: (context, constraints) {
                    double itemWidth =
                        (constraints.maxWidth - responsiveWidth(16)) / 2;

                    return Wrap(
                      spacing: responsiveWidth(16),
                      runSpacing: responsiveHeight(16),
                      children: [
                        buildActionCard(
                          icon: Icons.person,
                          label: "Profile",
                          onTap: () {
                            // Open profile page; profile page will fetch the data itself.
                            Navigator.pushNamed(context, '/patient/profile');
                          },
                          width: itemWidth,
                        ),
                        buildActionCard(
                          icon: Icons.medication,
                          label: "Prescriptions",
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/patient/prescriptions',
                            );
                          },
                          width: itemWidth,
                        ),
                        buildActionCard(
                          icon: Icons.description,
                          label: "My Reports",
                          onTap: () {
                            Navigator.pushNamed(context, '/patient/reports');
                          },
                          width: itemWidth,
                        ),
                        buildActionCard(
                          icon: Icons.upload_file,
                          label: "Upload Results",
                          onTap: () {
                            Navigator.pushNamed(context, '/patient/upload');
                          },
                          width: itemWidth,
                          startColor: Colors.blueAccent,
                          endColor: Colors.blue,
                        ),
                        buildActionCard(
                          icon: Icons.science_outlined,
                          label: "Lab Test Availability",
                          onTap: () {
                            Navigator.pushNamed(context, '/patient/lab');
                          },
                          width: itemWidth,
                          startColor: Colors.tealAccent,
                          endColor: Colors.teal,
                        ),
                        buildActionCard(
                          icon: Icons.local_hospital,
                          label: "Ambulance & Staff",
                          onTap: () {
                            Navigator.pushNamed(context, '/patient/ambulance');
                          },
                          width: itemWidth,
                          startColor: Colors.orangeAccent,
                          endColor: Colors.deepOrange,
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: responsiveHeight(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
