import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'verify_page.dart';
import 'login_page.dart';
import 'welcome_page.dart';
import '../language_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getTranslation(String key, String language) {
    switch (key) {
    // عنوان الصفحة
      case 'title':
        return language == 'fr'
            ? 'Créer un compte'
            : (language == 'ar' ? 'إنشاء حساب' : 'Create Account');
      case 'subtitle':
        return language == 'fr'
            ? 'Entrez vos informations pour vous inscrire'
            : (language == 'ar' ? 'أدخل معلوماتك للتسجيل' : 'Enter your information to sign up');

    // الحقول
      case 'first_name':
        return language == 'fr' ? 'Prénom' : (language == 'ar' ? 'الاسم الأول' : 'First Name');
      case 'last_name':
        return language == 'fr' ? 'Nom' : (language == 'ar' ? 'اسم العائلة' : 'Last Name');
      case 'age':
        return language == 'fr' ? 'Âge' : (language == 'ar' ? 'العمر' : 'Age');
      case 'phone':
        return language == 'fr' ? 'Numéro de téléphone' : (language == 'ar' ? 'رقم الهاتف' : 'Phone Number');
      case 'email':
        return language == 'fr' ? 'Email' : (language == 'ar' ? 'البريد الإلكتروني' : 'Email');
      case 'password':
        return language == 'fr' ? 'Mot de passe' : (language == 'ar' ? 'كلمة المرور' : 'Password');

    // رسائل التحقق
      case 'required_first_name':
        return language == 'fr' ? 'Prénom requis' : (language == 'ar' ? 'الاسم الأول مطلوب' : 'First name required');
      case 'required_last_name':
        return language == 'fr' ? 'Nom requis' : (language == 'ar' ? 'اسم العائلة مطلوب' : 'Last name required');
      case 'required_age':
        return language == 'fr' ? 'Âge requis' : (language == 'ar' ? 'العمر مطلوب' : 'Age required');
      case 'required_phone':
        return language == 'fr' ? 'Téléphone requis' : (language == 'ar' ? 'رقم الهاتف مطلوب' : 'Phone number required');
      case 'required_email':
        return language == 'fr' ? 'Email valide requis' : (language == 'ar' ? 'بريد إلكتروني صالح مطلوب' : 'Valid email required');
      case 'required_password':
        return language == 'fr'
            ? 'Le mot de passe doit contenir au moins 4 caractères'
            : (language == 'ar' ? 'كلمة المرور يجب أن تحتوي على 4 أحرف على الأقل' : 'Password must be at least 4 characters');

    // الأزرار والروابط
      case 'register_button':
        return language == 'fr' ? 'S\'inscrire' : (language == 'ar' ? 'تسجيل' : 'Register');
      case 'have_account':
        return language == 'fr' ? 'Vous avez déjà un compte ? ' : (language == 'ar' ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ');
      case 'login_link':
        return language == 'fr' ? 'Se connecter' : (language == 'ar' ? 'تسجيل الدخول' : 'Login');

    // رسائل الخطأ
      case 'error_occurred':
        return language == 'fr' ? 'Une erreur est survenue' : (language == 'ar' ? 'حدث خطأ' : 'An error occurred');
      case 'email_exists':
        return language == 'fr'
            ? 'Cet email est déjà utilisé. Veuillez vous connecter.'
            : (language == 'ar' ? 'هذا البريد الإلكتروني مستخدم بالفعل. الرجاء تسجيل الدخول' : 'This email is already used. Please login.');

      default:
        return '';
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final userData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'age': int.parse(_ageController.text),
        'phone': _phoneController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      final response = await ApiService.register(userData);

      setState(() => _isLoading = false);

      if (response.containsKey('email')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyPage(
              email: _emailController.text,
              userData: userData,
            ),
          ),
        );
      } else {
        final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
        String errorMessage = response['error'] ?? _getTranslation('error_occurred', language);

        if (errorMessage.contains('déjà utilisé') || errorMessage.contains('already used')) {
          errorMessage = _getTranslation('email_exists', language);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WelcomePage()),
              );
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.app_registration,
                            size: 70,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(height: 10),
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
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),

                          _buildTextField(
                            controller: _firstNameController,
                            label: _getTranslation('first_name', language),
                            icon: Icons.person,
                            validator: (v) => v!.isEmpty ? _getTranslation('required_first_name', language) : null,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _lastNameController,
                            label: _getTranslation('last_name', language),
                            icon: Icons.person_outline,
                            validator: (v) => v!.isEmpty ? _getTranslation('required_last_name', language) : null,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _ageController,
                            label: _getTranslation('age', language),
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? _getTranslation('required_age', language) : null,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _phoneController,
                            label: _getTranslation('phone', language),
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.isEmpty ? _getTranslation('required_phone', language) : null,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _emailController,
                            label: _getTranslation('email', language),
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.isEmpty || !v.contains('@')
                                ? _getTranslation('required_email', language) : null,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _passwordController,
                            label: _getTranslation('password', language),
                            icon: Icons.lock,
                            obscureText: true,
                            validator: (v) => v!.length < 4
                                ? _getTranslation('required_password', language) : null,
                          ),
                          const SizedBox(height: 30),

                          _isLoading
                              ? CircularProgressIndicator(color: Colors.blue.shade700)
                              : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                            child: Text(
                              _getTranslation('register_button', language),
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getTranslation('have_account', language),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
                                child: Text(
                                  _getTranslation('login_link', language),
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    final language = Provider.of<LanguageProvider>(context).currentLanguage;
    final isRtl = language == 'ar';

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
        ),
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}