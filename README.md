# NESTORA — Smart Maternal Healthcare Monitoring System

A full-stack maternal healthcare monitoring system that combines **IoT wearables**, **AI risk prediction**, and **mobile/web dashboards** to give expectant mothers continuous, intelligent care during pregnancy.

Built for a college project. All data is **mock/offline** — no real auth, no real devices, no database. Everything runs locally.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend API | Python, FastAPI, Uvicorn |
| Mobile App | Flutter (Dart) |
| Doctor Dashboard | React, TypeScript, Vite |
| AI Risk Engine | Python (rule-based scoring) |
| Database | None — mock data in code |

---

## Project Structure

```
iot-nestora/
├── backend/               # FastAPI REST API
│   └── app/
│       ├── main.py        # App entry, router registration
│       ├── routes/        # API endpoints per feature
│       │   ├── vitals.py
│       │   ├── symptoms.py
│       │   ├── reminders.py
│       │   ├── patients.py
│       │   ├── risk.py          # AI risk assessment
│       │   └── nutrition.py
│       └── services/
│           ├── mock_data.py     # All mock patients/vitals/symptoms
│           └── risk_engine.py   # Risk scoring logic
├── mobile/                # Flutter app (Android)
│   └── lib/
│       ├── main.dart
│       ├── screens/
│       │   ├── landing_screen.dart
│       │   ├── login_screen.dart
│       │   ├── home_screen.dart
│       │   ├── vitals_screen.dart
│       │   ├── symptoms_screen.dart
│       │   ├── reminders_screen.dart
│       │   └── nutrition_screen.dart
│       └── services/api_service.dart
├── doctor-dashboard/      # React + TS web dashboard
├── wearable/              # ESP32 firmware (placeholder)
└── ai/                    # ML models (placeholder)
```

---

## Prerequisites

| Tool | Version | Why |
|---|---|---|
| Python | 3.10+ | Backend |
| Flutter | 3.x | Mobile app |
| Android Studio / SDK | Any recent | Building APK |
| Node.js | 18+ | Doctor dashboard |
| (Optional) ADB + phone | — | Run app on device |

---

## 1. Backend Setup (FastAPI)

```bash
cd backend

# create & activate virtual environment
python -m venv venv
source venv/bin/activate        # Linux/macOS
# venv\Scripts\activate          # Windows

# install dependencies
pip install -r requirements.txt

# run the server
uvicorn app.main:app --reload
```

Verify: open http://localhost:8000 → should show `{"message": "NESTORA API is running"}`
Interactive docs: http://localhost:8000/docs

### API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/health` | Health check |
| GET | `/api/vitals/{patient_id}` | Vital history (10 readings per patient) |
| GET | `/api/vitals/{patient_id}/latest` | Latest single reading |
| GET | `/api/symptoms/{patient_id}` | Logged symptoms |
| GET | `/api/reminders/{patient_id}` | Reminders |
| GET | `/api/patients` | All patients |
| GET | `/api/patients/{patient_id}` | Single patient |
| GET | `/api/risk/{patient_id}` | AI risk assessment for patient |
| GET | `/api/nutrition/{patient_id}` | Daily nutrition data |

Mock patients: `P001` (medium risk), `P002` (low), `P003` (high), `P004` (low), `P005` (medium).

---

## 2. Mobile App Setup (Flutter)

```bash
cd mobile
flutter pub get

# run on connected device / emulator
flutter run

# or build APK
flutter build apk --debug
```

> **Note:** The app runs fully standalone with hardcoded data. To make it talk to the backend, the backend server must be running on the same machine (or your phone must reach your computer's IP). API base URL is in `mobile/lib/services/api_service.dart`.

### Screens Overview

| Screen | What it shows |
|---|---|
| **Landing** | Animated NESTORA text, auto-navigates to login after 3s |
| **Login** | Styled login with background image, gradient button (no real auth) |
| **Home** | Greeting, pregnancy progress bar, live vital cards, AI risk badge, quick actions |
| **Vitals** | Custom-painted line charts: Heart Rate, SpO2, Temperature + dual-line BP |
| **Symptoms** | Filter chips, symptom cards with severity dots, AI flag badges, log bottom sheet |
| **Reminders** | Toggle-able reminder cards (medication/hydration/appointment/nutrition) |
| **Nutrition** | Calorie circles, nutrient progress bars, water tracker, meal sections |

---

## 3. Doctor Dashboard Setup (React + TypeScript)

```bash
cd doctor-dashboard
npm install
npm run dev
```

Open http://localhost:5173

Features: sidebar navigation, overview page with 4 summary cards, patient table with risk badges, patient detail view with vital cards and trend indicators.

---

## Common Issues

**Gradle build fails / daemon crashes (Flutter)**
```bash
# memory already reduced to 4G in mobile/android/gradle.properties
cd mobile && flutter clean && flutter pub get && flutter build apk --debug
```

**Port 8000 already in use**
```bash
uvicorn app.main:app --reload --port 8001
```

**App shows blank/white screen**
Make sure backend isn't required for the screen you're viewing — all screens have fallback mock data.

---

## Contributors

- **Naveen** — backend, AI risk engine, project architecture
- **Nigesh** — mobile app UI screens
