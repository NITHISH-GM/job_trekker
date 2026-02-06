import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_trekker/features/applications/application/application_provider.dart';
import 'package:job_trekker/features/common/presentation/widgets/empty_state_widget.dart';
import 'package:job_trekker/features/gmail/application/gmail_provider.dart';
import 'package:intl/intl.dart';

class PersonalMailsScreen extends ConsumerWidget {
  const PersonalMailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);
    final isSyncing = ref.watch(gmailSyncProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('College & Personal', style: TextStyle(fontWeight: FontWeight.bold)),
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
          SliverToBoxAdapter(
            child: applicationsAsync.when(
              data: (apps) {
                final personalApps = apps.where((a) => a.isPersonal).toList()
                  ..sort((a, b) => b.dateApplied.compareTo(a.dateApplied));

                if (personalApps.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: EmptyStateWidget(
                      icon: Icons.school_outlined,
                      title: 'No College Mails',
                      message: 'Mails from college domains or containing student keywords will appear here.',
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: personalApps.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final app = personalApps[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school, color: Colors.purple, size: 20),
                        ),
                        title: Text(
                          app.companyName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              app.notes ?? 'Notification',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(app.dateApplied),
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                           _showDetails(context, app);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(64.0),
                child: CircularProgressIndicator(),
              )),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, dynamic app) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(app.companyName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(DateFormat('MMMM dd, yyyy').format(app.dateApplied), style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  app.notes ?? 'No detailed information available.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
