import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/state/unread_badge_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/section_header.dart';
import '../../features/education/models/education_models.dart';
import '../../features/education/services/education_service.dart';
import '../../services/student_services.dart';
import '../../features/communication/screens/teacher_reports_screen.dart';
import '../auth/login_screen.dart';

class TeacherAccountScreen extends StatefulWidget {
  const TeacherAccountScreen({super.key});

  @override
  State<TeacherAccountScreen> createState() => _TeacherAccountScreenState();
}

class _TeacherAccountScreenState extends State<TeacherAccountScreen> {
  TeacherMobileProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final badges = context.read<UnreadBadgeStore>();
    final auth = context.read<AuthService>();
    final appState = context.read<AppState>();
    await badges.reset();
    await auth.logout();
    if (!mounted) return;
    appState.clearSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _profile == null) {
      return Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final profile = _profile!;
    final role = profile.jobTitle ?? profile.department ?? 'عضو هيئة التدريس';

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PageHeader(
                  title: 'حسابي',
                  subtitle: profile.fullName,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeSlideIn(
                      child: AppCard(
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: AppColors.gradientPrimary,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                profile.fullName.isEmpty ? 'م' : profile.fullName.characters.first,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.fullName,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (profile.activeAcademicYearName.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      profile.activeAcademicYearName,
                                      style: GoogleFonts.cairo(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (context.watch<AppState>().teacherCanParentReports) ...[
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        child: AppCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TeacherReportsScreen()),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.description_rounded, color: AppColors.accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تقارير أولياء الأمور',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'إرسال تقرير لفصولك أو صفك أو مرحلتك',
                                      style: GoogleFonts.cairo(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_left_rounded),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'البيانات الوظيفية',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            _InfoTile(icon: Icons.work_outline_rounded, label: 'الوظيفة', value: profile.jobTitle),
                            _InfoTile(icon: Icons.apartment_rounded, label: 'القسم', value: profile.department),
                            _InfoTile(icon: Icons.badge_outlined, label: 'كود الموظف', value: profile.staffCode),
                            _InfoTile(icon: Icons.phone_outlined, label: 'الهاتف', value: profile.phone),
                            _InfoTile(icon: Icons.email_outlined, label: 'البريد', value: profile.email),
                            _InfoTile(icon: Icons.credit_card_outlined, label: 'الرقم القومي', value: profile.nationalId),
                            _InfoTile(icon: Icons.location_on_outlined, label: 'العنوان', value: profile.address),
                            _InfoTile(icon: Icons.school_outlined, label: 'المؤهل', value: profile.qualification),
                            _InfoTile(icon: Icons.workspace_premium_outlined, label: 'سنوات الخبرة', value: profile.missingDocuments),
                            _InfoTile(icon: Icons.menu_book_outlined, label: 'التربية العملية', value: profile.pedagogy),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الفصول والمواد',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            if (profile.assignments.isEmpty)
                              Text(
                                'لا توجد تعيينات في السنة الحالية.',
                                style: GoogleFonts.cairo(color: AppColors.textSecondary),
                              )
                            else
                              for (final assignment in profile.assignments)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.class_outlined),
                                  ),
                                  title: Text(
                                    assignment.classDisplayName,
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                    [
                                      assignment.subjectNameAr,
                                      assignment.stageNameAr,
                                      assignment.levelNameAr,
                                    ].where((e) => e.isNotEmpty).join(' • '),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('تسجيل الخروج'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final display = (value ?? '').trim();
    if (display.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(display, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
