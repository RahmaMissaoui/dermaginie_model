import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ الرابط الثابت - لا حاجة لملف .env
  static const String baseUrl = 'https://appmel-production.up.railway.app';

  // ==================== AUTHENTIFICATION ====================

  // 1. تسجيل مستخدم جديد
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      print('📤 Register request to: $baseUrl/register');
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 60));
      print('✅ Register response: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Register error: $e');
      return {'error': 'Connexion au serveur impossible'};
    }
  }

  // 2. التحقق من التوكن والتسجيل النهائي
  static Future<Map<String, dynamic>> verify(Map<String, dynamic> verifyData) async {
    try {
      print('📤 Verify request to: $baseUrl/verify');
      final response = await http.post(
        Uri.parse('$baseUrl/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(verifyData),
      ).timeout(const Duration(seconds: 60));
      print('✅ Verify response: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Verify error: $e');
      return {'error': 'Connexion au serveur impossible'};
    }
  }

  // 3. تسجيل الدخول
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Login attempt for: $email');
      print('🌐 URL: $baseUrl/login');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 60));

      print('✅ Login status: ${response.statusCode}');
      print('✅ Login body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'error': 'Connexion au serveur impossible'};
    }
  }

  // 4. طلب إعادة تعيين كلمة السر
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Forgot password error: $e');
      return {'error': 'Connexion au serveur impossible'};
    }
  }

  // 5. إعادة تعيين كلمة السر
  static Future<Map<String, dynamic>> resetPassword(String email, String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Reset password error: $e');
      return {'error': 'Connexion au serveur impossible'};
    }
  }

  // ==================== PROFIL MÉDECIN ====================

  static Future<Map<String, dynamic>> getDoctorInfo(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-doctor-info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get doctor info error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  static Future<Map<String, dynamic>> saveDoctorInfo(Map<String, dynamic> doctorData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save-doctor-info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(doctorData),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Save doctor info error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  static Future<Map<String, dynamic>> getUserInfo(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-user-info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get user info error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  static Future<Map<String, dynamic>> updateUserInfo(Map<String, dynamic> userData) async {
    try {
      print('📤 Update user info to: $baseUrl/update-user-info');
      final response = await http.post(
        Uri.parse('$baseUrl/update-user-info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 60));
      print('✅ Update user info response: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Update user info error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  // ==================== PATIENTS ====================

  static Future<Map<String, dynamic>> getPatients(String doctorEmail, {String search = ''}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-patients'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'doctor_email': doctorEmail, 'search': search}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get patients error: $e');
      return {'success': false, 'patients': []};
    }
  }

  static Future<Map<String, dynamic>> addPatient(Map<String, dynamic> patientData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-patient'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(patientData),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Add patient error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  static Future<Map<String, dynamic>> updatePatient(Map<String, dynamic> patientData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-patient'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(patientData),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Update patient error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  static Future<Map<String, dynamic>> deletePatient(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete-patient'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Delete patient error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  // ==================== DOCUMENTS ====================

  static Future<Map<String, dynamic>> addDocument(Map<String, dynamic> docData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-document'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(docData),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Add document error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  static Future<Map<String, dynamic>> getDocuments(int patientId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-documents'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patient_id': patientId}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get documents error: $e');
      return {'success': false, 'documents': []};
    }
  }

  static Future<Map<String, dynamic>> deleteDocument(int docId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete-document'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': docId}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Delete document error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  static Future<Map<String, dynamic>> getDocumentData(int docId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-document-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': docId}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get document data error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  // ==================== ANALYSE IMAGE ====================

  static Future<Map<String, dynamic>> analyzeMelanoma(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze-melanoma'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 120));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Analyze melanoma error: $e');
      return {'success': false, 'error': 'Connexion au serveur impossible'};
    }
  }

  static Future<Map<String, dynamic>> analyzeImageDemo(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze-demo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Analyze demo error: $e');
      return {'success': false, 'error': 'Connexion au serveur impossible'};
    }
  }

  static Future<Map<String, dynamic>> analyzeRealImage(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze-real'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 120));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Analyze real image error: $e');
      return {'success': false, 'error': 'Connexion au serveur impossible'};
    }
  }

  static Future<Map<String, dynamic>> saveAnalysisResult(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save-analysis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Save analysis error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  static Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reportData),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Create report error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }

  static Future<Map<String, dynamic>> getReports(int patientId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patient_id': patientId}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get reports error: $e');
      return {'success': false, 'reports': []};
    }
  }

  static Future<Map<String, dynamic>> getReport(int reportId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'report_id': reportId}),
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Get report error: $e');
      return {'success': false, 'error': 'Connexion impossible'};
    }
  }
}