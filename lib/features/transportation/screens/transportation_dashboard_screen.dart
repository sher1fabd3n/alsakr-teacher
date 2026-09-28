import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../models/transportation_models.dart';
import '../services/transportation_service.dart';
import 'live_tracking_screen.dart';
import 'private_driver_form_screen.dart';
import 'parent_trip_history_screen.dart';
import 'transport_notifications_screen.dart';
import 'transportation_card_screen.dart';

class TransportationDashboardScreen extends StatefulWidget {
  const TransportationDashboardScreen({super.key, this.studentId});

  final int? studentId;

  @override
  State<TransportationDashboardScreen> createState() => _TransportationDashboardScreenState();
}

class _TransportationDashboardScreenState extends State<TransportationDashboardScreen> {
  late Future<TransportDashboard> _future;
  late Future<TransportationCardData?> _cardFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final service = context.read<TransportationService>();
    _future = service.getDashboard(studentId: widget.studentId);
    _cardFuture = _loadCard(service);
  }

  Future<TransportationCardData?> _loadCard(TransportationService service) async {
    try {
      return await service.getCard(studentId: widget.studentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('النقل المدرسي')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await Future.wait([_future, _cardFuture]);
        },
        child: FutureBuilder<TransportDashboard>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(snapshot.error.toString()),
                  ),
                ],
              );
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مرحباً بك في نظام النقل',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.transportationType == 'None'
                              ? 'لم يتم تحديد نوع النقل بعد'
                              : data.isSchoolBus
                                  ? 'حافلة مدرسية • ${data.routeName ?? 'بدون مسار'}'
                                  : 'نقل خاص',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<TransportationCardData?>(
                  future: _cardFuture,
                  builder: (context, cardSnap) {
                    final card = cardSnap.data;
                    if (card == null) return const SizedBox.shrink();
                    if (card.isSchoolBus && card.schoolBus != null) {
                      final bus = card.schoolBus!;
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('معلومات الحافلة', style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text('المسار: ${bus.routeName}'),
                            Text('الحافلة: ${bus.busNumber}'),
                            Text('السائق: ${bus.driverName} • ${bus.driverPhone}'),
                            Text('المشرف: ${bus.supervisorName} • ${bus.supervisorPhone}'),
                          ],
                        ),
                      );
                    }
                    if (card.private != null) {
                      final p = card.private!;
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('النقل الخاص', style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text('السائق: ${p.driverFullName} • ${p.driverPhone}'),
                            Text('المركبة: ${p.vehicleType} ${p.vehicleModel ?? ''} • ${p.vehiclePlateNumber}'),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'الخدمات'),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.badge_rounded,
                  title: 'بطاقة النقل',
                  subtitle: 'عرض • تحميل • طباعة • مشاركة',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TransportationCardScreen(studentId: widget.studentId),
                    ),
                  ),
                ),
                if (data.isSchoolBus && data.hasActiveTrip)
                  _ActionTile(
                    icon: Icons.map_rounded,
                    title: 'تتبع الحافلة مباشرة',
                    subtitle: 'خريطة حية • ETA • حالة الرحلة',
                    color: AppColors.accent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LiveTrackingScreen(
                          studentId: widget.studentId,
                          tripId: data.activeTripId,
                        ),
                      ),
                    ),
                  ),
                if (data.isPrivate)
                  _ActionTile(
                    icon: Icons.edit_road_rounded,
                    title: 'بيانات سائق النقل الخاص',
                    subtitle: 'تحديث بيانات السائق والمركبة',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PrivateDriverFormScreen(studentId: widget.studentId ?? 0),
                      ),
                    ),
                  ),
                _ActionTile(
                  icon: Icons.history_rounded,
                  title: 'سجل الرحلات',
                  subtitle: 'صعود • نزول • حضور',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ParentTripHistoryScreen(studentId: widget.studentId),
                    ),
                  ),
                ),
                _ActionTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'إشعارات النقل',
                  subtitle: data.unreadNotifications > 0
                      ? '${data.unreadNotifications} إشعار غير مقروء'
                      : 'لا توجد إشعارات جديدة',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TransportNotificationsScreen(studentId: widget.studentId),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left_rounded),
        ),
      ),
    );
  }
}
