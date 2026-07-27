from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import vitals, symptoms, reminders, patients

app = FastAPI(
    title="NESTORA API",
    description="Smart Maternal Healthcare Monitoring System",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(vitals.router, prefix="/api/vitals", tags=["Vitals"])
app.include_router(symptoms.router, prefix="/api/symptoms", tags=["Symptoms"])
app.include_router(reminders.router, prefix="/api/reminders", tags=["Reminders"])
app.include_router(patients.router, prefix="/api/patients", tags=["Patients"])


@app.get("/")
def root():
    return {"message": "NESTORA API is running"}


@app.get("/api/health")
def health():
    return {"status": "ok"}
