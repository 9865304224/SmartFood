import React, { useState } from 'react';
import { Check, X, Shield, FileText, MapPin, Phone, Mail, Award } from 'lucide-react';
import { api } from '../services/api';

export default function PartnerApprovals({ approvals, onRefresh }) {
  const [activeTab, setActiveTab] = useState('RESTAURANT');
  const [processing, setProcessing] = useState(false);
  const [rejectionModal, setRejectionModal] = useState({ open: false, type: '', id: '', name: '', reason: '' });

  const handleApprove = async (type, id) => {
    try {
      setProcessing(true);
      await api.submitDecision(type, id, 'APPROVED');
      onRefresh();
    } catch (err) {
      alert('Error approving partner: ' + err.message);
    } finally {
      setProcessing(false);
    }
  };

  const handleReject = async () => {
    if (!rejectionModal.reason.trim()) {
      alert('Please enter a rejection reason.');
      return;
    }
    try {
      setProcessing(true);
      await api.submitDecision(rejectionModal.type, rejectionModal.id, 'REJECTED', rejectionModal.reason);
      setRejectionModal({ open: false, type: '', id: '', name: '', reason: '' });
      onRefresh();
    } catch (err) {
      alert('Error rejecting partner: ' + err.message);
    } finally {
      setProcessing(false);
    }
  };

  const currentList = activeTab === 'RESTAURANT' 
    ? (approvals?.restaurants || [])
    : activeTab === 'HOTEL' 
    ? (approvals?.hotels || [])
    : (approvals?.deliveryPersons || []);

  return (
    <div className="animate-fade" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Tabs Header */}
      <div style={{ display: 'flex', gap: '12px', borderBottom: '1px solid var(--border)', paddingBottom: '12px' }}>
        {[
          { key: 'RESTAURANT', label: `Restaurants (${approvals?.restaurants?.length || 0})` },
          { key: 'HOTEL', label: `Hotels & Caterers (${approvals?.hotels?.length || 0})` },
          { key: 'DELIVERY_PERSON', label: `Delivery Riders (${approvals?.deliveryPersons?.length || 0})` }
        ].map(t => (
          <button
            key={t.key}
            onClick={() => setActiveTab(t.key)}
            style={{
              background: activeTab === t.key ? 'var(--primary)' : 'transparent',
              color: activeTab === t.key ? 'white' : 'var(--text-muted)',
              padding: '8px 18px',
              borderRadius: 'var(--radius-md)',
              border: 'none',
              fontWeight: 600,
              cursor: 'pointer',
              fontSize: '0.875rem'
            }}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* Cards List */}
      {currentList.length === 0 ? (
        <div className="glass-panel" style={{ padding: '60px', textAlign: 'center', color: 'var(--text-muted)' }}>
          <Shield size={48} style={{ opacity: 0.3, marginBottom: '16px' }} />
          <h4 style={{ fontSize: '1.1rem', color: 'var(--text-main)', marginBottom: '6px' }}>No Pending Approvals</h4>
          <p style={{ fontSize: '0.85rem' }}>All {activeTab.toLowerCase().replace('_', ' ')} applications have been reviewed.</p>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '20px' }}>
          {currentList.map(item => (
            <div key={item.id} className="glass-panel" style={{ padding: '22px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h4 style={{ fontSize: '1.15rem', fontWeight: 700, color: 'var(--text-main)' }}>
                    {item.businessName || item.fullName}
                  </h4>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '6px', marginTop: '4px' }}>
                    <MapPin size={14} /> {item.address || (item.currentLocation?.formattedAddress) || 'Bengaluru, India'}
                  </div>
                </div>
                <span className="badge badge-pending">PENDING</span>
              </div>

              {/* Document & Contact Information */}
              <div style={{ background: 'rgba(15, 23, 42, 0.5)', padding: '14px', borderRadius: 'var(--radius-md)', display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '0.85rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--text-muted)' }}>
                  <Phone size={14} /> <span>{item.phone}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--text-muted)' }}>
                  <Mail size={14} /> <span>{item.email}</span>
                </div>
                {item.fssaiLicenseNumber && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--amber)' }}>
                    <FileText size={14} /> <span>FSSAI Lic: <b>{item.fssaiLicenseNumber}</b></span>
                  </div>
                )}
                {item.drivingLicenseNumber && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--cyan)' }}>
                    <Award size={14} /> <span>DL: <b>{item.drivingLicenseNumber}</b> ({item.vehicleType} - {item.vehicleNumber})</span>
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div style={{ display: 'flex', gap: '10px', marginTop: 'auto' }}>
                <button
                  className="btn btn-success"
                  style={{ flex: 1 }}
                  disabled={processing}
                  onClick={() => handleApprove(activeTab, item.id)}
                >
                  <Check size={16} /> Approve
                </button>
                <button
                  className="btn btn-danger"
                  style={{ flex: 1 }}
                  disabled={processing}
                  onClick={() => setRejectionModal({ 
                    open: true, 
                    type: activeTab, 
                    id: item.id, 
                    name: item.businessName || item.fullName, 
                    reason: '' 
                  })}
                >
                  <X size={16} /> Reject
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Rejection Modal */}
      {rejectionModal.open && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(0,0,0,0.75)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100
        }}>
          <div className="glass-panel" style={{ width: '420px', padding: '24px', background: '#0F172A', display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <h4 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Reject {rejectionModal.name}</h4>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
              Please provide a clear reason for rejecting this partner registration (e.g. invalid FSSAI, expired license).
            </p>
            <textarea
              className="input-field"
              rows={4}
              placeholder="Enter rejection reason..."
              value={rejectionModal.reason}
              onChange={e => setRejectionModal({ ...rejectionModal, reason: e.target.value })}
            />
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button 
                className="btn btn-secondary" 
                onClick={() => setRejectionModal({ open: false, type: '', id: '', name: '', reason: '' })}
              >
                Cancel
              </button>
              <button 
                className="btn btn-danger" 
                onClick={handleReject}
              >
                Confirm Rejection
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
