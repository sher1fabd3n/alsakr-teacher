import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../services/api_client.dart';
import '../models/communication_models.dart';

class CommunicationService {
  CommunicationService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ConversationItem>> getConversations({String? search}) async {
    final response = await _apiClient.dio.get(
      '/api/communication/chat/conversations',
      queryParameters: {if (search != null && search.isNotEmpty) 'search': search},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ConversationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessageItem>> getMessages(int conversationId, {int page = 0}) async {
    final response = await _apiClient.dio.get(
      '/api/communication/chat/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'pageSize': 50},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ChatMessageItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessageItem> sendMessage({
    required int conversationId,
    required String body,
  }) async {
    final form = FormData.fromMap({'body': body, 'contentType': 'Text'});
    final response = await _apiClient.dio.post(
      '/api/communication/chat/conversations/$conversationId/messages',
      data: form,
    );
    return ChatMessageItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> markRead(int conversationId) async {
    await _apiClient.dio.post(
      '/api/communication/chat/conversations/$conversationId/read',
    );
  }

  Future<int> startConversation({
    required int parentAccountId,
    required int studentId,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/communication/chat/conversations/start',
      data: {
        'parentAccountId': parentAccountId,
        'studentId': studentId,
      },
    );
    return response.data['conversationId'] as int;
  }

  Future<List<ParentOfStudentItem>> getParentsOfStudent(int studentId) async {
    final response = await _apiClient.dio.get(
      '/api/communication/chat/parents-of-student/$studentId',
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ParentOfStudentItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({int unread, List<NotificationItem> items})> getNotifications({
    int page = 0,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/communication/notifications',
      queryParameters: {'page': page},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return (unread: data['unread'] as int? ?? 0, items: items);
  }

  Future<UnreadSummary> getUnreadSummary() async {
    try {
      final response =
          await _apiClient.dio.get('/api/communication/notifications/unread-summary');
      return UnreadSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      final notes = await getNotifications();
      return UnreadSummary(
        notifications: 0,
        chats: notes.unread,
        tickets: 0,
        total: notes.unread,
      );
    }
  }

  Future<UnreadSummary> markAllNotificationsRead() async {
    try {
      final response =
          await _apiClient.dio.post('/api/communication/notifications/read-all');
      return UnreadSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      final summary = await getUnreadSummary();
      return UnreadSummary(
        notifications: 0,
        chats: summary.chats,
        tickets: summary.tickets,
        total: summary.chats + summary.tickets,
      );
    }
  }

  Future<List<AnnouncementItem>> getAnnouncements() async {
    final response = await _apiClient.dio.get('/api/communication/announcements');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AnnouncementItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String hubUrl(String token) =>
      '${ApiConfig.baseUrl}/hubs/chat?access_token=$token';
}
