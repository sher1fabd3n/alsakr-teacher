import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/student_avatar.dart';
import '../../../core/widgets/stat_card.dart';
import '../../transportation/screens/live_tracking_screen.dart';
import '../../transportation/screens/parent_trip_history_screen.dart';
import '../../transportation/screens/transportation_dashboard_screen.dart';
import '../models/parent_family_models.dart';
import '../state/parent_child_context.dart';
import '../widgets/child_switcher.dart';
import 'parent_child_attendance_screen.dart';
import 'parent_child_fees_screen.dart';
import 'parent_child_grades_screen.dart';
import 'parent_child_homework_screen.dart';

class ParentChildHubScreen extends StatelessWidget {
  const ParentChildHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<ParentChildContext>();
    final child = ctx.activeChild;

    final content = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (!embedded)
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'متابعة الابن',
              subtitle: child?.name ?? 'اختر ابناً للمتابعة',
            ),
          ),
        if (!embedded)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ChildSwitcher(compact: true, height: 120),
            ),
          ),
        if (child == null)
          const SliverFillRemaining(child: Center(child: Text('اسحب للتبديل بين الأبناء في الأعلى')))
        else
          SliverPadding(
            padding: EdgeInsets.all(embedded ? 16 : 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeSlideIn(child: _ChildSummaryCard(child: child)),
                const SizedBox(height: 20),
                const SectionHeader(title: 'الخدمات'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.12,
                  children: _serviceCards(context, child),
                ),
              ]),
            ),
          ),
      ],
    );

    final scrollable = RefreshIndicator(
      onRefresh: () async {
        await ctx.refreshActiveChildData();
        await ctx.refreshFamily();
      },
      child: content,
    );

    if (embedded) return scrollable;
    return Scaffold(body: scrollable);
  }

  List<Widget> _serviceCards(BuildContext context, ChildDashboardSummary child) {
    return [
      StatCard(
        title: 'الدرجات',
        value: child.latestExamPercentage != null
            ? '${child.latestExamPercentage!.toStringAsFixed(0)}%'
            : '—',
        subtitle: child.latestExamSubject ?? 'النتائج',
        icon: Icons.bar_chart_rounded,
        color: AppColors.primary,
        onTap: () => _open(context, const ParentChildGradesScreen()),
      ),
      StatCard(
        title: 'الواجبات',
        value: '${child.pendingHomeworkCount}',
        subtitle: 'معلّق',
        icon: Icons.assignment_rounded,
        color: AppColors.accent,
        onTap: () => _open(context, const ParentChildHomeworkScreen()),
      ),
      StatCard(
        title: 'الحضور',
        value: '${child.attendancePercentage.toStringAsFixed(0)}%',
        subtitle: 'نسبة الحضور',
        icon: Icons.event_available_rounded,
        color: AppColors.success,
        onTap: () => _open(context, const ParentChildAttendanceScreen()),
      ),
      StatCard(
        title: 'المصاريف',
        value: child.outstandingFees > 0 ? 'متبقي' : 'مسدّد',
        subtitle: child.outstandingFees > 0 ? 'يوجد مستحقات' : 'لا مستحقات',
        icon: Icons.payments_rounded,
        color: child.outstandingFees > 0 ? AppColors.danger : AppColors.secondary,
        onTap: () => _open(context, const ParentChildFeesScreen()),
      ),
      StatCard(
        title: 'النقل',
        value: child.transportationTypeAr,
        subtitle: 'بطاقة النقل',
        icon: Icons.badge_rounded,
        color: const Color(0xFF2563EB),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransportationDashboardScreen(studentId: child.studentId),
          ),
        ),
      ),
      if (child.routeName != null)
        StatCard(
          title: 'تتبع مباشر',
          value: 'مباشر',
          subtitle: child.routeName!,
          icon: Icons.map_rounded,
          color: const Color(0xFF1E3A8A),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LiveTrackingScreen(studentId: child.studentId),
            ),
          ),
        )
      else
        StatCard(
          title: 'سجل الرحلات',
          value: 'تاريخ',
          subtitle: 'صعود ونزول',
          icon: Icons.history_rounded,
          color: AppColors.secondary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ParentTripHistoryScreen(studentId: child.studentId),
            ),
          ),
        ),
    ];
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ChildSummaryCard extends StatelessWidget {
  const _ChildSummaryCard({required this.child});

  final ChildDashboardSummary child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: const LinearGradient(colors: AppColors.gradientPrimary),
      child: Row(
        children: [
          StudentAvatar(
            studentId: child.studentId,
            name: child.name,
            photoUrl: child.profilePhotoUrl,
            radius: 30,
            enableHero: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Text(
                  'جلوس ${child.rollNo} • ${child.grade}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
