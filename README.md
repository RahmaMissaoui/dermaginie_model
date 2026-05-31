# 🩺 DermaGenie - AI Medical Assistant

[![Flutter](https://img.shields.io/badge/Flutter-3.22-blue.svg)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.12-green.svg)](https://python.org)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.5-red.svg)](https://pytorch.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Application médicale intelligente pour la détection du mélanome à l'aide d'un modèle IA hybride (CNN + ViT)**

---

## 📋 Table des matières

- [Fonctionnalités](#-fonctionnalités)
- [Architecture du Modèle IA](#-architecture-du-modèle-ia)
- [Technologies utilisées](#-technologies-utilisées)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Structure du projet](#-structure-du-projet)
- [API Endpoints](#-api-endpoints)
- [Captures d'écran](#-captures-décran)
- [Téléchargement du modèle](#-téléchargement-du-modèle)
- [Déploiement](#-déploiement)
- [Contributions](#-contributions)
- [Licence](#-licence)

---

## ✨ Fonctionnalités

### 🔐 Authentification
- Inscription avec vérification par email (code à 6 chiffres)
- Connexion sécurisée avec JWT
- Réinitialisation du mot de passe
- Chiffrement bcrypt

### 👥 Gestion des patients
- Ajout, modification, suppression
- Recherche et filtrage
- Tri (date, A-Z, Z-A)
- Export de la liste (copier/coller)

### 🖼️ Analyse d'images médicales
- Prétraitement : DullRazor (suppression des poils) + CLAHE + Padding
- Modèle IA : Hybrid CNN-ViT (DenseNet169 + ViT-B/16)
- Classification : 7 classes HAM10000
- Visualisation : Grad-CAM (carte de chaleur)

### 📄 Rapports médicaux
- Création automatique après analyse
- Ajout de notes, plan de traitement, date de suivi
- Historique des rapports par patient
- Comparaison entre rapports (évolution)
- Export PDF
- Partage du rapport

### 🌐 Multilingue
- 🇫🇷 Français
- 🇬🇧 English
- 🇸🇦 العربية (avec support RTL)

### 📱 Multiplateforme
- 🌐 Web (Chrome, Edge)
- 📱 Android
- 💻 Windows

---

## 🧠 Architecture du Modèle IA

### Hybrid CNN-ViT

nput (3×224×224)
├──────────────────┬───────────────────
▼ ▼
DenseNet169 ViT-B/16 (IN-21k)
Local features Global context
(1664-dim) (768-dim)
└────────┬─────────┘
Bidirectional Cross-Attention Fusion
▼
Classification Head (512→256→128→7)
▼
Softmax (7 classes)

text

### Classes (HAM10000)

| Classe | Nom | Type |
|--------|-----|------|
| akiec | Actinic Keratosis | Lésion précancéreuse |
| bcc | Basal Cell Carcinoma | Cancer de la peau |
| bkl | Benign Keratosis | Lésion bénigne |
| df | Dermatofibroma | Lésion bénigne |
| **mel** | **Melanoma** | **Cancer dangereux** |
| nv | Melanocytic Nevus | Grain de beauté |
| vasc | Vascular Lesion | Lésion vasculaire |

### Préprocessing

| Étape | Opération | Pourquoi |
|-------|-----------|----------|
| 1 | DullRazor | Supprime les poils qui masquent la lésion |
| 2 | Resize + Padding | Mise à l'échelle sans distorsion |
| 3 | CLAHE | Améliore le contraste local |
| 4 | Normalisation | Adaptation aux poids pré-entraînés |

---

## 🛠️ Technologies utilisées

### Backend (Flask)

| Technologie | Version | Utilisation |
|-------------|---------|-------------|
| Flask | 3.0 | API REST |
| PyTorch | 2.5 | Modèle IA |
| Transformers | 4.45 | ViT-B/16 |
| timm | 1.0 | Modèles vision |
| SQLite3 | - | Base de données |
| bcrypt | 5.0 | Hash des mots de passe |
| PyJWT | 2.8 | Tokens d'authentification |
| OpenCV | 4.9 | Traitement d'images |

### Frontend (Flutter)

| Technologie | Version | Utilisation |
|-------------|---------|-------------|
| Flutter | 3.22 | Interface utilisateur |
| Provider | 6.1 | Gestion d'état |
| Image Picker | 1.0 | Sélection d'images |
| PDF | 3.10 | Génération de rapports |
| Share Plus | 7.2 | Partage de fichiers |

---

## 📦 Installation

### Prérequis

- **Python 3.12+** pour le backend
- **Flutter 3.22+** pour le frontend
- **Git** pour le versionnement

### 1. Cloner le projet

```bash
git clone https://github.com/samah-smouha/appMel.git
cd appMel
2. Backend (Flask)
bash
cd backend/flask_auth

# Créer l'environnement virtuel
python -m venv venv

# Activer l'environnement (Windows)
venv\Scripts\activate

# Activer l'environnement (Mac/Linux)
# source venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt

# Lancer le serveur
python app.py
Le serveur tourne sur http://127.0.0.1:5000

3. Frontend (Flutter)
bash
# Revenir à la racine du projet
cd ../..

# Installer les dépendances
flutter pub get

# Lancer l'application (Chrome)
flutter run -d chrome

# Lancer l'application (Windows)
flutter run -d windows

# Lancer l'application (Android)
flutter run -d android
⚙️ Configuration
Variables d'environnement (.env)
Créez un fichier .env à la racine du projet :

env
API_BASE_URL=http://127.0.0.1:5000
Pour le backend, créez .env dans backend/flask_auth/ :

env
EMAIL_ADDRESS=votre_email@gmail.com
EMAIL_PASSWORD=xxxx xxxx xxxx xxxx  # Mot de passe d'application Gmail
JWT_SECRET_KEY=une_cle_secrete_tres_longue_et_complexe
Configuration Gmail
Pour utiliser l'envoi d'emails :

Activez la double authentification sur votre compte Gmail

Générez un mot de passe d'application (App Password)

Utilisez ce mot de passe dans .env

📁 Structure du projet
text
DermaGenie/
├── lib/                          # Code Flutter
│   ├── main.dart
│   ├── pages/                    # Pages de l'application
│   │   ├── welcome_page.dart
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   ├── verify_page.dart
│   │   ├── home_page.dart
│   │   ├── patients_page.dart
│   │   ├── patient_details_page.dart
│   │   ├── analyze_result_page.dart
│   │   ├── create_report_page.dart
│   │   ├── reports_list_page.dart
│   │   └── report_details_page.dart
│   ├── services/                 # Services API
│   │   └── api_service.dart
│   └── providers/                # Gestion d'état
│       └── language_provider.dart
│
├── assets/                       # Ressources
│   └── images/
│
├── backend/
│   └── flask_auth/               # API Flask
│       ├── app.py
│       ├── models/
│       │   ├── hybrid_model.py
│       │   └── hybrid_final.pt   # ⚠️ Modèle IA (à télécharger)
│       ├── utils/
│       │   └── preprocessing.py
│       └── requirements.txt
│
├── pubspec.yaml
└── README.md
🔌 API Endpoints
Méthode	Endpoint	Description
POST	/register	Inscription
POST	/verify	Vérification email
POST	/login	Connexion
POST	/forgot-password	Demande réinitialisation
POST	/reset-password	Réinitialisation mot de passe
POST	/get-doctor-info	Infos médecin
POST	/save-doctor-info	Sauvegarde infos médecin
POST	/add-patient	Ajout patient
POST	/get-patients	Liste patients
POST	/update-patient	Modification patient
POST	/delete-patient	Suppression patient
POST	/add-document	Ajout document
POST	/get-documents	Liste documents
POST	/delete-document	Suppression document
POST	/analyze-melanoma	🧠 Analyse IA
POST	/create-report	Création rapport
POST	/get-reports	Liste rapports
POST	/get-report	Détails rapport
📸 Captures d'écran
(À ajouter)

Page d'accueil	Analyse IA	Rapport médical
(image)	(image)	(image)
📥 Téléchargement du modèle IA
Le fichier du modèle (hybrid_final.pt, ~411 MB) n'est pas inclus dans ce dépôt en raison de sa taille.

Téléchargez-le ici : 🔗 Lien Google Drive

Placez-le ensuite dans :

text
backend/flask_auth/models/hybrid_final.pt
🚀 Déploiement
Déploiement du backend (Render)
Créez un compte sur Render

Connectez votre dépôt GitHub

Créez un Web Service avec :

Build Command: pip install -r requirements.txt

Start Command: gunicorn app:app

Ajoutez les variables d'environnement

Déploiement du frontend (Flutter)
APK Android
bash
flutter build apk --release
Le fichier se trouve dans :

text
build/app/outputs/flutter-apk/app-release.apk
EXE Windows
bash
flutter build windows --release
Le fichier se trouve dans :

text
build/windows/runner/Release/app1.exe
Web
bash
flutter build web --release
🤝 Contributions
Les contributions sont les bienvenues !

Fork le projet

Créez une branche (git checkout -b feature/AmazingFeature)

Commit vos changements (git commit -m 'Add some AmazingFeature')

Push vers la branche (git push origin feature/AmazingFeature)

Ouvrez une Pull Request

📜 Licence
Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus d'informations.

👨‍⚕️ Auteur
Samah Smouha

GitHub : @samah-smouha

Projet : DermaGenie

⚠️ Avertissement
Cette application est un outil d'aide à la décision médicale. Elle ne remplace pas l'avis d'un dermatologue. Les résultats doivent être interprétés par un professionnel de santé qualifié.

🙏 Remerciements
HAM10000 dataset

Hugging Face pour ViT-B/16

PyTorch pour le framework deep learning

📧 Contact
Pour toute question ou suggestion : smouha2001@gmail.com

⭐ N'oubliez pas de mettre une étoile si ce projet vous a aidé !

text

---

## ✅ **Maintenant, exécutez ces commandes pour mettre à jour GitHub :**

```bash
cd C:\FlutterProjects\DermaGenie_clean
git add README.md
git commit -m "Add comprehensive README.md"
git push origin main
Le README est complet et professionnel. Il contient toutes les informations nécessaires pour comprendre, installer et utiliser votre projet. ✅


"# trigger" 
