import 'package:flutter/material.dart';

import '../routing/authenticated_route_guard.dart';

class DoctorRouteGuard extends StatelessWidget {
  final Widget child;

  const DoctorRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return UniversalRouteGuard(allowedRoles: const {'DOCTOR'}, child: child);
  }
}
