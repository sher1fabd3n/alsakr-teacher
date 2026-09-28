import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/student_models.dart';
import '../services/parent_family_service.dart';
import '../state/parent_child_context.dart';
import '../widgets/child_switcher.dart';

class ParentChildFeesScreen extends StatefulWidget {
  const ParentChildFeesScreen({super.key});

  @override
  State<ParentChildFeesScreen> createState() => _ParentChildFeesScreenState();
}

class _ParentChildFeesScreenState extends State<ParentChildFeesScreen> {
  int? _studentId;
  Future<StudentFeesResponse>? _future;

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<ParentChildContext>().activeStudentId;
    if (activeId != null && activeId != _studentId) {
      _studentId = activeId;
      _future = context.read<ParentFamilyService>().getChildFees(activeId);
    }

    final currency = NumberFormat('#,##0', 'ar');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (_studentId == null) return;
          setState(() {
            _future = context.read<ParentFamilyService>().getChildFees(_studentId!);
          });
          await _future;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'المصاريف',
                subtitle: context.watch<ParentChildContext>().activeChild?.name,
                trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: ChildSwitcher(compact: true, height: 120),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: FutureBuilder<StudentFeesResponse>(
                future: _future,
                builder: (context, snapshot) {
                  if (_studentId == null) {
                    return const SliverFillRemaining(child: Center(child: Text('اختر ابناً أولاً')));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', ''))),
                    );
                  }

                  final fees = snapshot.data!;
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      FadeSlideIn(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (fees.academicYearName != null)
                                Text(fees.academicYearName!,
                                    style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 12),
                              _FeeRow(label: 'القسط الأول', value: currency.format(fees.installment1Amount)),
                              _FeeRow(
                                  label: 'القسط الثاني المتوقع',
                                  value: currency.format(fees.installment2ExpectedAmount)),
                              _FeeRow(label: 'كتب', value: currency.format(fees.booksFee)),
                              _FeeRow(
                                  label: 'إجمالي المصاريف',
                                  value: currency.format(fees.tuitionAndBooksTotal),
                                  bold: true),
                              if (fees.otherFeesAvailable)
                                _FeeRow(label: 'مصاريف أخرى', value: currency.format(fees.otherFeesAmount)),
                            ],
                          ),
                        ),
                      ),
                      if (fees.message != null && fees.message!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(fees.message!, style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                      if (fees.paymentAccounts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const SectionHeader(title: 'حسابات التحويل'),
                        const SizedBox(height: 12),
                        ...fees.paymentAccounts.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.bankName, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text(a.accountNumber,
                                      textDirection: TextDirection.ltr,
                                      style: const TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (fees.receipts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const SectionHeader(title: 'إيصالات الدفع'),
                        const SizedBox(height: 12),
                        ...fees.receipts.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.category, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text(r.status, style: const TextStyle(color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Text(currency.format(r.amount),
                                      style: const TextStyle(fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                )),
          ),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? AppColors.primary : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}
