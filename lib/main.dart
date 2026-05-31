import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'language_provider.dart';
//import 'test_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await dotenv.load();
  //runApp(TestApiPage());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp(); // استدعاء دالة التهيئة
  }

  // دالة التهيئة - تتحقق من المنصة
  Future<void> _initializeApp() async {
    if (UniversalPlatform.isWeb) {
      // على الويب: لا تطلب صلاحيات
      debugPrint("🌐 Running on Web - No permissions needed");
      setState(() {
        _isLoading = false;
      });
    } else {
      // على الأجهزة المحمولة: اطلب الصلاحيات
      await _requestPermissions();
    }
  }

  // دالة طلب الصلاحيات للأجهزة المحمولة
  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.photos,
    ].request();

    final allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      debugPrint("⚠️ Certaines permissions ont été refusées");
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF010A1F),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF4DEBFF),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        title: 'Dermagenie',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomePage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}