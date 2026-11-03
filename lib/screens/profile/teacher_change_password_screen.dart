import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../features/education/services/education_service.dart';
import '../../services/api_client.dart';
import '../../services/remembered_credentials.dart';

class TeacherChangePasswordScreen extends StatefulWidget {
  const TeacherChangePasswordScreen({super.key});

  @override
  State<TeacherChangePasswordScreen> createState() =>
      _TeacherChangePasswordScreenState();
}

class _TeacherChangePasswordScreenState
    extends State<TeacherChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      await context.read<EducationService>().changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text.trim(),
          );
      await RememberedCredentials(api).updatePassword(_newController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تغيير كلمة المرور بنجاح',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(),
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      ),
      filled: true,
      fillColor: AppColors.surfaceMuted,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'تغيير كلمة المرور',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: AppColors.gradientPrimary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'حماية حسابك',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أدخل كلمة المرور الحالية ثم كلمة مرور جديدة لا تقل عن 6 أحرف.',
                      style: GoogleFonts.cairo(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _currentController,
                      obscureText: _obscureCurrent,
                      textDirection: TextDirection.ltr,
                      decoration: _decoration(
                        label: 'كلمة المرور الحالية',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscureCurrent,
                        onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newController,
                      obscureText: _obscureNew,
                      textDirection: TextDirection.ltr,
                      decoration: _decoration(
                        label: 'كلمة المرور الجديدة',
                        icon: Icons.lock_reset_rounded,
                        obscure: _obscureNew,
                        onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'مطلوب';
                        if (v.trim().length < 6) return 'يجب ألا تقل عن 6 أحرف';
                        if (v == _currentController.text) {
                          return 'يجب أن تختلف عن كلمة المرور الحالية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      textDirection: TextDirection.ltr,
                      decoration: _decoration(
                        label: 'تأكيد كلمة المرور',
                        icon: Icons.verified_user_outlined,
                        obscure: _obscureConfirm,
                        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        if (v != _newController.text) return 'كلمتا المرور غير متطابقتين';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _loading ? 'جاري الحفظ...' : 'حفظ كلمة المرور',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
