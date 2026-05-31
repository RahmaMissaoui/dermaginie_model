import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../language_provider.dart';
import 'analyze_result_page.dart';
import 'reports_list_page.dart';
import 'patients_page.dart';

class PatientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> patient;
  final String doctorEmail;

  const PatientDetailsPage({
    super.key,
    required this.patient,
    required this.doctorEmail,
  });

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  String _getTranslation(String key, String language) {
    switch (key) {
      case 'patient_info':
        return language == 'fr'
            ? 'Informations du patient'
            : (language == 'ar' ? 'معلومات المريض' : 'Patient Information');
      case 'full_name':
        return language == 'fr'
            ? 'Nom complet'
            : (language == 'ar' ? 'الاسم الكامل' : 'Full Name');
      case 'birth_date':
        return language == 'fr'
            ? 'Date de naissance'
            : (language == 'ar' ? 'تاريخ الميلاد' : 'Birth Date');
      case 'age':
        return language == 'fr'
            ? 'Âge'
            : (language == 'ar' ? 'العمر' : 'Age');
      case 'phone':
        return language == 'fr'
            ? 'Téléphone'
            : (language == 'ar' ? 'الهاتف' : 'Phone');
      case 'last_visit':
        return language == 'fr'
            ? 'Dernière visite'
            : (language == 'ar' ? 'آخر زيارة' : 'Last Visit');
      case 'medical_documents':
        return language == 'fr'
            ? 'Documents médicaux'
            : (language == 'ar' ? 'المستندات الطبية' : 'Medical Documents');
      case 'add_document':
        return language == 'fr'
            ? 'Ajouter'
            : (language == 'ar' ? 'إضافة' : 'Add');
      case 'reports':
        return language == 'fr'
            ? 'Rapports médicaux'
            : (language == 'ar' ? 'التقارير الطبية' : 'Medical Reports');
      case 'no_documents':
        return language == 'fr'
            ? 'Aucun document'
            : (language == 'ar' ? 'لا توجد مستندات' : 'No documents');
      case 'no_documents_subtitle':
        return language == 'fr'
            ? 'Cliquez sur + pour ajouter des résultats médicaux'
            : (language == 'ar' ? 'انقر على + لإضافة نتائج طبية' : 'Click + to add medical results');
      case 'added_on':
        return language == 'fr'
            ? 'Ajouté le:'
            : (language == 'ar' ? 'تمت الإضافة في:' : 'Added on:');
      case 'document_name':
        return language == 'fr'
            ? 'Nom du document'
            : (language == 'ar' ? 'اسم المستند' : 'Document Name');
      case 'document_name_label':
        return language == 'fr'
            ? 'Nom du document'
            : (language == 'ar' ? 'اسم المستند' : 'Document name');
      case 'cancel':
        return language == 'fr'
            ? 'Annuler'
            : (language == 'ar' ? 'إلغاء' : 'Cancel');
      case 'add':
        return language == 'fr'
            ? 'Ajouter'
            : (language == 'ar' ? 'إضافة' : 'Add');
      case 'confirm_title':
        return language == 'fr'
            ? 'Confirmation'
            : (language == 'ar' ? 'تأكيد' : 'Confirmation');
      case 'delete_confirm':
        return language == 'fr'
            ? 'Supprimer'
            : (language == 'ar' ? 'حذف' : 'Delete');
      case 'delete':
        return language == 'fr'
            ? 'Supprimer'
            : (language == 'ar' ? 'حذف' : 'Delete');
      case 'analyzing':
        return language == 'fr'
            ? 'Analyse en cours...'
            : (language == 'ar' ? 'جاري التحليل...' : 'Analyzing...');
      case 'analyze':
        return language == 'fr'
            ? 'Analyser'
            : (language == 'ar' ? 'تحليل' : 'Analyze');
      case 'document_added':
        return language == 'fr'
            ? 'Document ajouté'
            : (language == 'ar' ? 'تم إضافة المستند' : 'Document added');
      case 'document_deleted':
        return language == 'fr'
            ? 'Document supprimé'
            : (language == 'ar' ? 'تم حذف المستند' : 'Document deleted');
      case 'analysis_error':
        return language == 'fr'
            ? 'Erreur:'
            : (language == 'ar' ? 'خطأ:' : 'Error:');
      case 'analysis_failed':
        return language == 'fr'
            ? 'Analyse échouée'
            : (language == 'ar' ? 'فشل التحليل' : 'Analysis failed');
      case 'load_image_error':
        return language == 'fr'
            ? 'Impossible de charger l\'image'
            : (language == 'ar' ? 'تعذر تحميل الصورة' : 'Unable to load image');
      case 'not_specified':
        return language == 'fr'
            ? 'Non spécifiée'
            : (language == 'ar' ? 'غير محدد' : 'Not specified');
      case 'years':
        return language == 'fr'
            ? 'ans'
            : (language == 'ar' ? 'سنة' : 'years');
      case 'close':
        return language == 'fr'
            ? 'Fermer'
            : (language == 'ar' ? 'إغلاق' : 'Close');
      default:
        return '';
    }
  }

  int _calculateAge(String birthDate) {
    if (birthDate.isEmpty) return 0;
    try {
      List<String> parts = birthDate.split('/');
      DateTime birth = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      DateTime today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getDocuments(widget.patient['id']);
    if (response['success'] == true) {
      setState(() {
        _documents = List<Map<String, dynamic>>.from(response['documents']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDocument() async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final isRtl = language == 'ar';

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final nameController = TextEditingController(text: pickedFile.path.split('/').last);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_getTranslation('document_name', language)),
          content: TextField(
            controller: nameController,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            decoration: InputDecoration(
              labelText: _getTranslation('document_name_label', language),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_getTranslation('cancel', language)),
            ),
            ElevatedButton(
              onPressed: () async {
                final docData = {
                  'patient_id': widget.patient['id'],
                  'document_name': nameController.text,
                  'document_type': 'image',
                  'document_data': base64Image,
                };
                await ApiService.addDocument(docData);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadDocuments();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_getTranslation('document_added', language)),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(_getTranslation('add', language)),
            ),
          ],
        ),
      );
    }
  }

  void _viewDocument(Map<String, dynamic> document) async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final response = await ApiService.getDocumentData(document['id']);

    if (response['success'] == true && response['document_data'] != null) {
      try {
        final Uint8List imageBytes = base64Decode(response['document_data']);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(document['document_name']),
              content: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Erreur chargement image'));
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_getTranslation('close', language)),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        print('Error decoding image: $e');
      }
    }
  }

  void _deleteDocument(int docId, String name) async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTranslation('confirm_title', language)),
        content: Text('${_getTranslation('delete_confirm', language)} "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTranslation('cancel', language)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.deleteDocument(docId);
              if (context.mounted) {
                Navigator.pop(context);
                _loadDocuments();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_getTranslation('document_deleted', language)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(_getTranslation('delete', language)),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeDocument(Map<String, dynamic> document) async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final response = await ApiService.getDocumentData(document['id']);

    if (response['success'] == true && response['document_data'] != null) {
      try {
        final String base64Image = response['document_data'];
        final Uint8List imageBytes = base64Decode(base64Image);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.blue),
                const SizedBox(height: 20),
                Text(_getTranslation('analyzing', language)),
              ],
            ),
          ),
        );

        final analysisResult = await ApiService.analyzeMelanoma(base64Image);

        if (context.mounted) {
          Navigator.pop(context);

          if (analysisResult['success'] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalyzeResultPage(
                  imageBytes: imageBytes,
                  analysisResult: analysisResult,
                  patientId: widget.patient['id'],
                  doctorEmail: widget.doctorEmail,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_getTranslation('analysis_error', language)} ${analysisResult['error'] ?? _getTranslation('analysis_failed', language)}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getTranslation('load_image_error', language)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context).currentLanguage;
    final isRtl = language == 'ar';
    final age = _calculateAge(widget.patient['birth_date'] ?? '');

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.patient['first_name']} ${widget.patient['last_name']}',
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
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportsListPage(
                      patientId: widget.patient['id'],
                      patientName: '${widget.patient['first_name']} ${widget.patient['last_name']}',
                    ),
                  ),
                );
              },
              tooltip: _getTranslation('reports', language),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _addDocument,
              tooltip: _getTranslation('add_document', language),
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
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslation('patient_info', language),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(_getTranslation('full_name', language), '${widget.patient['first_name']} ${widget.patient['last_name']}', language),
                    _buildInfoRow(_getTranslation('birth_date', language), widget.patient['birth_date'] ?? _getTranslation('not_specified', language), language),
                    _buildInfoRow(_getTranslation('age', language), '$age ${_getTranslation('years', language)}', language),
                    _buildInfoRow(_getTranslation('phone', language), widget.patient['phone'] ?? _getTranslation('not_specified', language), language),
                    _buildInfoRow(_getTranslation('last_visit', language), widget.patient['last_visit'] ?? _getTranslation('not_specified', language), language),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTranslation('medical_documents', language),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    TextButton.icon(
                      onPressed: _addDocument,
                      icon: const Icon(Icons.upload, color: Colors.white),
                      label: Text(_getTranslation('add_document', language), style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _documents.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 80, color: Colors.white54),
                      const SizedBox(height: 20),
                      Text(_getTranslation('no_documents', language), style: const TextStyle(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 10),
                      Text(_getTranslation('no_documents_subtitle', language), style: const TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.image, color: Colors.blue.shade700),
                        ),
                        title: Text(doc['document_name']),
                        subtitle: Text('${_getTranslation('added_on', language)} ${doc['uploaded_at']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.analytics, color: Colors.purple),
                              onPressed: () => _analyzeDocument(doc),
                              tooltip: _getTranslation('analyze', language),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDocument(doc['id'], doc['document_name']),
                            ),
                          ],
                        ),
                        onTap: () => _viewDocument(doc),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, String language) {
    final isRtl = language == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isRtl ? 100 : 120,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700), textAlign: isRtl ? TextAlign.right : TextAlign.left),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.blue.shade800), textAlign: isRtl ? TextAlign.right : TextAlign.left),
          ),
        ],
      ),
    );
  }
}