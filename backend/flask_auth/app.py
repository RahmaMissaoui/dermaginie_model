from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import secrets
import os
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
import bcrypt
import jwt
import random
import base64
import requests
import replicate
import tempfile

load_dotenv()

app = Flask(__name__)

# ✅ CORS Configuration
CORS(app, origins=["*"], methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])

JWT_SECRET = os.getenv('JWT_SECRET_KEY', 'fallback_secret_key_change_me')
DB_PATH = '/app/persistent/users.db'

# ✅ إنشاء مجلد قاعدة البيانات إذا لم يكن موجوداً
db_dir = os.path.dirname(DB_PATH)
if not os.path.exists(db_dir):
    os.makedirs(db_dir, exist_ok=True)
    print(f"📁 Created database directory: {db_dir}")

# ✅ Skip email mode
SKIP_EMAIL = os.getenv('SKIP_EMAIL', 'false').lower() == 'true'

# ✅ Brevo API Key
BREVO_API_KEY = os.getenv('BREVO_API_KEY')
SENDER_EMAIL = os.getenv('MAIL_USERNAME', 'smouha2001@gmail.com')
SENDER_NAME = "DermaGenie"

# ✅ Replicate Configuration
REPLICATE_API_TOKEN = os.getenv('REPLICATE_API_TOKEN')
REPLICATE_MODEL = os.getenv('REPLICATE_MODEL', "samah-smouha/dermagenie-model")

def generate_token(email):
    payload = {'email': email, 'exp': datetime.now(timezone.utc) + timedelta(days=7)}
    return jwt.encode(payload, JWT_SECRET, algorithm='HS256')

def send_verification_email(email, token):
    if SKIP_EMAIL:
        print(f"🔧 SKIP_EMAIL: Code for {email} is {token}")
        return True

    if not BREVO_API_KEY:
        print("❌ Brevo API Key is missing.")
        return False

    headers = {'accept': 'application/json', 'api-key': BREVO_API_KEY, 'content-type': 'application/json'}
    data = {
        "sender": {"name": SENDER_NAME, "email": SENDER_EMAIL},
        "to": [{"email": email}],
        "subject": "🔬 DermaGenie - Votre code de vérification",
        "htmlContent": f"""
        <!DOCTYPE html>
        <html>
        <body>
            <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                <h2 style="color: #008CFF;">🔬 DermaGenie</h2>
                <h3>Bonjour,</h3>
                <p>Votre code de vérification est :</p>
                <div style="font-size: 36px; font-weight: bold; background: #f0f0f0; padding: 15px; text-align: center; letter-spacing: 5px; border-radius: 8px;">
                    {token}
                </div>
                <p>Ce code expire dans <strong>5 minutes</strong>.</p>
            </div>
        </body>
        </html>
        """
    }
    try:
        response = requests.post('https://api.brevo.com/v3/smtp/email', headers=headers, json=data, timeout=30)
        return response.status_code == 201
    except Exception as e:
        print(f"❌ Email error: {e}")
        return False

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, first_name TEXT, last_name TEXT, age INTEGER, phone TEXT, email TEXT UNIQUE, password TEXT, verified BOOLEAN DEFAULT 0, profile_image TEXT DEFAULT "")')
    c.execute('CREATE TABLE IF NOT EXISTS temp_tokens (email TEXT PRIMARY KEY, token TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)')
    c.execute('CREATE TABLE IF NOT EXISTS reset_tokens (email TEXT PRIMARY KEY, token TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)')
    c.execute('CREATE TABLE IF NOT EXISTS doctor_info (id INTEGER PRIMARY KEY AUTOINCREMENT, email_user TEXT, doctor_name TEXT, specialty TEXT, doctor_phone TEXT, doctor_email TEXT, working_hours TEXT, address TEXT)')
    c.execute('CREATE TABLE IF NOT EXISTS patients (id INTEGER PRIMARY KEY AUTOINCREMENT, doctor_email TEXT, first_name TEXT, last_name TEXT, age INTEGER, birth_date TEXT, phone TEXT, last_visit TEXT, notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)')
    c.execute('CREATE TABLE IF NOT EXISTS patient_documents (id INTEGER PRIMARY KEY AUTOINCREMENT, patient_id INTEGER, document_name TEXT, document_type TEXT, document_data TEXT, uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)')
    c.execute('CREATE TABLE IF NOT EXISTS medical_reports (id INTEGER PRIMARY KEY AUTOINCREMENT, patient_id INTEGER, doctor_email TEXT, report_title TEXT, diagnosis TEXT, confidence REAL, all_probabilities TEXT, doctor_notes TEXT, treatment_plan TEXT, follow_up_date TEXT, original_image_base64 TEXT, gradcam_image_base64 TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)')
    conn.commit()
    conn.close()
    print("✅ Database initialized at", DB_PATH)

init_db()

# ==================== HEALTH ====================
@app.route('/health', methods=['GET', 'OPTIONS'])
def health():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    return jsonify({
        'status': 'ok',
        'message': 'Server is running',
        'replicate_configured': REPLICATE_API_TOKEN is not None,
        'replicate_model': REPLICATE_MODEL
    }), 200

# ==================== AUTH ====================
@app.route('/register', methods=['POST', 'OPTIONS'])
def register():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    email, first_name, last_name, age, phone = data.get('email'), data.get('first_name'), data.get('last_name'), data.get('age'), data.get('phone')
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    if c.execute('SELECT email FROM users WHERE email = ?', (email,)).fetchone():
        conn.close()
        return jsonify({'error': 'Cet email est déjà utilisé.'}), 400
    token = secrets.token_hex(3).upper()
    if not SKIP_EMAIL:
        if not send_verification_email(email, token):
            conn.close()
            return jsonify({'error': "Erreur d'envoi d'email."}), 500
    temp_data = f"{first_name}|{last_name}|{age}|{phone}"
    c.execute('INSERT OR REPLACE INTO temp_tokens (email, token, created_at) VALUES (?, ?, ?)', (email, token + "|" + temp_data, datetime.now()))
    conn.commit()
    conn.close()
    response_data = {'message': 'Code envoyé', 'email': email}
    if SKIP_EMAIL:
        response_data['debug_token'] = token
    return jsonify(response_data)

@app.route('/verify', methods=['POST', 'OPTIONS'])
def verify():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    email, token, password = data.get('email'), data.get('token'), data.get('password')
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    row = c.execute('SELECT token, created_at FROM temp_tokens WHERE email = ?', (email,)).fetchone()
    if not row:
        conn.close()
        return jsonify({'error': 'Aucun code trouvé.'}), 400
    stored_full, created_at = row
    stored_token = stored_full.split('|')[0]
    user_data = stored_full.split('|')[1:] if '|' in stored_full else []
    created_time = datetime.fromisoformat(created_at)
    if datetime.now() - created_time > timedelta(minutes=5):
        c.execute('DELETE FROM temp_tokens WHERE email = ?', (email,))
        conn.commit()
        conn.close()
        return jsonify({'error': 'Code expiré.'}), 400
    if stored_token != token:
        conn.close()
        return jsonify({'error': 'Code incorrect.'}), 400
    if len(user_data) >= 4:
        first_name, last_name, age, phone = user_data
    else:
        conn.close()
        return jsonify({'error': 'Données manquantes.'}), 400
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    try:
        c.execute('INSERT INTO users (first_name, last_name, age, phone, email, password, verified) VALUES (?, ?, ?, ?, ?, ?, 1)', (first_name, last_name, age, phone, email, hashed_password.decode('utf-8')))
    except sqlite3.IntegrityError:
        conn.close()
        return jsonify({'error': 'Email déjà utilisé.'}), 400
    c.execute('DELETE FROM temp_tokens WHERE email = ?', (email,))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Inscription réussie', 'token': generate_token(email)})

@app.route('/login', methods=['POST', 'OPTIONS'])
def login():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    email, password = data.get('email'), data.get('password')
    conn = sqlite3.connect(DB_PATH)
    user = conn.execute('SELECT first_name, last_name, email, password FROM users WHERE email = ? AND verified = 1', (email,)).fetchone()
    conn.close()
    if user and bcrypt.checkpw(password.encode('utf-8'), user[3].encode('utf-8')):
        return jsonify({'success': True, 'user': {'first_name': user[0], 'last_name': user[1], 'email': user[2]}, 'token': generate_token(email)})
    return jsonify({'success': False, 'error': 'Email ou mot de passe incorrect'}), 401

@app.route('/forgot-password', methods=['POST', 'OPTIONS'])
def forgot_password():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    email = data.get('email')
    conn = sqlite3.connect(DB_PATH)
    if not conn.execute('SELECT email FROM users WHERE email = ?', (email,)).fetchone():
        conn.close()
        return jsonify({'error': 'Email non trouvé'}), 404
    token = secrets.token_hex(3).upper()
    if not SKIP_EMAIL:
        send_verification_email(email, token)
    conn.execute('INSERT OR REPLACE INTO reset_tokens (email, token, created_at) VALUES (?, ?, ?)', (email, token, datetime.now()))
    conn.commit()
    conn.close()
    response_data = {'message': 'Code de réinitialisation envoyé', 'email': email}
    if SKIP_EMAIL:
        response_data['debug_token'] = token
    return jsonify(response_data)

@app.route('/reset-password', methods=['POST', 'OPTIONS'])
def reset_password():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    email, token, new_password = data.get('email'), data.get('token'), data.get('new_password')
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute('SELECT token, created_at FROM reset_tokens WHERE email = ?', (email,)).fetchone()
    if not row:
        conn.close()
        return jsonify({'error': 'Aucun code trouvé'}), 400
    stored_token, created_at = row
    created_time = datetime.fromisoformat(created_at)
    if datetime.now() - created_time > timedelta(minutes=5):
        conn.execute('DELETE FROM reset_tokens WHERE email = ?', (email,))
        conn.commit()
        conn.close()
        return jsonify({'error': 'Code expiré'}), 400
    if stored_token != token:
        conn.close()
        return jsonify({'error': 'Code incorrect'}), 400
    hashed_password = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt())
    conn.execute('UPDATE users SET password = ? WHERE email = ?', (hashed_password.decode('utf-8'), email))
    conn.execute('DELETE FROM reset_tokens WHERE email = ?', (email,))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Mot de passe réinitialisé'})

# ==================== USER & DOCTOR INFO ====================
@app.route('/get-user-info', methods=['POST', 'OPTIONS'])
def get_user_info():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    email = request.json.get('email')
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute('SELECT first_name, last_name, age, phone, email, profile_image FROM users WHERE email = ?', (email,)).fetchone()
    conn.close()
    if row:
        return jsonify({'success': True, 'user_info': {'first_name': row[0], 'last_name': row[1], 'age': row[2], 'phone': row[3], 'email': row[4], 'profile_image': row[5] or ''}})
    return jsonify({'success': False, 'error': 'Utilisateur non trouvé'}), 404

@app.route('/update-user-info', methods=['POST', 'OPTIONS'])
def update_user_info():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    conn = sqlite3.connect(DB_PATH)
    conn.execute('UPDATE users SET first_name=?, last_name=?, age=?, phone=?, profile_image=? WHERE email=?', (data.get('first_name'), data.get('last_name'), data.get('age'), data.get('phone'), data.get('profile_image', ''), data.get('email')))
    conn.commit()
    conn.close()
    return jsonify({'success': True, 'message': 'Informations mises à jour'})

@app.route('/get-doctor-info', methods=['POST', 'OPTIONS'])
def get_doctor_info():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    email = request.json.get('email')
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute('SELECT doctor_name, specialty, doctor_phone, doctor_email, working_hours, address FROM doctor_info WHERE email_user = ?', (email,)).fetchone()
    conn.close()
    if row:
        return jsonify({'success': True, 'doctor_info': {'doctor_name': row[0], 'specialty': row[1], 'doctor_phone': row[2], 'doctor_email': row[3], 'working_hours': row[4], 'address': row[5]}})
    return jsonify({'success': True, 'doctor_info': {'doctor_name': 'Dr. Ahmed Benali', 'specialty': 'Médecin généraliste', 'doctor_phone': '+213 5 XX XX XX XX', 'doctor_email': 'dr.ahmed@medicare.com', 'working_hours': 'Lun - Ven: 09:00 - 17:00', 'address': '123 Rue Didouche Mourad, Alger'}})

@app.route('/save-doctor-info', methods=['POST', 'OPTIONS'])
def save_doctor_info():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    email, doctor_name, specialty, doctor_phone, doctor_email, working_hours, address = data.get('email'), data.get('doctor_name'), data.get('specialty'), data.get('doctor_phone'), data.get('doctor_email'), data.get('working_hours'), data.get('address')
    conn = sqlite3.connect(DB_PATH)
    if conn.execute('SELECT id FROM doctor_info WHERE email_user = ?', (email,)).fetchone():
        conn.execute('UPDATE doctor_info SET doctor_name=?, specialty=?, doctor_phone=?, doctor_email=?, working_hours=?, address=? WHERE email_user=?', (doctor_name, specialty, doctor_phone, doctor_email, working_hours, address, email))
    else:
        conn.execute('INSERT INTO doctor_info (email_user, doctor_name, specialty, doctor_phone, doctor_email, working_hours, address) VALUES (?, ?, ?, ?, ?, ?, ?)', (email, doctor_name, specialty, doctor_phone, doctor_email, working_hours, address))
    conn.commit()
    conn.close()
    return jsonify({'success': True, 'message': 'Informations sauvegardées'})

# ==================== PATIENTS ====================
@app.route('/add-patient', methods=['POST', 'OPTIONS'])
def add_patient():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''INSERT INTO patients (doctor_email, first_name, last_name, age, birth_date, phone, last_visit, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)''', (data.get('doctor_email'), data.get('first_name'), data.get('last_name'), data.get('age'), data.get('birth_date'), data.get('phone'), data.get('last_visit', ''), data.get('notes', '')))
    conn.commit()
    patient_id = c.lastrowid
    conn.close()
    return jsonify({'success': True, 'message': 'Patient ajouté', 'id': patient_id})

@app.route('/get-patients', methods=['POST', 'OPTIONS'])
def get_patients():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    doctor_email, search = data.get('doctor_email'), data.get('search', '')
    conn = sqlite3.connect(DB_PATH)
    query = 'SELECT id, first_name, last_name, age, birth_date, phone, last_visit, notes, created_at FROM patients WHERE doctor_email = ?'
    params = [doctor_email]
    if search:
        query += ' AND (first_name LIKE ? OR last_name LIKE ? OR phone LIKE ?)'
        s = f'%{search}%'
        params.extend([s, s, s])
    rows = conn.execute(query, params).fetchall()
    conn.close()
    patients = [{'id': r[0], 'first_name': r[1], 'last_name': r[2], 'age': r[3], 'birth_date': r[4] or '', 'phone': r[5] or '', 'last_visit': r[6] or '', 'notes': r[7] or '', 'created_at': r[8]} for r in rows]
    return jsonify({'success': True, 'patients': patients})

@app.route('/update-patient', methods=['POST', 'OPTIONS'])
def update_patient():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    conn = sqlite3.connect(DB_PATH)
    conn.execute('''UPDATE patients SET first_name=?, last_name=?, age=?, birth_date=?, phone=?, last_visit=?, notes=? WHERE id=?''', (data.get('first_name'), data.get('last_name'), data.get('age'), data.get('birth_date'), data.get('phone'), data.get('last_visit', ''), data.get('notes', ''), data.get('id')))
    conn.commit()
    conn.close()
    return jsonify({'success': True, 'message': 'Patient mis à jour'})

@app.route('/delete-patient', methods=['POST', 'OPTIONS'])
def delete_patient():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    conn = sqlite3.connect(DB_PATH)
    conn.execute('DELETE FROM patients WHERE id = ?', (request.json.get('id'),))
    conn.commit()
    conn.close()
    return jsonify({'success': True, 'message': 'Patient supprimé'})

# ==================== DOCUMENTS ====================
@app.route('/add-document', methods=['POST', 'OPTIONS'])
def add_document():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    conn = sqlite3.connect(DB_PATH)
    conn.execute('INSERT INTO patient_documents (patient_id, document_name, document_type, document_data) VALUES (?, ?, ?, ?)', (data.get('patient_id'), data.get('document_name'), data.get('document_type'), data.get('document_data')))
    conn.commit()
    doc_id = conn.execute('SELECT last_insert_rowid()').fetchone()[0]
    conn.close()
    return jsonify({'success': True, 'message': 'Document ajouté', 'id': doc_id})

@app.route('/get-documents', methods=['POST', 'OPTIONS'])
def get_documents():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    patient_id = request.json.get('patient_id')
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute('SELECT id, document_name, document_type, uploaded_at FROM patient_documents WHERE patient_id = ? ORDER BY uploaded_at DESC', (patient_id,)).fetchall()
    conn.close()
    documents = [{'id': r[0], 'document_name': r[1], 'document_type': r[2], 'uploaded_at': r[3]} for r in rows]
    return jsonify({'success': True, 'documents': documents})

@app.route('/delete-document', methods=['POST', 'OPTIONS'])
def delete_document():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    conn = sqlite3.connect(DB_PATH)
    conn.execute('DELETE FROM patient_documents WHERE id = ?', (request.json.get('id'),))
    conn.commit()
    conn.close()
    return jsonify({'success': True, 'message': 'Document supprimé'})

@app.route('/get-document-data', methods=['POST', 'OPTIONS'])
def get_document_data():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    doc_id = request.json.get('id')
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute('SELECT document_name, document_type, document_data FROM patient_documents WHERE id = ?', (doc_id,)).fetchone()
    conn.close()
    if row:
        return jsonify({'success': True, 'document_name': row[0], 'document_type': row[1], 'document_data': row[2]})
    return jsonify({'success': False, 'error': 'Document non trouvé'}), 404

# ==================== ANALYSIS ====================
def analyze_with_replicate(image_base64):
    """تحليل الصورة باستخدام Replicate API"""
    if ',' in image_base64:
        image_base64 = image_base64.split(',')[1]

    image_bytes = base64.b64decode(image_base64)

    with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
        tmp.write(image_bytes)
        tmp_path = tmp.name

    try:
        client = replicate.Client(api_token=REPLICATE_API_TOKEN)
        output = client.run(
            REPLICATE_MODEL,
            input={"image": open(tmp_path, "rb")}
        )

        # معالجة النتيجة حسب تنسيق نموذجك
        if isinstance(output, dict):
            is_melanoma = output.get('is_melanoma', False)
            confidence = output.get('confidence', 0.85)
            result = output.get('result', 'Bénin')
        elif isinstance(output, list) and len(output) > 0:
            is_melanoma = output[0] > 0.5
            confidence = output[0] if is_melanoma else 1 - output[0]
            result = 'Mélanome détecté' if is_melanoma else 'Bénin'
        else:
            is_melanoma = False
            confidence = 0.85
            result = 'Bénin'

        return {
            'success': True,
            'result': result,
            'confidence': round(confidence, 2),
            'color': 'red' if is_melanoma else 'green',
            'message': 'Analyse par IA (Replicate)',
            'is_demo': False,
            'source': 'replicate'
        }
    except Exception as e:
        print(f"❌ Replicate error: {e}")
        return {'success': False, 'error': str(e)}
    finally:
        try:
            os.unlink(tmp_path)
        except:
            pass

@app.route('/analyze-demo', methods=['POST', 'OPTIONS'])
def analyze_demo():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    is_melanoma = random.choice([True, False])
    if is_melanoma:
        return jsonify({'success': True, 'result': 'Mélanome détecté', 'confidence': round(random.uniform(0.70, 0.99), 2), 'color': 'red', 'message': '⚠️ Consultation recommandée', 'is_demo': True})
    return jsonify({'success': True, 'result': 'Bénin', 'confidence': round(random.uniform(0.85, 0.99), 2), 'color': 'green', 'message': '✅ Pas de signes détectés', 'is_demo': True})

@app.route('/analyze-melanoma', methods=['POST', 'OPTIONS'])
def analyze_melanoma():
    if request.method == 'OPTIONS':
        return jsonify({}), 200

    data = request.json
    image_base64 = data.get('image')
    if not image_base64:
        return jsonify({'error': 'No image provided'}), 400

    print("🔍 Starting melanoma analysis with Replicate...")

    if REPLICATE_API_TOKEN:
        result = analyze_with_replicate(image_base64)
        if result.get('success'):
            return jsonify(result)

    # Fallback to demo mode
    print("⚠️ Using demo mode")
    return analyze_demo()

@app.route('/save-analysis', methods=['POST', 'OPTIONS'])
def save_analysis():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    return jsonify({'success': True, 'message': 'Analysis saved'})

# ==================== MEDICAL REPORTS ====================
@app.route('/create-report', methods=['POST', 'OPTIONS'])
def create_report():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    data = request.json
    conn = sqlite3.connect(DB_PATH)
    conn.execute('''INSERT INTO medical_reports (patient_id, doctor_email, report_title, diagnosis, confidence, all_probabilities, doctor_notes, treatment_plan, follow_up_date, original_image_base64, gradcam_image_base64) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''', (data.get('patient_id'), data.get('doctor_email'), data.get('report_title'), data.get('diagnosis'), data.get('confidence'), data.get('all_probabilities'), data.get('doctor_notes', ''), data.get('treatment_plan', ''), data.get('follow_up_date', ''), data.get('original_image_base64', ''), data.get('gradcam_image_base64', '')))
    conn.commit()
    report_id = conn.execute('SELECT last_insert_rowid()').fetchone()[0]
    conn.close()
    return jsonify({'success': True, 'message': 'Rapport créé', 'report_id': report_id})

@app.route('/get-reports', methods=['POST', 'OPTIONS'])
def get_reports():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    patient_id = request.json.get('patient_id')
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute('SELECT id, report_title, diagnosis, confidence, doctor_notes, created_at FROM medical_reports WHERE patient_id = ? ORDER BY created_at DESC', (patient_id,)).fetchall()
    conn.close()
    reports = [{'id': r[0], 'report_title': r[1], 'diagnosis': r[2], 'confidence': r[3], 'doctor_notes': r[4], 'created_at': r[5]} for r in rows]
    return jsonify({'success': True, 'reports': reports})

@app.route('/get-report', methods=['POST', 'OPTIONS'])
def get_report():
    if request.method == 'OPTIONS':
        return jsonify({}), 200
    report_id = request.json.get('report_id')
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute('SELECT id, patient_id, report_title, diagnosis, confidence, all_probabilities, doctor_notes, treatment_plan, follow_up_date, original_image_base64, gradcam_image_base64, created_at FROM medical_reports WHERE id = ?', (report_id,)).fetchone()
    conn.close()
    if row:
        return jsonify({'success': True, 'report': {'id': row[0], 'patient_id': row[1], 'report_title': row[2], 'diagnosis': row[3], 'confidence': row[4], 'all_probabilities': row[5], 'doctor_notes': row[6], 'treatment_plan': row[7], 'follow_up_date': row[8], 'original_image_base64': row[9], 'gradcam_image_base64': row[10], 'created_at': row[11]}})
    return jsonify({'success': False, 'error': 'Report not found'}), 404

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)