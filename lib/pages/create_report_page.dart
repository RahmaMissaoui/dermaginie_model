import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../language_provider.dart';

class CreateReportPage extends StatefulWidget {
  final int patientId;
  final String doctorEmail;
  final String diagnosis;
  final double confidence;
  final Map<String, dynamic> allProbabilities;
  final String originalImageBase64;
  final String? gradcamImageBase64;

  const CreateReportPage({
    super.key,
    required this.patientId,
    required this.doctorEmail,
    required this.diagnosis,
    required this.confidence,
    required this.allProbabilities,
    required this.originalImageBase64,
    this.gradcamImageBase64,
  });

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _doctorNotesController = TextEditingController();
  final _treatmentPlanController = TextEditingController();
  final _followUpDateController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _doctorNotesController.dispose();
    _treatmentPlanController.dispose();
    _followUpDateController.dispose();
    super.dispose();
  }

  String _getTranslation(String key, String language) {
    switch (key) {
      case 'title':
        return language == 'fr'
            ? 'Créer un rapport médical'
            : (language == 'ar' ? 'إنشاء تقرير طبي' : 'Create Medical Report');
      case 'diagnosis_result':
        return language == 'fr'
            ? 'Résultat du diagnostic'
            : (language == 'ar' ? 'نتيجة التشخيص' : 'Diagnosis Result');
      case 'diagnosis':
        return language == 'fr'
            ? 'Diagnostic:'
            : (language == 'ar' ? 'التشخيص:' : 'Diagnosis:');
      case 'confidence':
        return language == 'fr'
            ? 'Confiance:'
            : (language == 'ar' ? 'الثقة:' : 'Confidence:');
      case 'report_title':
        return language == 'fr'
            ? 'Titre du rapport'
            : (language == 'ar' ? 'عنوان التقرير' : 'Report Title');
      case 'title_required':
        return language == 'fr'
            ? 'Titre requis'
            : (language == 'ar' ? 'العنوان مطلوب' : 'Title required');
      case 'doctor_notes':
        return language == 'fr'
            ? 'Notes du médecin'
            : (language == 'ar' ? 'ملاحظات الطبيب' : 'Doctor\'s Notes');
      case 'notes_hint':
        return language == 'fr'
            ? 'Observations, recommandations...'
            : (language == 'ar' ? 'ملاحظات، توصيات...' : 'Observations, recommendations...');
      case 'treatment_plan':
        return language == 'fr'
            ? 'Plan de traitement'
            : (language == 'ar' ? 'خطة العلاج' : 'Treatment Plan');
      case 'treatment_hint':
        return language == 'fr'
            ? 'Médicaments, procédures...'
            : (language == 'ar' ? 'الأدوية، الإجراءات...' : 'Medications, procedures...');
      case 'follow_up_date':
        return language == 'fr'
            ? 'Date de suivi'
            : (language == 'ar' ? 'تاريخ المتابعة' : 'Follow-up Date');
      case 'save_report':
        return language == 'fr'
            ? 'Enregistrer le rapport'
            : (language == 'ar' ? 'حفظ التقرير' : 'Save Report');
      case 'saving':
        return language == 'fr'
            ? 'Enregistrement...'
            : (language == 'ar' ? 'جاري الحفظ...' : 'Saving...');
      case 'report_saved':
        return language == 'fr'
            ? '✅ Rapport médical créé'
            : (language == 'ar' ? '✅ تم إنشاء التقرير الطبي' : '✅ Medical report created');
      case 'error':
        return language == 'fr'
            ? '❌ Erreur:'
            : (language == 'ar' ? '❌ خطأ:' : '❌ Error:');
      default:
        return '';
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _followUpDateController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    final reportData = {
      'patient_id': widget.patientId,
      'doctor_email': widget.doctorEmail,
      'report_title': _titleController.text.trim(),
      'diagnosis': widget.diagnosis,
      'confidence': widget.confidence,
      'all_probabilities': jsonEncode(widget.allProbabilities),
      'doctor_notes': _doctorNotesController.text.trim(),
      'treatment_plan': _treatmentPlanController.text.trim(),
      'follow_up_date': _followUpDateController.text.trim(),
      'original_image_base64': widget.originalImageBase64,
      'gradcam_image_base64': widget.gradcamImageBase64 ?? '',
    };

    final result = await ApiService.createReport(reportData);

    setState(() => _isSaving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTranslation('report_saved', language)), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getTranslation('error', language)} ${result['error']}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context).currentLanguage;
    final isRtl = language == 'ar';
    final bool isMelanoma = widget.diagnosis.toLowerCase().contains('mel') ||
        widget.diagnosis.toLowerCase().contains('mélanome');
    final Color diagnosisColor = isMelanoma ? Colors.red : Colors.green;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTranslation('title', language)),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: diagnosisColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getTranslation('diagnosis_result', language),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('${_getTranslation('diagnosis', language)} $widget.diagnosis',
                            style: TextStyle(color: diagnosisColor)),
                        Text('${_getTranslation('confidence', language)} ${(widget.confidence * 100).toInt()}%'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  decoration: InputDecoration(
                    labelText: _getTranslation('report_title', language),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? _getTranslation('title_required', language) : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _doctorNotesController,
                  maxLines: 5,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  decoration: InputDecoration(
                    labelText: _getTranslation('doctor_notes', language),
                    hintText: _getTranslation('notes_hint', language),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _treatmentPlanController,
                  maxLines: 3,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  decoration: InputDecoration(
                    labelText: _getTranslation('treatment_plan', language),
                    hintText: _getTranslation('treatment_hint', language),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _followUpDateController,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      decoration: InputDecoration(
                        labelText: _getTranslation('follow_up_date', language),
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isSaving
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(_getTranslation('save_report', language),
                        style: const TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}