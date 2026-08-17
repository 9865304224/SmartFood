import React, { useState } from 'react';
import { Sparkles, Send, Bot, User, HelpCircle } from 'lucide-react';
import { api } from '../services/api';

export default function AICommandCenter() {
  const [query, setQuery] = useState('');
  const [messages, setMessages] = useState([
    {
      role: 'ai',
      text: 'Hello Admin! I am your SmartFood AI Operations Assistant. Ask me anything about restaurant cancellation rates, top performing food categories, rider workload, or platform revenue.'
    }
  ]);
  const [loading, setLoading] = useState(false);

  const samplePrompts = [
    "Which restaurants had the highest cancellation rate?",
    "Which food categories are most popular?",
    "What is our total revenue and order volume?",
    "What is our active delivery rider fleet status?"
  ];

  const handleSend = async (textToSend) => {
    const q = textToSend || query;
    if (!q.trim()) return;

    const userMsg = { role: 'user', text: q };
    setMessages(prev => [...prev, userMsg]);
    setQuery('');
    setLoading(true);

    try {
      const res = await api.queryAiCommand(q);
      const aiMsg = {
        role: 'ai',
        text: res.answer,
        data: res.supportingData
      };
      setMessages(prev => [...prev, aiMsg]);
    } catch (err) {
      setMessages(prev => [...prev, { role: 'ai', text: 'Error executing query: ' + err.message }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="animate-fade" style={{ display: 'flex', flexDirection: 'column', gap: '20px', height: 'calc(100vh - 160px)' }}>
      {/* Header */}
      <div>
        <h3 style={{ fontSize: '1.2rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Sparkles size={20} color="var(--primary)" /> AI Operations Command Center
        </h3>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
          Natural language analytics and operational intelligence.
        </p>
      </div>

      {/* Suggested Quick Prompts */}
      <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
        {samplePrompts.map((p, idx) => (
          <button
            key={idx}
            onClick={() => handleSend(p)}
            style={{
              background: 'rgba(30, 41, 59, 0.6)',
              border: '1px solid var(--border)',
              color: 'var(--text-muted)',
              padding: '6px 12px',
              borderRadius: 'var(--radius-full)',
              fontSize: '0.8rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px'
            }}
          >
            <HelpCircle size={12} /> {p}
          </button>
        ))}
      </div>

      {/* Chat Messages Container */}
      <div className="glass-panel" style={{ flex: 1, padding: '20px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {messages.map((m, i) => (
          <div 
            key={i} 
            style={{ 
              display: 'flex', 
              gap: '12px', 
              alignItems: 'flex-start',
              alignSelf: m.role === 'user' ? 'flex-end' : 'flex-start',
              maxWidth: '80%'
            }}
          >
            <div style={{
              background: m.role === 'user' ? 'var(--primary)' : 'rgba(255, 107, 0, 0.15)',
              color: m.role === 'user' ? 'white' : 'var(--primary)',
              padding: '8px',
              borderRadius: 'var(--radius-sm)'
            }}>
              {m.role === 'user' ? <User size={16} /> : <Bot size={16} />}
            </div>

            <div style={{
              background: m.role === 'user' ? 'rgba(255, 107, 0, 0.12)' : 'rgba(15, 23, 42, 0.7)',
              border: '1px solid var(--border)',
              padding: '12px 16px',
              borderRadius: 'var(--radius-md)',
              fontSize: '0.9rem',
              lineHeight: 1.5
            }}>
              {m.text}
            </div>
          </div>
        ))}
        {loading && (
          <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Sparkles size={16} className="animate-spin" /> Querying platform intelligence...
          </div>
        )}
      </div>

      {/* Query Input Bar */}
      <div style={{ display: 'flex', gap: '10px' }}>
        <input
          type="text"
          className="input-field"
          placeholder="Ask a question about orders, cancellations, revenue, or drivers..."
          value={query}
          onChange={e => setQuery(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSend()}
        />
        <button className="btn btn-primary" onClick={() => handleSend()} disabled={loading}>
          <Send size={16} />
        </button>
      </div>
    </div>
  );
}
