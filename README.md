# NESTORA - Smart Maternal Healthcare Monitoring System

A comprehensive maternal healthcare monitoring system using IoT, AI, and mobile technology for continuous pregnancy care.

## Project Structure

```
iot-nestora/
├── backend/          # FastAPI REST API server
├── mobile/           # Flutter mobile application
├── doctor-dashboard/ # React + TypeScript web dashboard
├── wearable/         # ESP32 firmware (placeholder)
└── ai/               # ML models and training (placeholder)
```

## Components

### Backend (FastAPI)
- REST API for vitals, symptoms, reminders, and patient data
- Mock data for 5 patients with varying risk levels
- Run: `cd backend && pip install -r requirements.txt && uvicorn app.main:app --reload`
- API docs: http://localhost:8000/docs

### Mobile App (Flutter)
- Login screen with gradient UI
- Home dashboard with vitals, pregnancy progress, risk status
- Tabs: Home | Vitals | Symptoms | Reminders
- Run: `cd mobile && flutter run`

### Doctor Dashboard (React + TypeScript)
- Patient list with risk level badges
- Patient detail view with vital history and symptoms
- Run: `cd doctor-dashboard && npm install && npm run dev`

## Tech Stack
- **Backend:** Python, FastAPI
- **Mobile:** Flutter, Dart
- **Dashboard:** React, TypeScript, Vite
- **Database:** MongoDB (planned), InfluxDB (planned)
