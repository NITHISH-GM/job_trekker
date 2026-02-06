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
      debugPrint('Gmail Sync: Starting robust process to fetch last 100 messages...');
      
      final authService = ref.read(authServiceProvider);
      final headers = await authService.getAuthHeaders();

      if (headers == null) {
        debugPrint('Gmail Sync: ERROR - No Auth Headers found. Re-authentication might be needed.');
        state = false;
        return;
      }

      final gmailService = GmailService(headers);

      DateTime? lastSyncTime = ref.read(lastSyncTimeProvider);
      // If we've never synced, don't use since to get the absolute latest 100.
      // If we have synced, use since to only get new ones.
      
      final messages = await gmailService.fetchEmails(maxResults: 100, since: lastSyncTime);
      final repository = ref.read(applicationRepositoryProvider);
      
      debugPrint('Gmail Sync: Fetched ${messages.length} headers. Analyzing bodies...');

      if (messages.isEmpty) {
         debugPrint('Gmail Sync: No new messages found.');
         _updateSyncMetadata();
         state = false;
         return;
      }

      int newItemsCount = 0;
      int errorCount = 0;
      
      final List<gmail.Message> messagesToProcess = [];
      for (var msg in messages) {
        if (msg.id == null) continue;
        final exists = repository.getAllApplications().any((a) => a.gmailMessageId == msg.id);
        if (!exists) {
          messagesToProcess.add(msg);
        }
      }

      debugPrint('Gmail Sync: ${messagesToProcess.length} new messages to process in batches.');

      // Process in smaller batches to be fast but stable and respect API limits
      for (int i = 0; i < messagesToProcess.length; i += 5) {
        final end = (i + 5 < messagesToProcess.length) ? i + 5 : messagesToProcess.length;
        final batch = messagesToProcess.sublist(i, end);
        
        final List<Future<bool>> batchTasks = batch.map((msg) => 
          _processMessage(gmailService, msg.id!, repository)
        ).toList();

        try {
          final results = await Future.wait(batchTasks);
          newItemsCount += results.where((r) => r).length;
        } catch (e) {
          debugPrint('Gmail Sync: Error processing batch starting at $i: $e');
          errorCount += batch.length;
        }
        
        // Small delay to ensure API stability
        await Future.delayed(const Duration(milliseconds: 150));
      }

      debugPrint('Gmail Sync: COMPLETE. Added $newItemsCount new items. Errors: $errorCount');
      _updateSyncMetadata();
      _autoExpireApplications();

    } catch (e) {
      debugPrint('Gmail Sync CRITICAL ERROR: $e');
    } finally {
      state = false;
    }
  }

  Future<bool> _processMessage(GmailService service, String id, dynamic repository) async {
    try {
      final details = await service.getMessageDetails(id);
      if (details == null) return false;

      String accountEmail = 'me';
      final headers = details.payload?.headers;
      if (headers != null) {
        try {
          final toHeader = headers.firstWhere((h) => h.name?.toLowerCase() == 'to');
          accountEmail = toHeader.value ?? 'me';
        } catch (_) {}
      }

      final application = _parseEmailToApplication(details, accountEmail);
      if (application != null) {
        await repository.addApplication(application);
        return true;
      }
    } catch (e) {
      debugPrint('Error processing individual message $id: $e');
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
            status: ApplicationStatus.rejected,
            lastResponseDate: app.lastResponseDate,
            accountEmail: app.accountEmail,
            notes: '${app.notes}\n[Auto-Expired: No activity for 60 days]',
            gmailMessageId: app.gmailMessageId,
            location: app.location,
            salary: app.salary,
            timeline: [
              ...(app.timeline ?? []),
              ApplicationEvent(date: now, title: 'Auto-Expired', description: 'Marked as rejected due to 60 days of inactivity.'),
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

    final transactionKeywords = ['receipt', 'order', 'payment', 'subscription', 'invoice', 'billed', 'transaction', 'purchased', 'total amount'];
    if (transactionKeywords.any((k) => fullContent.contains(k))) return null;

    final collegeKeywords = ['college', 'university', 'student', 'professor', 'exam', 'lecture', 'assignment', 'campus', 'semester', 'hall ticket', 'admit card', 'result', 'degree', 'tuition'];
    bool isCollege = collegeKeywords.any((k) => fullContent.contains(k)) || from.toLowerCase().contains('.edu');

    final jobKeywords = [
      'application', 'interview', 'offer', 'hiring', 'career', 'internship', 
      'job', 'position', 'received', 'confirmed', 'opportunity',
      'shortlisted', 'recruitment', 'assessment', 'test', 'candidate', 'onboarding'
    ];
    bool isJob = jobKeywords.any((k) => fullContent.contains(k));

    if (!isJob && !isCollege) return null;

    if (from.contains('newsletter') || from.contains('notification@facebook') || from.contains('notification@linkedin')) {
      return null;
    }

    String companyName = _extractCompany(from);
    String role = isCollege ? 'Academic Notification' : _extractRole(subject, body);
    String? salary = isCollege ? null : _extractSalary(body);
    String? location = isCollege ? null : _extractLocation(body);

    final dateApplied = _parseDate(dateStr);

    return JobApplication(
      id: const Uuid().v4(),
      companyName: companyName,
      role: role,
      jobType: isCollege ? 'Academic' : ((fullContent.contains('intern')) ? 'Internship' : 'Job'),
      dateApplied: dateApplied,
      status: isCollege ? ApplicationStatus.personal : _determineStatus(subject, body),
      lastResponseDate: DateTime.now(),
      accountEmail: accountEmail,
      gmailMessageId: message.id,
      notes: body,
      salary: salary,
      location: location,
      timeline: [
        ApplicationEvent(date: dateApplied, title: isCollege ? 'Mail Received' : 'Application Detected', description: subject),
      ],
      isPersonal: isCollege,
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
      name = name.replaceAll('"', '');
      return name.isEmpty ? from : name;
    }
    return from;
  }

  String _extractRole(String subject, String body) {
    final roleRegex = RegExp(r'(?:role|position|for the post of|applying for|opening for)\s*:?\s*([^,\n\.]+)', caseSensitive: false);
    final match = roleRegex.firstMatch('$subject $body');
    if (match != null && match.group(1) != null) {
      String extracted = match.group(1)!.trim();
      if (extracted.length > 2 && extracted.length < 60) return extracted;
    }
    return subject.replaceAll(RegExp(r'(RE:|Fwd:|application for|received:|thank you for applying to)', caseSensitive: false), '').trim();
  }

  String? _extractSalary(String body) {
    final salaryRegex = RegExp(r'(?:\$|£|€|INR|Rs\.?)\s?(\d+[,.]?\d*\s?[kKmM]?)', caseSensitive: false);
    final match = salaryRegex.firstMatch(body);
    return match?.group(0);
  }

  String? _extractLocation(String body) {
    final locationRegex = RegExp(r'(?:Location|Remote|Based in|at)\s*:?\s*([A-Z][a-z]+(?: [A-Z][a-z]+)*)', caseSensitive: false);
    final match = locationRegex.firstMatch(body);
    return match?.group(1);
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateTime.tryParse(dateStr) ?? DateTime.now();
    } catch (_) { return DateTime.now(); }
  }

  ApplicationStatus _determineStatus(String subject, String body) {
    final s = (subject + body).toLowerCase();
    
    if ((s.contains('offer') || s.contains('congratulations') || s.contains('selected')) && 
        !s.contains('payment') && !s.contains('subscription')) {
      return ApplicationStatus.selected;
    }

    if (s.contains('interview') || s.contains('schedule') || s.contains('invite') || s.contains('call')) return ApplicationStatus.interview;
    if (s.contains('unfortunately') || s.contains('rejected') || s.contains('not moving forward')) return ApplicationStatus.rejected;
    if (s.contains('assessment') || s.contains('test') || s.contains('assignment')) return ApplicationStatus.assessment;
    if (s.contains('reviewing') || s.contains('processing')) return ApplicationStatus.underReview;
    return ApplicationStatus.applied;
  }
}
