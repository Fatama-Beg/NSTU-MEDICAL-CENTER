import 'package:flutter/material.dart';

import '../routing/authenticated_route_guard.dart';

class PatientRouteGuard extends StatelessWidget {
  final Widget child;

  const PatientRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return UniversalRouteGuard(
      allowedRoles: const {'STUDENT', 'TEACHER', 'STAFF'},
      child: child,
    );
  }
}
