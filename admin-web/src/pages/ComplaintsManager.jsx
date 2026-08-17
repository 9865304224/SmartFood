import React, { useState, useEffect } from 'react';
import { AlertCircle, CheckCircle2, MessageSquare, ShieldAlert } from 'lucide-react';
import { api } from '../services/api';

export default function ComplaintsManager() {
  const [complaints, setComplaints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [resolveModal, setResolveModal] = useState({ open: false, id: '', ticketNumber: '', details: '', notes: '' });

  const fetchComplaints = async () => {
    try {
      setLoading(true);
      const data = await api.getComplaints();
      setComplaints(data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchComplaints();
  }, []);

  const handleResolve = async (status) => {
    try {
      await api.resolveComplaint(
        resolveModal.id,
        status,
        resolveModal.details || 'Issue reviewed and resolved by admin team.',
        resolveModal.notes || 'No internal note.'
      );
      setResolveModal({ open: false, id: '', ticketNumber: '', details: '', notes: '' });
      fetchComplaints();
    } catch (err) {
      alert('Error resolving complaint: ' + err.message);
    }
  };

  return (
    <div className="animate-fade" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      <div>
        <h3 style={{ fontSize: '1.2rem', fontWeight: 700 }}>Dispute & Complaint Center</h3>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Investigate and resolve customer issues with order fulfillment.</p>
      </div>

      {loading ? (
        <div style={{ padding: '60px', textAlign: 'center', color: 'var(--text-muted)' }}>Loading tickets...</div>
      ) : complaints.length === 0 ? (
        <div className="glass-panel" style={{ padding: '60px', textAlign: 'center', color: 'var(--text-muted)' }}>
          <CheckCircle2 size={48} style={{ opacity: 0.3, marginBottom: '12px' }} />
          <div>No open customer disputes. All orders fulfilled cleanly.</div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '20px' }}>
          {complaints.map(c => (
            <div key={c.id} className="glass-panel" style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontWeight: 800 }}>{c.ticketNumber}</span>
                <span className={`badge badge-${c.status?.toLowerCase()}`}>{c.status}</span>
              </div>

              <div style={{ fontSize: '0.85rem' }}>
                <div style={{ color: 'var(--amber)', fontWeight: 600, marginBottom: '4px' }}>Category: {c.category}</div>
                <div style={{ color: 'var(--text-main)', background: 'rgba(15, 23, 42, 0.6)', padding: '10px', borderRadius: 'var(--radius-sm)' }}>
                  "{c.description}"
                </div>
              </div>

              <div style={{ fontSize: '0.8rem', color: 'var(--text-dim)' }}>
                Customer: <b>{c.customerName}</b> | Order ID: <b>{c.orderId}</b>
              </div>

              {c.status === 'OPEN' && (
                <div style={{ display: 'flex', gap: '8px', marginTop: 'auto' }}>
                  <button 
                    className="btn btn-success" 
                    style={{ flex: 1 }}
                    onClick={() => setResolveModal({ open: true, id: c.id, ticketNumber: c.ticketNumber, details: '', notes: '' })}
                  >
                    Resolve Ticket
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Resolution Modal */}
      {resolveModal.open && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(0,0,0,0.75)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100
        }}>
          <div className="glass-panel" style={{ width: '440px', padding: '24px', background: '#0F172A', display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <h4 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Resolve Ticket #{resolveModal.ticketNumber}</h4>
            
            <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Resolution Message to Customer</label>
            <textarea
              className="input-field"
              rows={3}
              placeholder="e.g. A ₹100 refund has been credited to your wallet..."
              value={resolveModal.details}
              onChange={e => setResolveModal({ ...resolveModal, details: e.target.value })}
            />

            <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Internal Admin Notes</label>
            <input
              type="text"
              className="input-field"
              placeholder="e.g. Contacted restaurant chef regarding packaging tape..."
              value={resolveModal.notes}
              onChange={e => setResolveModal({ ...resolveModal, notes: e.target.value })}
            />

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '8px' }}>
              <button className="btn btn-secondary" onClick={() => setResolveModal({ open: false, id: '', ticketNumber: '', details: '', notes: '' })}>
                Cancel
              </button>
              <button className="btn btn-success" onClick={() => handleResolve('RESOLVED')}>
                Confirm Resolution
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
