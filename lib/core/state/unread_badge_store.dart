import 'package:flutter/foundation.dart';

import '../../features/communication/models/communication_models.dart';
import '../../features/communication/services/communication_service.dart';
import '../../services/notification_router.dart';
import '../../services/push_notification_service.dart';

class UnreadBadgeStore extends ChangeNotifier {
  UnreadBadgeStore(this._communication, this._push) {
    _push.onIncomingMessage = _onIncoming;
    _push.onOpenedFromNotification = _onOpened;
  }

  final CommunicationService _communication;
  final PushNotificationService _push;

  int notificationCount = 0;
  int chatCount = 0;
  int ticketCount = 0;
  bool _refreshing = false;

  int get total => notificationCount + chatCount + ticketCount;

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final summary = await _communication.getUnreadSummary();
      _apply(summary);
      await _push.syncLauncherBadge(total);
    } catch (_) {
    } finally {
      _refreshing = false;
    }
  }

  Future<void> markNotificationsOpened() async {
    notificationCount = 0;
    notifyListeners();
    await _push.syncLauncherBadge(total, clearTray: total == 0);
    try {
      _apply(await _communication.markAllNotificationsRead());
      await _push.syncLauncherBadge(total, clearTray: total == 0);
    } catch (_) {
      await refresh();
    }
  }

  Future<void> reset() async {
    notificationCount = 0;
    chatCount = 0;
    ticketCount = 0;
    notifyListeners();
    await _push.syncLauncherBadge(0, clearTray: true);
  }

  void _apply(UnreadSummary summary) {
    notificationCount = summary.notifications;
    chatCount = summary.chats;
    ticketCount = summary.tickets;
    notifyListeners();
  }

  Future<void> _onOpened(Map<String, String> data) async {
    await refresh();
    await NotificationRouter.open(data);
  }

  void _onIncoming(String type) {
    if (type == 'chat') {
      chatCount += 1;
    } else if (type == 'ticket') {
      ticketCount += 1;
    } else {
      notificationCount += 1;
    }
    notifyListeners();
    _push.syncLauncherBadge(total);
    refresh();
  }

  @override
  void dispose() {
    if (_push.onIncomingMessage == _onIncoming) {
      _push.onIncomingMessage = null;
    }
    if (_push.onOpenedFromNotification == _onOpened) {
      _push.onOpenedFromNotification = null;
    }
    super.dispose();
  }
}
