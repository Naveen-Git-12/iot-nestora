"""NESTORA rule-based AI risk engine (prototype).

NOT a trained ML model and NOT a clinical diagnostic device. It applies
documented prototype reference ranges (not WHO/pregnancy-specific
diagnostic thresholds) to produce an explainable LOW / MEDIUM / HIGH /
CRITICAL assessment for the demo dashboard and mobile app.

Inputs: heart rate, SpO2, temperature, blood pressure (mock/manual for
now — the wearable measures HR + movement only), gestational week,
logged symptoms.

Scoring (prototype weights):
    BP >= 140/90            -> +3
    SpO2 < 95%              -> +3
    HR > 100 bpm            -> +1
    Temperature >= 38.0 C   -> +2
    Concerning symptom      -> +2 each (headache, swelling, bleeding,
                               vision changes, severe pain, high
                               severity >= 4, or AI-flagged)
    Headache + swelling     -> +3 extra (preeclampsia pattern)
    Late gestation (>= 36w)
      with any warning sign -> +1 (late-onset vigilance)

Levels (names kept stable for dashboard/mobile clients):
    0-2  -> low        3-5  -> medium
    6-8  -> high       9+   -> critical
"""

# Symptoms treated as concerning for maternal wellness monitoring.
CONCERNING_SYMPTOMS = {
    "headache",
    "swelling",
    "bleeding",
    "spotting",
    "vision",
    "blurred vision",
    "abdominal pain",
    "back pain",
    "nausea",
    "vomiting",
    "dizziness",
    "fever",
    "reduced fetal movement",
    "contractions",
    "high blood pressure",
}

BP_SYS_HIGH = 140
BP_DIA_HIGH = 90
SPO2_LOW = 95
HR_HIGH = 100
TEMP_HIGH = 38.0
LATE_WEEK = 36


def _is_concerning(symptom: dict) -> bool:
    stype = str(symptom.get("symptom_type", "")).lower()
    if symptom.get("ai_flagged"):
        return True
    try:
        if int(symptom.get("severity", 0)) >= 4:
            return True
    except (TypeError, ValueError):
        pass
    return any(key in stype for key in CONCERNING_SYMPTOMS)


def calculate_risk(vitals: dict, symptoms: list,
                   gestational_week: int | None = None) -> dict:
    """Assess maternal wellness risk. Missing sensors are treated as
    normal (null != zero): only supplied abnormal values add points."""
    score = 0
    factors: list[str] = []

    vitals = vitals or {}
    symptoms = symptoms or []

    hr = vitals.get("heart_rate")
    spo2 = vitals.get("spo2")
    temp = vitals.get("temperature")
    sys_bp = vitals.get("systolic_bp")
    dia_bp = vitals.get("diastolic_bp")

    bp_high = False
    if sys_bp is not None and sys_bp >= BP_SYS_HIGH:
        score += 3
        bp_high = True
        factors.append(f"Elevated blood pressure ({sys_bp}/{dia_bp} mmHg)")
    elif dia_bp is not None and dia_bp >= BP_DIA_HIGH:
        score += 3
        bp_high = True
        factors.append(f"Elevated blood pressure ({sys_bp}/{dia_bp} mmHg)")

    if spo2 is not None and spo2 < SPO2_LOW:
        score += 3
        factors.append(f"Low SpO2 ({spo2}%)")

    if hr is not None and hr > HR_HIGH:
        score += 1
        factors.append(f"Increased heart rate ({hr} bpm)")

    if temp is not None and temp >= TEMP_HIGH:
        score += 2
        factors.append(f"Elevated temperature ({temp}C)")

    has_headache = False
    has_swelling = False
    for s in symptoms:
        stype = str(s.get("symptom_type", "")).lower()
        if "headache" in stype:
            has_headache = True
        if "swelling" in stype:
            has_swelling = True
        if _is_concerning(s):
            score += 2
            sev = s.get("severity")
            label = s.get("symptom_type", "symptom")
            factors.append(
                f"{label} reported"
                + (f" (severity {sev}/5)" if sev else ""))

    if has_headache and has_swelling:
        score += 3
        factors.append(
            "Headache + swelling together - possible preeclampsia "
            "pattern, needs medical review")

    week = gestational_week
    if week is None:
        try:
            week = int(vitals.get("gestational_week"))
        except (TypeError, ValueError):
            week = None
    if week is not None and week >= LATE_WEEK and (
            bp_high or factors):
        score += 1
        factors.append(
            f"Late gestation (week {week}) with warning signs - "
            "extra vigilance")

    if score <= 2:
        level = "low"
    elif score <= 5:
        level = "medium"
    elif score <= 8:
        level = "high"
    else:
        level = "critical"

    if not factors:
        factors.append("All supplied vitals within prototype normal range")

    return {
        "risk_level": level,
        "score": score,
        "factors": factors,
        "recommendation": _get_recommendation(level),
        "gestational_week": week,
    }


def _get_recommendation(level: str) -> str:
    recs = {
        "low": "Continue routine monitoring. Maintain healthy diet "
               "and hydration.",
        "medium": "Schedule a checkup within the next week and keep "
                  "monitoring vitals daily.",
        "high": "Medical review required. Contact your doctor promptly "
                "and rest.",
        "critical": "Seek immediate medical attention. Call your "
                    "healthcare provider now.",
    }
    return recs.get(level, "Consult your healthcare provider.")
