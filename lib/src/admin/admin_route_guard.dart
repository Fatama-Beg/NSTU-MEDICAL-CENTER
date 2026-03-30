import 'package:flutter/material.dart';

import '../routing/authenticated_route_guard.dart';

class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return UniversalRouteGuard(allowedRoles: const {'ADMIN'}, child: child);
  }
}
