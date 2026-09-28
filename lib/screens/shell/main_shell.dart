import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/state/unread_badge_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/unread_count_badge.dart';
import '../../features/communication/screens/communication_hub_screen.dart';
import '../../features/education/screens/teacher_dashboard_screen.dart';
import '../../features/education/services/education_service.dart';
import '../attendance/attendance_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../grades/grades_screen.dart';
import '../homework/homework_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/teacher_account_screen.dart';
import '../../features/transportation/services/transportation_service.dart';
import '../../services/push_notification_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnreadBadgeStore>().refresh();
      context.read<PushNotificationService>().consumePending();
      context.read<PushNotificationService>().registerAfterLogin(
            context.read<TransportationService>(),
          );
      _refreshTeacherPermissions();
    });
  }

  Future<void> _refreshTeacherPermissions() async {
    if (!mounted) return;
    if (context.read<AppState>().communicationRole != 'Teacher') return;
    try {
      final profile = await context.read<EducationService>().getMyProfile();
      if (!mounted) return;
      context.read<AppState>().setTeacherPermissions(
            classes: profile.canClasses,
            students: profile.canStudents,
            attendance: profile.canAttendance,
            quizzes: profile.canQuizzes,
            chat: profile.canChat,
            reports: profile.canReports,
            parentReports: profile.canParentReports,
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<UnreadBadgeStore>().refresh();
      context.read<PushNotificationService>().registerAfterLogin(
            context.read<TransportationService>(),
          );
      _refreshTeacherPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppState>().communicationRole;
    final isStudent = role == 'Student';
    final isTeacher = role == 'Teacher';
    final showChat = !isTeacher || context.watch<AppState>().teacherCanChat;
    final showReports = isTeacher && context.watch<AppState>().teacherCanParentReports;
    final showCommunication = showChat || showReports;
    final badges = context.watch<UnreadBadgeStore>();

    final pages = [
      if (isStudent) const DashboardScreen(),
      if (isTeacher) const TeacherDashboardScreen(),
      if (isStudent) const GradesScreen(),
      if (isStudent) const HomeworkScreen(),
      if (showCommunication) CommunicationHubScreen(role: role),
      if (isTeacher) const TeacherAccountScreen() else const ProfileScreen(),
    ];

    final destinations = [
      if (isStudent)
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'الرئيسية',
        ),
      if (isTeacher)
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'الرئيسية',
        ),
      if (isStudent)
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'الدرجات',
        ),
      if (isStudent)
        const NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'الواجبات',
        ),
      if (showCommunication)
        NavigationDestination(
          icon: UnreadCountBadge(
            count: badges.chatCount + badges.notificationCount,
            child: const Icon(Icons.forum_outlined),
          ),
          selectedIcon: UnreadCountBadge(
            count: badges.chatCount + badges.notificationCount,
            child: const Icon(Icons.forum_rounded),
          ),
          label: 'التواصل',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'حسابي',
      ),
    ];

    if (_index >= pages.length) {
      _index = 0;
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              setState(() => _index = value);
              if (showCommunication && value == (isStudent ? 3 : 1)) {
                context.read<UnreadBadgeStore>().refresh();
                _refreshTeacherPermissions();
              }
            },
            destinations: destinations,
          ),
        ),
      ),
      floatingActionButton: isStudent && _index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                );
              },
              icon: const Icon(Icons.event_available_rounded),
              label: const Text('الحضور'),
            )
          : null,
    );
  }
}
