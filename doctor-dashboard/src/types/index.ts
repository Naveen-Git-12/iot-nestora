export interface Patient {
  id: string;
  name: string;
  age: number;
  gestational_week: number;
  due_date: string;
  phone: string;
  risk_level: 'low' | 'medium' | 'high';
  assigned_doctor: string;
}

export interface Vital {
  id: string;
  patient_id: string;
  heart_rate: number;
  spo2: number;
  temperature: number;
  systolic_bp: number;
  diastolic_bp: number;
  activity_level: string;
  steps: number;
  source: string;
  timestamp: string;
}

export interface Symptom {
  id: string;
  patient_id: string;
  symptom_type: string;
  severity: number;
  description: string;
  timestamp: string;
  ai_flagged: boolean;
}
