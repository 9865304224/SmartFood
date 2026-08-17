const API_BASE = 'http://localhost:8080/api';

export const api = {
  token: localStorage.getItem('smartfood_admin_token') || '',

  setToken(t) {
    this.token = t;
    localStorage.setItem('smartfood_admin_token', t);
  },

  async request(endpoint, options = {}) {
    const headers = {
      'Content-Type': 'application/json',
      ...(this.token ? { Authorization: `Bearer ${this.token}` } : {}),
      ...options.headers
    };

    try {
      const res = await fetch(`${API_BASE}${endpoint}`, {
        ...options,
        headers
      });
      const data = await res.json();
      if (!res.ok || data.success === false) {
        throw new Error(data.message || 'API Request failed');
      }
      return data.data;
    } catch (err) {
      console.error(`API Error on ${endpoint}:`, err);
      throw err;
    }
  },

  // Auth
  async login(username, password) {
    const data = await this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password })
    });
    if (data.accessToken) {
      this.setToken(data.accessToken);
    }
    return data;
  },

  // Admin APIs
  getOverview() {
    return this.request('/admin/overview');
  },

  getApprovals() {
    return this.request('/admin/approvals');
  },

  submitDecision(partnerType, partnerId, decision, rejectionReason = '') {
    return this.request('/admin/approvals/decision', {
      method: 'POST',
      body: JSON.stringify({ partnerType, partnerId, decision, rejectionReason })
    });
  },

  getOrders(status = '') {
    return this.request(status ? `/admin/orders?status=${status}` : '/admin/orders');
  },

  queryAiCommand(query) {
    return this.request(`/admin/ai-command?query=${encodeURIComponent(query)}`, {
      method: 'POST'
    });
  },

  getComplaints(status = '') {
    return this.request(status ? `/complaints/all?status=${status}` : '/complaints/all');
  },

  resolveComplaint(complaintId, status, resolutionDetails, adminNotes) {
    return this.request(`/complaints/${complaintId}/resolve`, {
      method: 'POST',
      body: JSON.stringify({ status, resolutionDetails, adminNotes })
    });
  },

  getAuditLogs() {
    return this.request('/admin/audit-logs');
  },

  getFraudFlags() {
    return this.request('/admin/fraud-flags');
  }
};
