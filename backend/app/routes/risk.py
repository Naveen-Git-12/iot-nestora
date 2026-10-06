from fastapi import APIRouter
from app.services.mock_data import MOCK_VITALS, MOCK_SYMPTOMS, MOCK_PATIENTS
from app.services.risk_engine import calculate_risk
from app.services.live_store import get_live, merge_into_vitals

router = APIRouter()


def _patient_week(patient_id: str):
    for p in MOCK_PATIENTS:
        if p["id"] == patient_id:
            return p.get("gestational_week")
    return None


@router.get("/{patient_id}")
def get_risk(patient_id: str):
    vitals_list = MOCK_VITALS.get(patient_id, [])
    symptoms_list = MOCK_SYMPTOMS.get(patient_id, [])

    if not vitals_list:
        return {"risk_level": "low", "score": 0, "factors": ["No data available"], "recommendation": "Start monitoring to get risk assessment."}

    # Score the live wearable reading when one is fresh, so the badge
    # reflects the real device instead of stale mock numbers.
    live = get_live(patient_id)
    latest_vitals = (
        merge_into_vitals(live, vitals_list[0]) if live else vitals_list[0]
    )
    return calculate_risk(latest_vitals, symptoms_list,
                          _patient_week(patient_id))


@router.post("/evaluate")
def evaluate_risk(data: dict):
    patient_id = data.get("patient_id", "P001")
    vitals_list = MOCK_VITALS.get(patient_id, [])
    symptoms_list = MOCK_SYMPTOMS.get(patient_id, [])

    if not vitals_list:
        return {"risk_level": "low", "score": 0, "factors": ["No data"], "recommendation": "No data available."}

    latest_vitals = vitals_list[0]
    return calculate_risk(latest_vitals, symptoms_list, _patient_week(patient_id))


@router.post("/assess")
def assess_risk(data: dict):
    """Direct assessment from supplied readings.

    Body: {patient_id?, heart_rate?, spo2?, temperature?,
           systolic_bp?, diastolic_bp?, gestational_week?,
           symptoms? [{symptom_type, severity, ...}]}.
    Missing fields fall back to the patient's latest mock vitals;
    absent sensors score nothing (null != zero).
    """
    patient_id = data.get("patient_id", "P001")
    vitals_list = MOCK_VITALS.get(patient_id, [])
    base = dict(vitals_list[0]) if vitals_list else {}

    vitals = dict(base)
    for key in ("heart_rate", "spo2", "temperature",
                "systolic_bp", "diastolic_bp", "gestational_week"):
        if data.get(key) is not None:
            vitals[key] = data[key]

    symptoms = data.get("symptoms")
    if symptoms is None:
        symptoms = MOCK_SYMPTOMS.get(patient_id, [])

    week = data.get("gestational_week", vitals.get("gestational_week"))
    return calculate_risk(vitals, symptoms, week)
