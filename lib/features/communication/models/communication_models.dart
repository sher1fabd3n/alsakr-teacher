class ConversationItem {
  final int id;
  final int studentId;
  final String studentName;
  final String studentGrade;
  final String teacherName;
  final String parentName;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.teacherName,
    required this.parentName,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) => ConversationItem(
        id: json['id'] as int,
        studentId: json['studentId'] as int,
        studentName: json['studentName'] as String? ?? '',
        studentGrade: json['studentGrade'] as String? ?? '',
        teacherName: json['teacherName'] as String? ?? '',
        parentName: json['parentName'] as String? ?? '',
        lastMessagePreview: json['lastMessagePreview'] as String?,
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.parse(json['lastMessageAt'] as String)
            : null,
        unreadCount: json['unreadCount'] as int? ?? 0,
      );
}

class ChatMessageItem {
  final int id;
  final int conversationId;
  final String senderRole;
  final int senderId;
  final String? body;
  final String contentType;
  final String deliveryStatus;
  final DateTime sentAt;
  final List<ChatAttachment> attachments;

  const ChatMessageItem({
    required this.id,
    required this.conversationId,
    required this.senderRole,
    required this.senderId,
    this.body,
    required this.contentType,
    required this.deliveryStatus,
    required this.sentAt,
    required this.attachments,
  });

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) {
    final attachments = json['attachments'] as List<dynamic>? ?? [];
    return ChatMessageItem(
      id: (json['id'] as num).toInt(),
      conversationId: (json['conversationId'] as num).toInt(),
      senderRole: json['senderRole'] as String? ?? '',
      senderId: json['senderId'] as int? ?? 0,
      body: json['body'] as String?,
      contentType: json['contentType'] as String? ?? 'Text',
      deliveryStatus: json['deliveryStatus'] as String? ?? 'Sent',
      sentAt: DateTime.parse(json['sentAt'] as String),
      attachments: attachments
          .map((e) => ChatAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatAttachment {
  final int id;
  final String fileName;
  final String contentType;
  final String url;
  final int fileSizeBytes;

  const ChatAttachment({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.url,
    required this.fileSizeBytes,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
        id: json['id'] as int,
        fileName: json['fileName'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        url: json['url'] as String? ?? '',
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      );
}

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final int? conversationId;
  final String? referenceType;
  final int? referenceId;
  final int? studentId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.conversationId,
    this.referenceType,
    this.referenceId,
    this.studentId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: json['type']?.toString() ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        conversationId: (json['conversationId'] as num?)?.toInt(),
        referenceType: json['referenceType'] as String?,
        referenceId: (json['referenceId'] as num?)?.toInt(),
        studentId: (json['studentId'] as num?)?.toInt(),
      );
}

class AnnouncementItem {
  final int id;
  final String title;
  final String body;
  final bool isEmergency;
  final DateTime? sentAt;

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isEmergency,
    this.sentAt,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) => AnnouncementItem(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        isEmergency: json['isEmergency'] as bool? ?? false,
        sentAt: json['sentAt'] != null
            ? DateTime.parse(json['sentAt'] as String)
            : null,
      );
}

class ParentOfStudentItem {
  final int parentAccountId;
  final String fullName;
  final String? phoneNumber;

  const ParentOfStudentItem({
    required this.parentAccountId,
    required this.fullName,
    this.phoneNumber,
  });

  factory ParentOfStudentItem.fromJson(Map<String, dynamic> json) =>
      ParentOfStudentItem(
        parentAccountId: json['parentAccountId'] as int,
        fullName: json['fullName'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String?,
      );
}

class UnreadSummary {
  final int notifications;
  final int chats;
  final int tickets;
  final int total;

  const UnreadSummary({
    required this.notifications,
    required this.chats,
    required this.tickets,
    required this.total,
  });

  factory UnreadSummary.fromJson(Map<String, dynamic> json) {
    final notifications = json['notifications'] as int? ?? 0;
    final chats = json['chats'] as int? ?? 0;
    final tickets = json['tickets'] as int? ?? 0;
    return UnreadSummary(
      notifications: notifications,
      chats: chats,
      tickets: tickets,
      total: json['total'] as int? ?? notifications + chats + tickets,
    );
  }
}
