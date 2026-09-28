import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_branding.dart';
import '../../../core/theme/app_colors.dart';
import '../models/transportation_models.dart';

class TransportationIdCard extends StatelessWidget {
  const TransportationIdCard({super.key, required this.card});

  final TransportationCardData card;

  @override
  Widget build(BuildContext context) {
    final isSchoolBus = card.isSchoolBus;
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSchoolBus
              ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB), const Color(0xFF3B82F6)]
              : [const Color(0xFF0F766E), const Color(0xFF0D9488), const Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          AppBranding.logoAsset,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.schoolName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'بطاقة النقل المدرسي',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          card.transportationTypeAr,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 88,
                        height: 108,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 3),
                          image: card.studentPhotoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(card.studentPhotoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: card.studentPhotoUrl == null
                            ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.studentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _infoRow('رقم الطالب', '${card.studentCode}'),
                            _infoRow('الصف', card.grade),
                            if (card.cardNumber != null) _infoRow('رقم البطاقة', card.cardNumber!),
                            if (card.emergencyContact != null)
                              _infoRow('طوارئ', card.emergencyContact!),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _dateChip(
                            'تاريخ الإصدار',
                            card.issuedAt != null ? dateFormat.format(card.issuedAt!.toLocal()) : '—',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dateChip(
                            'تاريخ الانتهاء',
                            card.expiresAt != null ? dateFormat.format(card.expiresAt!.toLocal()) : '—',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _dateChip('الحالة', card.status)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isSchoolBus && card.schoolBus != null) ...[
                    _sectionTitle('بيانات الحافلة'),
                    _infoRow('المسار', card.schoolBus!.routeName),
                    _infoRow('رقم الحافلة', card.schoolBus!.busNumber),
                    _infoRow('السائق', '${card.schoolBus!.driverName} • ${card.schoolBus!.driverPhone}'),
                    _infoRow('المشرف', '${card.schoolBus!.supervisorName} • ${card.schoolBus!.supervisorPhone}'),
                  ],
                  if (!isSchoolBus && card.private != null) ...[
                    _sectionTitle('بيانات النقل الخاص'),
                    _infoRow('السائق', card.private!.driverFullName),
                    _infoRow('الهاتف', card.private!.driverPhone),
                    _infoRow('المركبة', '${card.private!.vehicleType} ${card.private!.vehicleModel ?? ''}'),
                    _infoRow('اللوحة', card.private!.vehiclePlateNumber),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          title,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w800, fontSize: 14),
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            children: [
              TextSpan(text: '$label: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
              TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
