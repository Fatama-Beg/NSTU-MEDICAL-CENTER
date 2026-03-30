import 'package:backend_client/backend_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UniversalRouteGuard extends StatefulWidget {
  final Widget child;

  /// If provided, user role must be one of these (case-insensitive).
  /// If null, only authentication is checked.
  final Set<String>? allowedRoles;

  /// Where to redirect when unauthorized.
  final String redirectRoute;

  /// Optional widget to show while checking.
  final Widget? loading;

  /// Optional widget to show when unauthorized (usually never visible because
  /// we redirect immediately after build).
  final Widget? unauthorized;

  const UniversalRouteGuard({
    super.key,
    required this.child,
    this.allowedRoles,
    this.redirectRoute = '/',
    this.loading,
    this.unauthorized,
  });

  @override
  State<UniversalRouteGuard> createState() => _UniversalRouteGuardState();
}

class _UniversalRouteGuardState extends State<UniversalRouteGuard> {
  bool _checking = true;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkAccess();
    });
  }

  Future<void> _deny() async {
    if (!mounted) return;
    setState(() {
      _authorized = false;
      _checking = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(widget.redirectRoute, (_) => false);
    });
  }

  bool _roleAllowed(String role) {
    final allowed = widget.allowedRoles;
    if (allowed == null) return true;
    final normalized = role.trim().toUpperCase();
    final normalizedAllowed = allowed
        .map((e) => e.trim().toUpperCase())
        .toSet();
    return normalizedAllowed.contains(normalized);
  }

  Future<void> _checkAccess() async {
    try {
      // ignore: deprecated_member_use
      final authKey = await client.authenticationKeyManager?.get();
      if (authKey == null || authKey.isEmpty) {
        await _deny();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('user_id');
      if (storedUserId == null || storedUserId.trim().isEmpty) {
        await _deny();
        return;
      }

      if (widget.allowedRoles != null) {
        String role = '';
        try {
          role = (await client.patient.getUserRole()).trim().toUpperCase();
        } catch (e) {
          debugPrint('Failed to fetch user role: $e');
        }

        if (!_roleAllowed(role)) {
          await _deny();
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _authorized = true;
        _checking = false;
      });
    } catch (e) {
      debugPrint('UniversalRouteGuard auth check failed: $e');
      await _deny();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return widget.loading ??
          const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_authorized) {
      return widget.unauthorized ?? const Scaffold(body: SizedBox.shrink());
    }

    return widget.child;
  }
}

class AuthenticatedRouteGuard extends StatefulWidget {
  final Widget child;

  const AuthenticatedRouteGuard({super.key, required this.child});

  @override
  State<AuthenticatedRouteGuard> createState() =>
      _AuthenticatedRouteGuardState();
}

class _AuthenticatedRouteGuardState extends State<AuthenticatedRouteGuard> {
  @override
  Widget build(BuildContext context) {
    return UniversalRouteGuard(child: widget.child);
  }
}
