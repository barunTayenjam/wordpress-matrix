---
phase: 02
plan: 02
wave: 2
depends_on: [01]
requirements: [WS-02, UI-02]
files_modified: [frontend/app.js, frontend/public/js/app.js]
autonomous: true
---

# Plan 02: Operation Progress Streaming

## Objective
Add real-time progress feedback for long-running operations (create, start, stop, remove). Show spinners and progress indicators in the UI while operations are in progress. Emit events during operation lifecycle.

## must_haves
- Operation start event emitted to client when user clicks Start/Stop/Create
- Operation complete event with success/failure status
- UI shows spinner/loading state during operations
- Success/failure toast notification on completion

<task id="1">
<name>Add operation event emission to executeMatrix</name>
<read_first>
- frontend/app.js (executeMatrix function, POST routes)
- .planning/phases/02-real-time-websocket/01-CONTEXT.md (decisions)
</read_first>
<action>
1. Modify executeMatrix to accept operationName parameter and emit events:

```javascript
const executeMatrix = async (command, args = [], jsonMode = false, operationName = null) => {
  // ... existing code ...
  
  // Emit operation start event if operationName provided
  if (operationName) {
    const io = app.get('io');
    if (io) {
      io.emit('site.operation', {
        type: 'start',
        operation: operationName,
        command: command,
        args: args,
        timestamp: new Date().toISOString()
      });
    }
  }
  
  // ... existing spawn code ...
  
  // In close handler, emit completion event
  matrixCmd.on('close', (code) => {
    // ... existing code for jsonMode ...
    
    // Emit operation complete event
    if (operationName) {
      const io = app.get('io');
      if (io) {
        io.emit('site.operation', {
          type: code === 0 ? 'success' : 'failure',
          operation: operationName,
          command: command,
          exitCode: code,
          timestamp: new Date().toISOString()
        });
      }
    }
    
    // ... rest of existing code ...
  });
};
```

2. Update all POST routes to pass operationName:

In POST /api/sites/:action:
```javascript
const operationName = `${action}_${siteName}`;
const result = await executeMatrix(action, args, useJson, operationName);
```

In POST /api/environment/:action:
```javascript
const operationName = action;
const result = await executeMatrix(action, [], false, operationName);
```
</action>
<acceptance_criteria>
- executeMatrix emits 'site.operation' event with type: 'start' when operation begins
- executeMatrix emits 'site.operation' event with type: 'success' or 'failure' when operation completes
- Event includes operation name, command, and timestamp
- Frontend route handlers pass operationName to executeMatrix
</acceptance_criteria>
</task>

<task id="2">
<name>Add client-side operation progress UI</name>
<read_first>
- frontend/public/js/app.js (siteAction, quickAction functions)
</read_first>
<action>
1. Add WebSocket event listener for operation progress in app.js:

Add in initWebSocket() function:
```javascript
socket.on('site.operation', (data) => {
  console.log('[WebSocket] Operation event:', data);
  handleOperationEvent(data);
});
```

Add new function:
```javascript
function handleOperationEvent(data) {
  const { type, operation } = data;
  
  if (type === 'start') {
    // Show loading state for this operation
    showOperationLoading(operation);
  } else if (type === 'success' || type === 'failure') {
    // Hide loading state
    hideOperationLoading(operation);
    
    // Show notification
    const status = type === 'success' ? 'success' : 'danger';
    const message = type === 'success' 
      ? `Operation "${operation}" completed successfully`
      : `Operation "${operation}" failed`;
    showNotification(message, status);
    
    // Refresh dashboard after operation completes
    if (type === 'success') {
      setTimeout(() => loadDashboard(), 1000);
    }
  }
}
```

2. Add helper functions for loading state:

```javascript
function showOperationLoading(operation) {
  // Find button for this operation and show spinner
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
  // Restore button state
  const buttons = document.querySelectorAll('.btn[disabled]');
  buttons.forEach(btn => {
    if (btn.dataset.originalText) {
      btn.innerHTML = btn.dataset.originalText;
      btn.disabled = false;
      delete btn.dataset.originalText;
    }
  });
}
```

3. Update siteAction() and quickAction() to work with WebSocket loading (no changes needed - WebSocket events handle it automatically)
</action>
<acceptance_criteria>
- WebSocket receives 'site.operation' events
- showOperationLoading() displays spinner on button during operation
- hideOperationLoading() restores button after operation
- Toast notification shows on operation complete
- Dashboard refreshes after successful operation
</acceptance_criteria>
</task>

## Verification
1. Start frontend, open dashboard
2. Click "Start" on a site
3. Button shows spinner immediately
4. When complete, notification appears
5. Dashboard refreshes to show new status
