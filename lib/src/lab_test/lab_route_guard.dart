import 'package:flutter/material.dart';

import '../routing/authenticated_route_guard.dart';

class LabRouteGuard extends StatelessWidget {
  final Widget child;

  const LabRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return UniversalRouteGuard(allowedRoles: const {'LABSTAFF'}, child: child);
  }
}
