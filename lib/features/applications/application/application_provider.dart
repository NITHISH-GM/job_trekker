import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_trekker/domain/models/job_application.dart';
import 'package:job_trekker/core/providers.dart';

final applicationsProvider = StreamProvider<List<JobApplication>>((ref) {
  final repository = ref.watch(applicationRepositoryProvider);
  return repository.watchApplications();
});

final applicationStatsProvider = Provider((ref) {
  final applications = ref.watch(applicationsProvider).value ?? [];
  
  return {
    'total': applications.length,
    'applied': applications.where((a) => a.status == ApplicationStatus.applied).length,
    'interview': applications.where((a) => a.status == ApplicationStatus.interview).length,
    'rejected': applications.where((a) => a.status == ApplicationStatus.rejected).length,
    'selected': applications.where((a) => a.status == ApplicationStatus.selected).length,
  };
});
