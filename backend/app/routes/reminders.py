from fastapi import APIRouter
from app.services.mock_data import MOCK_REMINDERS

router = APIRouter()


@router.get("/{patient_id}")
def get_reminders(patient_id: str):
    return [r for r in MOCK_REMINDERS if r["patient_id"] == patient_id]
