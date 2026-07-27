from fastapi import APIRouter
from app.services.mock_data import MOCK_PATIENTS

router = APIRouter()


@router.get("/")
def get_all_patients():
    return MOCK_PATIENTS


@router.get("/{patient_id}")
def get_patient(patient_id: str):
    for p in MOCK_PATIENTS:
        if p["id"] == patient_id:
            return p
    return {"error": "Patient not found"}
