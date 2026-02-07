import 'package:job_trekker/domain/models/job_application.dart';
import 'dart:async';

class ApplicationRepository {
  // Direct In-Memory Storage (No Persistence as requested)
  // This ensures data is fetched fresh from Gmail every session.
  final List<JobApplication> _applications = [];
  final _changeController = StreamController<List<JobApplication>>.broadcast();

  Future<void> init() async {
    _notify();
  }

  List<JobApplication> getAllApplications() {
    return List.unmodifiable(_applications);
  }

  Future<void> addApplication(JobApplication application) async {
    // Prevent duplicates in memory
    if (!_applications.any((a) => a.gmailMessageId == application.gmailMessageId)) {
      _applications.add(application);
      _notify();
    }
  }

  Future<void> clearAll() async {
    _applications.clear();
    _notify();
  }

  void _notify() {
    if (!_changeController.isClosed) {
      _changeController.add(getAllApplications());
    }
  }

  Stream<List<JobApplication>> watchApplications() async* {
    yield getAllApplications();
    yield* _changeController.stream;
  }
}
