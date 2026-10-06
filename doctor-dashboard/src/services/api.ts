const API_BASE = 'http://localhost:8000';

export async function fetchPatients() {
  const res = await fetch(`${API_BASE}/api/patients/`);
  return res.json();
}

export async function fetchPatient(id: string) {
  const res = await fetch(`${API_BASE}/api/patients/${id}`);
  return res.json();
}

export async function fetchVitals(patientId: string) {
  const res = await fetch(`${API_BASE}/api/vitals/${patientId}`);
  return res.json();
}

export async function fetchLatestVital(patientId: string) {
  const res = await fetch(`${API_BASE}/api/vitals/${patientId}/latest`);
  return res.json();
}

export async function fetchSymptoms(patientId: string) {
  const res = await fetch(`${API_BASE}/api/symptoms/${patientId}`);
  return res.json();
}
