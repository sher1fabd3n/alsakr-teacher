import 'package:flutter/material.dart';

import '../features/communication/models/communication_models.dart';
import '../features/communication/screens/announcement_center_screen.dart';
import '../features/communication/screens/conversation_screen.dart';

class NotificationRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> open(Map<String, String> data) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final type = '${data['type'] ?? ''} ${data['referenceType'] ?? ''}'.toLowerCase();
    final conversationId = int.tryParse(data['conversationId'] ?? '');

    if (type.contains('announcement') || type.contains('emergency')) {
      nav.push(MaterialPageRoute(builder: (_) => const AnnouncementCenterScreen()));
      return;
    }

    if (conversationId == null) return;

    nav.push(MaterialPageRoute(
      builder: (_) => ConversationScreen(
        conversation: ConversationItem(
          id: conversationId,
          studentId: int.tryParse(data['studentId'] ?? '') ?? 0,
          studentName: data['senderName'] ?? data['title'] ?? 'محادثة',
          studentGrade: '',
          teacherName: '',
          parentName: data['senderName'] ?? '',
          unreadCount: 0,
        ),
      ),
    ));
  }
}
