let currentData = { sites: [], services: [] };
let socket = null;
let flyoutSite = null;

function toggleTheme() {
  const html = document.documentElement;
  const icon = document.getElementById('theme-icon');
  const label = document.getElementById('theme-label');
  const isLight = html.getAttribute('data-theme') === 'light';
  if (isLight) {
    html.removeAttribute('data-theme');
    localStorage.setItem('theme', 'dark');
    icon.className = 'ph-light ph-moon';
    if (label) label.textContent = 'Dark';
  } else {
    html.setAttribute('data-theme', 'light');
    localStorage.setItem('theme', 'light');
    icon.className = 'ph-light ph-sun';
    if (label) label.textContent = 'Light';
  }
}

function loadTheme() {
  const saved = localStorage.getItem('theme') || 'dark';
  const icon = document.getElementById('theme-icon');
  const label = document.getElementById('theme-label');
  if (saved === 'light') {
    document.documentElement.setAttribute('data-theme', 'light');
    if (icon) icon.className = 'ph-light ph-sun';
    if (label) label.textContent = 'Light';
  } else {
    if (icon) icon.className = 'ph-light ph-moon';
    if (label) label.textContent = 'Dark';
  }
}

document.addEventListener('DOMContentLoaded', loadTheme);

function initWebSocket() {
  const protocol = window.location.protocol === 'https:' ? 'https:' : 'http:';
  socket = io(`${protocol}//${window.location.host}`);
  socket.on('connect', () => console.log('[WS] Connected'));
  socket.on('status.changed', (data) => {
    updateStatusFromWebSocket(data);
  });
  socket.on('site.operation', (data) => {
    handleOperationEvent(data);
  });
  socket.on('disconnect', () => {
    console.log('[WS] Disconnected');
    setTimeout(initWebSocket, 5000);
  });
}

function updateStatusFromWebSocket(data) {
  if (data.containers && Array.isArray(data.containers)) {
    data.containers.forEach(container => {
      if (container.name && container.name.startsWith('wp_') && !container.name.startsWith('wp_phpmyadmin') && !container.name.startsWith('wp_db') && !container.name.startsWith('wp_redis')) {
        const siteName = container.name.replace('wp_', '');
        const site = currentData.sites.find(s => s.name === siteName);
        if (site) {
          site.status = container.status.toLowerCase().includes('up') ? 'Running' : 'Stopped';
        }
      }
    });
  }
  updateDashboard();
  updateLiveStatus();
}

function handleOperationEvent(data) {
  const { type, operation } = data;
  if (type === 'start') {
    showOperationLoading(operation);
  } else if (type === 'success' || type === 'failure') {
    hideOperationLoading(operation);
    const msg = type === 'success'
      ? `"${operation}" completed`
      : `"${operation}" failed`;
    showNotification(msg, type === 'success' ? 'success' : 'danger');
    if (type === 'success') setTimeout(() => loadDashboard(), 1000);
  }
}

function showOperationLoading(operation) {
  document.querySelectorAll('.action-btn, .action-chip, .toolbar-btn').forEach(btn => {
    if (btn.onclick && btn.onclick.toString().includes(operation)) {
      btn.disabled = true;
      btn.dataset.originalText = btn.innerHTML;
      btn.innerHTML = '<div class="spinner" style="width:16px;height:16px;border-width:2px;margin:0"></div>';
    }
  });
}

function hideOperationLoading() {
  document.querySelectorAll('[disabled]').forEach(btn => {
    if (btn.dataset.originalText) {
      btn.innerHTML = btn.dataset.originalText;
      btn.disabled = false;
      delete btn.dataset.originalText;
    }
  });
}

window.addEventListener('beforeunload', () => {
  if (socket) socket.disconnect();
});

let lastUpdateTime = null;

document.addEventListener('DOMContentLoaded', () => {
  loadDashboard();
  initWebSocket();
  initAutoRefresh();
  initKeyboardShortcuts();
  initSiteFilters();
  initScrollReveal();
  initTabs();
  initDropdownDismiss();
  initParticles();
  initCounters();
  initSiteFlyout();
  document.getElementById('refreshBtn').addEventListener('click', loadDashboard);
});

function initScrollReveal() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.05, rootMargin: '0px 0px -40px 0px' });
  document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
}

function initTabs() {
  document.querySelectorAll('.tab-pill').forEach(pill => {
    pill.addEventListener('click', () => {
      const tab = pill.dataset.tab;
      document.querySelectorAll('.tab-pill').forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
      const panel = document.getElementById(`panel-${tab}`);
      if (panel) panel.classList.add('active');
      if (tab === 'activity') loadActivity();
      panel.querySelectorAll('.reveal').forEach(el => el.classList.add('visible'));
    });
  });
}

function initDropdownDismiss() {
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.dropdown-container')) {
      document.querySelectorAll('.dropdown-menu.open').forEach(m => m.classList.remove('open'));
    }
  });
}

function toggleDropdown(event, name) {
  event.stopPropagation();
  const menu = document.getElementById(`dropdown-${name}`);
  if (!menu) return;
  const isOpen = menu.classList.contains('open');
  document.querySelectorAll('.dropdown-menu.open').forEach(m => m.classList.remove('open'));
  if (!isOpen) menu.classList.add('open');
}

function openModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.add('open');
}

function closeModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.remove('open');
}

async function loadDashboard() {
  try {
    showLoading();
    const response = await fetch('/api/sites');
    const data = await response.json();
    if (data.success) {
      currentData = data;
      updateDashboard();
      updateLiveStatus();
      updateLastUpdateTime();
      setTimeout(initScrollReveal, 50);
    } else {
      showError('Failed to load dashboard');
    }
    hideLoading();
  } catch (error) {
    console.error('Error loading dashboard:', error);
    showError('Network error');
    hideLoading();
  }
}

function initAutoRefresh() {}

function updateLastUpdateTime() {
  const now = new Date().toLocaleTimeString();
  const el = document.getElementById('lastUpdateTime');
  const display = document.getElementById('lastUpdateDisplay');
  if (el) el.textContent = now;
  if (display) display.textContent = now;
}

function updateLiveStatus() {
  const running = currentData.sites.filter(s => s.status && s.status.toLowerCase() === 'running').length;
  const stopped = currentData.sites.filter(s => s.status && s.status.toLowerCase() === 'stopped').length;
  const services = currentData.services.filter(s => s.status && s.status.toLowerCase() === 'running').length;
  const total = currentData.sites.length;

  const el = (id) => document.getElementById(id);
  if (el('liveRunning')) el('liveRunning').textContent = running;
  if (el('liveStopped')) el('liveStopped').textContent = stopped;
  if (el('liveServices')) el('liveServices').textContent = services;
  if (el('totalSitesCount')) el('totalSitesCount').textContent = total;
  if (el('runningSitesCount')) el('runningSitesCount').textContent = running;
  if (el('servicesCount')) el('servicesCount').textContent = services;
}

function initKeyboardShortcuts() {
  document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
    switch(e.key.toLowerCase()) {
      case 'r':
        if (!e.ctrlKey && !e.metaKey) { loadDashboard(); showNotification('Refreshing...', 'info'); }
        break;
      case '?':
        showNotification('R:Refresh | 1-6:Tabs | Enter:Execute', 'info');
        break;
      case '1': document.querySelector('[data-tab="dashboard"]')?.click(); break;
      case '2': document.querySelector('[data-tab="sites"]')?.click(); break;
      case '3': document.querySelector('[data-tab="services"]')?.click(); break;
      case '4': document.querySelector('[data-tab="frontend"]')?.click(); break;
      case '5': document.querySelector('[data-tab="terminal"]')?.click(); break;
      case '6': document.querySelector('[data-tab="activity"]')?.click(); break;
    }
  });
}

async function loadActivity() {
  try {
    const tbody = document.getElementById('activityTableBody');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="4" class="center"><div class="spinner" style="width:16px;height:16px;border-width:2px;margin:0 auto"></div> Loading...</td></tr>';
    const response = await fetch('/api/activity?limit=50');
    const data = await response.json();
    if (data.success && data.activities && data.activities.length > 0) {
      tbody.innerHTML = data.activities.map(a => `<tr>
        <td class="muted" style="font-size:0.8125rem">${escapeHtml(a.timestamp)}</td>
        <td><span class="type-badge" style="background:${getActionColor(a.action)};color:white">${escapeHtml(a.action)}</span></td>
        <td><strong>${escapeHtml(a.site)}</strong></td>
        <td style="font-size:0.8125rem;color:var(--text-secondary)">${escapeHtml(a.details)}</td>
      </tr>`).join('');
    } else {
      tbody.innerHTML = '<tr><td colspan="4" class="center muted">No activity</td></tr>';
    }
  } catch (error) {
    const tbody = document.getElementById('activityTableBody');
    if (tbody) tbody.innerHTML = '<tr><td colspan="4" class="center" style="color:var(--danger)">Failed to load</td></tr>';
  }
}

function getActionColor(action) {
  const colors = { 'CREATE': 'var(--success)', 'START': 'var(--accent)', 'STOP': 'var(--warning)', 'EDIT': '#0ea5e9', 'REMOVE': 'var(--danger)', 'BACKUP': 'var(--text-secondary)', 'RESTORE': '#0f0f0f' };
  return colors[action] || 'var(--text-secondary)';
}

function updateDashboard() {
  const runningSites = currentData.sites.filter(s => s.status && s.status.toLowerCase() === 'running');
  renderSites();
  const el = document.getElementById('runningSitesCount');
  if (el) el.textContent = runningSites.length;
  setTimeout(() => {
    const activePanel = document.querySelector('.tab-panel.active');
    if (activePanel) {
      activePanel.querySelectorAll('.reveal').forEach(el => el.classList.add('visible'));
    }
    initScrollReveal();
  }, 50);
}

function initSiteFilters() {
  ['siteSearch', 'siteStatusFilter', 'siteSort'].forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      el.addEventListener('input', applySiteFilters);
      el.addEventListener('change', applySiteFilters);
    }
  });
}

function resetSiteFilters() {
  const s = (id) => document.getElementById(id);
  if (s('siteSearch')) s('siteSearch').value = '';
  if (s('siteStatusFilter')) s('siteStatusFilter').value = 'all';
  if (s('siteSort')) s('siteSort').value = 'name-asc';
  applySiteFilters();
}

function sortSites(sites) {
  const sort = document.getElementById('siteSort')?.value || 'name-asc';
  const sorted = [...sites];
  sorted.sort((a, b) => {
    if (sort === 'name-desc') return String(b.name || '').localeCompare(String(a.name || ''));
    if (sort === 'status') return String(a.status || '').localeCompare(String(b.status || '')) || String(a.name || '').localeCompare(String(b.name || ''));
    if (sort === 'php') return String(a.phpVersion || '').localeCompare(String(b.phpVersion || '')) || String(a.name || '').localeCompare(String(b.name || ''));
    return String(a.name || '').localeCompare(String(b.name || ''));
  });
  return sorted;
}

function renderSites() {
  const grid = document.getElementById('sitesGrid');
  if (!grid || !Array.isArray(currentData.sites)) return;
  grid.innerHTML = sortSites(currentData.sites).map(renderSiteCard).join('');
  applySiteFilters();
}

function renderSiteCard(site) {
  const name = escapeHtml(site.name || '');
  const status = escapeHtml(site.status || 'Stopped');
  const statusClass = String(site.status || '').toLowerCase() === 'running' ? 'live' : 'down';
  const localUrl = site.localUrl ? escapeHtml(site.localUrl) : '';
  const phpVersion = escapeHtml(site.phpVersion || '');

  const urlMarkup = localUrl ? `
            <div class="site-meta">
              <i class="ph-light ph-link"></i>
              <a href="${localUrl}" target="_blank" rel="noopener">${localUrl}</a>
            </div>
            <div class="site-actions">
              <a href="${localUrl}" target="_blank" rel="noopener" class="action-chip small">
                <i class="ph-light ph-arrow-square-out"></i> Open
              </a>
              <button class="action-chip small" onclick="checkSiteHealth('${name}')">
                <i class="ph-light ph-heartbeat"></i> Health
              </button>
            </div>
            <div id="health-${name}" class="health-result" style="display:none">
              <span class="health-text"></span>
            </div>` : `
            <div class="site-meta muted">
              <i class="ph-light ph-info"></i>
              <span>Not configured</span>
            </div>`;

  return `<div class="site-card double-bezel reveal" data-site-name="${name}" data-site-status="${status}" data-site-php="${phpVersion}" data-site-url="${localUrl}">
        <div class="shell">
          <div class="inner">
            <div class="site-card-top">
              <h3 class="site-name">${name}</h3>
              <span class="status-tag ${statusClass}">
                <span class="status-tag-dot"></span>
                ${status}
              </span>
            </div>
            ${urlMarkup}
            <div class="site-toolbar">
              <div class="toolbar-group">
                <button class="toolbar-btn" onclick="siteAction('start','${name}')" title="Start ${name}">
                  <i class="ph-light ph-play"></i>
                  <span>Start</span>
                </button>
                <button class="toolbar-btn" onclick="siteAction('stop','${name}')" title="Stop ${name}">
                  <i class="ph-light ph-stop"></i>
                  <span>Stop</span>
                </button>
                <button class="toolbar-btn" onclick="siteAction('restart','${name}')" title="Restart ${name}">
                  <i class="ph-light ph-arrows-clockwise"></i>
                  <span>Restart</span>
                </button>
                <button class="toolbar-btn" onclick="runChecksForSite('${name}')" title="Run checks on ${name}">
                  <i class="ph-light ph-clipboard-text"></i>
                  <span>Check</span>
                </button>
                <button class="toolbar-btn" onclick="siteAction('backup','${name}')" title="Backup ${name}">
                  <i class="ph-light ph-download"></i>
                  <span>Backup</span>
                </button>
              </div>
              <div class="dropdown-container">
                <button class="toolbar-btn" onclick="toggleDropdown(event, '${name}')" title="More actions for ${name}">
                  <i class="ph-light ph-dots-three-vertical"></i>
                  <span>More</span>
                </button>
                <div class="dropdown-menu" id="dropdown-${name}">
                  <button onclick="siteAction('info','${name}')"><i class="ph-light ph-info"></i>Info</button>
                  <button onclick="siteAction('url','${name}')"><i class="ph-light ph-link"></i>URL</button>
                  <button onclick="siteAction('logs','${name}')"><i class="ph-light ph-terminal"></i>Logs</button>
                  <button onclick="siteAction('edit','${name}')"><i class="ph-light ph-pencil"></i>Edit</button>
                  <div class="dropdown-divider"></div>
                  <button onclick="siteAction('export-db','${name}')"><i class="ph-light ph-database-export"></i>Export DB</button>
                  <button onclick="siteAction('import-db','${name}')"><i class="ph-light ph-database-import"></i>Import DB</button>
                  <button onclick="siteAction('restore','${name}')"><i class="ph-light ph-arrow-counter-clockwise"></i>Restore</button>
                  <div class="dropdown-divider"></div>
                  <button onclick="siteAction('clone','${name}')"><i class="ph-light ph-copy"></i>Clone</button>
                  <button class="warning" onclick="siteAction('reset','${name}')"><i class="ph-light ph-warning"></i>Reset</button>
                  <button class="danger" onclick="siteAction('remove','${name}')"><i class="ph-light ph-trash"></i>Delete</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>`;
}

function applySiteFilters() {
  const searchTerm = (document.getElementById('siteSearch')?.value || '').trim().toLowerCase();
  const statusFilter = document.getElementById('siteStatusFilter')?.value || 'all';
  const cards = Array.from(document.querySelectorAll('.site-card'));
  let visibleCount = 0;
  cards.forEach(card => {
    const haystack = [card.dataset.siteName, card.dataset.siteStatus, card.dataset.sitePhp, card.dataset.siteUrl].join(' ').toLowerCase();
    const status = (card.dataset.siteStatus || '').toLowerCase();
    const matchesSearch = !searchTerm || haystack.includes(searchTerm);
    const matchesStatus = statusFilter === 'all' || status === statusFilter;
    const visible = matchesSearch && matchesStatus;
    card.style.display = visible ? '' : 'none';
    if (visible) visibleCount += 1;
  });
  const empty = document.getElementById('sitesEmptyState');
  if (empty) empty.style.display = visibleCount > 0 ? 'none' : '';
}

async function quickAction(action) {
  try {
    showLoading();
    const response = await fetch(`/api/environment/${action}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    });
    const data = await response.json();
    if (data.success) {
      showNotification(`"${action}" done`, 'success');
    } else {
      showNotification(`"${action}" failed: ${data.error?.message || data.error || 'Unknown'}`, 'danger');
    }
    await loadDashboard();
    hideLoading();
  } catch (error) {
    showNotification('Network error', 'danger');
    hideLoading();
  }
}

async function siteAction(action, siteName) {
  if ((action === 'remove' || action === 'delete') && !confirm(`Delete "${siteName}"? Cannot undo.`)) return;
  if (action === 'reset' && !confirm(`Reset "${siteName}" to fresh install? All data lost.`)) return;

  let endpoint, body;
  switch (action) {
    case 'restart': endpoint = '/api/sites/restart'; body = { siteName }; break;
    case 'url': endpoint = '/api/sites/url'; body = { siteName }; break;
    case 'logs': endpoint = '/api/sites/logs'; body = { siteName }; break;
    case 'backup': endpoint = '/api/sites/backup'; body = { siteName }; break;
    case 'restore': openSiteWorkflowModal('restore', siteName); return;
    case 'export-db': endpoint = '/api/sites/export-db'; body = { siteName }; break;
    case 'import-db': openSiteWorkflowModal('import-db', siteName); return;
    case 'edit': openSiteWorkflowModal('edit', siteName); return;
    case 'remove': case 'delete': endpoint = `/api/sites/${action}`; body = { siteName }; break;
    case 'clone': openSiteWorkflowModal('clone', siteName); return;
    case 'reset': endpoint = '/api/sites/reset'; body = { siteName }; break;
    default: endpoint = `/api/sites/${action}`; body = { siteName };
  }

  try {
    showLoading();
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    const data = await response.json();
    if (data.success) {
      if (['info', 'url', 'logs'].includes(action) && data.output) {
        showActionOutput(action, siteName, data.output);
      } else {
        showNotification(`"${action} ${siteName}" done`, 'success');
      }
    } else {
      showNotification(`"${action} ${siteName}" failed: ${data.error?.message || data.error || 'Unknown'}`, 'danger');
    }
    await loadDashboard();
    hideLoading();
  } catch (error) {
    showNotification('Network error', 'danger');
    hideLoading();
  }
}

function getWorkflowConfig(action, siteName) {
  return {
    'restore': {
      title: `Restore ${siteName}`,
      fields: [{ id: 'backupFile', label: 'Backup file', placeholder: 'backups/site.tar.gz', type: 'text' }],
      endpoint: '/api/sites/restore',
      buildBody: (v) => ({ siteName, backupFile: v.backupFile })
    },
    'import-db': {
      title: `Import DB — ${siteName}`,
      fields: [{ id: 'dumpFile', label: 'SQL dump', placeholder: 'backups/site.sql', type: 'text' }],
      endpoint: '/api/sites/import-db',
      buildBody: (v) => ({ siteName, dumpFile: v.dumpFile })
    },
    'edit': {
      title: `Edit ${siteName}`,
      fields: [{ id: 'phpVersion', label: 'PHP version', type: 'select', options: ['8.3', '8.2', '8.1', '8.0', '7.4'] }],
      endpoint: '/api/sites/edit',
      buildBody: (v) => ({ siteName, phpVersion: v.phpVersion })
    },
    'clone': {
      title: `Clone ${siteName}`,
      fields: [{ id: 'destName', label: 'New site name', placeholder: `${siteName}-copy`, type: 'text' }],
      endpoint: '/api/sites/clone',
      buildBody: (v) => ({ sourceName: siteName, destName: v.destName })
    }
  }[action];
}

function openSiteWorkflowModal(action, siteName) {
  const config = getWorkflowConfig(action, siteName);
  if (!config) return;

  const fields = config.fields.map(f => {
    if (f.type === 'select') {
      const opts = f.options.map(o => `<option value="${escapeHtml(o)}">${escapeHtml(o)}</option>`).join('');
      return `<div class="field-group">
        <label for="wf-${f.id}">${escapeHtml(f.label)}</label>
        <select id="wf-${f.id}" class="glass-select">${opts}</select>
      </div>`;
    }
    return `<div class="field-group">
      <label for="wf-${f.id}">${escapeHtml(f.label)}</label>
      <input type="${f.type}" id="wf-${f.id}" class="glass-input" placeholder="${escapeHtml(f.placeholder || '')}">
    </div>`;
  }).join('');

  const html = `<div class="modal-overlay open" id="workflowModal">
    <div class="modal-shell">
      <div class="modal-inner">
        <div class="modal-header">
          <h3><i class="ph-light ph-pencil"></i> ${escapeHtml(config.title)}</h3>
          <button class="modal-close" onclick="closeWorkflowModal()" aria-label="Close"><i class="ph-light ph-x"></i></button>
        </div>
        <div class="modal-body">
          <div id="wf-error" style="display:none;padding:0.75rem;border-radius:var(--radius-sm);background:rgba(239,68,68,0.1);color:var(--danger);font-size:0.8125rem;margin-bottom:1rem"></div>
          ${fields}
        </div>
        <div class="modal-footer">
          <button class="action-btn outline" onclick="closeWorkflowModal()"><span class="btn-inner">Cancel</span></button>
          <button class="action-btn primary" onclick="submitWorkflow('${action}','${siteName}')">
            <span class="btn-inner"><span>Run</span><span class="btn-icon-wrap"><i class="ph-light ph-arrow-right"></i></span></span>
          </button>
        </div>
      </div>
    </div>
  </div>`;

  const existing = document.getElementById('workflowModal');
  if (existing) existing.remove();
  document.body.insertAdjacentHTML('beforeend', html);
}

function closeWorkflowModal() {
  const el = document.getElementById('workflowModal');
  if (el) el.remove();
}

function validateWorkflowValues(action, values) {
  if (action === 'clone' && !/^[a-zA-Z][a-zA-Z0-9_-]*$/.test(values.destName || '')) {
    return 'Name must start with letter, alphanumeric/hyphens/underscores only';
  }
  if (['restore', 'import-db'].includes(action)) {
    const p = values.backupFile || values.dumpFile || '';
    if (!p || p.startsWith('/') || p.includes('..')) return 'Must be relative path inside project';
  }
  return null;
}

async function submitWorkflow(action, siteName) {
  const config = getWorkflowConfig(action, siteName);
  if (!config) return;
  const values = {};
  config.fields.forEach(f => { values[f.id] = document.getElementById(`wf-${f.id}`)?.value.trim(); });
  const error = validateWorkflowValues(action, values);
  const errorEl = document.getElementById('wf-error');
  if (error) {
    if (errorEl) { errorEl.textContent = error; errorEl.style.display = ''; }
    return;
  }
  try {
    showLoading();
    const response = await fetch(config.endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(config.buildBody(values))
    });
    const data = await response.json();
    hideLoading();
    if (data.success) {
      closeWorkflowModal();
      showNotification(`"${action} ${siteName}" done`, 'success');
      await loadDashboard();
    } else {
      if (errorEl) { errorEl.textContent = data.error?.message || data.error || 'Unknown'; errorEl.style.display = ''; }
    }
  } catch (error) {
    hideLoading();
    if (errorEl) { errorEl.textContent = 'Network error'; errorEl.style.display = ''; }
  }
}

async function createSite() {
  const siteName = document.getElementById('siteName').value.trim();
  const phpVersion = document.getElementById('phpVersion')?.value || '8.3';
  if (!siteName) { showNotification('Enter a site name', 'warning'); return; }
  if (!/^[a-zA-Z][a-zA-Z0-9_-]*$/.test(siteName)) {
    showNotification('Name: start with letter, alphanumeric/hyphens/underscores', 'warning');
    return;
  }
  try {
    showLoading();
    const response = await fetch('/api/sites/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ siteName, phpVersion })
    });
    const data = await response.json();
    if (data.success && (!data.exitCode || data.exitCode === 0)) {
      showNotification(`"${siteName}" created`, 'success');
      document.getElementById('siteName').value = '';
      closeModal('createSiteModal');
    } else {
      let msg = 'Unknown error';
      if (data.output) {
        const lines = data.output.split('\n').filter(l => l.trim());
        if (lines.length) msg = lines[lines.length - 1];
      } else if (data.error) { msg = data.error; }
      showNotification(`Create failed: ${msg}`, 'danger');
    }
    await loadDashboard();
    hideLoading();
  } catch (error) {
    showNotification('Network error', 'danger');
    hideLoading();
  }
}

async function checkSiteHealth(siteName) {
  const healthEl = document.getElementById(`health-${siteName}`);
  const statusEl = healthEl?.querySelector('.health-text');
  if (!healthEl || !statusEl) return;
  healthEl.style.display = 'block';
  statusEl.innerHTML = '<span style="color:var(--accent)">Checking...</span>';
  try {
    const response = await fetch(`/api/health/${siteName}`);
    const data = await response.json();
    if (data.success && data.healthy) {
      statusEl.innerHTML = `<span style="color:var(--success)">Healthy (${data.responseTime})</span>`;
    } else if (data.success && !data.healthy) {
      statusEl.innerHTML = `<span style="color:var(--warning)">${data.reason || data.error || 'Unhealthy'}</span>`;
    } else {
      statusEl.innerHTML = `<span style="color:var(--danger)">Error</span>`;
    }
  } catch (error) {
    statusEl.innerHTML = `<span style="color:var(--danger)">${error.message}</span>`;
  }
}

async function frontendAction(action) {
  try {
    showLoading();
    const response = await fetch(`/api/frontend/${action}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    });
    const data = await response.json();
    if (data.success) {
      showNotification(`Frontend "${action}" done`, 'success');
      updateFrontendStatus(action, data.output);
    } else {
      showNotification(`Frontend "${action}" failed: ${data.error?.message || data.error || 'Unknown'}`, 'danger');
    }
    hideLoading();
  } catch (error) {
    showNotification('Network error', 'danger');
    hideLoading();
  }
}

function updateFrontendStatus(action, output) {
  const el = document.getElementById('frontendStatus');
  if (!el) return;
  if (action === 'status') el.textContent = output || 'No output';
  else if (action === 'stop') el.innerHTML = '<span style="color:var(--danger)">Stopped</span>';
  else if (action === 'start' || action === 'restart') el.innerHTML = '<span style="color:var(--success)">Running — localhost:8500</span>';
}

async function executeCommand() {
  const input = document.getElementById('terminalInput');
  const output = document.getElementById('terminalOutput');
  const command = input.value.trim();
  if (!command) return;
  const line = document.createElement('div');
  line.className = 'terminal-line';
  line.innerHTML = `<span style="color:var(--accent);font-weight:700">$</span> ${escapeHtml(command)}`;
  output.appendChild(line);
  input.value = '';
  try {
    const parts = command.split(' ');
    const action = parts[0];
    const args = parts.slice(1);
    const siteActions = ['start','stop','restart','remove','delete','rm','info','url','logs','backup','restore','edit','clone','reset','export-db','import-db','create','check'];
    const envActions = ['start','stop','restart','status','logs','clean','check','health','cache','cache-clear','search-replace','update','update-core','install'];
    let endpoint, body;
    if (args.length > 0 && siteActions.includes(action)) {
      endpoint = '/api/sites/' + action;
      body = { siteName: args[0] };
    } else if (envActions.includes(action)) {
      endpoint = '/api/environment/' + action;
      body = { args };
    } else {
      const d = document.createElement('div');
      d.className = 'terminal-line dim';
      d.textContent = `Unknown: ${action}. Try 'help'`;
      output.appendChild(d);
      output.scrollTop = output.scrollHeight;
      return;
    }
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    const data = await response.json();
    if (data.success && data.output) {
      const d = document.createElement('div');
      d.className = 'terminal-line';
      d.style.whiteSpace = 'pre-wrap';
      d.textContent = data.output;
      output.appendChild(d);
    } else {
      const d = document.createElement('div');
      d.className = 'terminal-line';
      d.style.color = 'var(--danger)';
      d.textContent = `Error: ${data.error?.message || data.error || 'Unknown'}`;
      output.appendChild(d);
    }
  } catch (error) {
    const d = document.createElement('div');
    d.className = 'terminal-line';
    d.style.color = 'var(--danger)';
    d.textContent = 'Network error';
    output.appendChild(d);
  }
  output.scrollTop = output.scrollHeight;
}

function escapeHtml(text) {
  const d = document.createElement('div');
  d.textContent = text;
  return d.innerHTML;
}

function showLoading() {
  const btn = document.getElementById('refreshBtn');
  if (!btn) return;
  btn.dataset.originalContent = btn.innerHTML;
  btn.classList.add('loading');
  btn.innerHTML = '<i class="ph-light ph-arrows-clockwise"></i>';
}

function hideLoading() {
  const btn = document.getElementById('refreshBtn');
  if (!btn) return;
  btn.classList.remove('loading');
  if (btn.dataset.originalContent) {
    btn.innerHTML = btn.dataset.originalContent;
    delete btn.dataset.originalContent;
  } else {
    btn.innerHTML = '<i class="ph-light ph-arrows-clockwise"></i> <span>Refresh</span>';
  }
}

function showNotification(message, type = 'info') {
  const existing = document.querySelector('.notification-toast');
  if (existing) existing.remove();
  const toast = document.createElement('div');
  toast.className = `notification-toast ${type}`;
  toast.innerHTML = `
    <span>${escapeHtml(message)}</span>
    <button class="toast-close" onclick="this.parentElement.remove()"><i class="ph-light ph-x"></i></button>
  `;
  document.body.appendChild(toast);
  setTimeout(() => { if (toast.parentNode) toast.remove(); }, 5000);
}

function showActionOutput(action, siteName, output) {
  const clean = output.replace(/\x1b\[[0-9;]*m/g, '').replace(/[\u2705\u274c\u2139\ufe0f\u26a0\ufe0f]| - /g, '').trim();
  const html = `<div class="modal-overlay open" id="actionOutputModal">
    <div class="modal-shell wide">
      <div class="modal-inner">
        <div class="modal-header">
          <h3><i class="ph-light ph-info"></i> ${siteName}</h3>
          <button class="modal-close" onclick="closeActionOutputModal()"><i class="ph-light ph-x"></i></button>
        </div>
        <div class="modal-body">
          <pre class="code-block">${escapeHtml(clean)}</pre>
        </div>
        <div class="modal-footer">
          <button class="action-btn primary" onclick="closeActionOutputModal()"><span class="btn-inner">Close</span></button>
        </div>
      </div>
    </div>
  </div>`;
  const existing = document.getElementById('actionOutputModal');
  if (existing) existing.remove();
  document.body.insertAdjacentHTML('beforeend', html);
}

function closeActionOutputModal() {
  const el = document.getElementById('actionOutputModal');
  if (el) el.remove();
}

function showError(message) {
  hideLoading();
  showNotification(message, 'danger');
}

async function runChecksForSite(siteName) {
  try {
    showLoading();
    const response = await fetch('/api/sites/check', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ siteName })
    });
    const data = await response.json();
    hideLoading();
    if (data.success) {
      displayCheckResults(data.output || data.data, siteName);
    } else {
      showNotification(`Check failed: ${data.error?.message || data.error || 'Unknown'}`, 'danger');
    }
  } catch (error) {
    hideLoading();
    showNotification('Network error', 'danger');
  }
}

async function runAllChecks() {
  try {
    showLoading();
    const response = await fetch('/api/environment/check', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    });
    const data = await response.json();
    hideLoading();
    if (data.success) {
      displayCheckResults(data.output || data.data, 'All Sites');
    } else {
      showNotification(`Check failed: ${data.error?.message || data.error || 'Unknown'}`, 'danger');
    }
  } catch (error) {
    hideLoading();
    showNotification('Network error', 'danger');
  }
}

function displayCheckResults(results, siteName) {
  openModal('checkResultsModal');
  const progress = document.getElementById('checkProgress');
  const output = document.getElementById('checkOutput');
  progress.style.display = 'none';
  output.style.display = '';
  const pre = output.querySelector('.code-block');
  if (typeof results === 'string') {
    pre.textContent = results || 'No output';
  } else if (results && results.results) {
    let text = '';
    results.results.forEach(tool => {
      text += `=== ${tool.tool} ===\nFiles: ${tool.filesScanned}\nErrors: ${tool.totals.errors}, Warnings: ${tool.totals.warnings}\n`;
      if (tool.errors.length) { text += '\nErrors:\n'; tool.errors.forEach(e => { text += `  ${e.file}:${e.line} - ${e.message}\n`; }); }
      if (tool.warnings.length) { text += '\nWarnings:\n'; tool.warnings.forEach(w => { text += `  ${w.file}:${w.line} - ${w.message}\n`; }); }
      text += '\n';
    });
    pre.textContent = text;
  } else {
    pre.textContent = JSON.stringify(results, null, 2);
  }
}

function initParticles() {
  const canvas = document.getElementById('particlesCanvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  let particles = [];
  let mouse = { x: -1000, y: -1000 };
  let frame;

  function resize() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  }

  window.addEventListener('resize', resize);
  document.addEventListener('mousemove', e => {
    mouse.x = e.clientX;
    mouse.y = e.clientY;
  });
  document.addEventListener('mouseleave', () => {
    mouse.x = -1000;
    mouse.y = -1000;
  });

  resize();

  const count = Math.min(70, Math.floor(canvas.width * 0.035));
  const maxDist = 160;
  const speed = 0.25;

  for (let i = 0; i < count; i++) {
    particles.push({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      vx: (Math.random() - 0.5) * speed,
      vy: (Math.random() - 0.5) * speed,
      r: Math.random() * 1.5 + 0.5
    });
  }

  function getAccent() {
    const isLight = document.documentElement.getAttribute('data-theme') === 'light';
    return isLight ? '0, 148, 255' : '0, 229, 255';
  }

  function animate() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const accent = getAccent();

    for (let i = 0; i < particles.length; i++) {
      const p = particles[i];

      const dx = p.x - mouse.x;
      const dy = p.y - mouse.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < 180) {
        p.vx += (dx / Math.max(dist, 1)) * 0.08;
        p.vy += (dy / Math.max(dist, 1)) * 0.08;
      }

      p.vx *= 0.98;
      p.vy *= 0.98;

      p.x += p.vx;
      p.y += p.vy;

      if (p.x < -20) p.x = canvas.width + 20;
      if (p.x > canvas.width + 20) p.x = -20;
      if (p.y < -20) p.y = canvas.height + 20;
      if (p.y > canvas.height + 20) p.y = -20;

      for (let j = i + 1; j < particles.length; j++) {
        const p2 = particles[j];
        const dx = p.x - p2.x;
        const dy = p.y - p2.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < maxDist) {
          ctx.beginPath();
          ctx.moveTo(p.x, p.y);
          ctx.lineTo(p2.x, p2.y);
          const alpha = (1 - dist / maxDist) * 0.12;
          ctx.strokeStyle = `rgba(${accent}, ${alpha})`;
          ctx.lineWidth = 0.5;
          ctx.stroke();
        }
      }

      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(${accent}, 0.5)`;
      ctx.fill();
    }

    frame = requestAnimationFrame(animate);
  }

  animate();
}

function initCounters() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const el = entry.target;
        const target = parseInt(el.textContent, 10);
        if (isNaN(target) || target === 0) {
          observer.unobserve(el);
          return;
        }
        let current = 0;
        const duration = Math.min(1200, Math.max(400, target * 30));
        const start = performance.now();
        el.textContent = '0';

        function update(now) {
          const elapsed = now - start;
          const progress = Math.min(elapsed / duration, 1);
          const eased = 1 - Math.pow(1 - progress, 3);
          current = Math.round(eased * target);
          el.textContent = current;
          if (progress < 1) {
            requestAnimationFrame(update);
          } else {
            el.textContent = target;
            observer.unobserve(el);
          }
        }

        requestAnimationFrame(update);
      }
    });
  }, { threshold: 0.5 });

  document.querySelectorAll('.stat-value').forEach(el => observer.observe(el));
}

/* --- Site Detail Flyout --- */
function initSiteFlyout() {
  document.getElementById('sitesGrid').addEventListener('click', (e) => {
    const card = e.target.closest('.site-card');
    if (!card) return;
    if (e.target.closest('button, a, .toolbar-btn, .action-chip, .dropdown-container, .dropdown-menu, .site-meta a')) return;
    openSiteFlyout(card.dataset.siteName);
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeSiteFlyout();
  });
}

function openSiteFlyout(siteName) {
  const site = currentData.sites.find(s => s.name === siteName);
  if (!site) return;
  flyoutSite = site;

  const nameEl = document.getElementById('flyoutSiteName');
  const statusEl = document.getElementById('flyoutSiteStatus');
  const statusTextEl = document.getElementById('flyoutSiteStatusText');
  const urlEl = document.getElementById('flyoutSiteUrl');
  const phpEl = document.getElementById('flyoutSitePhp');
  const portEl = document.getElementById('flyoutSitePort');

  if (nameEl) nameEl.textContent = site.name;
  if (statusTextEl) statusTextEl.textContent = site.status || 'Stopped';
  if (statusEl) {
    const isRunning = String(site.status || '').toLowerCase() === 'running';
    statusEl.className = `status-tag ${isRunning ? 'live' : 'down'}`;
    const dot = statusEl.querySelector('.status-tag-dot');
    if (dot) dot.style.display = '';
  }
  if (urlEl) {
    const url = site.localUrl || '#';
    urlEl.href = url;
    urlEl.textContent = url !== '#' ? url : 'Not configured';
  }
  if (phpEl) phpEl.textContent = site.phpVersion || '--';
  if (portEl) portEl.textContent = site.port || '--';

  flyoutHealthCheck();

  document.getElementById('siteFlyoutOverlay').classList.add('open');
  document.getElementById('siteFlyout').classList.add('open');
  document.body.style.overflow = 'hidden';
}

function closeSiteFlyout() {
  document.getElementById('siteFlyoutOverlay').classList.remove('open');
  document.getElementById('siteFlyout').classList.remove('open');
  document.body.style.overflow = '';
}

async function flyoutHealthCheck() {
  const name = flyoutSite?.name;
  if (!name) return;
  const dot = document.getElementById('flyoutHealthDot');
  const text = document.getElementById('flyoutHealthText');
  if (dot) dot.className = 'pulse-dot';
  if (text) text.textContent = 'Checking...';

  try {
    const response = await fetch(`/api/health/${name}`);
    const data = await response.json();
    if (dot) {
      dot.className = 'dot';
      dot.style.color = data.healthy ? 'var(--success)' : 'var(--warning)';
      dot.style.background = data.healthy ? 'var(--success)' : 'var(--warning)';
    }
    if (text) {
      text.textContent = data.healthy
        ? `Healthy (${data.responseTime || 'OK'})`
        : (data.reason || 'Unhealthy');
    }
  } catch (e) {
    if (dot) { dot.className = 'dot'; dot.style.color = 'var(--danger)'; dot.style.background = 'var(--danger)'; }
    if (text) text.textContent = 'Error checking health';
  }
}

async function flyoutAction(action) {
  const name = flyoutSite?.name;
  if (!name) return;

  if (['start', 'stop', 'info', 'url', 'logs', 'check', 'remove', 'delete'].includes(action)) {
    await siteAction(action, name);
  } else if (action === 'restart') {
    await siteAction('restart', name);
  } else if (action === 'backup') {
    await siteAction('backup', name);
  } else if (action === 'export-db') {
    await siteAction('export-db', name);
  } else if (action === 'import-db') {
    await siteAction('import-db', name);
  } else if (action === 'restore') {
    await siteAction('restore', name);
  } else if (action === 'clone') {
    await siteAction('clone', name);
  } else if (action === 'reset') {
    await siteAction('reset', name);
  } else if (['rest', 'xdebug', 'repair'].includes(action)) {
    try {
      showLoading();
      const response = await fetch(`/api/sites/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ siteName: name })
      });
      const data = await response.json();
      hideLoading();
      if (data.success && data.output) {
        showActionOutput(action, name, data.output);
      } else if (data.success) {
        showNotification(`"${action} ${name}" done`, 'success');
      } else {
        showNotification(`"${action} ${name}" failed: ${data.error?.message || data.error || 'Unknown'}`, 'danger');
      }
    } catch (e) {
      hideLoading();
      showNotification('Network error', 'danger');
    }
  }

  setTimeout(async () => {
    await loadDashboard();
    if (flyoutSite) openSiteFlyout(flyoutSite.name);
  }, 1500);
}

function flyoutEditPhp() {
  const name = flyoutSite?.name;
  if (name) openSiteWorkflowModal('edit', name);
}

async function flyoutUpdateCore() {
  const name = flyoutSite?.name;
  if (!name) return;
  try {
    showLoading();
    const response = await fetch('/api/environment/update', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ args: [name] })
    });
    const data = await response.json();
    hideLoading();
    if (data.success) {
      showNotification(`Update "${name}" done`, 'success');
      setTimeout(() => loadDashboard(), 1000);
    } else {
      showNotification(`Update failed: ${data.error?.message || data.error || 'Unknown'}`, 'danger');
    }
  } catch (e) {
    hideLoading();
    showNotification('Network error', 'danger');
  }
}

async function flyoutClearCache() {
  const name = flyoutSite?.name;
  if (!name) return;
  try {
    showLoading();
    const response = await fetch('/api/environment/cache', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ args: [name] })
    });
    const data = await response.json();
    hideLoading();
    if (data.success) {
      showNotification(`Cache cleared for "${name}"`, 'success');
      setTimeout(() => loadDashboard(), 1000);
    } else {
      showNotification(`Cache clear failed: ${data.error?.message || data.error || 'Unknown'}`, 'danger');
    }
  } catch (e) {
    hideLoading();
    showNotification('Network error', 'danger');
  }
}

function flyoutSearchReplace() {
  const name = flyoutSite?.name;
  if (!name) return;
  const search = prompt('Search for:');
  if (!search) return;
  const replace = prompt('Replace with:');
  if (replace === null) return;
  (async () => {
    try {
      showLoading();
      const response = await fetch('/api/environment/search-replace', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ args: [name, search, replace || ''] })
      });
      const data = await response.json();
      hideLoading();
      if (data.success) {
        showNotification(`Search/replace done for "${name}"`, 'success');
        setTimeout(() => loadDashboard(), 1000);
      } else {
        showNotification(`Search/replace failed: ${data.error?.message || data.error || 'Unknown'}`, 'danger');
      }
    } catch (e) {
      hideLoading();
      showNotification('Network error', 'danger');
    }
  })();
}

async function flyoutWpcli() {
  const name = flyoutSite?.name;
  const input = document.getElementById('flyoutWpcliInput');
  const command = input?.value?.trim();
  if (!name || !command) return;
  try {
    showLoading();
    const response = await fetch('/api/sites/wp-cli', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ siteName: name, command })
    });
    const data = await response.json();
    hideLoading();
    if (data.success && data.output) {
      showActionOutput('wp', `${name} — ${command}`, data.output);
      input.value = '';
    } else if (data.success) {
      showNotification(`WP-CLI done`, 'success');
      input.value = '';
    } else {
      showNotification(`WP-CLI failed: ${data.error?.message || data.error || 'Unknown'}`, 'danger');
    }
  } catch (e) {
    hideLoading();
    showNotification('Network error', 'danger');
  }
}

