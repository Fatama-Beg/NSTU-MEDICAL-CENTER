import 'package:flutter/material.dart';

import '../routing/authenticated_route_guard.dart';

class DispenserRouteGuard extends StatelessWidget {
  final Widget child;

  const DispenserRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return UniversalRouteGuard(allowedRoles: const {'DISPENSER'}, child: child);
  }
}
