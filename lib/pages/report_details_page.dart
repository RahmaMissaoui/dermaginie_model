import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../language_provider.dart';

class ReportDetailsPage extends StatefulWidget {
  final int reportId;
  final int patientId;

  const ReportDetailsPage({
    super.key,
    required this.reportId,
    required this.patientId,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;
  bool _showComparison = false;
  Map<String, dynamic>? _otherReport;

  String _getTranslation(String key, String language) {
    switch (key) {
      case 'compare':
        return language == 'fr'
            ? 'Comparer'
            : (language == 'ar' ? 'مقارنة' : 'Compare');
      case 'result':
        return language == 'fr'
            ? 'Résultat'
            : (language == 'ar' ? 'النتيجة' : 'Result');
      case 'diagnosis':
        return language == 'fr'
            ? 'Diagnostic:'
            : (language == 'ar' ? 'التشخيص:' : 'Diagnosis:');
      case 'confidence':
        return language == 'fr'
            ? 'Confiance:'
            : (language == 'ar' ? 'الثقة:' : 'Confidence:');
      case 'date':
        return language == 'fr'
            ? 'Date:'
            : (language == 'ar' ? 'التاريخ:' : 'Date:');
      case 'doctor_notes':
        return language == 'fr'
            ? 'Notes du médecin'
            : (language == 'ar' ? 'ملاحظات الطبيب' : 'Doctor\'s Notes');
      case 'treatment_plan':
        return language == 'fr'
            ? 'Plan de traitement'
            : (language == 'ar' ? 'خطة العلاج' : 'Treatment Plan');
      case 'follow_up_date':
        return language == 'fr'
            ? 'Date de suivi'
            : (language == 'ar' ? 'تاريخ المتابعة' : 'Follow-up Date');
      case 'images':
        return language == 'fr'
            ? 'Images'
            : (language == 'ar' ? 'الصور' : 'Images');
      case 'original_image':
        return language == 'fr'
            ? 'Image originale'
            : (language == 'ar' ? 'الصورة الأصلية' : 'Original Image');
      case 'gradcam':
        return language == 'fr'
            ? 'Grad-CAM'
            : (language == 'ar' ? 'خريطة الحرارة' : 'Grad-CAM');
      case 'comparison':
        return language == 'fr'
            ? 'Comparaison avec:'
            : (language == 'ar' ? 'مقارنة مع:' : 'Comparison with:');
      case 'previous_diagnosis':
        return language == 'fr'
            ? 'Ancien diagnostic:'
            : (language == 'ar' ? 'التشخيص السابق:' : 'Previous diagnosis:');
      case 'previous_confidence':
        return language == 'fr'
            ? 'Ancienne confiance:'
            : (language == 'ar' ? 'الثقة السابقة:' : 'Previous confidence:');
      case 'previous_date':
        return language == 'fr'
            ? 'Ancienne date:'
            : (language == 'ar' ? 'التاريخ السابق:' : 'Previous date:');
      case 'evolution':
        return language == 'fr'
            ? 'Évolution:'
            : (language == 'ar' ? 'التطور:' : 'Evolution:');
      case 'stable':
        return language == 'fr'
            ? 'Stable'
            : (language == 'ar' ? 'مستقر' : 'Stable');
      case 'change_detected':
        return language == 'fr'
            ? 'Changement détecté'
            : (language == 'ar' ? 'تم اكتشاف تغيير' : 'Change detected');
      case 'no_other_reports':
        return language == 'fr'
            ? 'Aucun autre rapport disponible pour comparaison'
            : (language == 'ar' ? 'لا توجد تقارير أخرى للمقارنة' : 'No other reports available for comparison');
      case 'select_report':
        return language == 'fr'
            ? 'Comparer avec un autre rapport'
            : (language == 'ar' ? 'مقارنة مع تقرير آخر' : 'Compare with another report');
      case 'report_not_found':
        return language == 'fr'
            ? 'Rapport non trouvé'
            : (language == 'ar' ? 'التقرير غير موجود' : 'Report not found');
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getReport(widget.reportId);
    if (response['success'] == true) {
      setState(() {
        _report = response['report'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOtherReport(int otherId) async {
    final response = await ApiService.getReport(otherId);
    if (response['success'] == true) {
      setState(() {
        _otherReport = response['report'];
      });
    }
  }

  void _showComparisonDialog() async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final reports = await ApiService.getReports(widget.patientId);
    if (reports['success'] == true && reports['reports'].length > 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_getTranslation('select_report', language)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: reports['reports'].length,
              itemBuilder: (context, index) {
                final r = reports['reports'][index];
                if (r['id'] == widget.reportId) return const SizedBox.shrink();
                return ListTile(
                  title: Text(r['report_title']),
                  subtitle: Text(r['created_at'].split(' ')[0]),
                  onTap: () {
                    Navigator.pop(context);
                    _loadOtherReport(r['id']);
                    setState(() => _showComparison = true);
                  },
                );
              },
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTranslation('no_other_reports', language))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context).currentLanguage;
    final isRtl = language == 'ar';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_report == null) {
      return Scaffold(
        body: Center(child: Text(_getTranslation('report_not_found', language))),
      );
    }

    final bool isMelanoma = _report!['diagnosis'].toLowerCase().contains('mel');
    final Color diagnosisColor = isMelanoma ? Colors.red : Colors.green;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_report!['report_title']),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              onPressed: _showComparisonDialog,
              tooltip: _getTranslation('compare', language),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getTranslation('result', language),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${_getTranslation('diagnosis', language)} ${_report!['diagnosis']}',
                          style: TextStyle(color: diagnosisColor)),
                      Text('${_getTranslation('confidence', language)} ${(_report!['confidence'] * 100).toInt()}%'),
                      Text('${_getTranslation('date', language)} ${_report!['created_at']}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_report!['doctor_notes'].isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getTranslation('doctor_notes', language),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_report!['doctor_notes']),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              if (_report!['treatment_plan'].isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getTranslation('treatment_plan', language),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_report!['treatment_plan']),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              if (_report!['follow_up_date'].isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getTranslation('follow_up_date', language),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_report!['follow_up_date']),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              Text(_getTranslation('images', language),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Column(
                        children: [
                          Text(_getTranslation('original_image', language)),
                          Image.memory(
                            base64Decode(_report!['original_image_base64']),
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_report!['gradcam_image_base64'] != null &&
                      _report!['gradcam_image_base64'].isNotEmpty)
                    Expanded(
                      child: Card(
                        child: Column(
                          children: [
                            Text(_getTranslation('gradcam', language)),
                            Image.memory(
                              base64Decode(_report!['gradcam_image_base64']),
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              if (_showComparison && _otherReport != null)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.compare),
                              const SizedBox(width: 8),
                              Text('${_getTranslation('comparison', language)} ${_otherReport!['report_title']}'),
                            ],
                          ),
                          const Divider(),
                          Text('${_getTranslation('previous_diagnosis', language)} ${_otherReport!['diagnosis']}'),
                          Text('${_getTranslation('previous_confidence', language)} ${(_otherReport!['confidence'] * 100).toInt()}%'),
                          Text('${_getTranslation('previous_date', language)} ${_otherReport!['created_at'].split(' ')[0]}'),
                          const SizedBox(height: 8),
                          Text(_getTranslation('evolution', language),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(_otherReport!['diagnosis'] == _report!['diagnosis']
                              ? _getTranslation('stable', language)
                              : _getTranslation('change_detected', language)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}