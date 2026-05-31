import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../language_provider.dart';
import 'home_page.dart';

class VerifyPage extends StatefulWidget {
  final String email;
  final Map<String, dynamic> userData;

  const VerifyPage({super.key, required this.email, required this.userData});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final _tokenController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  String _getTranslation(String key, String language) {
    switch (key) {
    // عنوان الصفحة
      case 'title':
        return language == 'fr'
            ? 'Vérification'
            : (language == 'ar' ? 'تحقق' : 'Verification');

    // النصوص التوضيحية
      case 'subtitle':
        return language == 'fr'
            ? 'Un code a été envoyé à votre email'
            : (language == 'ar' ? 'تم إرسال رمز إلى بريدك الإلكتروني' : 'A code has been sent to your email');

    // الحقول
      case 'verification_code':
        return language == 'fr'
            ? 'Code de vérification'
            : (language == 'ar' ? 'رمز التحقق' : 'Verification Code');

    // الأزرار
      case 'verify_button':
        return language == 'fr'
            ? 'Vérifier'
            : (language == 'ar' ? 'تحقق' : 'Verify');

    // رسائل الخطأ
      case 'error_enter_code':
        return language == 'fr'
            ? 'Veuillez entrer le code de vérification'
            : (language == 'ar' ? 'الرجاء إدخال رمز التحقق' : 'Please enter the verification code');
      case 'error_wrong_code':
        return language == 'fr'
            ? 'Code incorrect. Veuillez réessayer.'
            : (language == 'ar' ? 'رمز غير صحيح. الرجاء المحاولة مرة أخرى' : 'Incorrect code. Please try again.');

      default:
        return '';
    }
  }

  Future<void> _verify() async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    if (_tokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation('error_enter_code', language)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final verifyData = {
      'email': widget.email,
      'token': _tokenController.text,
      'first_name': widget.userData['first_name'],
      'last_name': widget.userData['last_name'],
      'age': widget.userData['age'],
      'phone': widget.userData['phone'],
      'password': widget.userData['password'],
    };

    final response = await ApiService.verify(verifyData);

    setState(() => _isLoading = false);

    if (response.containsKey('message') && response['message'] == 'Inscription réussie') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            firstName: widget.userData['first_name'],
            lastName: widget.userData['last_name'],
            email: widget.email,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation('error_wrong_code', language)),
          backgroundColor: Colors.red,
        ),
      );
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isRtl ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // العودة إلى RegisterPage
            },
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900,
                Colors.blue.shade600,
                Colors.blue.shade400,
                Colors.blue.shade200,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 20,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 80,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 20),

                        Text(
                          _getTranslation('title', language),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          _getTranslation('subtitle', language),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            widget.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        TextFormField(
                          controller: _tokenController,
                          keyboardType: TextInputType.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 4,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: _getTranslation('verification_code', language),
                            prefixIcon: Icon(Icons.security, color: Colors.blue.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 30),

                        _isLoading
                            ? CircularProgressIndicator(color: Colors.blue.shade700)
                            : ElevatedButton(
                          onPressed: _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: Text(
                            _getTranslation('verify_button', language),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}