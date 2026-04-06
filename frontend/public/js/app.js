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
      if (container.name && container.name.startsWith('wp_')) {
        const siteName = container.name.replace('wp_', '');
        const site = currentData.sites.find(s => s.name === siteName);
        if (site) {
          site.status = container.status.toLowerCase().includes('up') ? 'Running' : 'Stopped';
        }
      }
    });
  }
  updateDashboard();
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
document.addEventListener('DOMContentLoaded', () => {
  loadDashboard();
  initWebSocket();

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
      hideLoading();
    } else {
      showError('Failed to load dashboard data');
    }
  } catch (error) {
    console.error('Error loading dashboard:', error);
    showError('Network error while loading dashboard');
  }
}

// Update dashboard UI
function updateDashboard() {
  const runningSites = currentData.sites.filter(site => site.status === 'Running');
  const runningServices = currentData.services.filter(service => service.status === 'Running');
  
  // Update counters (only if elements exist)
  const runningSitesCount = document.getElementById('running-sites-count');
  const runningServicesCount = document.getElementById('running-services-count');
  
  if (runningSitesCount) runningSitesCount.textContent = runningSites.length;
  if (runningServicesCount) runningServicesCount.textContent = runningServices.length;
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
      await loadDashboard();
    } else {
      const errorMsg = data.error?.message || data.error || 'Unknown error';
      showNotification(`Command "${action}" failed: ${errorMsg}`, 'danger');
    }
    
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
  
  try {
    showLoading();
    const response = await fetch(`/api/sites/${action}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ siteName })
    });
    
    const data = await response.json();
    
    if (data.success) {
      showNotification(`Command "${action} ${siteName}" executed successfully`, 'success');
      await loadDashboard();
    } else {
      const errorMsg = data.error?.message || data.error || 'Unknown error';
      showNotification(`Command "${action} ${siteName}" failed: ${errorMsg}`, 'danger');
    }
    
    hideLoading();
  } catch (error) {
    console.error('Error executing site action:', error);
    showNotification('Network error while executing command', 'danger');
    hideLoading();
  }
}

// Create site
async function createSite() {
  const siteNameInput = document.getElementById('siteName');
  const siteName = siteNameInput.value.trim();
  
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
      body: JSON.stringify({ siteName })
    });
    
    const data = await response.json();
    
    if (data.success) {
      showNotification(`Site "${siteName}" created successfully`, 'success');
      siteNameInput.value = '';
      
      // Close modal
      const modal = bootstrap.Modal.getInstance(document.getElementById('createSiteModal'));
      modal.hide();
      
      await loadDashboard();
    } else {
      const errorMsg = data.error?.message || data.error || 'Unknown error';
      showNotification(`Failed to create site: ${errorMsg}`, 'danger');
    }
    
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
    statusDiv.innerHTML = output;
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
  
  // Show command in output with proper formatting
  const outputLine = document.createElement('div');
  outputLine.innerHTML = `<span style="color: var(--accent-color);">$</span> ${escapeHtml(command)}`;
  output.appendChild(outputLine);
  input.value = '';
  
  try {
    // Build the full command - extract action and any args
    const parts = command.split(' ');
    const action = parts[0];
    const args = parts.slice(1);
    
    const response = await fetch(`/api/environment/${action}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ args })
    });
    
    const data = await response.json();
    
    if (data.success && data.output) {
      // Format output with proper newlines and colors
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
  
  // Scroll to bottom
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
      <div class="toast-body">${message}</div>
      <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
    </div>
  `;
  
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