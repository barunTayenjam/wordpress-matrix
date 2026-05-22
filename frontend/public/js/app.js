// Global variables
let currentData = {
  sites: [],
  services: []
};
let socket = null;

// Theme toggle
function toggleTheme() {
  const html = document.documentElement;
  const icon = document.getElementById('theme-icon');
  const current = html.getAttribute('data-theme');
  const next = current === 'dark' ? 'light' : 'dark';
  
  html.setAttribute('data-theme', next);
  localStorage.setItem('theme', next);
  
  if (next === 'dark') {
    icon.className = 'bi bi-sun';
  } else {
    icon.className = 'bi bi-moon-stars';
  }
}

// Load saved theme
function loadTheme() {
  const saved = localStorage.getItem('theme') || 'light';
  if (saved === 'dark') {
    document.documentElement.setAttribute('data-theme', 'dark');
    const icon = document.getElementById('theme-icon');
    if (icon) icon.className = 'bi bi-sun';
  }
}

// Initialize theme on load
document.addEventListener('DOMContentLoaded', loadTheme);

// Initialize WebSocket connection
function initWebSocket() {
  const protocol = window.location.protocol === 'https:' ? 'https:' : 'http:';
  const socketUrl = `${protocol}//${window.location.host}`;
  
  socket = io(socketUrl);
  
  socket.on('connect', () => {
    console.log('[WebSocket] Connected to server');
  });
  
  socket.on('status.changed', (data) => {
    console.log('[WebSocket] Status changed received:', data);
    updateStatusFromWebSocket(data);
  });
  
  socket.on('site.operation', (data) => {
    console.log('[WebSocket] Operation event:', data);
    handleOperationEvent(data);
  });
  
  socket.on('disconnect', () => {
    console.log('[WebSocket] Disconnected from server');
    setTimeout(initWebSocket, 5000);
  });
}

function updateStatusFromWebSocket(data) {
  if (data.containers && Array.isArray(data.containers)) {
    data.containers.forEach(container => {
      // Only process WordPress site containers (wp_sitename format)
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
    
    const status = type === 'success' ? 'success' : 'danger';
    const message = type === 'success' 
      ? `Operation "${operation}" completed successfully`
      : `Operation "${operation}" failed`;
    showNotification(message, status);
    
    if (type === 'success') {
      setTimeout(() => loadDashboard(), 1000);
    }
  }
}

function showOperationLoading(operation) {
  const buttons = document.querySelectorAll('.btn');
  buttons.forEach(btn => {
    if (btn.onclick && btn.onclick.toString().includes(operation)) {
      btn.disabled = true;
      btn.dataset.originalText = btn.innerHTML;
      btn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status"></span> Working...';
    }
  });
}

function hideOperationLoading(operation) {
  const buttons = document.querySelectorAll('.btn[disabled]');
  buttons.forEach(btn => {
    if (btn.dataset.originalText) {
      btn.innerHTML = btn.dataset.originalText;
      btn.disabled = false;
      delete btn.dataset.originalText;
    }
  });
}

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  if (socket) {
    socket.disconnect();
  }
});

// Initialize the application
let autoRefreshInterval = null;
let lastUpdateTime = null;

document.addEventListener('DOMContentLoaded', () => {
  loadDashboard();
  initWebSocket();
  initAutoRefresh();
  initKeyboardShortcuts();
  initSiteFilters();

  // Setup event listeners
  document.getElementById('refresh-btn').addEventListener('click', loadDashboard);

  // Let Bootstrap handle tab switching automatically
  // Setup tab switching for sidebar links since they use href="#" approach
  const sidebarTabs = document.querySelectorAll('.sidebar .nav-link[data-bs-toggle="tab"]');
  sidebarTabs.forEach(tab => {
    tab.addEventListener('click', (e) => {
      e.preventDefault();

      // Get the target from data-bs-target attribute
      const target = e.currentTarget.getAttribute('data-bs-target');

      // Remove active class from all sidebar nav links
      document.querySelectorAll('.sidebar .nav-link').forEach(link => {
        link.classList.remove('active');
      });

      // Add active class to clicked link
      e.currentTarget.classList.add('active');

      // Also activate the corresponding top tab
      const topTabButton = document.querySelector(`[data-bs-target="${target}"]`);
      if (topTabButton) {
        // Remove active class from all top tab buttons
        document.querySelectorAll('.nav-tabs .nav-link').forEach(link => {
          link.classList.remove('active');
        });

        // Add active class to the corresponding top tab
        topTabButton.classList.add('active');
      }

      // Show the target tab pane
      document.querySelectorAll('.tab-pane').forEach(pane => {
        pane.classList.remove('show', 'active');
      });

      const targetPane = document.querySelector(target);
      if (targetPane) {
        targetPane.classList.add('show', 'active');
      }
    });
  });
});

// Load dashboard data
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
      hideLoading();
    } else {
      showError('Failed to load dashboard data');
    }
  } catch (error) {
    console.error('Error loading dashboard:', error);
    showError('Network error while loading dashboard');
  }
}

function initAutoRefresh() {
  // Auto-refresh disabled - refresh on action instead
  // Uncomment below to enable auto-refresh:
  // if (autoRefreshInterval) clearInterval(autoRefreshInterval);
  // autoRefreshInterval = setInterval(() => {
  //   console.log('[Auto-refresh] Updating dashboard...');
  //   loadDashboard();
  // }, 30000);
}

function updateLastUpdateTime() {
  const now = new Date();
  const timeStr = now.toLocaleTimeString();
  const timeEl = document.getElementById('last-update-time');
  const displayEl = document.getElementById('last-update-display');
  if (timeEl) timeEl.textContent = timeStr;
  if (displayEl) displayEl.textContent = timeStr;
  lastUpdateTime = now;
}

function updateLiveStatus() {
  const running = currentData.sites.filter(s => s.status && s.status.toLowerCase() === 'running').length;
  const stopped = currentData.sites.filter(s => s.status && s.status.toLowerCase() === 'stopped').length;
  const services = currentData.services.filter(s => s.status && s.status.toLowerCase() === 'running').length;
  const total = currentData.sites.length;
  
  const liveRunning = document.getElementById('live-running');
  const liveStopped = document.getElementById('live-stopped');
  const liveServices = document.getElementById('live-services');
  const totalSites = document.getElementById('total-sites-count');
  
  if (liveRunning) liveRunning.textContent = running;
  if (liveStopped) liveStopped.textContent = stopped;
  if (liveServices) liveServices.textContent = services;
  if (totalSites) totalSites.textContent = total;
}

function initKeyboardShortcuts() {
  document.addEventListener('keydown', (e) => {
    // Don't trigger if typing in input fields
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
    
    switch(e.key.toLowerCase()) {
      case 'r':
        if (!e.ctrlKey && !e.metaKey) {
          loadDashboard();
          showNotification('Refreshing...', 'info');
        }
        break;
      case '?':
        showKeyboardShortcuts();
        break;
      case '1':
        document.getElementById('dashboard-tab')?.click();
        break;
      case '2':
        document.getElementById('sites-tab')?.click();
        break;
      case '3':
        document.getElementById('services-tab')?.click();
        break;
      case '4':
        document.getElementById('frontend-tab')?.click();
        break;
      case '5':
        document.getElementById('terminal-tab')?.click();
        break;
      case '6':
        document.getElementById('activity-tab')?.click();
        break;
    }
  });
}

function showKeyboardShortcuts() {
  const shortcuts = [
    'R: Refresh dashboard',
    '1-6: Switch tabs',
    '?: Show keyboard shortcuts',
    'Enter: Execute terminal command'
  ];
  showNotification(`Keyboard shortcuts: ${shortcuts.join(' | ')}`, 'info');
}

// Load activity log
async function loadActivity() {
  try {
    const tbody = document.getElementById('activity-table-body');
    if (!tbody) return;

    tbody.innerHTML = '<tr><td colspan="4" class="text-center"><div class="spinner-border spinner-border-sm me-2"></div>Loading...</td></tr>';

    const response = await fetch('/api/activity?limit=50');
    const data = await response.json();

    if (data.success && data.activities && data.activities.length > 0) {
      tbody.innerHTML = data.activities.map(activity => {
        const actionClass = getActionClass(activity.action);
        return `<tr>
          <td class="small text-muted">${escapeHtml(activity.timestamp)}</td>
          <td><span class="badge ${actionClass}">${escapeHtml(activity.action)}</span></td>
          <td><strong>${escapeHtml(activity.site)}</strong></td>
          <td class="small">${escapeHtml(activity.details)}</td>
        </tr>`;
      }).join('');
    } else {
      tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted">No activity recorded yet</td></tr>';
    }
  } catch (error) {
    console.error('Error loading activity:', error);
    const tbody = document.getElementById('activity-table-body');
    if (tbody) {
      tbody.innerHTML = '<tr><td colspan="4" class="text-center text-danger">Failed to load activity log</td></tr>';
    }
  }
}

function getActionClass(action) {
  const classes = {
    'CREATE': 'bg-success',
    'START': 'bg-primary',
    'STOP': 'bg-warning',
    'EDIT': 'bg-info',
    'REMOVE': 'bg-danger',
    'BACKUP': 'bg-secondary',
    'RESTORE': 'bg-dark'
  };
  return classes[action] || 'bg-secondary';
}

// Update dashboard UI
function updateDashboard() {
  const runningSites = currentData.sites.filter(site => site.status && site.status.toLowerCase() === 'running');
  const runningServices = currentData.services.filter(service => service.status && service.status.toLowerCase() === 'running');
  renderSites();
  
  // Update counters (only if elements exist)
  const runningSitesCount = document.getElementById('running-sites-count');
  const runningServicesCount = document.getElementById('running-services-count');
  
  if (runningSitesCount) runningSitesCount.textContent = runningSites.length;
  if (runningServicesCount) runningServicesCount.textContent = runningServices.length;
}

function initSiteFilters() {
  ['site-search', 'site-status-filter', 'site-sort'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('input', applySiteFilters);
    if (el) el.addEventListener('change', applySiteFilters);
  });
}

function resetSiteFilters() {
  const search = document.getElementById('site-search');
  const status = document.getElementById('site-status-filter');
  const sort = document.getElementById('site-sort');
  if (search) search.value = '';
  if (status) status.value = 'all';
  if (sort) sort.value = 'name-asc';
  applySiteFilters();
}

function sortSites(sites) {
  const sort = document.getElementById('site-sort')?.value || 'name-asc';
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
  const grid = document.getElementById('sites-grid');
  if (!grid || !Array.isArray(currentData.sites)) return;
  grid.innerHTML = sortSites(currentData.sites).map(renderSiteCard).join('');
  applySiteFilters();
}

function renderSiteCard(site) {
  const name = escapeHtml(site.name || '');
  const status = escapeHtml(site.status || 'Stopped');
  const statusClass = String(site.status || '').toLowerCase() === 'running' ? 'status-running' : 'status-stopped';
  const localUrl = site.localUrl ? escapeHtml(site.localUrl) : '';
  const phpVersion = escapeHtml(site.phpVersion || '');
  const urlMarkup = localUrl ? `
            <div class="site-info">
              <i class="bi bi-link me-2"></i>
              <a href="${localUrl}" target="_blank" rel="noopener" class="site-link">${localUrl}</a>
            </div>
            <div class="site-actions-primary">
              <a href="${localUrl}" target="_blank" rel="noopener" class="btn-modern-sm btn-modern-outline">
                <i class="bi bi-box-arrow-up-right"></i> Open
              </a>
              <button class="btn-modern-sm btn-modern-outline" onclick="checkSiteHealth('${name}')" aria-label="Check health for ${name}">
                <i class="bi bi-heart-pulse"></i> Health
              </button>
            </div>
            <div id="health-${name}" class="site-health mt-2" style="display: none;" aria-live="polite">
              <span class="health-status small"></span>
            </div>` : `
            <div class="site-info text-muted">
              <i class="bi bi-info-circle me-2"></i>Not configured
            </div>`;

  return `
      <div class="col-md-6 col-lg-4 site-card-wrapper" data-site-name="${name}" data-site-status="${status}" data-site-php="${phpVersion}" data-site-url="${localUrl}">
        <div class="site-card-modern">
          <div class="site-card-header">
            <h5 class="site-title">${name}</h5>
            <span class="status-badge ${statusClass}">${status}</span>
          </div>
          <div class="site-card-body">${urlMarkup}</div>
          <div class="site-card-footer">
            <div class="btn-group-modern">
              <button class="btn-icon btn-success" onclick="siteAction('start', '${name}')" title="Start" aria-label="Start ${name}">
                <i class="bi bi-play-fill"></i>
              </button>
              <button class="btn-icon btn-warning" onclick="siteAction('stop', '${name}')" title="Stop" aria-label="Stop ${name}">
                <i class="bi bi-stop-fill"></i>
              </button>
              <button class="btn-icon btn-info" onclick="siteAction('restart', '${name}')" title="Restart" aria-label="Restart ${name}">
                <i class="bi bi-arrow-clockwise"></i>
              </button>
              <button class="btn-icon btn-secondary" onclick="runChecksForSite('${name}')" title="Check" aria-label="Run checks for ${name}">
                <i class="bi bi-clipboard-check"></i>
              </button>
              <button class="btn-icon btn-secondary" onclick="siteAction('backup', '${name}')" title="Backup" aria-label="Back up ${name}">
                <i class="bi bi-download"></i>
              </button>
              <div class="dropdown">
                <button class="btn btn-sm btn-outline-secondary dropdown-toggle" data-bs-toggle="dropdown" aria-label="More actions for ${name}">
                  <i class="bi bi-three-dots-vertical"></i>
                </button>
                <ul class="dropdown-menu dropdown-menu-end">
                  <li><a class="dropdown-item" href="#" onclick="siteAction('info', '${name}')"><i class="bi bi-info-circle me-2"></i>Info</a></li>
                  <li><a class="dropdown-item" href="#" onclick="siteAction('url', '${name}')"><i class="bi bi-link-45deg me-2"></i>Show URL</a></li>
                  <li><a class="dropdown-item" href="#" onclick="siteAction('logs', '${name}')"><i class="bi bi-terminal me-2"></i>Logs</a></li>
                  <li><a class="dropdown-item" href="#" onclick="siteAction('edit', '${name}')"><i class="bi bi-pencil me-2"></i>Edit Config</a></li>
                  <li><hr class="dropdown-divider"></li>
                  <li><a class="dropdown-item" href="#" onclick="siteAction('export-db', '${name}')"><i class="bi bi-database-export me-2"></i>Export DB</a></li>
                  <li><a class="dropdown-item" href="#" onclick="siteAction('import-db', '${name}')"><i class="bi bi-database-import me-2"></i>Import DB</a></li>
                  <li><a class="dropdown-item" href="#" onclick="siteAction('restore', '${name}')"><i class="bi bi-arrow-counterclockwise me-2"></i>Restore</a></li>
                  <li><hr class="dropdown-divider"></li>
                  <li><a class="dropdown-item" href="#" onclick="siteAction('clone', '${name}')"><i class="bi bi-copy me-2"></i>Clone</a></li>
                  <li><a class="dropdown-item text-warning" href="#" onclick="siteAction('reset', '${name}')"><i class="bi bi-exclamation-triangle me-2"></i>Reset</a></li>
                  <li><a class="dropdown-item text-danger" href="#" onclick="siteAction('remove', '${name}')"><i class="bi bi-trash me-2"></i>Delete</a></li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>`;
}

function applySiteFilters() {
  const searchTerm = (document.getElementById('site-search')?.value || '').trim().toLowerCase();
  const statusFilter = document.getElementById('site-status-filter')?.value || 'all';
  const cards = Array.from(document.querySelectorAll('.site-card-wrapper'));
  let visibleCount = 0;

  cards.forEach(card => {
    const haystack = [
      card.dataset.siteName,
      card.dataset.siteStatus,
      card.dataset.sitePhp,
      card.dataset.siteUrl
    ].join(' ').toLowerCase();
    const status = (card.dataset.siteStatus || '').toLowerCase();
    const matchesSearch = !searchTerm || haystack.includes(searchTerm);
    const matchesStatus = statusFilter === 'all' || status === statusFilter;
    const visible = matchesSearch && matchesStatus;
    card.classList.toggle('d-none', !visible);
    if (visible) visibleCount += 1;
  });

  const emptyState = document.getElementById('sites-empty-state');
  if (emptyState) emptyState.classList.toggle('d-none', visibleCount > 0);
}

// Quick actions
async function quickAction(action) {
  try {
    showLoading();
    const response = await fetch(`/api/environment/${action}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    const data = await response.json();
    
    if (data.success) {
      showNotification(`Command "${action}" executed successfully`, 'success');
    } else {
      const errorMsg = data.error?.message || data.error || 'Unknown error';
      showNotification(`Command "${action}" failed: ${errorMsg}`, 'danger');
    }
    
    // Always refresh after any action
    await loadDashboard();
    hideLoading();
  } catch (error) {
    console.error('Error executing quick action:', error);
    showNotification('Network error while executing command', 'danger');
    hideLoading();
  }
}

// Site actions
async function siteAction(action, siteName) {
  if (action === 'remove' || action === 'delete') {
    if (!confirm(`Are you sure you want to remove site "${siteName}"? This action cannot be undone.`)) {
      return;
    }
  }
  
  if (action === 'reset') {
    if (!confirm(`Are you sure you want to reset site "${siteName}" to a fresh WordPress install? All data will be lost.`)) {
      return;
    }
  }

  let endpoint, body;

  switch (action) {
    case 'restart':
      endpoint = '/api/sites/restart';
      body = { siteName };
      break;
    case 'url':
      endpoint = '/api/sites/url';
      body = { siteName };
      break;
    case 'logs':
      endpoint = '/api/sites/logs';
      body = { siteName };
      break;
    case 'backup':
      endpoint = '/api/sites/backup';
      body = { siteName };
      break;
    case 'restore':
      openSiteWorkflowModal('restore', siteName);
      return;
    case 'export-db':
      endpoint = '/api/sites/export-db';
      body = { siteName };
      break;
    case 'import-db':
      openSiteWorkflowModal('import-db', siteName);
      return;
    case 'edit':
      openSiteWorkflowModal('edit', siteName);
      return;
    case 'remove':
    case 'delete':
      endpoint = `/api/sites/${action}`;
      body = { siteName, forceYes: '--yes' };
      break;
    case 'clone':
      openSiteWorkflowModal('clone', siteName);
      return;
    case 'reset':
      if (!confirm(`Are you sure you want to reset site "${siteName}" to a fresh WordPress install? All data will be lost.`)) return;
      endpoint = '/api/sites/reset';
      body = { siteName, forceYes: '--yes' };
      break;
    default:
      endpoint = `/api/sites/${action}`;
      body = { siteName };
  }
  
  try {
    showLoading();
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    });
    
    const data = await response.json();
    
    if (data.success) {
      // Show output for info, url, logs actions
      if (['info', 'url', 'logs'].includes(action) && data.output) {
        showActionOutput(action, siteName, data.output);
      } else {
        showNotification(`Command "${action} ${siteName}" executed successfully`, 'success');
      }
    } else {
      const errorMsg = data.error?.message || data.error || 'Unknown error';
      showNotification(`Command "${action} ${siteName}" failed: ${errorMsg}`, 'danger');
    }
    
    // Always refresh after any action (success or failure)
    await loadDashboard();
    hideLoading();
  } catch (error) {
    console.error('Error executing site action:', error);
    showNotification('Network error while executing command', 'danger');
    hideLoading();
  }
}

function getWorkflowConfig(action, siteName) {
  const configs = {
    'restore': {
      title: `Restore ${siteName}`,
      description: 'Restore this site from a backup archive.',
      fields: [{ id: 'backupFile', label: 'Backup file', placeholder: 'backups/site-20260501.tar.gz', type: 'text' }],
      endpoint: '/api/sites/restore',
      buildBody: (values) => ({ siteName, backupFile: values.backupFile })
    },
    'import-db': {
      title: `Import database for ${siteName}`,
      description: 'Import a SQL dump into this site database.',
      fields: [{ id: 'dumpFile', label: 'SQL dump file', placeholder: 'backups/site.sql', type: 'text' }],
      endpoint: '/api/sites/import-db',
      buildBody: (values) => ({ siteName, dumpFile: values.dumpFile })
    },
    'edit': {
      title: `Edit ${siteName}`,
      description: 'Change this site PHP version.',
      fields: [{ id: 'phpVersion', label: 'PHP version', type: 'select', options: ['8.3', '8.2', '8.1', '8.0', '7.4'] }],
      endpoint: '/api/sites/edit',
      buildBody: (values) => ({ siteName, phpVersion: values.phpVersion })
    },
    'clone': {
      title: `Clone ${siteName}`,
      description: 'Create a new site from this site.',
      fields: [{ id: 'destName', label: 'New site name', placeholder: `${siteName}-copy`, type: 'text' }],
      endpoint: '/api/sites/clone',
      buildBody: (values) => ({ sourceName: siteName, destName: values.destName })
    }
  };
  return configs[action];
}

function openSiteWorkflowModal(action, siteName) {
  const config = getWorkflowConfig(action, siteName);
  if (!config) return;

  const fieldMarkup = config.fields.map(field => {
    if (field.type === 'select') {
      const options = field.options.map(option => `<option value="${escapeHtml(option)}">${escapeHtml(option)}</option>`).join('');
      return `
        <div class="mb-3">
          <label class="form-label" for="workflow-${field.id}">${escapeHtml(field.label)}</label>
          <select class="form-select" id="workflow-${field.id}">${options}</select>
        </div>`;
    }
    return `
      <div class="mb-3">
        <label class="form-label" for="workflow-${field.id}">${escapeHtml(field.label)}</label>
        <input type="${field.type}" class="form-control" id="workflow-${field.id}" placeholder="${escapeHtml(field.placeholder || '')}">
      </div>`;
  }).join('');

  const modalHtml = `
    <div class="modal fade" id="siteWorkflowModal" tabindex="-1">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">${escapeHtml(config.title)}</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            <p class="text-muted">${escapeHtml(config.description)}</p>
            <div id="workflow-error" class="alert alert-danger d-none" role="alert"></div>
            ${fieldMarkup}
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary" onclick="submitSiteWorkflow('${action}', '${siteName}')">Run</button>
          </div>
        </div>
      </div>
    </div>`;

  const existing = document.getElementById('siteWorkflowModal');
  if (existing) existing.remove();
  document.body.insertAdjacentHTML('beforeend', modalHtml);
  new bootstrap.Modal(document.getElementById('siteWorkflowModal')).show();
}

function validateWorkflowValues(action, values) {
  if (action === 'clone' && !/^[a-zA-Z][a-zA-Z0-9_-]*$/.test(values.destName || '')) {
    return 'New site name must start with a letter and contain only alphanumeric characters, hyphens, and underscores.';
  }
  if (['restore', 'import-db'].includes(action)) {
    const pathValue = values.backupFile || values.dumpFile || '';
    if (!pathValue || pathValue.startsWith('/') || pathValue.includes('..')) {
      return 'File path must be a relative path inside the project.';
    }
  }
  return null;
}

async function submitSiteWorkflow(action, siteName) {
  const config = getWorkflowConfig(action, siteName);
  if (!config) return;

  const values = {};
  config.fields.forEach(field => {
    values[field.id] = document.getElementById(`workflow-${field.id}`)?.value.trim();
  });

  const error = validateWorkflowValues(action, values);
  const errorEl = document.getElementById('workflow-error');
  if (error) {
    if (errorEl) {
      errorEl.textContent = error;
      errorEl.classList.remove('d-none');
    }
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
      bootstrap.Modal.getInstance(document.getElementById('siteWorkflowModal'))?.hide();
      showNotification(`Command "${action} ${siteName}" executed successfully`, 'success');
      await loadDashboard();
    } else {
      const errorMsg = data.error?.message || data.error || 'Unknown error';
      if (errorEl) {
        errorEl.textContent = errorMsg;
        errorEl.classList.remove('d-none');
      }
    }
  } catch (error) {
    hideLoading();
    if (errorEl) {
      errorEl.textContent = 'Network error while executing command';
      errorEl.classList.remove('d-none');
    }
  }
}

// Create site
async function createSite() {
  const siteNameInput = document.getElementById('siteName');
  const siteName = siteNameInput.value.trim();
  const phpVersionSelect = document.getElementById('phpVersion');
  const phpVersion = phpVersionSelect ? phpVersionSelect.value : '8.3';
  
  if (!siteName) {
    showNotification('Please enter a site name', 'warning');
    return;
  }
  
  if (!/^[a-zA-Z][a-zA-Z0-9_-]*$/.test(siteName)) {
    showNotification('Site name must start with a letter and contain only alphanumeric characters, hyphens, and underscores', 'warning');
    return;
  }
  
  try {
    showLoading();
    const response = await fetch('/api/sites/create', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ siteName, phpVersion })
    });
    
    const data = await response.json();
    
    if (data.success && (!data.exitCode || data.exitCode === 0)) {
      showNotification(`Site "${siteName}" created successfully`, 'success');
      siteNameInput.value = '';
      
      // Close modal
      const modal = bootstrap.Modal.getInstance(document.getElementById('createSiteModal'));
      modal.hide();
    } else {
      // Extract error message from output (last non-empty line)
      let errorMsg = 'Unknown error';
      if (data.output) {
        const lines = data.output.split('\n').filter(l => l.trim());
        if (lines.length > 0) {
          errorMsg = lines[lines.length - 1].replace(/✅|❌|ℹ️|⚠️| - /g, '').trim();
        }
      } else if (data.error) {
        errorMsg = data.error;
      }
      showNotification(`Failed to create site: ${errorMsg}`, 'danger');
    }
    
    // Always refresh after create attempt (success or failure)
    await loadDashboard();
    
    hideLoading();
  } catch (error) {
    console.error('Error creating site:', error);
    showNotification('Network error while creating site', 'danger');
    hideLoading();
  }
}

// Site health check
async function checkSiteHealth(siteName) {
  const healthEl = document.getElementById(`health-${siteName}`);
  const statusEl = healthEl?.querySelector('.health-status');
  
  if (!healthEl || !statusEl) return;
  
  healthEl.style.display = 'block';
  statusEl.innerHTML = '<span class="text-info">Checking...</span>';
  
  try {
    const response = await fetch(`/api/health/${siteName}`);
    const data = await response.json();
    
    if (data.success && data.healthy) {
      statusEl.innerHTML = `<span class="text-success">✓ Healthy (${data.responseTime})</span>`;
    } else if (data.success && !data.healthy) {
      statusEl.innerHTML = `<span class="text-warning">✗ ${data.reason || data.error || 'Unhealthy'}</span>`;
    } else {
      statusEl.innerHTML = `<span class="text-danger">Error: ${data.error?.message || 'Unknown'}</span>`;
    }
  } catch (error) {
    statusEl.innerHTML = `<span class="text-danger">Error: ${error.message}</span>`;
  }
}

// Frontend management
async function frontendAction(action) {
  try {
    showLoading();
    const response = await fetch(`/api/frontend/${action}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    const data = await response.json();
    
    if (data.success) {
      showNotification(`Frontend "${action}" executed successfully`, 'success');
      updateFrontendStatus(action, data.output);
    } else {
      const errorMsg = data.error?.message || data.error || 'Unknown error';
      showNotification(`Frontend "${action}" failed: ${errorMsg}`, 'danger');
    }
    
    hideLoading();
  } catch (error) {
    console.error('Error executing frontend action:', error);
    showNotification('Network error while executing frontend command', 'danger');
    hideLoading();
  }
}

// Update frontend status display
function updateFrontendStatus(action, output) {
  const statusDiv = document.getElementById('frontend-status');
  if (!statusDiv) return;
  
  if (action === 'status') {
    statusDiv.textContent = output || 'No status output';
  } else if (action === 'stop') {
    statusDiv.innerHTML = '<span class="badge bg-danger">Stopped</span>';
  } else if (action === 'start' || action === 'restart') {
     statusDiv.innerHTML = '<span class="badge bg-success">Running (http://localhost:8500)</span>';
   }
}

// Terminal commands
async function executeCommand() {
  const input = document.getElementById('terminal-input');
  const output = document.getElementById('terminal-output');
  const command = input.value.trim();
  
  if (!command) return;
  
  const outputLine = document.createElement('div');
  outputLine.innerHTML = `<span style="color: var(--accent-color);">$</span> ${escapeHtml(command)}`;
  output.appendChild(outputLine);
  input.value = '';
  
  try {
    const parts = command.split(' ');
    const action = parts[0];
    const args = parts.slice(1);
    
    let endpoint, body;

    const siteActions = ['start', 'stop', 'restart', 'remove', 'delete', 'rm', 'info', 'url', 'logs', 'backup', 'restore', 'edit', 'clone', 'reset', 'export-db', 'import-db', 'create', 'check'];
    const envActions = ['start', 'stop', 'restart', 'status', 'logs', 'clean', 'check', 'health', 'cache', 'cache-clear', 'search-replace', 'update', 'update-core', 'install'];

    if (args.length > 0 && siteActions.includes(action)) {
      endpoint = '/api/sites/' + action;
      body = { siteName: args[0], phpVersion: undefined };
    } else if (envActions.includes(action)) {
      endpoint = '/api/environment/' + action;
      body = { args };
    } else {
      const outputDiv = document.createElement('div');
      outputDiv.className = 'text-warning';
      outputDiv.style.whiteSpace = 'pre-wrap';
      outputDiv.textContent = `Unknown command: ${action}. Type 'help' for available commands.`;
      output.appendChild(outputDiv);
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
      const outputDiv = document.createElement('div');
      outputDiv.style.whiteSpace = 'pre-wrap';
      outputDiv.style.fontFamily = 'monospace';
      outputDiv.style.fontSize = '0.85rem';
      outputDiv.innerHTML = escapeHtml(data.output);
      output.appendChild(outputDiv);
    } else {
      const errorMsg = data.error?.message || data.error || 'Unknown error';
      const errorDiv = document.createElement('div');
      errorDiv.className = 'text-danger';
      errorDiv.style.whiteSpace = 'pre-wrap';
      errorDiv.innerHTML = escapeHtml(`Error: ${errorMsg}`);
      output.appendChild(errorDiv);
    }
  } catch (error) {
    console.error('Error executing command:', error);
    const errorDiv = document.createElement('div');
    errorDiv.className = 'text-danger';
    errorDiv.textContent = 'Network error';
    output.appendChild(errorDiv);
  }
  
  output.scrollTop = output.scrollHeight;
}

// Utility functions
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Utility functions
function showLoading() {
  const refreshBtn = document.getElementById('refresh-btn');
  refreshBtn.disabled = true;
  refreshBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status"></span> Loading...';
}

function hideLoading() {
  const refreshBtn = document.getElementById('refresh-btn');
  refreshBtn.disabled = false;
  refreshBtn.innerHTML = '<i class="bi bi-arrow-clockwise"></i> Refresh';
}

function showNotification(message, type = 'info') {
  // Remove existing notifications
  const existing = document.querySelector('.notification-toast');
  if (existing) {
    existing.remove();
  }
  
  // Create new notification
  const notification = document.createElement('div');
  notification.className = `notification-toast toast align-items-center text-white bg-${type} border-0`;
  notification.setAttribute('role', 'alert');
  notification.innerHTML = `
    <div class="d-flex">
      <div class="toast-body"></div>
      <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
    </div>
  `;
  notification.querySelector('.toast-body').textContent = message;
  
  // Add to page
  document.body.appendChild(notification);
  
  // Position notification
  notification.style.position = 'fixed';
  notification.style.top = '20px';
  notification.style.right = '20px';
  notification.style.zIndex = '9999';
  
  // Show notification
  const toast = new bootstrap.Toast(notification);
  toast.show();
  
  // Remove after auto-hide
  setTimeout(() => {
    if (notification.parentNode) {
      notification.parentNode.removeChild(notification);
    }
  }, 5000);
}

function showActionOutput(action, siteName, output) {
  // Clean up ANSI codes and format output
  const cleanOutput = output
    .replace(/\x1b\[[0-9;]*m/g, '')  // Remove ANSI colors
    .replace(/✅|❌|ℹ️|⚠️| - /g, '')  // Remove icons
    .trim();
  
  // Show in modal
  const modalHtml = `
    <div class="modal fade" id="actionOutputModal" tabindex="-1">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              <i class="bi bi-${getActionIcon(action)} me-2"></i>
              ${getActionTitle(action)}: ${siteName}
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <pre class="bg-dark text-light p-3 rounded" style="white-space: pre-wrap; max-height: 400px; overflow-y: auto;">${escapeHtml(cleanOutput)}</pre>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-primary" data-bs-dismiss="modal">Close</button>
          </div>
        </div>
      </div>
    </div>
  `;
  
  // Remove existing modal if any
  const existingModal = document.getElementById('actionOutputModal');
  if (existingModal) existingModal.remove();
  
  // Add modal to page
  document.body.insertAdjacentHTML('beforeend', modalHtml);
  
  // Show modal
  const modal = new bootstrap.Modal(document.getElementById('actionOutputModal'));
  modal.show();
}

function getActionIcon(action) {
  const icons = {
    'info': 'info-circle',
    'url': 'link-45deg',
    'logs': 'terminal',
    'edit': 'pencil',
    'backup': 'download',
    'clone': 'copy'
  };
  return icons[action] || 'gear';
}

function getActionTitle(action) {
  const titles = {
    'info': 'Site Information',
    'url': 'Site URL',
    'logs': 'Site Logs',
    'edit': 'Edit Configuration',
    'backup': 'Backup',
    'clone': 'Clone Site'
  };
  return titles[action] || 'Action Result';
}

function showError(message) {
  const errorDiv = document.createElement('div');
  errorDiv.className = 'alert alert-danger alert-dismissible fade show';
  errorDiv.setAttribute('role', 'alert');
  errorDiv.innerHTML = `
    <strong>Error:</strong> ${message}
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  `;
  
  // Insert at the top of main content
  const main = document.querySelector('main');
  main.insertBefore(errorDiv, main.firstChild);
  
  // Auto-remove after 5 seconds
  setTimeout(() => {
    if (errorDiv.parentNode) {
      errorDiv.parentNode.removeChild(errorDiv);
    }
  }, 5000);
}

// Code quality check functions
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
      const errorMsg = data.error?.message || data.error || 'Check failed';
      showNotification(`Check failed: ${errorMsg}`, 'danger');
    }
  } catch (error) {
    console.error('Error running checks:', error);
    hideLoading();
    showNotification('Network error while running checks', 'danger');
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
      const errorMsg = data.error?.message || data.error || 'Check failed';
      showNotification(`Check failed: ${errorMsg}`, 'danger');
    }
  } catch (error) {
    console.error('Error running checks:', error);
    hideLoading();
    showNotification('Network error while running checks', 'danger');
  }
}

function displayCheckResults(results, siteName) {
  const modal = new bootstrap.Modal(document.getElementById('checkResultsModal'));
  const body = document.getElementById('check-results-body');
  const progress = document.getElementById('check-progress');
  const output = document.getElementById('check-output');
  
  progress.classList.add('d-none');
  output.classList.remove('d-none');
  
  const pre = output.querySelector('pre');
  
  if (typeof results === 'string') {
    pre.textContent = results || 'No output';
  } else if (results && results.results) {
    let text = '';
    results.results.forEach(tool => {
      text += `=== ${tool.tool} ===\n`;
      text += `Files Scanned: ${tool.filesScanned}\n`;
      text += `Errors: ${tool.totals.errors}, Warnings: ${tool.totals.warnings}\n`;
      if (tool.errors.length > 0) {
        text += '\nErrors:\n';
        tool.errors.forEach(e => {
          text += `  ${e.file}:${e.line} - ${e.message}\n`;
        });
      }
      if (tool.warnings.length > 0) {
        text += '\nWarnings:\n';
        tool.warnings.forEach(w => {
          text += `  ${w.file}:${w.line} - ${w.message}\n`;
        });
      }
      text += '\n';
    });
    pre.textContent = text;
  } else {
    pre.textContent = JSON.stringify(results, null, 2);
  }
  
  modal.show();
}

// Activity tab event listener
document.addEventListener('shown.bs.tab', function (event) {
  if (event.target.id === 'activity-tab') {
    loadActivity();
  }
});