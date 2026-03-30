import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backend_client/backend_client.dart';

import '../core/date_time_utils.dart';
import '../routing/route_refresh.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard>
    with RouteRefreshMixin<AdminDashboard> {
  final Color primaryTeal = const Color(0xFF00695C);
  final Color backgroundLight = const Color(0xFFF8F9FA);

  // Admin profile data from backend
  String _adminName = '';
  String _adminEmail = '';
  String _adminRole = 'S';
  String? _profilePictureUrl;
  bool _isLoadingProfile = true;

  // Dashboard overview + recent activity from backend
  bool _isLoadingOverview = true;
  int _totalUsers = 0;
  int _totalStockItems = 0;

  bool _isLoadingRecentActivity = true;
  List<AuditEntry> _recentAuditLogs = const [];

  // Auth guard state
  bool _checkingAuth = true;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _verifyAdmin();
    });
  }

  @override
  Future<void> refreshOnFocus() async {
    // Best-effort refresh; do nothing until auth is resolved.
    if (_checkingAuth || !_authorized) return;
    await Future.wait([
      _loadAdminProfile(),
      _loadDashboardOverview(),
      _loadRecentActivity(),
    ]);
  }

  Future<void> _goToNamedRoute(String routeName) async {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) return;
    await Navigator.pushNamed(context, routeName);
  }

  Future<void> _verifyAdmin() async {
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
      if (storedUserId == null || storedUserId.trim().isEmpty) {
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

      if (role != 'ADMIN') {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      if (!mounted) return;
      setState(() {
        _authorized = true;
        _checkingAuth = false;
      });

      // Load all admin dashboard data only after auth is verified.
      _loadAdminProfile();
      _loadDashboardOverview();
      _loadRecentActivity();
    } catch (e) {
      debugPrint('Admin auth check failed: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _loadDashboardOverview() async {
    try {
      final overview = await client.adminReportEndpoints
          .getAdminDashboardOverview();
      if (!mounted) return;
      setState(() {
        _totalUsers = overview.totalUsers;
        _totalStockItems = overview.totalStockItems;
        _isLoadingOverview = false;
      });
    } catch (e) {
      debugPrint('Failed to load dashboard overview: $e');
      if (!mounted) return;
      setState(() => _isLoadingOverview = false);
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      final items = await client.adminEndpoints.getRecentAuditLogs(24, 30);
      if (!mounted) return;
      setState(() {
        _recentAuditLogs = items;
        _isLoadingRecentActivity = false;
      });
    } catch (e) {
      debugPrint('Failed to load recent activity: $e');
      if (!mounted) return;
      setState(() => _isLoadingRecentActivity = false);
    }
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  String _prettyAction(String action) {
    final a = action.trim();
    if (a.isEmpty) return 'Activity';
    return a
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Future<void> _loadAdminProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail =
          prefs.getString('user_email') ??
          prefs.getString('email') ??
          prefs.getString('userId');

      if (storedEmail == null || storedEmail.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoadingProfile = false);
        return;
      }

      final AdminProfileRespond? profile = await client.adminEndpoints
          .getAdminProfile(storedEmail);

      if (profile != null && mounted) {
        setState(() {
          _adminName = profile.name;
          _adminEmail = profile.email;
          _adminRole = profile.designation ?? 'Admin';
          _profilePictureUrl = profile.profilePictureUrl;
          _isLoadingProfile = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Failed to load admin profile: $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSectionTitle('Dashboard Overview'),
                const SizedBox(height: 12),
                _buildOverviewCards(),
                const SizedBox(height: 24),
                _buildSectionTitle('Quick Actions'),
                const SizedBox(height: 12),
                _buildQuickActionsGrid(context),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Recent Activity'),
                    TextButton(
                      onPressed: () {
                        _loadRecentActivity();
                      },
                      child: const Text(
                        'Refresh',
                        style: TextStyle(color: Color(0xFF00695C)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRecentActivityList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Generate initials from admin name
    final initials = _adminName.isNotEmpty
        ? _adminName
              .split(' ')
              .where((word) => word.isNotEmpty)
              .take(2)
              .map((word) => word[0].toUpperCase())
              .join()
        : 'AD';

    final designationText = (!_isLoadingProfile && _adminRole.trim().isNotEmpty)
        ? 'Designation: $_adminRole'
        : '';

    return InkWell(
      onTap: () async {
        await _goToNamedRoute('/admin/profile');
        _loadAdminProfile();
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00695C), Color(0xFF4DB6AC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              _isLoadingProfile
                  ? const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 24,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00695C),
                        ),
                      ),
                    )
                  : (_profilePictureUrl != null &&
                        _profilePictureUrl!.isNotEmpty)
                  ? CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 24,
                      backgroundImage: NetworkImage(_profilePictureUrl!),
                      onBackgroundImageError: (_, __) {},
                      child: null,
                    )
                  : CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 24,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFF00695C),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoadingProfile ? 'Loading...' : _adminName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoadingProfile ? '' : _adminEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      designationText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard(
          'Total Users',
          _isLoadingOverview ? '...' : _totalUsers.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Stock',
          _isLoadingOverview ? '...' : '$_totalStockItems Items',
          Icons.inventory,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'User Management',
        'icon': Icons.group_add_outlined,
        'color': Colors.blue.shade700,
        'bg': Colors.blue.shade50,
        'route': '/admin/users',
      },
      {
        'title': 'Inventory',
        'icon': Icons.inventory_2_outlined,
        'color': Colors.orange.shade700,
        'bg': Colors.orange.shade50,
        'route': '/admin/inventory',
      },
      {
        'title': 'Roster',
        'icon': Icons.calendar_month_outlined,
        'color': Colors.purple.shade700,
        'bg': Colors.purple.shade50,
        'route': '/admin/roster',
      },
      {
        'title': 'Report',
        'icon': Icons.assessment_outlined,
        'color': Colors.teal.shade700,
        'bg': Colors.teal.shade50,
        'route': '/admin/reports',
      },
      {
        'title': 'History',
        'icon': Icons.history,
        'color': Colors.indigo.shade700,
        'bg': Colors.indigo.shade50,
        'route': '/admin/history',
      },
      {
        'title': 'Ambulance',
        'icon': Icons.local_shipping_outlined,
        'color': Colors.red.shade700,
        'bg': Colors.red.shade50,
        'route': '/admin/ambulance',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0, // More square-ish for better look
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];

        return InkWell(
          onTap: () {
            _goToNamedRoute(action['route'] as String);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: action['bg'],
                  radius: 24,
                  child: Icon(action['icon'], color: action['color'], size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  action['title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivityList() {
    if (_isLoadingRecentActivity) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentAuditLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No recent activity found')),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentAuditLogs.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final entry = _recentAuditLogs[index];

        final title = _prettyAction(entry.action);
        final subtitleParts = <String>[];
        if (entry.adminName != null && entry.adminName!.trim().isNotEmpty) {
          subtitleParts.add('By ${entry.adminName}');
        }
        if (entry.targetName != null && entry.targetName!.trim().isNotEmpty) {
          final target = AppDateTime.formatMaybeIsoRange(entry.targetName!);
          subtitleParts.add('Target: $target');
        }
        final subtitle = subtitleParts.isEmpty
            ? 'System activity'
            : subtitleParts.join(' • ');

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withAlpha((0.10 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.history, color: Colors.teal, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            _timeAgo(entry.createdAt.toLocal()),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        );
      },
    );
  }
}
