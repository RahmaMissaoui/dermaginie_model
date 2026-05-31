import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../language_provider.dart';
import 'patient_details_page.dart';

class PatientsPage extends StatefulWidget {
  final String doctorEmail;

  const PatientsPage({super.key, required this.doctorEmail});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortOrder = 'recent';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  String _getTranslation(String key, String language) {
    switch (key) {
      case 'title':
        return language == 'fr'
            ? 'Mes patients'
            : (language == 'ar' ? 'مرضاي' : 'My Patients');
      case 'recent':
        return language == 'fr'
            ? 'Récent'
            : (language == 'ar' ? 'الأحدث' : 'Recent');
      case 'az':
        return language == 'fr'
            ? 'A-Z'
            : (language == 'ar' ? 'أ-ي' : 'A-Z');
      case 'za':
        return language == 'fr'
            ? 'Z-A'
            : (language == 'ar' ? 'ي-أ' : 'Z-A');
      case 'search_hint':
        return language == 'fr'
            ? 'Rechercher un patient...'
            : (language == 'ar' ? 'البحث عن مريض...' : 'Search for a patient...');
      case 'first_name':
        return language == 'fr'
            ? 'Prénom *'
            : (language == 'ar' ? 'الاسم الأول *' : 'First Name *');
      case 'last_name':
        return language == 'fr'
            ? 'Nom *'
            : (language == 'ar' ? 'اسم العائلة *' : 'Last Name *');
      case 'birth_date':
        return language == 'fr'
            ? 'Date de naissance *'
            : (language == 'ar' ? 'تاريخ الميلاد *' : 'Birth Date *');
      case 'phone':
        return language == 'fr'
            ? 'Téléphone'
            : (language == 'ar' ? 'الهاتف' : 'Phone');
      case 'last_visit':
        return language == 'fr'
            ? 'Dernière visite'
            : (language == 'ar' ? 'آخر زيارة' : 'Last Visit');
      case 'medical_notes':
        return language == 'fr'
            ? 'Notes médicales'
            : (language == 'ar' ? 'ملاحظات طبية' : 'Medical Notes');
      case 'add_patient':
        return language == 'fr'
            ? 'Ajouter un patient'
            : (language == 'ar' ? 'إضافة مريض' : 'Add Patient');
      case 'edit_patient':
        return language == 'fr'
            ? 'Modifier le patient'
            : (language == 'ar' ? 'تعديل المريض' : 'Edit Patient');
      case 'cancel':
        return language == 'fr'
            ? 'Annuler'
            : (language == 'ar' ? 'إلغاء' : 'Cancel');
      case 'add':
        return language == 'fr'
            ? 'Ajouter'
            : (language == 'ar' ? 'إضافة' : 'Add');
      case 'edit':
        return language == 'fr'
            ? 'Modifier'
            : (language == 'ar' ? 'تعديل' : 'Edit');
      case 'delete':
        return language == 'fr'
            ? 'Supprimer'
            : (language == 'ar' ? 'حذف' : 'Delete');
      case 'export':
        return language == 'fr'
            ? 'Exporter la liste'
            : (language == 'ar' ? 'تصدير القائمة' : 'Export list');
      case 'confirm_title':
        return language == 'fr'
            ? 'Confirmation'
            : (language == 'ar' ? 'تأكيد' : 'Confirmation');
      case 'delete_message':
        return language == 'fr'
            ? 'Supprimer'
            : (language == 'ar' ? 'حذف' : 'Delete');
      case 'required_fields':
        return language == 'fr'
            ? 'Prénom, Nom et Date de naissance sont requis'
            : (language == 'ar' ? 'الاسم الأول والاسم الأخير وتاريخ الميلاد مطلوبة' : 'First name, last name and birth date are required');
      case 'patient_added':
        return language == 'fr'
            ? 'Patient ajouté'
            : (language == 'ar' ? 'تم إضافة المريض' : 'Patient added');
      case 'patient_updated':
        return language == 'fr'
            ? 'Patient modifié'
            : (language == 'ar' ? 'تم تعديل المريض' : 'Patient updated');
      case 'patient_deleted':
        return language == 'fr'
            ? 'Patient supprimé'
            : (language == 'ar' ? 'تم حذف المريض' : 'Patient deleted');
      case 'exported_clipboard':
        return language == 'fr'
            ? 'Liste copiée dans le presse-papier'
            : (language == 'ar' ? 'تم نسخ القائمة إلى الحافظة' : 'List copied to clipboard');
      case 'no_patients':
        return language == 'fr'
            ? 'Aucun patient'
            : (language == 'ar' ? 'لا يوجد مرضى' : 'No patients');
      case 'no_patients_subtitle':
        return language == 'fr'
            ? 'Cliquez sur le bouton + pour ajouter un patient'
            : (language == 'ar' ? 'انقر على زر + لإضافة مريض' : 'Click the + button to add a patient');
      case 'empty_export':
        return language == 'fr'
            ? 'Aucun patient à exporter'
            : (language == 'ar' ? 'لا يوجد مرضى للتصدير' : 'No patients to export');
      case 'years_old':
        return language == 'fr'
            ? 'ans'
            : (language == 'ar' ? 'سنة' : 'years');
      case 'last_visit_label':
        return language == 'fr'
            ? 'Dernière visite:'
            : (language == 'ar' ? 'آخر زيارة:' : 'Last visit:');
      case 'not_specified':
        return language == 'fr'
            ? 'Non spécifiée'
            : (language == 'ar' ? 'غير محدد' : 'Not specified');
      case 'none':
        return language == 'fr'
            ? 'Aucune'
            : (language == 'ar' ? 'لا يوجد' : 'None');
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

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getPatients(widget.doctorEmail, search: _searchQuery);
    if (response['success'] == true) {
      setState(() {
        _patients = List<Map<String, dynamic>>.from(response['patients']);
        _applySorting();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _applySorting() {
    List<Map<String, dynamic>> sorted = List.from(_patients);
    if (_sortOrder == 'recent') {
      sorted.sort((a, b) {
        String dateA = a['created_at'] ?? '';
        String dateB = b['created_at'] ?? '';
        return dateB.compareTo(dateA);
      });
    } else if (_sortOrder == 'az') {
      sorted.sort((a, b) => '${a['first_name']} ${a['last_name']}'.compareTo('${b['first_name']} ${b['last_name']}'));
    } else if (_sortOrder == 'za') {
      sorted.sort((a, b) => '${b['first_name']} ${b['last_name']}'.compareTo('${a['first_name']} ${a['last_name']}'));
    }
    setState(() {
      _filteredPatients = sorted;
    });
  }

  void _sortBy(String order) {
    setState(() {
      _sortOrder = order;
      _applySorting();
    });
  }

  void _copyToClipboard() async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    if (_filteredPatients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getTranslation('empty_export', language)), backgroundColor: Colors.orange),
      );
      return;
    }
    StringBuffer buffer = StringBuffer();
    buffer.writeln('=== ${_getTranslation('title', language).toUpperCase()} ===\n');
    buffer.writeln('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n');
    buffer.writeln('-' * 50);
    for (var patient in _filteredPatients) {
      buffer.writeln('${_getTranslation('first_name', language)}: ${patient['first_name']} ${patient['last_name']}');
      buffer.writeln('${_getTranslation('birth_date', language)}: ${patient['birth_date'] ?? _getTranslation('not_specified', language)}');
      buffer.writeln('${_getTranslation('age', language)}: ${_calculateAge(patient['birth_date'] ?? '')} ${_getTranslation('years_old', language)}');
      buffer.writeln('${_getTranslation('phone', language)}: ${patient['phone'] ?? _getTranslation('not_specified', language)}');
      buffer.writeln('${_getTranslation('last_visit', language)}: ${patient['last_visit'] ?? _getTranslation('not_specified', language)}');
      buffer.writeln('${_getTranslation('medical_notes', language)}: ${patient['notes'] ?? _getTranslation('none', language)}');
      buffer.writeln('-' * 50);
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_getTranslation('exported_clipboard', language)), backgroundColor: Colors.green),
    );
  }

  void _showAddPatientDialog() {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final isRtl = language == 'ar';
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final birthDateController = TextEditingController();
    final phoneController = TextEditingController();
    final lastVisitController = TextEditingController();
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_getTranslation('add_patient', language)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: _getTranslation('first_name', language),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: _getTranslation('last_name', language),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    birthDateController.text = '${date.day}/${date.month}/${date.year}';
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: birthDateController,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    decoration: InputDecoration(
                      labelText: _getTranslation('birth_date', language),
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: _getTranslation('phone', language),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    lastVisitController.text = '${date.day}/${date.month}/${date.year}';
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: lastVisitController,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    decoration: InputDecoration(
                      labelText: _getTranslation('last_visit', language),
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: _getTranslation('medical_notes', language),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTranslation('cancel', language)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.isEmpty || lastNameController.text.isEmpty || birthDateController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_getTranslation('required_fields', language)), backgroundColor: Colors.red),
                );
                return;
              }
              int age = _calculateAge(birthDateController.text);
              final patientData = {
                'doctor_email': widget.doctorEmail,
                'first_name': firstNameController.text,
                'last_name': lastNameController.text,
                'age': age,
                'birth_date': birthDateController.text,
                'phone': phoneController.text,
                'last_visit': lastVisitController.text,
                'notes': notesController.text,
              };
              await ApiService.addPatient(patientData);
              if (context.mounted) {
                Navigator.pop(context);
                _loadPatients();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_getTranslation('patient_added', language)), backgroundColor: Colors.green),
                );
              }
            },
            child: Text(_getTranslation('add', language)),
          ),
        ],
      ),
    );
  }

  void _showEditPatientDialog(Map<String, dynamic> patient) {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final isRtl = language == 'ar';
    final firstNameController = TextEditingController(text: patient['first_name']);
    final lastNameController = TextEditingController(text: patient['last_name']);
    final birthDateController = TextEditingController(text: patient['birth_date'] ?? '');
    final phoneController = TextEditingController(text: patient['phone'] ?? '');
    final lastVisitController = TextEditingController(text: patient['last_visit'] ?? '');
    final notesController = TextEditingController(text: patient['notes'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_getTranslation('edit_patient', language)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: _getTranslation('first_name', language),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: _getTranslation('last_name', language),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    birthDateController.text = '${date.day}/${date.month}/${date.year}';
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: birthDateController,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    decoration: InputDecoration(
                      labelText: _getTranslation('birth_date', language),
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: _getTranslation('phone', language),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    lastVisitController.text = '${date.day}/${date.month}/${date.year}';
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: lastVisitController,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    decoration: InputDecoration(
                      labelText: _getTranslation('last_visit', language),
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: _getTranslation('medical_notes', language),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTranslation('cancel', language)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.isEmpty || lastNameController.text.isEmpty || birthDateController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_getTranslation('required_fields', language)), backgroundColor: Colors.red),
                );
                return;
              }
              int age = _calculateAge(birthDateController.text);
              final patientData = {
                'id': patient['id'],
                'first_name': firstNameController.text,
                'last_name': lastNameController.text,
                'age': age,
                'birth_date': birthDateController.text,
                'phone': phoneController.text,
                'last_visit': lastVisitController.text,
                'notes': notesController.text,
              };
              await ApiService.updatePatient(patientData);
              if (context.mounted) {
                Navigator.pop(context);
                _loadPatients();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_getTranslation('patient_updated', language)), backgroundColor: Colors.green),
                );
              }
            },
            child: Text(_getTranslation('edit', language)),
          ),
        ],
      ),
    );
  }

  void _deletePatient(int id, String name) async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTranslation('confirm_title', language)),
        content: Text('${_getTranslation('delete_message', language)} $name ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTranslation('cancel', language)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.deletePatient(id);
              if (context.mounted) {
                Navigator.pop(context);
                _loadPatients();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_getTranslation('patient_deleted', language)), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context).currentLanguage;
    final isRtl = language == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTranslation('title', language), style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          leading: IconButton(
            icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              onPressed: _copyToClipboard,
              tooltip: _getTranslation('export', language),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _showAddPatientDialog,
              tooltip: _getTranslation('add_patient', language),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        _searchQuery = value;
                        _loadPatients();
                      },
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      decoration: InputDecoration(
                        hintText: _getTranslation('search_hint', language),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchQuery = '';
                            _loadPatients();
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSortButton(_getTranslation('recent', language), 'recent', Icons.access_time),
                        _buildSortButton(_getTranslation('az', language), 'az', Icons.sort_by_alpha),
                        _buildSortButton(_getTranslation('za', language), 'za', Icons.sort_by_alpha),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _filteredPatients.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.white54),
                      const SizedBox(height: 20),
                      Text(_getTranslation('no_patients', language), style: const TextStyle(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 10),
                      Text(_getTranslation('no_patients_subtitle', language), style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredPatients.length,
                  itemBuilder: (context, index) {
                    final patient = _filteredPatients[index];
                    int age = _calculateAge(patient['birth_date'] ?? '');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            '${patient['first_name'][0]}${patient['last_name'][0]}',
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('${patient['first_name']} ${patient['last_name']}'),
                        subtitle: Column(
                          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text('$age ${_getTranslation('years_old', language)} • ${patient['phone'] ?? ''}'),
                            if (patient['last_visit'] != null && patient['last_visit'].isNotEmpty)
                              Text(
                                '${_getTranslation('last_visit_label', language)} ${patient['last_visit']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.teal),
                              onPressed: () => _showEditPatientDialog(patient),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePatient(patient['id'], '${patient['first_name']} ${patient['last_name']}'),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientDetailsPage(
                                patient: patient,
                                doctorEmail: widget.doctorEmail,
                              ),
                            ),
                          );
                        },
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

  Widget _buildSortButton(String label, String order, IconData icon) {
    final bool isActive = _sortOrder == order;
    return ElevatedButton.icon(
      onPressed: () => _sortBy(order),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.teal.shade600 : Colors.white,
        foregroundColor: isActive ? Colors.white : Colors.blue.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}