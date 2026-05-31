import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final String language = languageProvider.currentLanguage;

    return WelcomePageContent(language: language);
  }
}

class WelcomePageContent extends StatelessWidget {
  final String language;
  const WelcomePageContent({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isRtl = language == 'ar';

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          final buttonWidth = screenWidth * 0.55;
          final buttonHeight = (screenHeight * 0.065).clamp(44.0, 60.0);
          final buttonFontSize = (screenWidth * 0.04).clamp(14.0, 20.0);
          final iconSize = (screenWidth * 0.05).clamp(18.0, 24.0);
          final bottomPadding = screenHeight * 0.05;
          final bool isTooSmall = screenWidth < 320;

          late final String buttonText;
          late final String questionText;
          late final String signUpText;

          switch (language) {
            case 'fr':
              buttonText = isTooSmall ? "Démarrer" : "Commencer";
              questionText = "Vous n'avez pas de compte ? ";
              signUpText = "S'inscrire";
              break;
            case 'ar':
              buttonText = isTooSmall ? "ابدأ" : "ابدأ الآن";
              questionText = "ليس لديك حساب؟ ";
              signUpText = "إنشاء حساب";
              break;
            default:
              buttonText = isTooSmall ? "Start" : "Get Started";
              questionText = "Don't have an account? ";
              signUpText = "Sign Up";
              break;
          }

          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/welwel1.png',
                    fit: BoxFit.cover,
                    width: screenWidth,
                    height: screenHeight,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // أزرار اختيار اللغة
                      Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLanguageButton(context, 'EN', 'en', language, languageProvider),
                            const SizedBox(width: 12),
                            _buildLanguageButton(context, 'FR', 'fr', language, languageProvider),
                            const SizedBox(width: 12),
                            _buildLanguageButton(context, 'AR', 'ar', language, languageProvider),
                          ],
                        ),
                      ),
                      const Spacer(flex: 4),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                          child: GestureDetector(
                            onTap: () {
                              // الانتقال إلى LoginPage مع الحفاظ على اللغة
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: Container(
                              width: buttonWidth,
                              height: buttonHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(buttonHeight / 2),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00E5FF),
                                    Color(0xFF008CFF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.3),
                                    blurRadius: screenHeight * 0.02,
                                    spreadRadius: 1,
                                    offset: Offset(0, screenHeight * 0.008),
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(buttonHeight / 2),
                                  color: const Color(0xFF04142E),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        buttonText,
                                        style: TextStyle(
                                          color: const Color(0xFF4DEBFF),
                                          fontSize: buttonFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (screenWidth > 280)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: isRtl ? 0 : screenWidth * 0.02,
                                          right: isRtl ? screenWidth * 0.02 : 0,
                                        ),
                                        child: Transform.scale(
                                          scaleX: isRtl ? -1 : 1,
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            color: const Color(0xFF4DEBFF),
                                            size: iconSize,
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
                      SizedBox(height: screenHeight * 0.025),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              questionText,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: (screenWidth * 0.035).clamp(11.0, 16.0),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: Text(
                                signUpText,
                                style: TextStyle(
                                  color: const Color(0xFF4DEBFF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: (screenWidth * 0.035).clamp(11.0, 16.0),
                                  decoration: TextDecoration.underline,
                                  decorationColor: const Color(0xFF4DEBFF),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: bottomPadding),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageButton(
      BuildContext context,
      String text,
      String langCode,
      String currentLanguage,
      LanguageProvider languageProvider,
      ) {
    final bool isSelected = currentLanguage == langCode;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          languageProvider.setLanguage(langCode);
          // لا حاجة لإعادة توجيه، الصفحة ستتغير تلقائياً
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF4DEBFF) : Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(25),
          color: isSelected ? const Color(0xFF4DEBFF).withOpacity(0.2) : Colors.transparent,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4DEBFF) : Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}