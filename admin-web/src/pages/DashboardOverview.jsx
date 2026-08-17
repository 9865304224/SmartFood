import React from 'react';
import { 
  ShoppingBag, 
  Store, 
  Building2, 
  Bike, 
  DollarSign, 
  Clock, 
  ShieldAlert, 
  CheckCircle, 
  TrendingUp,
  Leaf
} from 'lucide-react';

export default function DashboardOverview({ stats, onNavigate }) {
  if (!stats) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: '60px' }}>
        <div style={{ color: 'var(--text-muted)' }}>Loading live operations overview...</div>
      </div>
    );
  }

  const metricCards = [
    {
      title: 'Platform Gross Revenue',
      value: `₹${stats.totalRevenue?.toLocaleString('en-IN') || 0}`,
      change: '+18.4% vs last week',
      icon: DollarSign,
      glow: 'rgba(255, 107, 0, 0.2)',
      accent: 'var(--primary)'
    },
    {
      title: 'Active Live Orders',
      value: stats.activeOrders || 0,
      change: 'Real-time transit',
      icon: ShoppingBag,
      glow: 'rgba(6, 182, 212, 0.2)',
      accent: 'var(--cyan)'
    },
    {
      title: 'Completed Deliveries',
      value: stats.completedOrders || 0,
      change: '99.4% on-time fulfillment',
      icon: CheckCircle,
      glow: 'rgba(16, 185, 129, 0.2)',
      accent: 'var(--emerald)'
    },
    {
      title: 'Pending Approvals',
      value: stats.pendingApprovals || 0,
      change: 'Requires action',
      icon: Clock,
      glow: 'rgba(245, 158, 11, 0.2)',
      accent: 'var(--amber)',
      action: () => onNavigate('approvals')
    }
  ];

  const networkEntities = [
    { label: 'Active Customers', value: stats.totalCustomers || 0, icon: ShoppingBag, color: '#38BDF8' },
    { label: 'Partner Restaurants', value: stats.totalRestaurants || 0, icon: Store, color: '#F472B6' },
    { label: 'Partner Hotels & Caterers', value: stats.totalHotels || 0, icon: Building2, color: '#A78BFA' },
    { label: 'Delivery Riders (EV & Fuel)', value: stats.totalDeliveryPersons || 0, icon: Bike, color: '#34D399' }
  ];

  return (
    <div className="animate-fade" style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      {/* Top Metrics Row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '20px' }}>
        {metricCards.map((c, i) => {
          const Icon = c.icon;
          return (
            <div 
              key={i} 
              className="glass-panel" 
              style={{ 
                padding: '22px', 
                cursor: c.action ? 'pointer' : 'default',
                position: 'relative',
                overflow: 'hidden'
              }}
              onClick={c.action}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', fontWeight: 600, marginBottom: '8px' }}>
                    {c.title}
                  </div>
                  <div style={{ fontSize: '1.9rem', fontWeight: 800, color: 'var(--text-main)', letterSpacing: '-0.02em' }}>
                    {c.value}
                  </div>
                  <div style={{ fontSize: '0.75rem', color: c.accent, marginTop: '8px', fontWeight: 600 }}>
                    {c.change}
                  </div>
                </div>
                <div style={{ 
                  background: c.glow, 
                  padding: '12px', 
                  borderRadius: 'var(--radius-md)',
                  color: c.accent
                }}>
                  <Icon size={24} />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Network Overview & Eco Score Section */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '20px' }}>
        {/* Network Breakdown */}
        <div className="glass-panel" style={{ padding: '24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 700 }}>Platform Ecosystem & Partners</h3>
            <span className="badge badge-approved">Online</span>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '16px' }}>
            {networkEntities.map((item, idx) => {
              const Icon = item.icon;
              return (
                <div key={idx} style={{ 
                  background: 'rgba(15, 23, 42, 0.6)', 
                  padding: '18px', 
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '14px'
                }}>
                  <div style={{ background: `${item.color}22`, padding: '10px', borderRadius: 'var(--radius-sm)', color: item.color }}>
                    <Icon size={20} />
                  </div>
                  <div>
                    <div style={{ fontSize: '1.4rem', fontWeight: 700 }}>{item.value}</div>
                    <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{item.label}</div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Eco & AI Delivery Insights */}
        <div className="glass-panel" style={{ padding: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--emerald)', marginBottom: '12px' }}>
              <Leaf size={20} />
              <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-main)' }}>Eco-Route Savings</h3>
            </div>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', lineHeight: 1.5 }}>
              SmartFood's multi-order routing and EV fleet pairing have saved an estimated:
            </p>
            <div style={{ fontSize: '2.2rem', fontWeight: 800, color: 'var(--emerald)', margin: '14px 0 6px 0' }}>
              ~148.5 kg
            </div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-dim)' }}>
              CO2 emissions reduced through AI batching.
            </div>
          </div>

          <button 
            className="btn btn-secondary" 
            style={{ width: '100%', marginTop: '16px' }}
            onClick={() => onNavigate('ai')}
          >
            Ask AI Command Assistant
          </button>
        </div>
      </div>
    </div>
  );
}
