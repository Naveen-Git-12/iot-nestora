def calculate_risk(vitals: dict, symptoms: list) -> dict:
    score = 0
    factors = []

    hr = vitals.get("heart_rate", 72)
    spo2 = vitals.get("spo2", 97)
    temp = vitals.get("temperature", 36.5)
    sys_bp = vitals.get("systolic_bp", 120)
    dia_bp = vitals.get("diastolic_bp", 80)

    if sys_bp > 140:
        score += 2
        factors.append(f"High systolic BP ({sys_bp} mmHg)")
    elif sys_bp > 130:
        score += 1
        factors.append(f"Elevated systolic BP ({sys_bp} mmHg)")

    if dia_bp > 90:
        score += 2
        factors.append(f"High diastolic BP ({dia_bp} mmHg)")
    elif dia_bp > 85:
        score += 1
        factors.append(f"Elevated diastolic BP ({dia_bp} mmHg)")

    if spo2 < 94:
        score += 2
        factors.append(f"Low SpO2 ({spo2}%)")
    elif spo2 < 96:
        score += 1
        factors.append(f"Borderline SpO2 ({spo2}%)")

    if hr > 100:
        score += 2
        factors.append(f"Elevated heart rate ({hr} bpm)")
    elif hr > 90:
        score += 1
        factors.append(f"Slightly elevated heart rate ({hr} bpm)")

    if temp > 37.5:
        score += 2
        factors.append(f"Fever detected ({temp}°C)")
    elif temp > 37.2:
        score += 1
        factors.append(f"Slightly elevated temperature ({temp}°C)")

    has_headache = False
    has_swelling = False
    for s in symptoms:
        stype = s.get("symptom_type", "").lower()
        severity = s.get("severity", 0)
        if stype == "headache" and severity > 3:
            score += 2
            factors.append(f"Severe headache (severity {severity}/5) - preeclampsia risk")
            has_headache = True
        elif stype == "headache":
            has_headache = True
        if stype == "swelling":
            has_swelling = True
        if s.get("ai_flagged"):
            score += 1
            factors.append(f"AI flagged symptom: {s.get('symptom_type')}")

    if has_headache and has_swelling:
        score += 3
        factors.append("Headache + Swelling combo - high preeclampsia risk")

    if score <= 1:
        level = "low"
    elif score <= 3:
        level = "medium"
    elif score <= 5:
        level = "high"
    else:
        level = "critical"

    if not factors:
        factors.append("All vitals within normal range")

    return {
        "risk_level": level,
        "score": score,
        "factors": factors,
        "recommendation": _get_recommendation(level),
    }


def _get_recommendation(level: str) -> str:
    recs = {
        "low": "Continue regular monitoring. Maintain healthy diet and hydration.",
        "medium": "Schedule a checkup within the next week. Monitor BP closely.",
        "high": "Contact your doctor today. Rest and avoid physical exertion.",
        "critical": "Seek immediate medical attention. Call your healthcare provider now.",
    }
    return recs.get(level, "Consult your healthcare provider.")
