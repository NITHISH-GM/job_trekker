import 'package:hive_flutter/hive_flutter.dart';
import 'package:job_trekker/domain/models/job_application.dart';
import 'package:job_trekker/domain/models/linked_account.dart';

class HiveRepository {
  static const String jobApplicationsBoxName = 'job_applications';
  static const String linkedAccountsBoxName = 'linked_accounts';
  static const String metadataBoxName = 'metadata';

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    _registerAdapters();
    
    // Open all necessary boxes
    await Hive.openBox<JobApplication>(jobApplicationsBoxName);
    await Hive.openBox<LinkedAccount>(linkedAccountsBoxName);
    await Hive.openBox(metadataBoxName);
  }

  void _registerAdapters() {
    // Check if adapters are already registered to prevent errors on hot reload
    if (!Hive.isAdapterRegistered(JobApplicationAdapter().typeId)) {
      Hive.registerAdapter(JobApplicationAdapter());
    }
    if (!Hive.isAdapterRegistered(ApplicationStatusAdapter().typeId)) {
      Hive.registerAdapter(ApplicationStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(ApplicationEventAdapter().typeId)) {
      Hive.registerAdapter(ApplicationEventAdapter());
    }
    if (!Hive.isAdapterRegistered(LinkedAccountAdapter().typeId)) {
      Hive.registerAdapter(LinkedAccountAdapter());
    }
    // Added missing ApplicationPriority adapter registration
    if (!Hive.isAdapterRegistered(ApplicationPriorityAdapter().typeId)) {
      Hive.registerAdapter(ApplicationPriorityAdapter());
    }
  }

  Future<void> close() async {
    await Hive.close();
  }
}
