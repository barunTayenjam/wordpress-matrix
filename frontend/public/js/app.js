// Global variables
let currentData = {
  sites: [],
  services: []
};

// Initialize the application
document.addEventListener('DOMContentLoaded', () => {
  loadDashboard();

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
      showNotification(`Command "${action}" failed: ${data.error}`, 'danger');
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
      showNotification(`Command "${action} ${siteName}" failed: ${data.error}`, 'danger');
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
      showNotification(`Failed to create site: ${data.error}`, 'danger');
    }
    
    hideLoading();
  } catch (error) {
    console.error('Error creating site:', error);
    showNotification('Network error while creating site', 'danger');
    hideLoading();
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
      // Update frontend status display
      updateFrontendStatus(action, data.output);
    } else {
      showNotification(`Frontend "${action}" failed: ${data.error}`, 'danger');
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
  
  // Show command in output
  output.innerHTML += `<div>$ ${command}</div>`;
  input.value = '';
  
  try {
    const response = await fetch(`/api/environment/${command.split(' ')[0]}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    const data = await response.json();
    
    if (data.success) {
      output.innerHTML += `<div>${data.output}</div>`;
    } else {
      output.innerHTML += `<div class="text-danger">Error: ${data.error}</div>`;
    }
  } catch (error) {
    console.error('Error executing command:', error);
    output.innerHTML += '<div class="text-danger">Network error</div>';
  }
  
  // Scroll to bottom
  output.scrollTop = output.scrollHeight;
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