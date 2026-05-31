import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';
import 'welcome_page.dart';
import '../language_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getTranslation(String key, String language) {
    switch (key) {
      case 'login':
        return language == 'fr' ? 'Connexion' : (language == 'ar' ? 'تسجيل الدخول' : 'Login');
      case 'subtitle':
        return language == 'fr'
            ? 'Entrez vos identifiants pour vous connecter'
            : (language == 'ar' ? 'أدخل بياناتك لتسجيل الدخول' : 'Enter your credentials to login');
      case 'email':
        return language == 'fr' ? 'Email' : (language == 'ar' ? 'البريد الإلكتروني' : 'Email');
      case 'email_required':
        return language == 'fr' ? 'Email valide requis' : (language == 'ar' ? 'بريد إلكتروني صالح مطلوب' : 'Valid email required');
      case 'password':
        return language == 'fr' ? 'Mot de passe' : (language == 'ar' ? 'كلمة المرور' : 'Password');
      case 'password_required':
        return language == 'fr'
            ? 'Mot de passe doit contenir au moins 4 caractères'
            : (language == 'ar' ? 'كلمة المرور يجب أن تحتوي على 4 أحرف على الأقل' : 'Password must be at least 4 characters');
      case 'login_button':
        return language == 'fr' ? 'Se connecter' : (language == 'ar' ? 'تسجيل الدخول' : 'Login');
      case 'forgot_password':
        return language == 'fr' ? 'Mot de passe oublié ?' : (language == 'ar' ? 'نسيت كلمة المرور؟' : 'Forgot password?');
      case 'no_account':
        return language == 'fr' ? 'Vous n\'avez pas de compte ? ' : (language == 'ar' ? 'ليس لديك حساب؟ ' : 'Don\'t have an account? ');
      case 'sign_up':
        return language == 'fr' ? 'S\'inscrire' : (language == 'ar' ? 'إنشاء حساب' : 'Sign Up');
      case 'error_connection':
        return language == 'fr' ? 'Erreur de connexion' : (language == 'ar' ? 'خطأ في الاتصال' : 'Connection error');
      default:
        return '';
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final response = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (response['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              firstName: response['user']['first_name'],
              lastName: response['user']['last_name'],
              email: response['user']['email'],
            ),
          ),
        );
      } else {
        final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? _getTranslation('error_connection', language)),
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
                            Icons.login,
                            size: 70,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getTranslation('login', language),
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

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.isEmpty || !v.contains('@')
                                ? _getTranslation('email_required', language)
                                : null,
                            decoration: InputDecoration(
                              labelText: _getTranslation('email', language),
                              prefixIcon: Icon(Icons.email, color: Colors.blue.shade700),
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
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (v) => v!.length < 4
                                ? _getTranslation('password_required', language)
                                : null,
                            decoration: InputDecoration(
                              labelText: _getTranslation('password', language),
                              prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.blue.shade700,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
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
                            onPressed: _login,
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
                              _getTranslation('login_button', language),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) =>  ForgotPasswordPage()),
                              );
                            },
                            child: Text(
                              _getTranslation('forgot_password', language),
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getTranslation('no_account', language),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                                  );
                                },
                                child: Text(
                                  _getTranslation('sign_up', language),
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
}