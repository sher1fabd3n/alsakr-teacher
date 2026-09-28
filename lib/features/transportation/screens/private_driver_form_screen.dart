import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/transportation_service.dart';
import 'transportation_card_screen.dart';

class PrivateDriverFormScreen extends StatefulWidget {
  const PrivateDriverFormScreen({super.key, required this.studentId});

  final int studentId;

  @override
  State<PrivateDriverFormScreen> createState() => _PrivateDriverFormScreenState();
}

class _PrivateDriverFormScreenState extends State<PrivateDriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _plateController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;
  String? _frontImagePath;
  String? _backImagePath;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _vehicleTypeController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _plateController.dispose();
    _relationshipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<TransportationService>().savePrivateDriver(
            studentId: widget.studentId,
            driverFullName: _nameController.text.trim(),
            driverPhone: _phoneController.text.trim(),
            nationalIdNumber: _nationalIdController.text.trim(),
            vehicleType: _vehicleTypeController.text.trim(),
            vehicleModel: _vehicleModelController.text.trim().isEmpty
                ? null
                : _vehicleModelController.text.trim(),
            vehicleColor: _vehicleColorController.text.trim().isEmpty
                ? null
                : _vehicleColorController.text.trim(),
            vehiclePlateNumber: _plateController.text.trim(),
            relationshipToStudent: _relationshipController.text.trim(),
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      if (_frontImagePath != null || _backImagePath != null) {
        await context.read<TransportationService>().uploadPrivateDriverImages(
              studentId: widget.studentId,
              frontPath: _frontImagePath,
              backPath: _backImagePath,
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات النقل الخاص')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TransportationCardScreen(studentId: widget.studentId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(bool front) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() {
      if (front) {
        _frontImagePath = file.path;
      } else {
        _backImagePath = file.path;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات النقل الخاص')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم السائق'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'هاتف السائق'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _nationalIdController,
                  decoration: const InputDecoration(labelText: 'الرقم القومي'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _vehicleTypeController,
                  decoration: const InputDecoration(labelText: 'نوع المركبة'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(labelText: 'موديل المركبة'),
                ),
                TextFormField(
                  controller: _vehicleColorController,
                  decoration: const InputDecoration(labelText: 'لون المركبة'),
                ),
                TextFormField(
                  controller: _plateController,
                  decoration: const InputDecoration(labelText: 'رقم اللوحة'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _relationshipController,
                  decoration: const InputDecoration(labelText: 'صلة القرابة بالطالب'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('صور الرقم القومي', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.credit_card_rounded),
                        label: Text(_frontImagePath == null ? 'الوجه الأمامي' : 'تم اختيار الوجه'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(false),
                        icon: const Icon(Icons.credit_card_outlined),
                        label: Text(_backImagePath == null ? 'الوجه الخلفي' : 'تم اختيار الظهر'),
                      ),
                    ),
                  ],
                ),
                if (_frontImagePath != null || _backImagePath != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: Row(
                      children: [
                        if (_frontImagePath != null)
                          Expanded(child: Image.file(File(_frontImagePath!), fit: BoxFit.cover)),
                        if (_backImagePath != null)
                          Expanded(child: Image.file(File(_backImagePath!), fit: BoxFit.cover)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('حفظ وإنشاء البطاقة'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
