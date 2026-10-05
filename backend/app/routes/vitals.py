from fastapi import APIRouter
from app.services.mock_data import MOCK_VITALS
from app.services.live_store import save_live, get_live, merge_into_vitals

router = APIRouter()


@router.get("/{patient_id}")
def get_vitals(patient_id: str):
    return MOCK_VITALS.get(patient_id, [])


@router.get("/{patient_id}/latest")
def get_latest_vital(patient_id: str):
    vitals = MOCK_VITALS.get(patient_id, [])
    if not vitals:
        return {"error": "No vitals found"}
    live = get_live(patient_id)
    if live:
        return merge_into_vitals(live, vitals[0])
    return vitals[0]


@router.post("/live")
def ingest_live_vitals(data: dict):
    """Wearable gateway ingestion (Flutter POSTs BLE readings here).

    In-memory only. Never overwrites mock history; the latest live
    reading is merged into GET .../latest while fresh.
    """
    return save_live(data)


# Alias: some clients POST to /ingest instead of /live.
@router.post("/ingest")
def ingest_live_vitals_alias(data: dict):
    return save_live(data)
