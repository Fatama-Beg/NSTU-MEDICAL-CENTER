// ignore_for_file: unnecessary_underscores, unused_element

import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart';
import '../core/date_time_utils.dart';
import '../routing/route_refresh.dart';

enum NotificationFilter { all, unread, read }

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with RouteRefreshMixin<Notifications> {
  bool loading = true;

  int unreadCount = 0;
  int readCount = 0;

  List<NotificationInfo> _all = [];

  // dealt to showing all, read, unread
  NotificationFilter _filter = NotificationFilter.all;

  List<NotificationInfo> get _filtered {
    switch (_filter) {
      case NotificationFilter.unread:
        return _all.where((n) => n.isRead == false).toList();
      case NotificationFilter.read:
        return _all.where((n) => n.isRead == true).toList();
      case NotificationFilter.all:
        return _all;
    }
  }

  int get _allCount => _all.length;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  Future<void> refreshOnFocus() async {
    await _loadAll();
  }

  // load all data function
  Future<void> _loadAll() async {
    setState(() => loading = true);
    try {
      final counts = await client.notification.getMyNotificationCounts();
      final list = await client.notification.getMyNotifications(limit: 190);

      if (!mounted) return;
      setState(() {
        unreadCount = counts['unread'] ?? 0;
        readCount = counts['read'] ?? 0;
        _all = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      debugPrint('Error loading notifications: $e');
    }
  }

  // mark as read all function
  Future<void> _markAllRead() async {
    final ok = await client.notification.markAllAsRead();
    if (ok) await _loadAll();
  }

  //mark as read one function
  Future<void> _markOneRead(NotificationInfo n) async {
    if (n.isRead) return;

    await client.notification.markAsRead(notificationId: n.notificationId);
    await _loadAll();
  }

  // dot badge widget
  Widget _badgeDot({required Widget child}) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        child,

        // if unreadCount is more than 0, show red dot
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filtered;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            // apply badge dot to menu icon
            icon: _badgeDot(
              child: const Icon(Icons.more_vert, color: Colors.blueAccent),
            ),
            initialValue: switch (_filter) {
              NotificationFilter.all => 'all',
              NotificationFilter.unread => 'unread',
              NotificationFilter.read => 'read',
            },
            onSelected: (value) async {
              if (value == 'markAll') {
                if (!loading) await _markAllRead();
                return;
              }

              setState(() {
                if (value == 'all') _filter = NotificationFilter.all;
                if (value == 'unread') _filter = NotificationFilter.unread;
                if (value == 'read') _filter = NotificationFilter.read;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All ($_allCount)')),
              PopupMenuItem(
                value: 'unread',
                child: Text('Unread ($unreadCount)'),
              ),
              PopupMenuItem(value: 'read', child: Text('Read ($readCount)')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'markAll',
                child: Text('Mark all read'),
              ),
            ],
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.blueAccent),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: shown.isEmpty
                      ? const Center(child: Text('No notifications'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: shown.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final n = shown[i];
                            return ListTile(
                              leading: Icon(
                                n.isRead
                                    ? Icons.notifications_none
                                    : Icons.notifications_active,
                                color: n.isRead
                                    ? Colors.grey
                                    : Colors.blueAccent,
                              ),
                              title: Text(
                                n.title.isEmpty ? '(No title)' : n.title,
                                style: TextStyle(
                                  fontWeight: n.isRead
                                      ? FontWeight.w400
                                      : FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                n.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                AppDateTime.formatLocal(
                                  n.createdAt,
                                  pattern: 'yyyy-MM-dd',
                                ),
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () async {
                                await _markOneRead(n);
                                if (!context.mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => NotificationDetails(
                                      notificationId: n.notificationId,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// notification details page
class NotificationDetails extends StatefulWidget {
  final int notificationId;
  const NotificationDetails({super.key, required this.notificationId});

  @override
  State<NotificationDetails> createState() => _NotificationDetailsState();
}

class _NotificationDetailsState extends State<NotificationDetails> {
  bool loading = true;
  NotificationInfo? data;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => loading = true);
    try {
      final res = await client.notification.getNotificationById(
        notificationId: widget.notificationId,
      );

      if (mounted) {
        setState(() {
          data = res;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (data?.title ?? '').trim();
    final msg = (data?.message ?? '').trim();
    final createdAt = data?.createdAt.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Details')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(
              child: Text('Notification not found or access denied.'),
            )
          : Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? '(No title)' : title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(createdAt, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Text(msg, style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
    );
  }
}
