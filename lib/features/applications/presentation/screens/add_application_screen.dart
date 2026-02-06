import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:job_trekker/domain/models/job_application.dart';
import 'package:job_trekker/core/providers.dart';
import 'package:uuid/uuid.dart';

class AddApplicationScreen extends ConsumerStatefulWidget {
  const AddApplicationScreen({super.key});

  @override
  ConsumerState<AddApplicationScreen> createState() => _AddApplicationScreenState();
}

class _AddApplicationScreenState extends ConsumerState<AddApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  String _jobType = 'Job';
  ApplicationStatus _status = ApplicationStatus.applied;
  DateTime _dateApplied = DateTime.now();

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateApplied,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateApplied) {
      setState(() {
        _dateApplied = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Application'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company Name'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter company name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Role / Position'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter role' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _jobType,
              decoration: const InputDecoration(labelText: 'Job Type'),
              items: ['Job', 'Internship', 'Freelance'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) => setState(() => _jobType = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ApplicationStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ApplicationStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.toString().split('.').last),
                );
              }).toList(),
              onChanged: (val) => setState(() => _status = val!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date Applied'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_dateApplied)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final app = JobApplication(
                    id: const Uuid().v4(),
                    companyName: _companyController.text,
                    role: _roleController.text,
                    jobType: _jobType,
                    dateApplied: _dateApplied,
                    status: _status,
                    lastResponseDate: DateTime.now(),
                    accountEmail: 'manual',
                  );
                  
                  await ref.read(applicationRepositoryProvider).addApplication(app);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save Application'),
            ),
          ],
        ),
      ),
    );
  }
}
