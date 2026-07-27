import { useState, useEffect } from 'react';
import { fetchPatients, fetchPatient, fetchVitals, fetchSymptoms } from './services/api';
import type { Patient, Vital, Symptom } from './types';
import './App.css';

function App() {
  const [view, setView] = useState<'list' | 'detail'>('list');
  const [patients, setPatients] = useState<Patient[]>([]);
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);
  const [vitals, setVitals] = useState<Vital[]>([]);
  const [symptoms, setSymptoms] = useState<Symptom[]>([]);

  useEffect(() => {
    fetchPatients().then(setPatients).catch(console.error);
  }, []);

  const openPatient = async (id: string) => {
    const [p, v, s] = await Promise.all([
      fetchPatient(id),
      fetchVitals(id),
      fetchSymptoms(id),
    ]);
    setSelectedPatient(p);
    setVitals(v);
    setSymptoms(s);
    setView('detail');
  };

  const latestVital = vitals[0];

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="logo">
          <div className="logo-icon">N</div>
          <span>NESTORA</span>
        </div>
        <nav>
          <button className={view === 'list' ? 'active' : ''} onClick={() => setView('list')}>
            Patients
          </button>
        </nav>
        <div className="sidebar-footer">
          <small>Dr. Rajesh Kumar</small>
          <small style={{ color: '#999' }}>Cardiologist</small>
        </div>
      </aside>

      <main className="main">
        {view === 'list' ? (
          <>
            <div className="header">
              <h1>Patient Dashboard</h1>
              <div className="stats">
                <div className="stat red">{patients.filter(p => p.risk_level === 'high').length} High Risk</div>
                <div className="stat yellow">{patients.filter(p => p.risk_level === 'medium').length} Medium</div>
                <div className="stat green">{patients.filter(p => p.risk_level === 'low').length} Low Risk</div>
              </div>
            </div>
            <div className="patient-list">
              {patients.map(p => (
                <div key={p.id} className={`patient-card risk-${p.risk_level}`} onClick={() => openPatient(p.id)}>
                  <div className="patient-avatar">{p.name[0]}</div>
                  <div className="patient-info">
                    <strong>{p.name}</strong>
                    <small>Week {p.gestational_week} &bull; Age {p.age}</small>
                  </div>
                  <div className="patient-meta">
                    <span className={`badge ${p.risk_level}`}>{p.risk_level} risk</span>
                    <small>Due: {p.due_date}</small>
                  </div>
                </div>
              ))}
            </div>
          </>
        ) : selectedPatient && (
          <>
            <div className="header">
              <button className="back-btn" onClick={() => setView('list')}>&larr; Back</button>
              <h1>{selectedPatient.name}</h1>
              <span className={`badge ${selectedPatient.risk_level}`}>{selectedPatient.risk_level} risk</span>
            </div>

            <div className="detail-grid">
              <div className="info-card">
                <h3>Patient Info</h3>
                <p><strong>Age:</strong> {selectedPatient.age}</p>
                <p><strong>Gestational Week:</strong> {selectedPatient.gestational_week}</p>
                <p><strong>Due Date:</strong> {selectedPatient.due_date}</p>
                <p><strong>Phone:</strong> {selectedPatient.phone}</p>
              </div>

              {latestVital && (
                <div className="vitals-card">
                  <h3>Latest Vitals</h3>
                  <div className="vital-grid">
                    <div className="vital-item red">
                      <span className="vital-val">{latestVital.heart_rate}</span>
                      <span className="vital-label">Heart Rate (bpm)</span>
                    </div>
                    <div className="vital-item blue">
                      <span className="vital-val">{latestVital.spo2}%</span>
                      <span className="vital-label">SpO2</span>
                    </div>
                    <div className="vital-item orange">
                      <span className="vital-val">{latestVital.temperature}°C</span>
                      <span className="vital-label">Temperature</span>
                    </div>
                    <div className="vital-item purple">
                      <span className="vital-val">{latestVital.systolic_bp}/{latestVital.diastolic_bp}</span>
                      <span className="vital-label">Blood Pressure</span>
                    </div>
                  </div>
                </div>
              )}
            </div>

            <div className="section">
              <h2>Vital History</h2>
              <div className="chart-placeholder">
                <table>
                  <thead>
                    <tr>
                      <th>Time</th>
                      <th>HR</th>
                      <th>SpO2</th>
                      <th>Temp</th>
                      <th>BP</th>
                    </tr>
                  </thead>
                  <tbody>
                    {vitals.map(v => (
                      <tr key={v.id}>
                        <td>{new Date(v.timestamp).toLocaleString()}</td>
                        <td>{v.heart_rate} bpm</td>
                        <td>{v.spo2}%</td>
                        <td>{v.temperature}°C</td>
                        <td>{v.systolic_bp}/{v.diastolic_bp}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="section">
              <h2>Symptoms</h2>
              {symptoms.length === 0 ? (
                <p className="empty">No symptoms logged</p>
              ) : (
                symptoms.map(s => (
                  <div key={s.id} className={`symptom-item ${s.ai_flagged ? 'flagged' : ''}`}>
                    <div className="symptom-header">
                      <strong>{s.symptom_type}</strong>
                      <div className="severity">
                        {Array.from({length: 5}, (_, i) => (
                          <span key={i} className={`dot ${i < s.severity ? 'filled' : ''}`} />
                        ))}
                      </div>
                      {s.ai_flagged && <span className="flag">AI Flagged</span>}
                    </div>
                    <p>{s.description}</p>
                    <small>{new Date(s.timestamp).toLocaleString()}</small>
                  </div>
                ))
              )}
            </div>
          </>
        )}
      </main>
    </div>
  );
}

export default App;
