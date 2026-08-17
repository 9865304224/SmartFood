import React, { useState, useEffect } from 'react';
import { ShoppingBag, MapPin, User, Bike, Clock, ArrowRight, ShieldCheck, Tag } from 'lucide-react';
import { api } from '../services/api';

export default function LiveOrderMonitor() {
  const [orders, setOrders] = useState([]);
  const [filter, setFilter] = useState('');
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState(null);

  const fetchOrders = async () => {
    try {
      setLoading(true);
      const data = await api.getOrders(filter);
      setOrders(data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, [filter]);

  return (
    <div className="animate-fade" style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Header & Filter Row */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h3 style={{ fontSize: '1.2rem', fontWeight: 700 }}>Real-Time Order Monitoring</h3>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Live status of orders across all kitchens and delivery routes.</p>
        </div>

        <div style={{ display: 'flex', gap: '8px' }}>
          {['', 'PLACED', 'PREPARING', 'READY_FOR_PICKUP', 'DELIVERY_ASSIGNED', 'OUT_FOR_DELIVERY', 'DELIVERED'].map(st => (
            <button
              key={st}
              onClick={() => setFilter(st)}
              style={{
                background: filter === st ? 'var(--primary)' : 'rgba(30, 41, 59, 0.6)',
                color: filter === st ? 'white' : 'var(--text-muted)',
                padding: '6px 14px',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--border)',
                fontSize: '0.8rem',
                fontWeight: 600,
                cursor: 'pointer'
              }}
            >
              {st ? st.replace('_', ' ') : 'All Orders'}
            </button>
          ))}
        </div>
      </div>

      {/* Orders Grid / Table */}
      {loading ? (
        <div style={{ padding: '60px', textAlign: 'center', color: 'var(--text-muted)' }}>Loading live orders...</div>
      ) : orders.length === 0 ? (
        <div className="glass-panel" style={{ padding: '60px', textAlign: 'center', color: 'var(--text-muted)' }}>
          No orders found matching the filter.
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))', gap: '20px' }}>
          {orders.map(order => (
            <div 
              key={order.id} 
              className="glass-panel" 
              style={{ 
                padding: '20px', 
                display: 'flex', 
                flexDirection: 'column', 
                gap: '14px',
                cursor: 'pointer',
                border: selectedOrder?.id === order.id ? '1px solid var(--primary)' : '1px solid var(--border)'
              }}
              onClick={() => setSelectedOrder(order)}
            >
              {/* Order Number & Status */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <ShoppingBag size={18} color="var(--primary)" />
                  <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>{order.orderNumber}</span>
                </div>
                <span className={`badge badge-${order.status?.toLowerCase()}`}>{order.status}</span>
              </div>

              {/* Business & Customer */}
              <div style={{ fontSize: '0.85rem', display: 'flex', flexDirection: 'column', gap: '6px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Restaurant:</span>
                  <span style={{ fontWeight: 600 }}>{order.businessName}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Customer:</span>
                  <span>{order.customerName} ({order.customerPhone})</span>
                </div>
                {order.deliveryPersonName && (
                  <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--cyan)' }}>
                    <span>Rider:</span>
                    <span>{order.deliveryPersonName}</span>
                  </div>
                )}
              </div>

              {/* Items Summary */}
              <div style={{ background: 'rgba(15, 23, 42, 0.5)', padding: '10px 14px', borderRadius: 'var(--radius-sm)', fontSize: '0.8rem' }}>
                {order.items?.map((item, idx) => (
                  <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', margin: '2px 0' }}>
                    <span>{item.quantity}x {item.foodName}</span>
                    <span>₹{item.itemTotal}</span>
                  </div>
                ))}
              </div>

              {/* Footer Total & Eco */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border)', paddingTop: '10px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.75rem', color: 'var(--emerald)' }}>
                  <ShieldCheck size={14} /> Delivery OTP: <b>{order.deliveryOtp}</b>
                </div>
                <div style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--text-main)' }}>
                  ₹{order.finalTotal}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
