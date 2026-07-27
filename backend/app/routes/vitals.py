from fastapi import APIRouter
from app.services.mock_data import MOCK_VITALS

router = APIRouter()


@router.get("/{patient_id}")
def get_vitals(patient_id: str):
    return MOCK_VITALS.get(patient_id, [])


@router.get("/{patient_id}/latest")
def get_latest_vital(patient_id: str):
    vitals = MOCK_VITALS.get(patient_id, [])
    if vitals:
        return vitals[0]
    return {"error": "No vitals found"}
