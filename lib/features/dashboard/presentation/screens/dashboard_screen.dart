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

// State to track if the recent activity list is expanded
final isExpandedProvider = StateProvider<bool>((ref) => false);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(applicationStatsProvider);
    final isSyncing = ref.watch(gmailSyncProvider);
    final isExpanded = ref.watch(isExpandedProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text(AppStrings.dashboard, style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
               if (isSyncing)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () => ref.read(gmailSyncProvider.notifier).syncEmails(),
                ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildStatsGrid(context, stats),
                const SizedBox(height: 32),
                if ((stats['total'] ?? 0) > 0) ...[
                  Text('Status Distribution', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  SizedBox(height: 220, child: _buildPieChart(stats)),
                  const SizedBox(height: 32),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        ref.read(isExpandedProvider.notifier).state = !isExpanded;
                      },
                      child: Text(isExpanded ? 'Show Less' : 'View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const RecentApplicationsList(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, int> stats) {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _PremiumStatCard(label: 'Total', value: stats['total'] ?? 0, icon: Icons.all_inbox, color: Colors.blue),
        _PremiumStatCard(label: 'Interviews', value: stats['interview'] ?? 0, icon: Icons.video_call, color: Colors.orange),
        _PremiumStatCard(label: 'Offers', value: stats['selected'] ?? 0, icon: Icons.verified, color: Colors.green),
        _PremiumStatCard(label: 'Rejected', value: stats['rejected'] ?? 0, icon: Icons.cancel, color: Colors.red),
      ],
    );
  }

  Widget _buildPieChart(Map<String, int> stats) {
    final List<PieChartSectionData> sections = [];
    final List<Map<String, dynamic>> data = [
      {'value': stats['applied'] ?? 0, 'color': Colors.blue, 'label': 'Applied'},
      {'value': stats['interview'] ?? 0, 'color': Colors.orange, 'label': 'Interview'},
      {'value': stats['selected'] ?? 0, 'color': Colors.green, 'label': 'Offers'},
      {'value': stats['rejected'] ?? 0, 'color': Colors.red, 'label': 'Rejected'},
    ];

    for (var item in data) {
      if (item['value'] > 0) {
        sections.add(
          PieChartSectionData(
            value: item['value'].toDouble(),
            color: item['color'].withOpacity(0.8),
            radius: 60,
            title: '${item['label']}\n${item['value']}',
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            badgeWidget: _buildBadge(item['color']),
            badgePositionPercentageOffset: 1.1,
          ),
        );
      }
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: sections,
      ),
      swapAnimationDuration: const Duration(milliseconds: 800),
      swapAnimationCurve: Curves.easeInOutBack,
    );
  }

  Widget _buildBadge(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _PremiumStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toString(),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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

    return applicationsAsync.when(
      data: (apps) {
        final jobApps = apps.where((a) => !a.isPersonal).toList();
        if (jobApps.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.search_off,
            title: 'No Applications',
            message: 'Tap Sync to fetch from Gmail.',
          );
        }
        
        final sortedApps = [...jobApps]..sort((a,b) => b.dateApplied.compareTo(a.dateApplied));
        // If not expanded, only show first 5. If expanded, show all.
        final displayApps = isExpanded ? sortedApps : sortedApps.take(5).toList();
        
        return AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayApps.length,
            itemBuilder: (context, index) {
              final app = displayApps[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: OpenContainer(
                  transitionDuration: const Duration(milliseconds: 500),
                  openBuilder: (context, _) => ApplicationDetailsScreen(application: app),
                  closedElevation: 0,
                  closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                  closedColor: Theme.of(context).cardColor,
                  closedBuilder: (context, openContainer) => ListTile(
                    onTap: openContainer,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(app.companyName.isNotEmpty ? app.companyName[0] : '?', style: const TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(app.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                    subtitle: Text(app.role, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                    trailing: _CompactStatusChip(status: app.status),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _CompactStatusChip extends StatelessWidget {
  final ApplicationStatus status;
  const _CompactStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ApplicationStatus.applied: color = Colors.blue; break;
      case ApplicationStatus.interview: color = Colors.orange; break;
      case ApplicationStatus.selected: color = Colors.green; break;
      case ApplicationStatus.rejected: color = Colors.red; break;
      case ApplicationStatus.personal: color = Colors.teal; break;
      case ApplicationStatus.expired: color = Colors.grey; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toString().split('.').last.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
