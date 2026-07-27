from fastapi import APIRouter
from app.services.mock_data import MOCK_SYMPTOMS

router = APIRouter()


@router.get("/{patient_id}")
def get_symptoms(patient_id: str):
    return MOCK_SYMPTOMS.get(patient_id, [])
