import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:job_trekker/core/services/gmail_service.dart';
import 'package:job_trekker/domain/models/job_application.dart';
import 'package:job_trekker/core/providers.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

final gmailSyncProvider = StateNotifierProvider<GmailSyncNotifier, bool>((ref) {
  return GmailSyncNotifier(ref);
});

final lastSyncTimeProvider = StateProvider<DateTime?>((ref) {
  final box = Hive.box('metadata');
  final timestamp = box.get('lastSyncTime');
  return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
});

class GmailSyncNotifier extends StateNotifier<bool> {
  final Ref ref;
  GmailSyncNotifier(this.ref) : super(false);

  Future<void> syncEmails() async {
    if (state) return;
    state = true;

    try {
      debugPrint('Gmail Sync: Starting robust sync...');
      
      final authService = ref.read(authServiceProvider);
      final headers = await authService.getAuthHeaders();

      if (headers == null) {
        debugPrint('Gmail Sync: ERROR - No Auth Headers.');
        state = false;
        return;
      }

      final gmailService = GmailService(headers);
      final repository = ref.read(applicationRepositoryProvider);

      // To make it robust, we'll fetch latest 100 regardless of lastSyncTime if the repo is small,
      // but we use lastSyncTime to skip already processed ones efficiently.
      DateTime? lastSyncTime = ref.read(lastSyncTimeProvider);
      final messages = await gmailService.fetchEmails(maxResults: 100, since: lastSyncTime);

      debugPrint('Gmail Sync: Fetched ${messages.length} headers.');

      if (messages.isEmpty) {
         _updateSyncMetadata();
         state = false;
         return;
      }

      int newItemsCount = 0;
      final List<gmail.Message> toProcess = [];
      
      for (var msg in messages) {
        if (msg.id == null) continue;
        final exists = repository.getAllApplications().any((a) => a.gmailMessageId == msg.id);
        if (!exists) toProcess.add(msg);
      }

      debugPrint('Gmail Sync: ${toProcess.length} new messages to analyze.');

      // Process in batches
      for (int i = 0; i < toProcess.length; i += 5) {
        final end = (i + 5 < toProcess.length) ? i + 5 : toProcess.length;
        final batch = toProcess.sublist(i, end);
        
        final List<Future<bool>> tasks = batch.map((msg) =>
          _processMessage(gmailService, msg.id!, repository)
        ).toList();

        final results = await Future.wait(tasks);
        newItemsCount += results.where((r) => r).length;
        
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('Gmail Sync: COMPLETE. Added $newItemsCount new items.');
      _updateSyncMetadata();
      _autoExpireApplications();

    } catch (e) {
      debugPrint('Gmail Sync ERROR: $e');
    } finally {
      state = false;
    }
  }

  Future<bool> _processMessage(GmailService service, String id, dynamic repository) async {
    try {
      final details = await service.getMessageDetails(id);
      if (details == null) return false;

      final headers = details.payload?.headers;
      String accountEmail = 'me';
      if (headers != null) {
        try {
          final found = headers.where((h) => h.name?.toLowerCase() == 'to');
          if (found.isNotEmpty) accountEmail = found.first.value ?? 'me';
        } catch (_) {}
      }

      final application = _parseEmailToApplication(details, accountEmail);
      if (application != null) {
        await repository.addApplication(application);
        return true;
      }
    } catch (e) {
      debugPrint('Msg processing fail ($id): $e');
    }
    return false;
  }

  void _updateSyncMetadata() {
    final now = DateTime.now();
    Hive.box('metadata').put('lastSyncTime', now.millisecondsSinceEpoch);
    ref.read(lastSyncTimeProvider.notifier).state = now;
  }

  void _autoExpireApplications() async {
    final repository = ref.read(applicationRepositoryProvider);
    final apps = repository.getAllApplications();
    final now = DateTime.now();

    for (var app in apps) {
      if (!app.isPersonal && (app.status == ApplicationStatus.applied || app.status == ApplicationStatus.underReview)) {
        if (now.difference(app.dateApplied).inDays > 60) {
          final updatedApp = JobApplication(
            id: app.id,
            companyName: app.companyName,
            role: app.role,
            jobType: app.jobType,
            dateApplied: app.dateApplied,
            status: ApplicationStatus.expired,
            lastResponseDate: app.lastResponseDate,
            accountEmail: app.accountEmail,
            notes: '${app.notes}\n[System: Auto-Expired]',
            gmailMessageId: app.gmailMessageId,
            location: app.location,
            salary: app.salary,
            timeline: [
              ...(app.timeline ?? []),
              ApplicationEvent(date: now, title: 'Marked Expired', description: 'No updates for 60 days.'),
            ],
            isPersonal: app.isPersonal,
          );
          await repository.updateApplication(updatedApp);
        }
      }
    }
  }

  JobApplication? _parseEmailToApplication(gmail.Message message, String accountEmail) {
    final payload = message.payload;
    if (payload == null) return null;
    
    final headers = payload.headers;
    if (headers == null) return null;

    String getHeader(String name) {
      try {
        final found = headers.where((h) => h.name?.toLowerCase() == name.toLowerCase());
        return found.isNotEmpty ? found.first.value ?? '' : '';
      } catch (_) { return ''; }
    }

    final subject = getHeader('Subject');
    final from = getHeader('From');
    final dateStr = getHeader('Date');

    String body = _extractBody(payload);
    String fullContent = '$subject $body'.toLowerCase();

    // Premium Filtering Logic: Scoring
    int jobScore = 0;
    int collegeScore = 0;

    final jobWords = ['application', 'interview', 'offer', 'hiring', 'career', 'internship', 'job', 'position', 'shortlisted', 'recruitment', 'candidate'];
    final collegeWords = ['college', 'university', 'student', 'professor', 'exam', 'lecture', 'assignment', 'campus', 'semester', 'result', 'admit card', 'degree'];

    for (var w in jobWords) { if (fullContent.contains(w)) jobScore++; }
    for (var w in collegeWords) { if (fullContent.contains(w)) collegeScore++; }

    bool isPersonal = collegeScore > jobScore || from.toLowerCase().contains('.edu');
    bool isRelevant = jobScore > 0 || collegeScore > 0;

    if (!isRelevant) return null;

    // Filter noise
    if (from.contains('newsletter') || from.contains('notification') || from.contains('social')) return null;
    if (fullContent.contains('receipt') || fullContent.contains('invoice') || fullContent.contains('subscription')) return null;

    String companyName = _extractCompany(from);
    String role = isPersonal ? 'Academic Item' : _extractRole(subject, body);

    final dateApplied = _parseDate(dateStr);

    return JobApplication(
      id: const Uuid().v4(),
      companyName: companyName,
      role: role,
      jobType: isPersonal ? 'Academic' : (fullContent.contains('intern') ? 'Internship' : 'Job'),
      dateApplied: dateApplied,
      status: isPersonal ? ApplicationStatus.personal : _determineStatus(subject, body),
      lastResponseDate: DateTime.now(),
      accountEmail: accountEmail,
      gmailMessageId: message.id,
      notes: body,
      location: _extractLocation(body),
      salary: _extractSalary(body),
      timeline: [
        ApplicationEvent(date: dateApplied, title: isPersonal ? 'Mail Received' : 'Application Detected', description: subject),
      ],
      isPersonal: isPersonal,
    );
  }

  String _extractBody(gmail.MessagePart part) {
    if (part.body?.data != null) {
      try {
        return utf8.decode(base64Url.decode(part.body!.data!));
      } catch (_) { return ''; }
    }
    if (part.parts != null) {
      return part.parts!.map((p) => _extractBody(p)).join(' ');
    }
    return '';
  }

  String _extractCompany(String from) {
    if (from.contains('<')) {
      String name = from.split('<')[0].trim();
      return name.replaceAll('"', '').isEmpty ? from : name.replaceAll('"', '');
    }
    return from;
  }

  String _extractRole(String subject, String body) {
    final roleRegex = RegExp(r'(?:role|position|applying for|opening for)\s*:?\s*([^,\n\.]+)', caseSensitive: false);
    final match = roleRegex.firstMatch('$subject $body');
    if (match != null && match.group(1) != null) {
      String extracted = match.group(1)!.trim();
      if (extracted.length > 2 && extracted.length < 60) return extracted;
    }
    return subject.replaceAll(RegExp(r'(RE:|Fwd:|application for|received:)', caseSensitive: false), '').trim();
  }

  String? _extractSalary(String body) {
    final match = RegExp(r'(?:\$|£|€|INR|Rs\.?)\s?(\d+[,.]?\d*\s?[kKmM]?)', caseSensitive: false).firstMatch(body);
    return match?.group(0);
  }

  String? _extractLocation(String body) {
    final match = RegExp(r'(?:Location|Remote|Based in|at)\s*:?\s*([A-Z][a-z]+(?: [A-Z][a-z]+)*)', caseSensitive: false).firstMatch(body);
    return match?.group(1);
  }

  DateTime _parseDate(String dateStr) {
    try { return DateTime.tryParse(dateStr) ?? DateTime.now(); } catch (_) { return DateTime.now(); }
  }

  ApplicationStatus _determineStatus(String subject, String body) {
    final s = (subject + body).toLowerCase();
    if (s.contains('offer') || s.contains('congratulations')) return ApplicationStatus.selected;
    if (s.contains('interview') || s.contains('schedule') || s.contains('call')) return ApplicationStatus.interview;
    if (s.contains('rejected') || s.contains('unfortunately')) return ApplicationStatus.rejected;
    if (s.contains('assessment') || s.contains('test')) return ApplicationStatus.assessment;
    return ApplicationStatus.applied;
  }
}
