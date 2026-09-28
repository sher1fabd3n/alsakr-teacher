import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../features/admin/models/parent_account_models.dart';
import '../../features/parent/state/parent_child_context.dart';
import '../../services/student_services.dart';
import '../auth/login_screen.dart';

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().currentParent;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Icon(
                profile.parentType == ParentType.father ? Icons.man_rounded : Icons.woman_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName.isNotEmpty ? profile.fullName : 'ولي أمر',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              profile.nationalId,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Center(child: Chip(label: Text(profile.status.labelAr))),
            const SizedBox(height: 24),
            _ProfileTile(icon: Icons.phone_rounded, label: 'الهاتف', value: profile.phone ?? '—'),
            _ProfileTile(icon: Icons.email_outlined, label: 'البريد', value: profile.email ?? '—'),
            _ProfileTile(
              icon: Icons.family_restroom_rounded,
              label: 'الأبناء المرتبطون',
              value: '${profile.linkedStudents.length}',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  context.read<ParentChildContext>().clear();
                  await context.read<AuthService>().logout();
                  if (!context.mounted) return;
                  context.read<AppState>().clearSession();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل الخروج'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
