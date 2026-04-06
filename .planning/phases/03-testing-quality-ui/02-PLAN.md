---
phase: 03
plan: 02
wave: 2
depends_on: [01]
requirements: [UI-03]
files_modified: [frontend/views/dashboard.handlebars, frontend/public/js/app.js]
autonomous: true
---

# Plan 02: Code Quality Check UI

## Objective
Add a dashboard UI for running and displaying code quality check results. Use the existing WebSocket infrastructure for progress updates. Display errors and warnings in a structured format.

## must_haves
- "Run Checks" button per site on Sites tab
- Global "Run All Checks" button on Dashboard tab
- Progress display during check execution
- Structured results display (errors count, warnings count, expandable list)

<task id="1">
<name>Add Run Checks buttons to dashboard</name>
<read_first>
- frontend/views/dashboard.handlebars
</read_first>
<action>
1. In dashboard.handlebars, add a "Run Checks" button in the Quick Actions section:
```handlebars
<button class="btn btn-info" onclick="runAllChecks()">
  <i class="bi bi-clipboard-check"></i> Code Quality
</button>
```

2. Add a "Run Checks" button per site in the Sites tab site cards:
```handlebars
<div class="card-footer d-flex justify-content-between">
  <button class="btn btn-sm btn-success" onclick="siteAction('start', '{{name}}')">
    <i class="bi bi-play"></i> Start
  </button>
  <button class="btn btn-sm btn-warning" onclick="siteAction('stop', '{{name}}')">
    <i class="bi bi-stop"></i> Stop
  </button>
  <button class="btn btn-sm btn-info" onclick="siteAction('info', '{{name}}')">
    <i class="bi bi-info"></i> Info
  </button>
  <button class="btn btn-sm btn-outline-info" onclick="runChecksForSite('{{name}}')">
    <i class="bi bi-clipboard-check"></i> Check
  </button>
  <button class="btn btn-sm btn-danger" onclick="siteAction('remove', '{{name}}')">
    <i class="bi bi-trash"></i> Delete
  </button>
</div>
```

3. Add a results modal or section at the bottom of the dashboard:
```handlebars
<!-- Code Quality Results Modal -->
<div class="modal fade" id="checkResultsModal" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Code Quality Check Results</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="check-results-body">
        <div id="check-progress" class="text-center">
          <div class="spinner-border" role="status"></div>
          <p>Running checks...</p>
        </div>
        <div id="check-output" class="d-none">
          <div class="alert alert-success">
            <strong>Passed!</strong> No issues found.
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```
</action>
<acceptance_criteria>
- "Run All Checks" button in Quick Actions
- "Check" button per site in Sites tab
- Results modal present in HTML
- Clicking buttons triggers check API
</acceptance_criteria>
</task>

<task id="2">
<name>Add check execution functions to client JS</name>
<read_first>
- frontend/public/js/app.js
</read_first>
<action>
1. Add runChecksForSite function:
```javascript
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
      displayCheckResults(data.output || data.data);
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
```

2. Add runAllChecks function:
```javascript
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
      displayCheckResults(data.output || data.data);
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
```

3. Add displayCheckResults function:
```javascript
function displayCheckResults(results) {
  const modal = new bootstrap.Modal(document.getElementById('checkResultsModal'));
  const body = document.getElementById('check-results-body');
  const progress = document.getElementById('check-progress');
  const output = document.getElementById('check-output');
  
  progress.classList.add('d-none');
  output.classList.remove('d-none');
  
  // Parse and display results
  if (typeof results === 'string') {
    output.innerHTML = `<pre class="bg-dark text-light p-3">${results}</pre>`;
  } else if (results && results.results) {
    // Structured JSON results
    let html = '';
    results.results.forEach(tool => {
      html += `<div class="card mb-2">
        <div class="card-header">${tool.tool}</div>
        <div class="card-body">
          <p><strong>Files Scanned:</strong> ${tool.filesScanned}</p>
          <p><span class="badge bg-danger">Errors: ${tool.totals.errors}</span>
             <span class="badge bg-warning">Warnings: ${tool.totals.warnings}</span></p>
          ${tool.errors.length > 0 ? `<ul class="list-group">${tool.errors.map(e => `<li class="list-group-item list-group-item-danger">${e.file}:${e.line} - ${e.message}</li>`).join('')}</ul>` : ''}
        </div>
      </div>`;
    });
    output.innerHTML = html;
  } else {
    output.innerHTML = '<pre>' + JSON.stringify(results, null, 2) + '</pre>';
  }
  
  modal.show();
}
```

4. Add API endpoint in frontend/app.js:
```javascript
app.post('/api/sites/check', async (req, res) => {
  const { siteName } = req.body;
  
  if (!siteName) {
    return sendError(res, 'INVALID_NAME', 'Site name is required', 400);
  }
  
  const validation = validateSiteName(siteName);
  if (!validation.valid) {
    return sendError(res, validation.code, validation.message);
  }
  
  try {
    const result = await executeMatrix('check', [siteName], false, `check_${siteName}`);
    
    res.json({
      success: result.success,
      output: result.stdout,
      error: result.stderr
    });
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});
```
</action>
<acceptance_criteria>
- runChecksForSite() calls POST /api/sites/check
- runAllChecks() calls POST /api/environment/check
- displayCheckResults() shows formatted results in modal
- Modal displays errors and warnings with file/line info
</acceptance_criteria>
</task>

## Verification
1. Start frontend, open dashboard
2. Click "Code Quality" button in Quick Actions
3. See results in modal after check completes
4. Click "Check" button on a specific site
5. Results show errors/warnings with file locations
