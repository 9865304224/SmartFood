import React, { useState, useEffect } from 'react';
import { 
  LayoutDashboard, 
  CheckSquare, 
  ShoppingBag, 
  Sparkles, 
  AlertCircle, 
  Shield, 
  LogOut, 
  UtensilsCrossed 
} from 'lucide-react';
import { api } from './services/api';
import DashboardOverview from './pages/DashboardOverview';
import PartnerApprovals from './pages/PartnerApprovals';
import LiveOrderMonitor from './pages/LiveOrderMonitor';
import ComplaintsManager from './pages/ComplaintsManager';
import AICommandCenter from './pages/AICommandCenter';
import AuditLogs from './pages/AuditLogs';

export default function App() {
  const [user, setUser] = useState(null);
  const [currentPage, setCurrentPage] = useState('overview');
  const [overviewStats, setOverviewStats] = useState(null);
  const [approvals, setApprovals] = useState(null);
  const [loading, setLoading] = useState(true);

  // Login form state
  const [loginEmail, setLoginEmail] = useState('admin@smartfood.com');
  const [loginPass, setLoginPass] = useState('Admin@123');
  const [loginError, setLoginError] = useState('');

  const loadAdminData = async () => {
    try {
      setLoading(true);
      const [stats, apprs] = await Promise.all([
        api.getOverview().catch(() => null),
        api.getApprovals().catch(() => null)
      ]);
      setOverviewStats(stats);
      setApprovals(apprs);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = async (e) => {
    e?.preventDefault();
    try {
      setLoginError('');
      const data = await api.login(loginEmail, loginPass);
      if (data.role !== 'ADMIN') {
        throw new Error('Access denied: Admin role required');
      }
      setUser(data);
      loadAdminData();
    } catch (err) {
      setLoginError(err.message || 'Login failed');
    }
  };

  useEffect(() => {
    // Auto-login with demo admin credentials if token available
    handleLogin();
  }, []);

  const navItems = [
    { key: 'overview', label: 'Overview', icon: LayoutDashboard },
    { key: 'approvals', label: 'Partner Approvals', icon: CheckSquare, badge: approvals?.restaurants?.length + approvals?.hotels?.length + approvals?.deliveryPersons?.length },
    { key: 'orders', label: 'Live Order Monitor', icon: ShoppingBag },
    { key: 'complaints', label: 'Disputes & Support', icon: AlertCircle },
    { key: 'ai', label: 'AI Command Center', icon: Sparkles },
    { key: 'audit', label: 'Security & Audit Logs', icon: Shield }
  ];

  if (!user) {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px'
      }}>
        <div className="glass-panel" style={{ width: '400px', padding: '32px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px' }}>
            <div style={{ background: 'var(--primary)', padding: '10px', borderRadius: 'var(--radius-md)', color: 'white' }}>
              <UtensilsCrossed size={24} />
            </div>
            <div>
              <h2 style={{ fontSize: '1.3rem', fontWeight: 800 }}>SmartFood</h2>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Admin & Operations Console</div>
            </div>
          </div>

          {loginError && (
            <div style={{ background: 'rgba(244,63,94,0.15)', border: '1px solid var(--rose)', color: '#FB7185', padding: '10px', borderRadius: 'var(--radius-sm)', fontSize: '0.85rem', marginBottom: '16px' }}>
              {loginError}
            </div>
          )}

          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', display: 'block', marginBottom: '6px' }}>Email</label>
              <input 
                type="email" 
                className="input-field" 
                value={loginEmail} 
                onChange={e => setLoginEmail(e.target.value)} 
              />
            </div>

            <div>
              <label style={{ fontSize: '0.8rem', color: 'var(--text-muted)', display: 'block', marginBottom: '6px' }}>Password</label>
              <input 
                type="password" 
                className="input-field" 
                value={loginPass} 
                onChange={e => setLoginPass(e.target.value)} 
              />
            </div>

            <button type="submit" className="btn btn-primary" style={{ marginTop: '10px' }}>
              Sign In to Command Center
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <aside style={{
        width: '260px',
        background: 'rgba(15, 23, 42, 0.95)',
        borderRight: '1px solid var(--border)',
        padding: '24px 16px',
        display: 'flex',
        flexDirection: 'column',
        gap: '24px'
      }}>
        {/* Brand */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '0 8px' }}>
          <div style={{ background: 'var(--primary)', padding: '8px', borderRadius: 'var(--radius-sm)', color: 'white' }}>
            <UtensilsCrossed size={20} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.2rem', fontWeight: 800, letterSpacing: '-0.02em' }}>SmartFood</h1>
            <div style={{ fontSize: '0.7rem', color: 'var(--primary-light)', fontWeight: 700 }}>AI OPS CONSOLE</div>
          </div>
        </div>

        {/* Navigation Items */}
        <nav style={{ display: 'flex', flexDirection: 'column', gap: '6px', flex: 1 }}>
          {navItems.map(item => {
            const Icon = item.icon;
            const active = currentPage === item.key;
            return (
              <button
                key={item.key}
                onClick={() => setCurrentPage(item.key)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '12px 14px',
                  borderRadius: 'var(--radius-md)',
                  border: 'none',
                  background: active ? 'rgba(255, 107, 0, 0.15)' : 'transparent',
                  color: active ? 'var(--primary)' : 'var(--text-muted)',
                  fontWeight: active ? 700 : 500,
                  fontSize: '0.875rem',
                  cursor: 'pointer',
                  textAlign: 'left',
                  transition: 'all 0.2s ease'
                }}
              >
                <Icon size={18} />
                <span style={{ flex: 1 }}>{item.label}</span>
                {item.badge > 0 && (
                  <span style={{ 
                    background: 'var(--amber)', 
                    color: '#000', 
                    fontSize: '0.7rem', 
                    fontWeight: 800, 
                    padding: '2px 6px', 
                    borderRadius: 'var(--radius-full)' 
                  }}>
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>

        {/* User Info & Logout */}
        <div style={{ 
          borderTop: '1px solid var(--border)', 
          paddingTop: '16px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between'
        }}>
          <div>
            <div style={{ fontSize: '0.85rem', fontWeight: 700 }}>{user.fullName}</div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{user.email}</div>
          </div>
          <button 
            onClick={() => setUser(null)}
            style={{ background: 'transparent', border: 'none', color: 'var(--text-dim)', cursor: 'pointer' }}
            title="Logout"
          >
            <LogOut size={18} />
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main style={{ flex: 1, padding: '32px 40px', overflowY: 'auto' }}>
        {currentPage === 'overview' && (
          <DashboardOverview stats={overviewStats} onNavigate={setCurrentPage} />
        )}
        {currentPage === 'approvals' && (
          <PartnerApprovals approvals={approvals} onRefresh={loadAdminData} />
        )}
        {currentPage === 'orders' && (
          <LiveOrderMonitor />
        )}
        {currentPage === 'complaints' && (
          <ComplaintsManager />
        )}
        {currentPage === 'ai' && (
          <AICommandCenter />
        )}
        {currentPage === 'audit' && (
          <AuditLogs />
        )}
      </main>
    </div>
  );
}
