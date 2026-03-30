import 'dart:ui' show AppExitResponse, ViewFocusEvent;

import 'package:flutter/services.dart' show PredictiveBackEvent;
import 'package:flutter/widgets.dart';

/// Global RouteObserver used to detect when a page becomes visible again.
///
/// Add this to `MaterialApp.navigatorObservers`.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

/// Mixin for auto-refreshing a route when the user navigates back to it
/// (or when the app resumes), without forcing any UI indicator.
///
/// Implement [refreshOnFocus] in your State class.
mixin RouteRefreshMixin<T extends StatefulWidget> on State<T>
    implements RouteAware, WidgetsBindingObserver {
  /// Minimum time between consecutive refreshes.
  Duration get refreshCooldown => const Duration(milliseconds: 800);

  /// Refresh when app is resumed.
  bool get refreshOnAppResume => true;

  DateTime? _lastRefreshAt;
  Future<void>? _inFlight;

  Future<void> refreshOnFocus();

  /// Trigger a refresh from a user gesture (e.g., pull-to-refresh).
  /// Uses the same cooldown + in-flight coalescing as focus-based refresh.
  Future<void> refreshFromPull() => _maybeRefresh();

  Future<void> _maybeRefresh() {
    if (!mounted) return Future.value();

    final now = DateTime.now();
    final last = _lastRefreshAt;
    if (last != null && now.difference(last) < refreshCooldown) {
      return _inFlight ?? Future.value();
    }

    _lastRefreshAt = now;
    _inFlight = Future<void>(() async {
      try {
        await refreshOnFocus();
      } catch (_) {
        // Intentionally swallow errors: refresh is best-effort and should not
        // change UI state with dialogs/snackbars.
      }
    });
    return _inFlight!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Returned to this page from another route.
    _maybeRefresh();
  }

  void didPush() {
    // No-op.
  }

  void didPop() {
    // No-op.
  }

  void didPushNext() {
    // No-op.
  }

  // ---- WidgetsBindingObserver (no-op defaults) ----

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) => false;

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {}

  @override
  void handleCommitBackGesture() {}

  @override
  void handleCancelBackGesture() {}

  /// Added to fix "missing implementation" error in Flutter master channel (3.29+)
  void handleStatusBarTap() {}

  @override
  void didChangeAccessibilityFeatures() {}
  @override
  void didChangeLocales(List<Locale>? locales) {}

  @override
  void didChangeMetrics() {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {}

  @override
  void didChangeViewFocus(ViewFocusEvent event) {}

  @override
  Future<AppExitResponse> didRequestAppExit() async => AppExitResponse.exit;
  @override
  Future<bool> didPopRoute() async => false;
  @override
  Future<bool> didPushRoute(String route) async => false;
  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async => false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!refreshOnAppResume) return;
    if (state == AppLifecycleState.resumed) {
      _maybeRefresh();
    }
  }
}
