import { useState, useEffect } from 'react';
import { fetchPatients, fetchPatient, fetchVitals, fetchLatestVital, fetchSymptoms } from './services/api';
import type { Patient, Vital, Symptom } from './types';
import './App.css';

const gradients = ['gradient-1', 'gradient-2', 'gradient-3', 'gradient-4', 'gradient-5'];

function getVitalTrend(type: string, value: number): { label: string; status: string } {
  const ranges: Record<string, [number, number, number, number]> = {
    heart_rate: [60, 90, 100, 120],
    spo2: [95, 100, 93, 90],
    temperature: [36.1, 37.2, 37.5, 38.5],
    bp_systolic: [90, 130, 140, 160],
  };
  const r = ranges[type];
  if (!r) return { label: 'Normal', status: 'normal' };
  if (value >= r[0] && value <= r[1]) return { label: 'Normal', status: 'normal' };
  if (value <= r[2]) return { label: 'Elevated', status: 'warning' };
  return { label: 'Critical', status: 'danger' };
}

function App() {
  const [view, setView] = useState<'overview' | 'patients' | 'detail'>('overview');
  const [patients, setPatients] = useState<Patient[]>([]);
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);
  const [vitals, setVitals] = useState<Vital[]>([]);
  const [symptoms, setSymptoms] = useState<Symptom[]>([]);
  const [, setLoading] = useState(true);

  useEffect(() => {
    // Live-device view: keep only patients with a fresh wearable
    // reading (GET .../latest merged with live:true). Mock-only
    // patients are hidden so the dashboard shows the real device.
    fetchPatients()
      .then(async (data) => {
        const list = Array.isArray(data) ? data : [];
        const checks = await Promise.all(
          list.map(async (p: Patient) => {
            try {
              const latest = await fetchLatestVital(p.id);
              return latest && latest.live === true ? p : null;
            } catch {
              return null;
            }
          })
        );
        setPatients(checks.filter((p): p is Patient => p !== null));
        setLoading(false);
      })
      .catch(console.error);
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

  const highRisk = patients.filter((p) => p.risk_level === 'high').length;
  const medRisk = patients.filter((p) => p.risk_level === 'medium').length;
  const lowRisk = patients.filter((p) => p.risk_level === 'low').length;

  const latestVital = vitals[0];

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="logo">
            <div className="logo-icon">N</div>
            <div className="logo-text">NEST<span>ORA</span></div>
          </div>
        </div>

        <nav className="sidebar-nav">
          <button
            className={`nav-item ${view === 'overview' ? 'active' : ''}`}
            onClick={() => setView('overview')}
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>
            Overview
          </button>
          <button
            className={`nav-item ${view === 'patients' ? 'active' : ''}`}
            onClick={() => setView('patients')}
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
            Patients
          </button>
          <button
            className={`nav-item ${view === 'detail' ? 'active' : ''}`}
            disabled={!selectedPatient}
            style={{ opacity: selectedPatient ? 1 : 0.4 }}
            onClick={() => setView('detail')}
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>
            Vitals Detail
          </button>
        </nav>

        <div className="sidebar-footer">
          <div className="doctor-info">
            <div className="doctor-avatar">RK</div>
            <div>
              <div className="doctor-name">Dr. Rajesh Kumar</div>
              <div className="doctor-role">OB-GYN Specialist</div>
            </div>
          </div>
        </div>
      </aside>

      <main className="main">
        {view === 'overview' && (
          <>
            <div className="page-header">
              <div>
                <h1 className="page-title">Dashboard Overview</h1>
                <p className="page-subtitle">Live wearable patients only</p>
              </div>
            </div>

            <div className="summary-grid">
              <div className="summary-card">
                <div className="summary-card-header">
                  <span className="summary-card-label">Total Patients</span>
                  <div className="summary-card-icon pink">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                  </div>
                </div>
                <div className="summary-card-value">{patients.length}</div>
                <div className="summary-card-change">Active pregnancies</div>
              </div>
              <div className="summary-card">
                <div className="summary-card-header">
                  <span className="summary-card-label">High Risk</span>
                  <div className="summary-card-icon red">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                  </div>
                </div>
                <div className="summary-card-value text-red">{highRisk}</div>
                <div className="summary-card-change">Requires attention</div>
              </div>
              <div className="summary-card">
                <div className="summary-card-header">
                  <span className="summary-card-label">Medium Risk</span>
                  <div className="summary-card-icon orange">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                  </div>
                </div>
                <div className="summary-card-value text-orange">{medRisk}</div>
                <div className="summary-card-change">Monitor closely</div>
              </div>
              <div className="summary-card">
                <div className="summary-card-header">
                  <span className="summary-card-label">Low Risk</span>
                  <div className="summary-card-icon green">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
                  </div>
                </div>
                <div className="summary-card-value text-green">{lowRisk}</div>
                <div className="summary-card-change">On track</div>
              </div>
            </div>

            <div className="patient-table-wrap">
              <div className="patient-table-header">
                <span className="patient-table-title">Patients Needing Attention</span>
                <span className="patient-count">{highRisk + medRisk} flagged</span>
              </div>
              <table className="patient-table">
                <thead>
                  <tr>
                    <th>Patient</th>
                    <th>Week</th>
                    <th>Due Date</th>
                    <th>Risk Level</th>
                  </tr>
                </thead>
                <tbody>
                  {patients
                    .filter((p) => p.risk_level !== 'low')
                    .map((p, i) => (
                      <tr key={p.id} onClick={() => openPatient(p.id)}>
                        <td>
                          <div className="patient-cell">
                            <div className={`patient-avatar ${gradients[i % gradients.length]}`}>
                              {p.name[0]}
                            </div>
                            <div>
                              <div className="patient-name">{p.name}</div>
                              <div className="patient-id">ID: {p.id.slice(0, 8)}</div>
                            </div>
                          </div>
                        </td>
                        <td className="patient-meta">Week {p.gestational_week}</td>
                        <td className="patient-meta">{p.due_date}</td>
                        <td><span className={`risk-badge ${p.risk_level}`}>{p.risk_level}</span></td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>
          </>
        )}

        {view === 'patients' && (
          <>
            <div className="page-header">
              <div>
                <h1 className="page-title">All Patients</h1>
                <p className="page-subtitle">{patients.length} live {patients.length === 1 ? 'patient' : 'patients'} connected</p>
              </div>
            </div>

            <div className="patient-table-wrap">
              <table className="patient-table">
                <thead>
                  <tr>
                    <th>Patient</th>
                    <th>Age</th>
                    <th>Week</th>
                    <th>Due Date</th>
                    <th>Phone</th>
                    <th>Risk Level</th>
                  </tr>
                </thead>
                <tbody>
                  {patients.map((p, i) => (
                    <tr key={p.id} onClick={() => openPatient(p.id)}>
                      <td>
                        <div className="patient-cell">
                          <div className={`patient-avatar ${gradients[i % gradients.length]}`}>
                            {p.name[0]}
                          </div>
                          <div>
                            <div className="patient-name">{p.name}</div>
                            <div className="patient-id">ID: {p.id.slice(0, 8)}</div>
                          </div>
                        </div>
                      </td>
                      <td className="patient-meta">{p.age} yrs</td>
                      <td className="patient-meta">Week {p.gestational_week}</td>
                      <td className="patient-meta">{p.due_date}</td>
                      <td className="patient-meta">{p.phone}</td>
                      <td><span className={`risk-badge ${p.risk_level}`}>{p.risk_level}</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}

        {view === 'detail' && selectedPatient && (
          <>
            <div className="detail-top-bar">
              <button className="back-btn" onClick={() => setView('patients')}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
                Back
              </button>
              <h1 className="detail-patient-name">{selectedPatient.name}</h1>
              <span className={`risk-badge ${selectedPatient.risk_level}`}>{selectedPatient.risk_level} risk</span>
              {latestVital?.live && (
                <span className="risk-badge live-device" title={`Wearable sync: ${latestVital.live_at ?? 'just now'}`}>
                  ● LIVE DEVICE
                </span>
              )}
            </div>
            {latestVital?.live && (
              <p className="live-sync-note">
                Last wearable sync: {latestVital.live_at ? new Date(latestVital.live_at).toLocaleTimeString() : 'just now'}
                {latestVital.signal_quality != null && ` · signal ${latestVital.signal_quality}/100`}
                {latestVital.fall_candidate && ' · possible sudden movement detected'}
              </p>
            )}

            <div className="info-grid">
              <div className="info-card">
                <h3>Patient Info</h3>
                <div className="info-row">
                  <span className="info-label">Age</span>
                  <span className="info-value">{selectedPatient.age} years</span>
                </div>
                <div className="info-row">
                  <span className="info-label">Gestational Week</span>
                  <span className="info-value">{selectedPatient.gestational_week} weeks</span>
                </div>
                <div className="info-row">
                  <span className="info-label">Due Date</span>
                  <span className="info-value">{selectedPatient.due_date}</span>
                </div>
                <div className="info-row">
                  <span className="info-label">Phone</span>
                  <span className="info-value">{selectedPatient.phone}</span>
                </div>
                <div className="info-row">
                  <span className="info-label">Doctor</span>
                  <span className="info-value">{selectedPatient.assigned_doctor}</span>
                </div>
              </div>

              {latestVital && (
                <div className="vitals-grid">
                  <div className="vital-card heart">
                    <div className="vital-icon heart">
                      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
                    </div>
                    <div className="vital-value">{latestVital.heart_rate}</div>
                    <div className="vital-label">Heart Rate (bpm)</div>
                    <div className={`vital-trend ${getVitalTrend('heart_rate', latestVital.heart_rate).status}`}>
                      {getVitalTrend('heart_rate', latestVital.heart_rate).label}
                    </div>
                  </div>
                  <div className="vital-card spo2">
                    <div className="vital-icon spo2">
                      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
                    </div>
                    <div className="vital-value">{latestVital.spo2}%</div>
                    <div className="vital-label">SpO2</div>
                    <div className={`vital-trend ${getVitalTrend('spo2', latestVital.spo2).status}`}>
                      {getVitalTrend('spo2', latestVital.spo2).label}
                    </div>
                  </div>
                  <div className="vital-card temp">
                    <div className="vital-icon temp">
                      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/></svg>
                    </div>
                    <div className="vital-value">{latestVital.temperature}°</div>
                    <div className="vital-label">Temperature (°C)</div>
                    <div className={`vital-trend ${getVitalTrend('temperature', latestVital.temperature).status}`}>
                      {getVitalTrend('temperature', latestVital.temperature).label}
                    </div>
                  </div>
                  <div className="vital-card bp">
                    <div className="vital-icon bp">
                      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
                    </div>
                    <div className="vital-value">{latestVital.systolic_bp}/{latestVital.diastolic_bp}</div>
                    <div className="vital-label">Blood Pressure</div>
                    <div className={`vital-trend ${getVitalTrend('bp_systolic', latestVital.systolic_bp).status}`}>
                      {getVitalTrend('bp_systolic', latestVital.systolic_bp).label}
                    </div>
                  </div>
                </div>
              )}
            </div>

            <div className="section-card">
              <div className="section-header">
                <h2 className="section-title">Vital History</h2>
                <span className="patient-count">{vitals.length} records</span>
              </div>
              <div className="section-body" style={{ padding: 0 }}>
                <table className="vitals-table">
                  <thead>
                    <tr>
                      <th>Timestamp</th>
                      <th>Heart Rate</th>
                      <th>SpO2</th>
                      <th>Temperature</th>
                      <th>Blood Pressure</th>
                      <th>Steps</th>
                    </tr>
                  </thead>
                  <tbody>
                    {vitals.map((v) => {
                      const hrTrend = getVitalTrend('heart_rate', v.heart_rate);
                      return (
                        <tr key={v.id}>
                          <td>{new Date(v.timestamp).toLocaleString()}</td>
                          <td>
                            <span style={{ fontWeight: 600 }}>{v.heart_rate} bpm</span>
                            <span className={`vital-trend ${hrTrend.status}`} style={{ marginLeft: 8 }}>
                              {hrTrend.label}
                            </span>
                          </td>
                          <td>{v.spo2}%</td>
                          <td>{v.temperature}°C</td>
                          <td>{v.systolic_bp}/{v.diastolic_bp}</td>
                          <td>{v.steps?.toLocaleString() || '—'}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="section-card">
              <div className="section-header">
                <h2 className="section-title">Symptoms</h2>
                <span className="patient-count">
                  {symptoms.filter((s) => s.ai_flagged).length} AI flagged
                </span>
              </div>
              <div className="section-body">
                {symptoms.length === 0 ? (
                  <div className="empty-state">
                    <div className="empty-state-icon">📋</div>
                    <div className="empty-state-text">No symptoms logged yet</div>
                  </div>
                ) : (
                  symptoms.map((s) => (
                    <div key={s.id} className={`symptom-card ${s.ai_flagged ? 'flagged' : ''}`}>
                      <div className="symptom-dot" />
                      <div className="symptom-content">
                        <div className="symptom-top">
                          <span className="symptom-type">{s.symptom_type}</span>
                          <div className="symptom-severity">
                            {Array.from({ length: 5 }, (_, i) => (
                              <span key={i} className={`severity-dot ${i < s.severity ? 'filled' : ''}`} />
                            ))}
                          </div>
                          {s.ai_flagged && <span className="symptom-flag">AI Flagged</span>}
                        </div>
                        <p className="symptom-desc">{s.description}</p>
                        <span className="symptom-time">{new Date(s.timestamp).toLocaleString()}</span>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </>
        )}
      </main>
    </div>
  );
}

export default App;
