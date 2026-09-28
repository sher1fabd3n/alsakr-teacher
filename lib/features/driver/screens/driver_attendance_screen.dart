import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../transportation/models/transportation_models.dart';
import '../services/driver_service.dart';

class DriverAttendanceScreen extends StatelessWidget {
  const DriverAttendanceScreen({super.key, required this.tripId, required this.attendance});

  final int tripId;
  final List<DriverAttendanceStudent> attendance;

  @override
  Widget build(BuildContext context) {
    final boarded = attendance.where((s) => s.isBoarded).toList();
    final missing = attendance.where((s) => s.isMissing || s.tripStatus == 'Pending').toList();
    final delivered = attendance.where((s) => s.isDelivered).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('حضور الحافلة')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SummaryRow(boarded: boarded.length, missing: missing.length, delivered: delivered.length),
          const SizedBox(height: 20),
          _Section(title: 'صعدوا الحافلة', color: AppColors.success, students: boarded, tripId: tripId),
          const SizedBox(height: 16),
          _Section(title: 'لم يُلتقطوا / غائبون', color: AppColors.accent, students: missing, tripId: tripId),
          const SizedBox(height: 16),
          _Section(title: 'تم التوصيل', color: const Color(0xFF2563EB), students: delivered, tripId: tripId),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.boarded, required this.missing, required this.delivered});

  final int boarded;
  final int missing;
  final int delivered;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _box('صعدوا', boarded, AppColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _box('مفقودون', missing, AppColors.accent)),
        const SizedBox(width: 8),
        Expanded(child: _box('تم التوصيل', delivered, const Color(0xFF2563EB))),
      ],
    );
  }

  Widget _box(String label, int count, Color color) => AppCard(
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
            Text(label),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.color, required this.students, required this.tripId});

  final String title;
  final Color color;
  final List<DriverAttendanceStudent> students;
  final int tripId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 8),
        if (students.isEmpty)
          const AppCard(child: Text('لا يوجد طلاب في هذه الفئة'))
        else
          ...students.map((s) => AppCard(
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text('${s.grade} • ${s.tripStatus}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (status) => _update(context, s.studentId, status),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'Boarded', child: Text('صعد')),
                      PopupMenuItem(value: 'DroppedAtSchool', child: Text('وصل المدرسة')),
                      PopupMenuItem(value: 'ArrivedHome', child: Text('وصل المنزل')),
                      PopupMenuItem(value: 'Absent', child: Text('غائب')),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Future<void> _update(BuildContext context, int studentId, String status) async {
    final service = context.read<DriverService>();
    try {
      final pos = await Geolocator.getCurrentPosition();
      await service.updateStudentStatus(tripId, studentId, status, latitude: pos.latitude, longitude: pos.longitude);
    } catch (_) {
      await service.updateStudentStatus(tripId, studentId, status);
    }
  }
}
