import 'package:googleapis/gmail/v1.dart';
import 'package:http/http.dart' as http;

class GmailService {
  final Map<String, String> authHeaders;

  GmailService(this.authHeaders);

  /// Fetches the latest 100 messages from the inbox.
  /// This is the most robust way to ensure data is retrieved.
  Future<List<Message>> fetchEmails({int maxResults = 100, DateTime? since}) async {
    final client = _AuthenticatedClient(authHeaders);
    final gmailApi = GmailApi(client);

    try {
      // Step 1: Attempt to fetch with a very broad query first
      String query = 'application OR interview OR offer OR career OR internship OR college OR university OR result';
      
      if (since != null) {
        final secondsSinceEpoch = (since.millisecondsSinceEpoch / 1000).floor();
        query += ' after:$secondsSinceEpoch';
      }

      print('Gmail API: Fetching messages with query: $query');
      final response = await gmailApi.users.messages.list(
        'me', 
        maxResults: maxResults,
        q: query,
      );
      
      List<Message> messages = response.messages ?? [];
      
      // Step 2: Critical Fallback - If we found nothing, fetch the absolute latest 100 messages regardless of query
      if (messages.isEmpty) {
        print('Gmail API: No matches for query. Falling back to fetching absolute latest 100 messages...');
        final fallbackResponse = await gmailApi.users.messages.list('me', maxResults: 100);
        messages = fallbackResponse.messages ?? [];
      }
      
      print('Gmail API: Total message headers retrieved: ${messages.length}');
      return messages;
    } catch (e) {
      print('Gmail API List Error: $e');
      // Final Fallback: try one more time without any parameters
      try {
        final finalResponse = await gmailApi.users.messages.list('me', maxResults: 100);
        return finalResponse.messages ?? [];
      } catch (e2) {
        print('Gmail API Fatal Error: $e2');
        return [];
      }
    }
  }

  Future<Message?> getMessageDetails(String messageId) async {
    final client = _AuthenticatedClient(authHeaders);
    final gmailApi = GmailApi(client);
    try {
      // Use format: full to ensure we get the body data for our smart filter
      return await gmailApi.users.messages.get('me', messageId, format: 'full');
    } catch (e) {
      print('Gmail API Get Details Error for $messageId: $e');
      return null;
    }
  }
}

class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
