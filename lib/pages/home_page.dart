import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';
import 'welcome_page.dart';
import 'patients_page.dart';
import '../services/api_service.dart';
import '../language_provider.dart';

class HomePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;

  const HomePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _age = '';
  String _phone = '';
  String _profileImage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  String _getTranslation(String key, String language) {
    switch (key) {
      case 'home_title':
        return language == 'fr' ? 'Accueil' : (language == 'ar' ? 'الرئيسية' : 'Home');
      case 'doctor':
        return language == 'fr' ? 'Dr.' : (language == 'ar' ? 'د.' : 'Dr.');
      case 'welcome_title':
        return language == 'fr' ? 'Bienvenue dans votre espace' : (language == 'ar' ? 'مرحباً بك في مساحتك الخاصة' : 'Welcome to your space');
      case 'welcome_subtitle':
        return language == 'fr' ? 'Gérez vos patients et vos consultations' : (language == 'ar' ? 'إدارة مرضاك واستشاراتك' : 'Manage your patients and consultations');
      case 'see_patients':
        return language == 'fr' ? 'Voir mes patients' : (language == 'ar' ? 'عرض مرضاي' : 'View my patients');
      case 'logout':
        return language == 'fr' ? 'Déconnexion' : (language == 'ar' ? 'تسجيل الخروج' : 'Logout');
      case 'first_name':
        return language == 'fr' ? 'Prénom' : (language == 'ar' ? 'الاسم الأول' : 'First Name');
      case 'last_name':
        return language == 'fr' ? 'Nom' : (language == 'ar' ? 'اسم العائلة' : 'Last Name');
      case 'age':
        return language == 'fr' ? 'Âge' : (language == 'ar' ? 'العمر' : 'Age');
      case 'phone':
        return language == 'fr' ? 'Téléphone' : (language == 'ar' ? 'الهاتف' : 'Phone');
      case 'email':
        return language == 'fr' ? 'Email' : (language == 'ar' ? 'البريد الإلكتروني' : 'Email');
      case 'edit_profile':
        return language == 'fr' ? 'Modifier le profil' : (language == 'ar' ? 'تعديل الملف الشخصي' : 'Edit Profile');
      case 'cancel':
        return language == 'fr' ? 'Annuler' : (language == 'ar' ? 'إلغاء' : 'Cancel');
      case 'save':
        return language == 'fr' ? 'Enregistrer' : (language == 'ar' ? 'حفظ' : 'Save');
      case 'profile_updated':
        return language == 'fr' ? 'Profil mis à jour!' : (language == 'ar' ? 'تم تحديث الملف الشخصي!' : 'Profile updated!');
      case 'profile_image_updated':
        return language == 'fr' ? 'Photo de profil mise à jour!' : (language == 'ar' ? 'تم تحديث صورة الملف الشخصي!' : 'Profile image updated!');
      default:
        return '';
    }
  }

  // ✅ دالة مساعدة لعرض الصورة بأمان
  ImageProvider? _getProfileImage() {
    if (_profileImage.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(_profileImage));
    } catch (e) {
      print('❌ Error decoding base64 image: $e');
      return null;
    }
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getUserInfo(widget.email);
      if (response['success'] == true) {
        setState(() {
          _age = response['user_info']['age'].toString();
          _phone = response['user_info']['phone'] ?? '';
          _profileImage = response['user_info']['profile_image'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading user info: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        File imageFile = File(pickedFile.path);
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        final userData = {
          'email': widget.email,
          'first_name': widget.firstName,
          'last_name': widget.lastName,
          'age': int.parse(_age),
          'phone': _phone,
          'profile_image': base64Image,
        };

        await ApiService.updateUserInfo(userData);
        await _loadUserInfo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getTranslation('profile_image_updated', Provider.of<LanguageProvider>(context, listen: false).currentLanguage)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Error picking/updating image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error updating profile image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditProfileDialog() {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    final isRtl = language == 'ar';
    final firstNameController = TextEditingController(text: widget.firstName);
    final lastNameController = TextEditingController(text: widget.lastName);
    final ageController = TextEditingController(text: _age);
    final phoneController = TextEditingController(text: _phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_getTranslation('edit_profile', language)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: _getProfileImage(),
                  child: _profileImage.isEmpty ? Icon(Icons.camera_alt, size: 40, color: Colors.blue.shade700) : null,
                ),
              ),
              const SizedBox(height: 20),
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
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  labelText: _getTranslation('age', language),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
              try {
                final userData = {
                  'email': widget.email,
                  'first_name': firstNameController.text,
                  'last_name': lastNameController.text,
                  'age': int.parse(ageController.text),
                  'phone': phoneController.text,
                  'profile_image': _profileImage,
                };
                await ApiService.updateUserInfo(userData);
                await _loadUserInfo();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_getTranslation('profile_updated', language)),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error updating profile: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error updating profile'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            child: Text(_getTranslation('save', language), style: const TextStyle(color: Colors.white)),
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade900, Colors.blue.shade700, Colors.blue.shade500, Colors.blue.shade300],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Column(
              children: [
                // AppBar personnalisée
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WelcomePage())),
                      ),
                      Text(_getTranslation('home_title', language), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                      ),
                    ],
                  ),
                ),
                // Carte du médecin
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    color: Colors.white.withOpacity(0.95),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: _getProfileImage(),
                              child: _profileImage.isEmpty ? Icon(Icons.camera_alt, size: 30, color: Colors.blue.shade700) : null,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getTranslation('doctor', language)} ${widget.firstName} ${widget.lastName}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                                ),
                                const SizedBox(height: 4),
                                Text(widget.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          // ✅ أيقونة المرضى فقط (تم حذف edit و medical_information)
                          IconButton(
                            icon: Icon(Icons.people, color: Colors.green.shade700),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PatientsPage(doctorEmail: widget.email))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services, size: 100, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 20),
                        Text(_getTranslation('welcome_title', language), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 20, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Text(_getTranslation('welcome_subtitle', language), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14), textAlign: TextAlign.center),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PatientsPage(doctorEmail: widget.email))),
                          icon: const Icon(Icons.people),
                          label: Text(_getTranslation('see_patients', language)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade800,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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