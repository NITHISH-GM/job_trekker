import 'package:hive_flutter/hive_flutter.dart';
import 'package:job_trekker/domain/models/job_application.dart';

class ApplicationRepository {
  static const String _boxName = 'job_applications';

  Future<void> init() async {
    await Hive.openBox<JobApplication>(_boxName);
  }

  Box<JobApplication> get _box => Hive.box<JobApplication>(_boxName);

  List<JobApplication> getAllApplications() {
    return _box.values.toList();
  }

  Future<void> addApplication(JobApplication application) async {
    await _box.put(application.id, application);
  }

  Future<void> updateApplication(JobApplication application) async {
    await _box.put(application.id, application);
  }

  Future<void> deleteApplication(String id) async {
    await _box.delete(id);
  }

  Stream<List<JobApplication>> watchApplications() {
    return _box.watch().map((_) => getAllApplications());
  }
}
