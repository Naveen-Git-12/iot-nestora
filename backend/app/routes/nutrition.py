from fastapi import APIRouter
from app.services.mock_data import MOCK_NUTRITION

router = APIRouter()


@router.get("/{patient_id}")
def get_nutrition(patient_id: str):
    return MOCK_NUTRITION.get(patient_id, {})
