import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../models/transportation_models.dart';
import '../screens/transportation_card_screen.dart';
import '../screens/transportation_dashboard_screen.dart';
import '../services/transportation_service.dart';
import '../widgets/transportation_id_card.dart';

class StudentTransportSummaryCard extends StatefulWidget {
  const StudentTransportSummaryCard({super.key, this.studentId});

  final int? studentId;

  @override
  State<StudentTransportSummaryCard> createState() => _StudentTransportSummaryCardState();
}

class _StudentTransportSummaryCardState extends State<StudentTransportSummaryCard> {
  late Future<TransportationCardData?> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _loadCard();
  }

  Future<TransportationCardData?> _loadCard() async {
    try {
      return await context.read<TransportationService>().getCard(studentId: widget.studentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TransportationCardData?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final card = snapshot.data;
        if (card == null) {
          return FadeSlideIn(
            child: AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TransportationDashboardScreen(studentId: widget.studentId)),
              ),
              child: const ListTile(
                leading: Icon(Icons.directions_bus_rounded, color: AppColors.primary),
                title: Text('النقل المدرسي', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('لم يتم تحديد نوع النقل بعد'),
                trailing: Icon(Icons.chevron_left_rounded),
              ),
            ),
          );
        }

        return FadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransportationIdCard(card: card),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransportationCardScreen(studentId: widget.studentId),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('عرض البطاقة كاملة'),
              ),
            ],
          ),
        );
      },
    );
  }
}
