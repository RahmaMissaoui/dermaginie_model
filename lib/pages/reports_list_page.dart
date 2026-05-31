import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../language_provider.dart';
import 'report_details_page.dart';

class ReportsListPage extends StatefulWidget {
  final int patientId;
  final String patientName;

  const ReportsListPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  String _getTranslation(String key, String language) {
    switch (key) {
      case 'title':
        return language == 'fr'
            ? 'Rapports - '
            : (language == 'ar' ? 'التقارير - ' : 'Reports - ');
      case 'no_reports':
        return language == 'fr'
            ? 'Aucun rapport médical'
            : (language == 'ar' ? 'لا توجد تقارير طبية' : 'No medical reports');
      case 'click_to_create':
        return language == 'fr'
            ? 'Cliquez sur "Créer un rapport" après analyse'
            : (language == 'ar' ? 'انقر على "إنشاء تقرير" بعد التحليل' : 'Click "Create report" after analysis');
      case 'diagnosis':
        return language == 'fr'
            ? 'Diagnostic:'
            : (language == 'ar' ? 'التشخيص:' : 'Diagnosis:');
      case 'date':
        return language == 'fr'
            ? 'Date:'
            : (language == 'ar' ? 'التاريخ:' : 'Date:');
      case 'unknown_date':
        return language == 'fr'
            ? 'Date inconnue'
            : (language == 'ar' ? 'تاريخ غير معروف' : 'Unknown date');
      default:
        return '';
    }
  }

  String _formatDate(String date) {
    if (date.isEmpty) return 'Date inconnue';
    return date.split(' ')[0];
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getReports(widget.patientId);
    if (response['success'] == true) {
      setState(() {
        _reports = List<Map<String, dynamic>>.from(response['reports']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context).currentLanguage;
    final isRtl = language == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_getTranslation('title', language)}${widget.patientName}'),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_getTranslation('no_reports', language)),
              const SizedBox(height: 8),
              Text(_getTranslation('click_to_create', language)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _reports.length,
          itemBuilder: (context, index) {
            final report = _reports[index];
            final bool isMelanoma = report['diagnosis']
                .toLowerCase()
                .contains('mel');
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  Icons.description,
                  color: isMelanoma ? Colors.red : Colors.green,
                ),
                title: Text(report['report_title']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_getTranslation('diagnosis', language)} ${report['diagnosis']}'),
                    Text('${_getTranslation('date', language)} ${_formatDate(report['created_at'])}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailsPage(
                        reportId: report['id'],
                        patientId: widget.patientId,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}