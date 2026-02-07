import 'package:hive_flutter/hive_flutter.dart';
import 'package:job_trekker/domain/models/job_application.dart';
import 'dart:async';

class ApplicationRepository {
  static const String _boxName = 'job_applications';
  
  final _changeController = StreamController<List<JobApplication>>.broadcast();

  Future<void> init() async {
    await Hive.openBox<JobApplication>(_boxName);
    _notify();
  }

  Box<JobApplication> get _box => Hive.box<JobApplication>(_boxName);

  List<JobApplication> getAllApplications() {
    return _box.values.toList();
  }

  Future<void> addApplication(JobApplication application) async {
    await _box.put(application.id, application);
    _notify();
  }

  Future<void> updateApplication(JobApplication application) async {
    await _box.put(application.id, application);
    _notify();
  }

  Future<void> deleteApplication(String id) async {
    await _box.delete(id);
    _notify();
  }

  void _notify() {
    if (!_changeController.isClosed) {
      _changeController.add(getAllApplications());
    }
  }

  Stream<List<JobApplication>> watchApplications() async* {
    // Start by yielding the current data immediately
    yield getAllApplications();
    // Then pipe all future updates
    yield* _changeController.stream;
  }
}
