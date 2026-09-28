import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../features/communication/screens/communication_hub_screen.dart';
import '../../features/parent/screens/parent_child_hub_screen.dart';
import '../../features/parent/screens/parent_family_dashboard_screen.dart';
import '../../features/parent/screens/parent_notifications_screen.dart';
import '../../features/parent/state/parent_child_context.dart';
import '../../features/parent/widgets/child_switcher.dart';
import 'parent_profile_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = context.read<ParentChildContext>();
      if (ctx.family == null && !ctx.isLoading) {
        ctx.bootstrap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final childCtx = context.watch<ParentChildContext>();
    final activeId = childCtx.activeStudentId;
    final showCarousel = childCtx.children.isNotEmpty || childCtx.isLoading;

    final hubKey = ValueKey<int?>(activeId);

    final pages = [
      const ParentFamilyDashboardScreen(),
      ParentChildHubScreen(key: hubKey, embedded: true),
      const ParentNotificationsScreen(),
      const CommunicationHubScreen(role: 'Parent'),
      const ParentProfileScreen(),
    ];

    if (_index >= pages.length) {
      _index = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (showCarousel)
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: AppColors.gradientPrimary,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        childCtx.childCount > 1
                            ? 'اسحب للتبديل بين ${childCtx.childCount} أبناء'
                            : 'الابن المرتبط',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ChildSwitcher(
                        showPageIndicator: true,
                        onActiveCardTap: (child) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ParentChildHubScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
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
            onDestinationSelected: (v) => setState(() => _index = v),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'العائلة',
              ),
              NavigationDestination(
                icon: Icon(Icons.child_care_outlined),
                selectedIcon: Icon(Icons.child_care_rounded),
                label: 'الابن',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'الإشعارات',
              ),
              NavigationDestination(
                icon: Icon(Icons.forum_outlined),
                selectedIcon: Icon(Icons.forum_rounded),
                label: 'التواصل',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
