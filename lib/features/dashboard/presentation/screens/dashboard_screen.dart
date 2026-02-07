import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_trekker/core/constants/app_strings.dart';
import 'package:job_trekker/core/providers.dart';
import 'package:job_trekker/features/applications/application/application_provider.dart';
import 'package:job_trekker/features/gmail/application/gmail_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:job_trekker/features/applications/presentation/screens/application_details_screen.dart';
import 'package:job_trekker/domain/models/job_application.dart';
import 'package:job_trekker/features/common/presentation/widgets/empty_state_widget.dart';
import 'package:animations/animations.dart';

final isExpandedProvider = StateProvider<bool>((ref) => false);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(applicationStatsProvider);
    final isSyncing = ref.watch(gmailSyncProvider);
    final isExpanded = ref.watch(isExpandedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              stretch: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              title: Text(AppStrings.dashboard,
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.5)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsGrid(context, stats, isSyncing),
                  const SizedBox(height: 32),
                  if (isSyncing || (stats['total'] ?? 0) > 0) ...[
                    _buildSectionHeader(context, 'Intelligence Overview'),
                    const SizedBox(height: 20),
                    isSyncing
                      ? _buildSkeletonAnalytics(context)
                      : _buildAnalyticsCard(context, stats),
                    const SizedBox(height: 32),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader(context, 'Activity Stream'),
                      TextButton(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () => ref.read(isExpandedProvider.notifier).state = !isExpanded,
                        child: Text(isExpanded ? 'Show Less' : 'View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  isSyncing
                    ? _buildSkeletonList(context)
                    : const RecentApplicationsList(),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          elevation: 4,
          onPressed: isSyncing ? null : () => ref.read(gmailSyncProvider.notifier).syncEmails(),
          backgroundColor: isSyncing
              ? theme.colorScheme.surfaceVariant
              : theme.colorScheme.primary,
          label: Row(
            children: [
              if (isSyncing)
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70),
                  ),
                )
              else
                const Icon(Icons.sync_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                isSyncing ? 'Syncing Inbox...' : 'Sync Emails',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 1.0));
  }

  Widget _buildAnalyticsCard(BuildContext context, Map<String, int> stats) {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: _buildPieChart(stats),
    );
  }

  Widget _buildSkeletonAnalytics(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.cardTheme.color?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, int> stats, bool isSyncing) {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _PremiumStatCard(label: 'Tracked', value: stats['total'] ?? 0, icon: Icons.auto_awesome_rounded, color: const Color(0xFF0061FF), isSyncing: isSyncing),
        _PremiumStatCard(label: 'Interviews', value: stats['interview'] ?? 0, icon: Icons.videocam_rounded, color: const Color(0xFFFF9500), isSyncing: isSyncing),
        _PremiumStatCard(label: 'Offers', value: stats['selected'] ?? 0, icon: Icons.stars_rounded, color: const Color(0xFF34C759), isSyncing: isSyncing),
        _PremiumStatCard(label: 'Archived', value: stats['rejected'] ?? 0, icon: Icons.inventory_2_rounded, color: const Color(0xFFFF3B30), isSyncing: isSyncing),
      ],
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(3, (index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
        ),
      )),
    );
  }

  Widget _buildPieChart(Map<String, int> stats) {
    final List<PieChartSectionData> sections = [];
    final List<Map<String, dynamic>> data = [
      {'value': stats['applied'] ?? 0, 'color': const Color(0xFF0061FF), 'label': 'App'},
      {'value': stats['interview'] ?? 0, 'color': const Color(0xFFFF9500), 'label': 'Int'},
      {'value': stats['selected'] ?? 0, 'color': const Color(0xFF34C759), 'label': 'Off'},
      {'value': stats['rejected'] ?? 0, 'color': const Color(0xFFFF3B30), 'label': 'Rej'},
    ];

    for (var item in data) {
      if (item['value'] > 0) {
        sections.add(
          PieChartSectionData(
            value: item['value'].toDouble(),
            color: item['color'],
            radius: 55,
            title: '${item['label']} ${item['value']}',
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
            badgeWidget: _buildBadge(item['color']),
            badgePositionPercentageOffset: 1.2,
          ),
        );
      }
    }

    return PieChart(
      PieChartData(sectionsSpace: 4, centerSpaceRadius: 30, sections: sections),
      swapAnimationDuration: const Duration(milliseconds: 800),
      swapAnimationCurve: Curves.easeOutBack,
    );
  }

  Widget _buildBadge(Color color) {
    return Container(
      width: 14, height: 14,
      decoration: BoxDecoration(
        color: color, shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
      ),
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isSyncing;

  const _PremiumStatCard({super.key, required this.label, required this.value, required this.icon, required this.color, this.isSyncing = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: isSyncing 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color.withOpacity(0.3)))
              : Text(value.toString(), 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -1)),
          ),
          Text(label, 
            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class RecentApplicationsList extends ConsumerWidget {
  const RecentApplicationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);
    final isExpanded = ref.watch(isExpandedProvider);
    final theme = Theme.of(context);

    return applicationsAsync.when(
      data: (apps) {
        final jobApps = apps.where((a) => !a.isPersonal).toList();
        if (jobApps.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.auto_awesome_mosaic_rounded,
            title: 'Your Board is Clear',
            message: 'Sync with Gmail to automatically categorize your career emails.',
          );
        }
        
        final sortedApps = [...jobApps]..sort((a,b) => b.dateApplied.compareTo(a.dateApplied));
        final displayApps = isExpanded ? sortedApps : sortedApps.take(5).toList();
        
        return AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayApps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final app = displayApps[index];
              return OpenContainer(
                transitionDuration: const Duration(milliseconds: 500),
                openBuilder: (context, _) => ApplicationDetailsScreen(application: app),
                closedElevation: 0,
                closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                closedColor: theme.cardTheme.color!,
                closedBuilder: (context, openContainer) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
                  ),
                  child: ListTile(
                    onTap: openContainer,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(app.companyName.isNotEmpty ? app.companyName[0] : '?', 
                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(app.companyName, 
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        _CompactStatusChip(status: app.status),
                      ],
                    ),
                    subtitle: Text(app.role, 
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => Column(
        children: List.generate(3, (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
          ),
        )),
      ),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _CompactStatusChip extends StatelessWidget {
  final ApplicationStatus status;
  const _CompactStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ApplicationStatus.applied: color = const Color(0xFF0061FF); break;
      case ApplicationStatus.underReview: color = const Color(0xFF5856D6); break;
      case ApplicationStatus.interview: color = const Color(0xFFFF9500); break;
      case ApplicationStatus.assessment: color = const Color(0xFF007AFF); break;
      case ApplicationStatus.selected: color = const Color(0xFF34C759); break;
      case ApplicationStatus.rejected: color = const Color(0xFFFF3B30); break;
      case ApplicationStatus.personal: color = const Color(0xFF5856D6); break;
      case ApplicationStatus.expired: color = const Color(0xFF8E8E93); break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toString().split('.').last.toUpperCase(), 
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }
}
