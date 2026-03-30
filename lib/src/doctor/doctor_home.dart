// ignore_for_file: unused_local_variable, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:backend_client/backend_client.dart';
import 'dosage_times.dart';
import 'test_reports_view.dart';

import '../routing/route_refresh.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({
    super.key,
    required this.doctorId,
    this.refreshSeed = 0,
    this.onOpenReviewReports,
  });
  final int doctorId;
  final int refreshSeed;
  final void Function({
    int? highlightReportId,
    bool highlightAllUnreviewed,
    DateTime? highlightUnreviewedSinceUtc,
  })?
  onOpenReviewReports;

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage>
    with RouteRefreshMixin<DoctorHomePage> {
  DoctorHomeData? _homeData;
  bool _loading = false;

  bool _reviewStatusLoading = false;
  int _allTimeUnreviewedReports = 0;
  static const int _initialVisibleCount = 10;
  static const int _pageSize = 20;
  int _visibleRecentCount = _initialVisibleCount;
  int _visibleReviewedCount = _initialVisibleCount;

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  @override
  Future<void> refreshOnFocus() async {
    await _fetchHomeData(silent: true);
  }

  @override
  void didUpdateWidget(covariant DoctorHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      _fetchHomeData(silent: true);
    }
  }

  Future<void> _fetchHomeData({bool silent = false}) async {
    if (!silent) {
      setState(() => _loading = true);
    }
    try {
      // Backend resolves doctor from auth user; doctorId not needed.
      final data = await client.doctor.getDoctorHomeData();

      if (!mounted) return;
      setState(() {
        _homeData = data;
        _visibleRecentCount = _initialVisibleCount;
        _visibleReviewedCount = _initialVisibleCount;
        if (!silent) _loading = false;
      });

      // Also compute review status (all-time) for the indicator.
      // Uses the full reports endpoint since home payload doesn't include a reviewed flag.
      _fetchAllTimeReviewStatus();
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _homeData = null;
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchAllTimeReviewStatus() async {
    if (!mounted) return;
    setState(() {
      _reviewStatusLoading = true;
    });

    try {
      // Backend resolves doctor from auth user.
      final all = await client.doctor.getReportsForDoctor(0);
      if (!mounted) return;

      int total = 0;
      int unreviewed = 0;
      for (final r in all) {
        total++;
        if (r.reviewed != true) unreviewed++;
      }

      setState(() {
        _allTimeUnreviewedReports = unreviewed;
        _reviewStatusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allTimeUnreviewedReports = 0;
        _reviewStatusLoading = false;
      });
    }
  }

  void _handleReviewStatusTap() {
    if (_reviewStatusLoading) return;

    if (_allTimeUnreviewedReports <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All reports are reviewed.')),
      );
      return;
    }

    if (widget.onOpenReviewReports != null) {
      widget.onOpenReviewReports!(highlightAllUnreviewed: true);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestReportsView(
          doctorId: widget.doctorId,
          highlightAllUnreviewed: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final resolvedDoctorName = (_homeData?.doctorName ?? '').trim();

    final designation = (_homeData?.doctorDesignation ?? '').trim();
    final today = (_homeData?.today ?? DateTime.now()).toLocal();

    final lastMonthCount = _homeData?.lastMonthPrescriptions ?? 0;
    final lastWeekCount = _homeData?.lastWeekPrescriptions ?? 0;

    final profilePictureUrl = _homeData?.doctorProfilePictureUrl;

    final recentAll = _homeData?.recent ?? <DoctorHomeRecentItem>[];
    final reportsAll =
        _homeData?.reviewedReports ?? <DoctorHomeReviewedReport>[];

    final visibleRecent = recentAll
        .take(_visibleRecentCount.clamp(0, recentAll.length))
        .toList();
    final canReadMoreRecent = visibleRecent.length < recentAll.length;

    final visibleReports = reportsAll
        .take(_visibleReviewedCount.clamp(0, reportsAll.length))
        .toList();
    final canReadMoreReviewed = visibleReports.length < reportsAll.length;

    final hasUnreviewed = _allTimeUnreviewedReports > 0;
    final statusColor = _reviewStatusLoading
        ? Colors.grey
        : (hasUnreviewed ? Colors.red : Colors.blue);
    final statusText = _reviewStatusLoading
        ? 'Checking review status...'
        : (hasUnreviewed
              ? 'Pending review: $_allTimeUnreviewedReports'
              : 'All reviewed');

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchHomeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeaderCard(
                doctorName: resolvedDoctorName,
                designation: designation,
                today: today,
                profilePictureUrl: profilePictureUrl,
                lastMonthPrescriptions: lastMonthCount,
                lastWeekPrescriptions: lastWeekCount,
                loading: _loading,
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _reviewStatusLoading
                      ? null
                      : _handleReviewStatusTap,
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ReviewedReportsCard(
                items: visibleReports,
                subtitle: 'Last 24 hours',
                showReadMore: canReadMoreReviewed,
                onReadMore: () {
                  setState(() {
                    _visibleReviewedCount = (_visibleReviewedCount + _pageSize)
                        .clamp(0, reportsAll.length);
                  });
                },
                onTapItem: (item) {
                  if (!mounted) return;
                  if (widget.onOpenReviewReports != null) {
                    widget.onOpenReviewReports!(
                      highlightReportId: item.reportId,
                      highlightAllUnreviewed: false,
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TestReportsView(
                        doctorId: widget.doctorId,
                        highlightReportId: item.reportId,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              RecentActivityCard(
                items: visibleRecent,
                titleStyle: theme.textTheme.titleMedium,
                onTapItem: _handleRecentTap,
                subtitle: 'Last 24 hours',
                showReadMore: canReadMoreRecent,
                onReadMore: () {
                  setState(() {
                    _visibleRecentCount = (_visibleRecentCount + _pageSize)
                        .clamp(0, recentAll.length);
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRecentTap(DoctorHomeRecentItem item) async {
    if (item.type == 'prescription' && item.prescriptionId != null) {
      try {
        final details = await client.doctor.getPrescriptionDetails(
          prescriptionId: item.prescriptionId!,
        );

        if (!mounted) return;

        if (details == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription not found.')),
          );
          return;
        }

        await showDialog<void>(
          context: context,
          builder: (_) => PrescriptionDetailsDialog(details: details),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
      return;
    }

    if (!mounted) return;

    if (widget.onOpenReviewReports != null) {
      widget.onOpenReviewReports!(highlightAllUnreviewed: false);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestReportsView(doctorId: widget.doctorId),
      ),
    );
  }
}

/* ---------------- UI Widgets ---------------- */

class HeaderCard extends StatelessWidget {
  const HeaderCard({
    super.key,
    required this.doctorName,
    required this.designation,
    required this.today,
    required this.profilePictureUrl,
    required this.lastMonthPrescriptions,
    required this.lastWeekPrescriptions,
    required this.loading,
  });

  final String doctorName;
  final String designation;
  final DateTime today;
  final String? profilePictureUrl;
  final int lastMonthPrescriptions;
  final int lastWeekPrescriptions;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final dateStr = '${today.day}/${today.month}/${today.year}';
    final maxWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = maxWidth < 560;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(color: Color(0xFF38B6FF)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF6EC9FF),
                    ),
                    child: ClipOval(
                      child: (profilePictureUrl ?? '').trim().isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            )
                          : Image.network(
                              profilePictureUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          doctorName.trim().isEmpty ? '—' : doctorName.trim(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          designation.trim().isEmpty ? ' ' : designation.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4B3A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Today: $dateStr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (isNarrow)
            Column(
              children: [
                StatTile(
                  title: 'Last Month',
                  subtitle: 'Prescriptions',
                  value: '$lastMonthPrescriptions',
                  icon: Icons.description_rounded,
                  accent: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 12),
                StatTile(
                  title: 'Last Week',
                  subtitle: 'Prescriptions (7 days)',
                  value: '$lastWeekPrescriptions',
                  icon: Icons.calendar_today_rounded,
                  accent: const Color(0xFF0EA5A5),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    title: 'Last Month',
                    subtitle: 'Prescriptions',
                    value: '$lastMonthPrescriptions',
                    icon: Icons.description_rounded,
                    accent: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    title: 'Last Week',
                    subtitle: 'Prescriptions (7 days)',
                    value: '$lastWeekPrescriptions',
                    icon: Icons.calendar_today_rounded,
                    accent: const Color(0xFF0EA5A5),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Beginner-friendly reusable widget:
/// shows a small label on top and the value below it.
class LabeledValue extends StatelessWidget {
  const LabeledValue({
    super.key,
    required this.label,
    required this.value,
    this.placeholder = '',
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final String placeholder;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = value.trim().isEmpty ? placeholder : value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              labelStyle ??
              TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          effectiveValue,
          style: valueStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.items,
    required this.titleStyle,
    required this.onTapItem,
    this.subtitle,
    this.showReadMore = false,
    this.onReadMore,
  });

  final List<DoctorHomeRecentItem> items;
  final TextStyle? titleStyle;
  final Future<void> Function(DoctorHomeRecentItem item) onTapItem;
  final String? subtitle;
  final bool showReadMore;
  final VoidCallback? onReadMore;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Recent Activity',
      subtitle: subtitle ?? '',
      trailing: Icon(Icons.show_chart_rounded, color: Colors.grey.shade600),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                'No activity found',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onTapItem(items[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _RecentActivityRow(item: items[i]),
                    ),
                  ),
                  if (i != items.length - 1)
                    Divider(height: 18, color: Colors.grey.shade200),
                ],

                if (showReadMore && onReadMore != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onReadMore,
                      child: const Text('Read more'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.item});
  final DoctorHomeRecentItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          height: 10,
          width: 10,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          item.timeAgo,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class ReviewedReportsCard extends StatelessWidget {
  const ReviewedReportsCard({
    super.key,
    required this.items,
    this.subtitle,
    this.showReadMore = false,
    this.onReadMore,
    this.onTapItem,
  });

  final List<DoctorHomeReviewedReport> items;
  final String? subtitle;
  final bool showReadMore;
  final VoidCallback? onReadMore;
  final void Function(DoctorHomeReviewedReport item)? onTapItem;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Reports',
      subtitle: subtitle ?? '',
      trailing: Icon(Icons.fact_check_rounded, color: Colors.purple.shade700),
      child: items.isEmpty
          ? Text(
              'No reports found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onTapItem == null
                        ? null
                        : () => onTapItem!(items[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _ReviewedReportRow(item: items[i]),
                    ),
                  ),
                  if (i != items.length - 1)
                    Divider(height: 18, color: Colors.grey.shade200),
                ],

                if (showReadMore && onReadMore != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onReadMore,
                      child: const Text('Read more'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ReviewedReportRow extends StatelessWidget {
  const _ReviewedReportRow({required this.item});
  final DoctorHomeReviewedReport item;

  @override
  Widget build(BuildContext context) {
    final iconColor = Colors.purple.shade700;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.fact_check, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.type.isEmpty ? 'Report' : item.type,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                (item.uploadedByName).trim().isEmpty
                    ? 'Uploaded by: Unknown'
                    : 'Uploaded by: ${item.uploadedByName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          item.timeAgo,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class PrescriptionDetailsDialog extends StatelessWidget {
  const PrescriptionDetailsDialog({super.key, required this.details});
  final PatientPrescriptionDetails details;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Prescription #${details.prescriptionId}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patient: ${details.name}'),
              const SizedBox(height: 6),
              Text('Mobile: ${details.mobileNumber ?? ''}'),
              const SizedBox(height: 6),
              Text('Advice: ${details.advice ?? ''}'),
              const SizedBox(height: 10),
              const Text(
                'Medicines:',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              if (details.items.isEmpty)
                const Text('No items')
              else
                for (final it in details.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(() {
                      final dt = dosageTimesDisplayBangla(it.dosageTimes ?? '');
                      return '- ${it.medicineName} | ${dt.isEmpty ? '-' : dt} | ${it.mealTiming ?? ''} | ${it.duration ?? ''}';
                    }()),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
