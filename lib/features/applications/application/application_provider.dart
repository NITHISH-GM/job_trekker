import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_trekker/domain/models/job_application.dart';
import 'package:job_trekker/core/providers.dart';

// We use watch to ensure the provider rebuilds whenever the repository's watch stream emits
final applicationsProvider = StreamProvider<List<JobApplication>>((ref) {
  final repository = ref.watch(applicationRepositoryProvider);
  return repository.watchApplications();
});

final applicationStatsProvider = Provider((ref) {
  // We use .value to get the latest emitted list from the stream
  final applications = ref.watch(applicationsProvider).value ?? [];

  // Only calculate stats for non-personal items for the main dashboard
  final jobApps = applications.where((a) => !a.isPersonal).toList();

  return {
    'total': jobApps.length,
    'applied': jobApps.where((a) => a.status == ApplicationStatus.applied).length,
    'interview': jobApps.where((a) => a.status == ApplicationStatus.interview).length,
    'rejected': jobApps.where((a) => a.status == ApplicationStatus.rejected).length,
    'selected': jobApps.where((a) => a.status == ApplicationStatus.selected).length,
    'personalCount': applications.where((a) => a.isPersonal).length,
  };
});
