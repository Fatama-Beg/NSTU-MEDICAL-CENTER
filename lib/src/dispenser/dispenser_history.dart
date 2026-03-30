import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart';
import 'package:intl/intl.dart';

import '../routing/route_refresh.dart';

class DispenseLogsScreen extends StatefulWidget {
  const DispenseLogsScreen({super.key});

  @override
  State<DispenseLogsScreen> createState() => _DispenseLogsScreenState();
}

class _DispenseLogsScreenState extends State<DispenseLogsScreen>
    with RouteRefreshMixin<DispenseLogsScreen> {
  List<DispenseHistoryEntry> _dispenses = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;

  static const int _pageSize = 10;
  int _limit = _pageSize;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Future<void> refreshOnFocus() async {
    await _loadHistory(reset: true);
  }

  Future<void> _loadHistory({bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      _limit = _pageSize;
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
      });
    } else {
      setState(() => _isLoading = true);
    }

    try {
      // Request one extra item to detect if there are more.
      final result = await client.dispenser.getDispenserDispenseHistory(
        limit: _limit + 1,
      );
      if (!mounted) return;

      final hasMore = result.length > _limit;
      final shown = hasMore ? result.take(_limit).toList() : result;

      setState(() {
        _dispenses = shown;
        _hasMore = hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading history: $e");
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      _limit += _pageSize;
      await _loadHistory();
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadHistory(reset: true),
              child: _dispenses.isEmpty
                  ? _buildEmptyState()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        final isWide = maxWidth >= 900;
                        final contentWidth = maxWidth > 980 ? 980.0 : maxWidth;

                        final itemCount =
                            _dispenses.length + (_hasMore ? 1 : 0);

                        return Center(
                          child: SizedBox(
                            width: contentWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: isWide
                                  ? GridView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 2.1,
                                          ),
                                      itemCount: itemCount,
                                      itemBuilder: (context, index) {
                                        if (index >= _dispenses.length) {
                                          return _buildLoadMoreCard();
                                        }
                                        return _buildDispenseCard(
                                          _dispenses[index],
                                        );
                                      },
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: itemCount,
                                      itemBuilder: (context, index) {
                                        if (index >= _dispenses.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                              bottom: 14,
                                            ),
                                            child: _buildLoadMoreCard(),
                                          );
                                        }
                                        return _buildDispenseCard(
                                          _dispenses[index],
                                        );
                                      },
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildLoadMoreCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _isLoadingMore ? 'Loading...' : 'Load more',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (_isLoadingMore)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              ElevatedButton(
                onPressed: _loadMore,
                child: const Text('Load more'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDispenseCard(DispenseHistoryEntry d) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(Icons.outbox, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rx #${d.prescriptionId} • ${d.mobileNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Text(
                  DateFormat('dd MMM yyyy').format(d.dispensedAt.toLocal()),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (d.items.isEmpty)
              Text('No items', style: TextStyle(color: Colors.grey.shade700))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: d.items.map((it) {
                  final label = '${it.medicineName} × ${it.quantity}';
                  final color = it.isAlternative ? Colors.purple : Colors.blue;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "No activity history found",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
