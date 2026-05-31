import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../language_provider.dart';
import 'create_report_page.dart';

class AnalyzeResultPage extends StatefulWidget {
  final Uint8List imageBytes;
  final Map<String, dynamic> analysisResult;
  final int? patientId;
  final String doctorEmail;  // ✅ أضف هذا

  const AnalyzeResultPage({
    super.key,
    required this.imageBytes,
    required this.analysisResult,
    this.patientId,
    required this.doctorEmail,
  });

  @override
  State<AnalyzeResultPage> createState() => _AnalyzeResultPageState();
}

class _AnalyzeResultPageState extends State<AnalyzeResultPage> {
  bool _isSaving = false;
  bool _isSaved = false;

  String _getTranslation(String key, String language) {
    switch (key) {
      case 'analysis_result':
        return language == 'fr'
            ? 'Résultat d\'analyse'
            : (language == 'ar' ? 'نتيجة التحليل' : 'Analysis Result');
      case 'visual_analysis':
        return language == 'fr'
            ? 'Analyse visuelle'
            : (language == 'ar' ? 'التحليل البصري' : 'Visual Analysis');
      case 'original_image':
        return language == 'fr'
            ? 'Image originale'
            : (language == 'ar' ? 'الصورة الأصلية' : 'Original Image');
      case 'gradcam':
        return language == 'fr'
            ? 'Grad-CAM'
            : (language == 'ar' ? 'خريطة الحرارة' : 'Grad-CAM');
      case 'not_available':
        return language == 'fr'
            ? 'Non disponible'
            : (language == 'ar' ? 'غير متوفر' : 'Not available');
      case 'confidence':
        return language == 'fr'
            ? 'Confiance:'
            : (language == 'ar' ? 'الثقة:' : 'Confidence:');
      case 'saved':
        return language == 'fr'
            ? 'Sauvegardé'
            : (language == 'ar' ? 'تم الحفظ' : 'Saved');
      case 'save':
        return language == 'fr'
            ? 'Sauvegarder'
            : (language == 'ar' ? 'حفظ' : 'Save');
      case 'saved_button':
        return language == 'fr'
            ? 'Sauvegardé'
            : (language == 'ar' ? 'تم الحفظ' : 'Saved');
      case 'pdf_report':
        return language == 'fr'
            ? 'Rapport PDF'
            : (language == 'ar' ? 'تقرير PDF' : 'PDF Report');
      case 'share_report':
        return language == 'fr'
            ? 'Partager le rapport'
            : (language == 'ar' ? 'مشاركة التقرير' : 'Share report');
      case 'result_saved':
        return language == 'fr'
            ? '✅ Résultat sauvegardé'
            : (language == 'ar' ? '✅ تم حفظ النتيجة' : '✅ Result saved');
      case 'save_error':
        return language == 'fr'
            ? '❌ Erreur lors de la sauvegarde'
            : (language == 'ar' ? '❌ خطأ في الحفظ' : '❌ Save error');
      case 'pdf_error':
        return language == 'fr'
            ? 'Erreur lors de la création du PDF:'
            : (language == 'ar' ? 'خطأ في إنشاء PDF:' : 'Error creating PDF:');
      case 'demo_warning':
        return language == 'fr'
            ? '⚠️ Version démo : Les résultats sont simulés.'
            : (language == 'ar' ? '⚠️ نسخة تجريبية: النتائج محاكاة.' : '⚠️ Demo version: Results are simulated.');
      case 'pdf_title':
        return language == 'fr'
            ? 'Rapport d\'analyse médicale'
            : (language == 'ar' ? 'تقرير التحليل الطبي' : 'Medical Analysis Report');
      case 'pdf_date':
        return language == 'fr'
            ? 'Date:'
            : (language == 'ar' ? 'التاريخ:' : 'Date:');
      case 'pdf_result_title':
        return language == 'fr'
            ? 'Résultat de l\'analyse'
            : (language == 'ar' ? 'نتيجة التحليل' : 'Analysis Result');
      case 'pdf_diagnosis':
        return language == 'fr'
            ? 'Diagnostic:'
            : (language == 'ar' ? 'التشخيص:' : 'Diagnosis:');
      case 'pdf_confidence':
        return language == 'fr'
            ? 'Confiance:'
            : (language == 'ar' ? 'الثقة:' : 'Confidence:');
      case 'pdf_visual_analysis':
        return language == 'fr'
            ? 'Analyse visuelle'
            : (language == 'ar' ? 'التحليل البصري' : 'Visual Analysis');
      case 'pdf_original_image':
        return language == 'fr'
            ? 'Image originale'
            : (language == 'ar' ? 'الصورة الأصلية' : 'Original Image');
      case 'pdf_heatmap':
        return language == 'fr'
            ? 'Carte de chaleur (Grad-CAM)'
            : (language == 'ar' ? 'خريطة الحرارة (Grad-CAM)' : 'Heatmap (Grad-CAM)');
      case 'pdf_footer':
        return language == 'fr'
            ? 'Ce rapport est généré automatiquement par MediCare AI.'
            : (language == 'ar' ? 'تم إنشاء هذا التقرير تلقائياً بواسطة MediCare AI.' : 'This report is generated automatically by MediCare AI.');
      case 'pdf_share_text':
        return language == 'fr'
            ? 'Rapport d\'analyse médicale - MediCare'
            : (language == 'ar' ? 'تقرير التحليل الطبي - MediCare' : 'Medical Analysis Report - MediCare');
      case 'medical_report':
        return language == 'fr'
            ? 'Rapport médical'
            : (language == 'ar' ? 'تقرير طبي' : 'Medical Report');
      case 'report_created':
        return language == 'fr'
            ? 'Rapport créé avec succès'
            : (language == 'ar' ? 'تم إنشاء التقرير بنجاح' : 'Report created successfully');
      default:
        return '';
    }
  }

  Future<void> _saveResult() async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    setState(() => _isSaving = true);

    final result = await ApiService.saveAnalysisResult({
      'patient_id': widget.patientId,
      'predicted_class': widget.analysisResult['predicted_label'] ??
          widget.analysisResult['result'] ??
          widget.analysisResult['predicted_class'],
      'confidence': widget.analysisResult['confidence'],
      'all_probabilities': widget.analysisResult['all_probabilities'],
      'gradcam_image': widget.analysisResult['gradcam_image'],
    });

    setState(() {
      _isSaving = false;
      _isSaved = true;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? _getTranslation('result_saved', language)
              : _getTranslation('save_error', language)),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePDF() async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    try {
      pw.ImageProvider image = pw.MemoryImage(Uint8List.fromList(widget.imageBytes));

      pw.ImageProvider? gradcamImage;
      if (widget.analysisResult['gradcam_image'] != null &&
          widget.analysisResult['gradcam_image'].isNotEmpty) {
        gradcamImage = pw.MemoryImage(Uint8List.fromList(base64Decode(widget.analysisResult['gradcam_image'])));
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                _getTranslation('pdf_title', language),
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              '${_getTranslation('pdf_date', language)} ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              padding: pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue, width: 1),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _getTranslation('pdf_result_title', language),
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${_getTranslation('pdf_diagnosis', language)} ${widget.analysisResult['predicted_label'] ?? widget.analysisResult['result']}',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.Text(
                    '${_getTranslation('pdf_confidence', language)} ${((widget.analysisResult['confidence'] ?? 0.0) * 100).toInt()}%',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey, width: 1),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _getTranslation('pdf_visual_analysis', language),
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          children: [
                            pw.Text(_getTranslation('pdf_original_image', language)),
                            pw.SizedBox(height: 10),
                            pw.Image(image, width: 150, height: 150),
                          ],
                        ),
                      ),
                      if (gradcamImage != null)
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Text(_getTranslation('pdf_heatmap', language)),
                              pw.SizedBox(height: 10),
                              pw.Image(gradcamImage, width: 150, height: 150),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              _getTranslation('pdf_footer', language),
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/rapport_medical_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: _getTranslation('pdf_share_text', language),
      );

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getTranslation('pdf_error', language)} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createMedicalReport() async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReportPage(
          patientId: widget.patientId ?? 0,
          doctorEmail: widget.doctorEmail,
          diagnosis: widget.analysisResult['predicted_label'] ?? widget.analysisResult['result'],
          confidence: widget.analysisResult['confidence'],
          allProbabilities: widget.analysisResult['all_probabilities'],
          originalImageBase64: base64Encode(widget.imageBytes),
          gradcamImageBase64: widget.analysisResult['gradcam_image'],
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation('report_created', language)),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context).currentLanguage;
    final isRtl = language == 'ar';

    String result = widget.analysisResult['predicted_label'] ??
        widget.analysisResult['result'] ??
        'En attente...';

    double confidence = (widget.analysisResult['confidence'] ?? 0.0).toDouble();
    String gradcamImage = widget.analysisResult['gradcam_image'] ?? '';
    bool isDemo = widget.analysisResult['is_demo'] ?? false;

    bool isMelanoma = result.toLowerCase().contains('mélanome') ||
        result.toLowerCase().contains('melanoma') ||
        result.toLowerCase().contains('mel');

    Color resultColor = isMelanoma ? Colors.red : Colors.green;
    IconData resultIcon = isMelanoma ? Icons.warning_amber_rounded : Icons.check_circle;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getTranslation('analysis_result', language),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          leading: IconButton(
            icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _isSaved ? null : _saveResult,
              tooltip: _getTranslation('save', language),
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _sharePDF,
              tooltip: _getTranslation('share_report', language),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade900, Colors.blue.shade600, Colors.blue.shade400],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(resultIcon, size: 60, color: resultColor),
                        const SizedBox(height: 10),
                        Text(
                          result,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_getTranslation('confidence', language)} ${(confidence * 100).toInt()}%',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        if (_isSaved)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Chip(
                              label: Text(_getTranslation('saved', language)),
                              backgroundColor: Colors.green.shade100,
                              avatar: const Icon(Icons.check, size: 16, color: Colors.green),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _getTranslation('visual_analysis', language),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _getTranslation('original_image', language),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                widget.imageBytes,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 180,
                                    color: Colors.grey.shade200,
                                    child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _getTranslation('gradcam', language),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: gradcamImage.isNotEmpty
                                  ? Image.memory(base64Decode(gradcamImage), fit: BoxFit.cover)
                                  : Center(child: Text(_getTranslation('not_available', language))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaved ? null : _saveResult,
                        icon: Icon(_isSaved ? Icons.check : Icons.save),
                        label: Text(_isSaved
                            ? _getTranslation('saved_button', language)
                            : _getTranslation('save', language)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _sharePDF,
                        icon: const Icon(Icons.share),
                        label: Text(_getTranslation('pdf_report', language)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _createMedicalReport,
                        icon: const Icon(Icons.description),
                        label: Text(_getTranslation('medical_report', language)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isDemo)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.amber.shade800),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getTranslation('demo_warning', language),
                              style: TextStyle(color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
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