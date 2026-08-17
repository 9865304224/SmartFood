import React, { useState, useEffect } from 'react';
import { Shield, Clock, Terminal } from 'lucide-react';
import { api } from '../services/api';

export default function AuditLogs() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const data = await api.getAuditLogs();
        setLogs(data || []);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <div className="animate-fade" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      <div>
        <h3 style={{ fontSize: '1.2rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Shield size={20} color="var(--primary)" /> Immutable System Audit Trail
        </h3>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
          Tamper-evident logs of administrative approvals, state overrides, and financial transactions.
        </p>
      </div>

      <div className="glass-panel" style={{ padding: '20px', overflowX: 'auto' }}>
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-muted)' }}>Loading audit logs...</div>
        ) : logs.length === 0 ? (
          <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-muted)' }}>No audit logs recorded yet.</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border)', textAlign: 'left', color: 'var(--text-muted)' }}>
                <th style={{ padding: '12px 8px' }}>Timestamp</th>
                <th style={{ padding: '12px 8px' }}>Admin</th>
                <th style={{ padding: '12px 8px' }}>Action</th>
                <th style={{ padding: '12px 8px' }}>Target Resource</th>
                <th style={{ padding: '12px 8px' }}>Details</th>
              </tr>
            </thead>
            <tbody>
              {logs.map((l, i) => (
                <tr key={l.id || i} style={{ borderBottom: '1px solid var(--border)' }}>
                  <td style={{ padding: '12px 8px', fontFamily: 'var(--font-mono)', color: 'var(--text-dim)' }}>
                    {new Date(l.timestamp).toLocaleString()}
                  </td>
                  <td style={{ padding: '12px 8px', fontWeight: 600 }}>{l.adminEmail}</td>
                  <td style={{ padding: '12px 8px' }}>
                    <span className="badge badge-active">{l.action}</span>
                  </td>
                  <td style={{ padding: '12px 8px', color: 'var(--cyan)' }}>{l.targetResource} ({l.targetId})</td>
                  <td style={{ padding: '12px 8px', color: 'var(--text-muted)' }}>{l.details}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
