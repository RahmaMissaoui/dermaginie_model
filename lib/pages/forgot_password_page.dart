import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../language_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String _email = '';

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getTranslation(String key, String language) {
    switch (key) {
    // عنوان الصفحة
      case 'title_send':
        return language == 'fr'
            ? 'Mot de passe oublié'
            : (language == 'ar' ? 'نسيت كلمة المرور' : 'Forgot Password');
      case 'title_reset':
        return language == 'fr'
            ? 'Réinitialisation'
            : (language == 'ar' ? 'إعادة تعيين' : 'Reset Password');

    // النصوص التوضيحية
      case 'subtitle_send':
        return language == 'fr'
            ? 'Entrez votre email pour recevoir un code de réinitialisation'
            : (language == 'ar' ? 'أدخل بريدك الإلكتروني لاستلام رمز إعادة التعيين' : 'Enter your email to receive a reset code');
      case 'subtitle_reset':
        return language == 'fr'
            ? 'Entrez le code reçu par email et votre nouveau mot de passe'
            : (language == 'ar' ? 'أدخل الرمز المستلم عبر البريد الإلكتروني وكلمة المرور الجديدة' : 'Enter the code received by email and your new password');

    // الحقول
      case 'email':
        return language == 'fr' ? 'Email' : (language == 'ar' ? 'البريد الإلكتروني' : 'Email');
      case 'reset_code':
        return language == 'fr' ? 'Code de vérification' : (language == 'ar' ? 'رمز التحقق' : 'Verification Code');
      case 'new_password':
        return language == 'fr' ? 'Nouveau mot de passe' : (language == 'ar' ? 'كلمة المرور الجديدة' : 'New Password');
      case 'confirm_password':
        return language == 'fr' ? 'Confirmer le mot de passe' : (language == 'ar' ? 'تأكيد كلمة المرور' : 'Confirm Password');

    // الأزرار
      case 'send_code':
        return language == 'fr' ? 'Envoyer le code' : (language == 'ar' ? 'إرسال الرمز' : 'Send Code');
      case 'reset_button':
        return language == 'fr' ? 'Réinitialiser' : (language == 'ar' ? 'إعادة تعيين' : 'Reset');
      case 'back_to_login':
        return language == 'fr' ? 'Retour à la connexion' : (language == 'ar' ? 'العودة إلى تسجيل الدخول' : 'Back to Login');
      case 'ok':
        return language == 'fr' ? 'OK' : (language == 'ar' ? 'حسنًا' : 'OK');

    // رسائل النجاح
      case 'code_sent':
        return language == 'fr'
            ? 'Code envoyé à votre email'
            : (language == 'ar' ? 'تم إرسال الرمز إلى بريدك الإلكتروني' : 'Code sent to your email');
      case 'reset_success':
        return language == 'fr'
            ? 'Mot de passe réinitialisé avec succès!\nVous pouvez maintenant vous connecter.'
            : (language == 'ar' ? 'تم إعادة تعيين كلمة المرور بنجاح!\nيمكنك الآن تسجيل الدخول.' : 'Password reset successfully!\nYou can now login.');

    // رسائل الخطأ
      case 'error_valid_email':
        return language == 'fr'
            ? 'Email valide requis'
            : (language == 'ar' ? 'بريد إلكتروني صالح مطلوب' : 'Valid email required');
      case 'error_code_required':
        return language == 'fr'
            ? 'Code à 6 caractères requis'
            : (language == 'ar' ? 'رمز مكون من 6 أحرف مطلوب' : '6-character code required');
      case 'error_password_length':
        return language == 'fr'
            ? 'Mot de passe doit contenir au moins 4 caractères'
            : (language == 'ar' ? 'كلمة المرور يجب أن تحتوي على 4 أحرف على الأقل' : 'Password must be at least 4 characters');
      case 'error_password_mismatch':
        return language == 'fr'
            ? 'Les mots de passe ne correspondent pas'
            : (language == 'ar' ? 'كلمات المرور غير متطابقة' : 'Passwords do not match');
      case 'error_occurred':
        return language == 'fr'
            ? 'Une erreur est survenue'
            : (language == 'ar' ? 'حدث خطأ' : 'An error occurred');

      default:
        return '';
    }
  }

  Future<void> _sendResetCode() async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation('error_valid_email', language)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.forgotPassword(_emailController.text);

    setState(() => _isLoading = false);

    if (response.containsKey('message')) {
      setState(() {
        _codeSent = true;
        _email = _emailController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation('code_sent', language)),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['error'] ?? _getTranslation('error_occurred', language)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    final language = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    if (_tokenController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation('error_code_required', language)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation('error_password_length', language)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslation('error_password_mismatch', language)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.resetPassword(
      _email,
      _tokenController.text,
      _newPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (response.containsKey('message')) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: Text(
            _getTranslation('reset_success', language),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // fermer dialog
                  Navigator.pop(context); // retour à login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  _getTranslation('ok', language),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['error'] ?? _getTranslation('error_occurred', language)),
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
              Navigator.pop(context);
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
                          _codeSent ? Icons.security : Icons.lock_reset,
                          size: 70,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _codeSent
                              ? _getTranslation('title_reset', language)
                              : _getTranslation('title_send', language),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _codeSent
                              ? _getTranslation('subtitle_reset', language)
                              : _getTranslation('subtitle_send', language),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        if (!_codeSent) ...[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
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
                          const SizedBox(height: 30),

                          _isLoading
                              ? CircularProgressIndicator(color: Colors.blue.shade700)
                              : ElevatedButton(
                            onPressed: _sendResetCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            ),
                            child: Text(
                              _getTranslation('send_code', language),
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],

                        if (_codeSent) ...[
                          TextFormField(
                            controller: _tokenController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: _getTranslation('reset_code', language),
                              prefixIcon: Icon(Icons.security, color: Colors.blue.shade700),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
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
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(
                              labelText: _getTranslation('new_password', language),
                              prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility, color: Colors.blue.shade700),
                                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
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
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(
                              labelText: _getTranslation('confirm_password', language),
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.blue.shade700),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.blue.shade700),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
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
                            onPressed: _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            ),
                            child: Text(
                              _getTranslation('reset_button', language),
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            _getTranslation('back_to_login', language),
                            style: TextStyle(color: Colors.blue.shade700),
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