import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:job_trekker/domain/models/job_application.dart';
import 'package:job_trekker/features/applications/application/application_provider.dart';
import 'package:job_trekker/features/common/presentation/widgets/empty_state_widget.dart';
import 'application_details_screen.dart';
import 'add_application_screen.dart';
import 'package:animations/animations.dart';

class ApplicationsListScreen extends ConsumerWidget {
  const ApplicationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: applicationsAsync.when(
        data: (apps) {
          // Only show non-personal job applications here
          final jobApps = apps.where((a) => !a.isPersonal).toList();

          if (jobApps.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: EmptyStateWidget(
                icon: Icons.work_outline,
                title: 'No Job Applications',
                message: 'Sync from Gmail or add one manually to start tracking.',
              ),
            );
          }

          final sortedApps = [...jobApps]..sort((a, b) => b.dateApplied.compareTo(a.dateApplied));

          return ListView.builder(
            itemCount: sortedApps.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final app = sortedApps[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OpenContainer(
                  transitionDuration: const Duration(milliseconds: 500),
                  openBuilder: (context, _) => ApplicationDetailsScreen(application: app),
                  closedElevation: 0,
                  closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  closedColor: Theme.of(context).cardColor,
                  closedBuilder: (context, openContainer) => ListTile(
                    onTap: openContainer,
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(app.status).withOpacity(0.1),
                      child: Icon(_getStatusIcon(app.status), color: _getStatusColor(app.status), size: 20),
                    ),
                    title: Text(app.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(app.role),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddApplicationScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied: return Icons.send;
      case ApplicationStatus.interview: return Icons.video_call;
      case ApplicationStatus.selected: return Icons.check_circle;
      case ApplicationStatus.rejected: return Icons.cancel;
      default: return Icons.info;
    }
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied: return Colors.blue;
      case ApplicationStatus.interview: return Colors.orange;
      case ApplicationStatus.selected: return Colors.green;
      case ApplicationStatus.rejected: return Colors.red;
      default: return Colors.grey;
    }
  }
}
