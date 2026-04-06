---
phase: 02
plan: 01
wave: 1
depends_on: []
requirements: [WS-01, UI-01]
files_modified: [frontend/app.js, frontend/public/js/app.js, frontend/views/layouts/main.handlebars]
autonomous: true
---

# Plan 01: Initialize socket.io and Real-time Status Updates

## Objective
Add socket.io WebSocket server to the frontend, implement status polling, and push real-time container status changes to the dashboard. Status badges update without page refresh.

## must_haves
- socket.io server initialized in frontend/app.js
- Client connects to WebSocket on page load
- Container status polled every 30 seconds via `matrix status --json`
- `status.changed` event emitted to all connected clients when status changes
- Dashboard status badges update in real-time

<task id="1">
<name>Initialize socket.io server in frontend/app.js</name>
<read_first>
- frontend/app.js (full file - see current structure after Phase 1)
- frontend/package.json (check socket.io dependency)
</read_first>
<action>
1. Check that socket.io is in package.json dependencies:
```bash
grep -q "socket.io" frontend/package.json || echo "MISSING"
```
If missing, add: `"socket.io": "^4.7.0",` and `"socket.io-client": "^4.7.0",`

2. In frontend/app.js, add socket.io require after existing requires:
```javascript
const http = require('http');
const { Server } = require('socket.io');
```

3. Create HTTP server wrapper (needed for socket.io to attach to Express):
Replace the direct `app.listen()` at the end of the file with:
```javascript
const server = http.createServer(app);
const io = new Server(server);

io.on('connection', (socket) => {
  console.log('[WebSocket] Client connected:', socket.id);
  
  socket.on('disconnect', () => {
    console.log('[WebSocket] Client disconnected:', socket.id);
  });
});

// Make io accessible to routes via app.set
app.set('io', io);

server.listen(PORT, () => {
  console.log(`🚀 WordPress Matrix Frontend running on http://localhost:${PORT}`);
  console.log(`📊 Dashboard: http://localhost:${PORT}`);
  console.log(`🔗 API Endpoint: http://localhost:${PORT}/api`);
  console.log(`⚡ WebSocket: ws://localhost:${PORT}`);
});
```

4. Keep the original `app.listen()` line commented or remove it.

5. Verify socket.io is loaded:
```bash
node -e "require('socket.io')" -C "socket.io" frontend/ 2>&1 || echo "NOT_FOUND"
```
</action>
<acceptance_criteria>
- socket.io imports work without errors
- HTTP server created and wraps Express app
- io object attached to app for use in routes
- Server starts and logs WebSocket availability
- WebSocket connection logs appear in console
</acceptance_criteria>
</task>

<task id="2">
<name>Add status polling with socket.io emission</name>
<read_first>
- frontend/app.js (after socket.io initialization in task 1)
- .planning/phases/02-real-time-websocket/01-CONTEXT.md
</read_first>
<action>
1. In frontend/app.js, after socket.io setup, add status polling:

```javascript
let lastStatus = null;
const POLL_INTERVAL = 30000; // 30 seconds

const pollStatus = async () => {
  try {
    const result = await executeMatrix('status', [], true);
    if (result.success && result.data) {
      const currentStatus = JSON.stringify(result.data);
      
      if (lastStatus !== null && lastStatus !== currentStatus) {
        // Status changed - emit to all clients
        const io = app.get('io');
        if (io) {
          io.emit('status.changed', result.data);
          console.log('[WebSocket] Status changed, emitting to clients');
        }
      }
      
      lastStatus = currentStatus;
    }
  } catch (error) {
    console.error('[WebSocket] Status poll error:', error.message);
  }
};

// Start polling after server is ready
setInterval(pollStatus, POLL_INTERVAL);
console.log(`[WebSocket] Status polling started (every ${POLL_INTERVAL/1000}s)`);
```

2. Add initial poll after server starts to get baseline:
```javascript
// Initial status fetch after server starts
setTimeout(() => {
  pollStatus();
}, 2000);
```

3. Ensure executeMatrix is called with jsonMode=true (already done in Phase 1 for status endpoint).
</action>
<acceptance_criteria>
- Status polling runs every 30 seconds
- Status changes detected by comparing JSON stringified state
- 'status.changed' event emitted to all connected WebSocket clients
- Console logs confirm polling is active
- No errors in server logs from the polling loop
</acceptance_criteria>
</task>

<task id="3">
<name>Add socket.io client to dashboard</name>
<read_first>
- frontend/views/layouts/main.handlebars
- frontend/public/js/app.js
</read_first>
<action>
1. Add socket.io client library to main.handlebars (in head or before closing body):
```html
<script src="https://cdn.socket.io/4.7.0/socket.io.min.js"></script>
```

2. In frontend/public/js/app.js, initialize socket connection and event handlers:

Add at the top of the file (after currentData declaration):
```javascript
let socket = null;
```

Add in DOMContentLoaded, after loadDashboard():
```javascript
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
    // Update currentData with new status
    if (data.containers) {
      // Update container status from status JSON
      updateStatusFromWebSocket(data);
    }
  });
  
  socket.on('disconnect', () => {
    console.log('[WebSocket] Disconnected from server');
    // Try to reconnect after 5 seconds
    setTimeout(initWebSocket, 5000);
  });
}

function updateStatusFromWebSocket(data) {
  // Update sites status from containers array
  if (data.containers && Array.isArray(data.containers)) {
    // Map container status to site data
    data.containers.forEach(container => {
      // Update site status if it's a WordPress container
      if (container.name && container.name.startsWith('wp_')) {
        const siteName = container.name.replace('wp_', '');
        const site = currentData.sites.find(s => s.name === siteName);
        if (site) {
          site.status = container.status.toLowerCase().includes('up') ? 'Running' : 'Stopped';
        }
      }
    });
  }
  
  // Trigger UI update
  updateDashboard();
}

// Start WebSocket connection
initWebSocket();
```

3. Add cleanup on page unload:
```javascript
window.addEventListener('beforeunload', () => {
  if (socket) {
    socket.disconnect();
  }
});
```
</action>
<acceptance_criteria>
- socket.io client library loads in browser without errors
- WebSocket connects to server on page load
- Console shows "Connected to server" message
- When server emits 'status.changed', client receives it
- updateDashboard() called to refresh UI
- Status badges visually update without full page reload
</acceptance_criteria>
</task>

## Verification
1. Start frontend: `cd frontend && npm start`
2. Open browser console at http://localhost:8500
3. Verify "WebSocket: Connected to server" appears
4. Start/stop a site via another tab
5. Within 30 seconds, see status badge change in first tab
6. Console shows "Status changed received"
