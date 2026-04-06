const express = require('express');
const exphbs = require('express-handlebars');
const path = require('path');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const { spawn } = require('child_process');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Create HTTP server and initialize socket.io
const server = http.createServer(app);
const io = new Server(server);

io.on('connection', (socket) => {
  console.log('[WebSocket] Client connected:', socket.id);
  
  socket.on('disconnect', () => {
    console.log('[WebSocket] Client disconnected:', socket.id);
  });
});

app.set('io', io);

// Status polling for real-time updates
let lastStatus = null;
const POLL_INTERVAL = 30000; // 30 seconds

const pollStatus = async () => {
  try {
    const result = await executeMatrix('status', [], true);
    if (result.success && result.data) {
      const currentStatus = JSON.stringify(result.data);
      
      if (lastStatus !== null && lastStatus !== currentStatus) {
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

// Start status polling
setInterval(pollStatus, POLL_INTERVAL);
console.log(`[WebSocket] Status polling started (every ${POLL_INTERVAL/1000}s)`);

// Initial status fetch after server starts
setTimeout(() => {
  pollStatus();
}, 2000);

// Validation constants
const SUPPORTED_PHP_VERSIONS = ['7.4', '8.0', '8.1', '8.2', '8.3'];
const VALID_SITE_NAME = /^[a-zA-Z][a-zA-Z0-9_-]*$/;
const RESERVED_NAMES = ['frontend', 'matrix', 'db', 'redis', 'phpmyadmin', 'nginx'];
const VALID_SITE_ACTIONS = ['create', 'start', 'stop', 'remove', 'info', 'url'];
const VALID_ENV_ACTIONS = ['start', 'stop', 'restart', 'status', 'logs', 'clean', 'check'];

const ERROR_STATUS_MAP = {
  SITE_NOT_FOUND: 404,
  SITE_ALREADY_EXISTS: 409,
  INVALID_NAME: 400,
  DOCKER_ERROR: 503,
  COMMAND_FAILED: 500,
};

const sendError = (res, code, message, overrideStatus) => {
  const status = overrideStatus || ERROR_STATUS_MAP[code] || 500;
  res.status(status).json({ success: false, error: { code, message } });
};

const validateSiteName = (name) => {
  if (!name || typeof name !== 'string') return { valid: false, code: 'INVALID_NAME', message: 'Site name is required' };
  if (!VALID_SITE_NAME.test(name)) return { valid: false, code: 'INVALID_NAME', message: 'Site name must start with a letter and contain only alphanumeric characters, hyphens, and underscores' };
  if (RESERVED_NAMES.includes(name.toLowerCase())) return { valid: false, code: 'INVALID_NAME', message: `"${name}" is a reserved name` };
  return { valid: true };
};

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Handlebars setup
app.engine('handlebars', exphbs.engine({
  defaultLayout: 'main',
  layoutsDir: path.join(__dirname, 'views/layouts'),
  helpers: {
    eq: (a, b) => a === b,
    ne: (a, b) => a !== b
  }
}));
app.set('view engine', 'handlebars');
app.set('views', path.join(__dirname, 'views'));

// Helper function to execute matrix command
const executeMatrix = async (command, args = [], jsonMode = false, operationName = null) => {
  return new Promise((resolve, reject) => {
    const projectRoot = path.join(__dirname, '..');
    const matrixPath = path.join(projectRoot, 'matrix');

    // Longer timeout for operations like check, start, stop
    const isLongRunning = ['check', 'start', 'stop', 'restart', 'create'].includes(command);
    const timeout = isLongRunning ? 120000 : 30000; // 2 minutes for long operations

    // Build spawn args - prepend --json when jsonMode is true
    const spawnArgs = jsonMode ? [command, '--json', ...args] : [command, ...args];
    
    console.log(`[Frontend] Executing: matrix ${spawnArgs.join(' ')}`);

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

    const matrixCmd = spawn(matrixPath, spawnArgs, {
      cwd: projectRoot,
      timeout: timeout,
      env: { ...process.env, NODE_ENV: 'development' }
    });

    let stdout = '';
    let stderr = '';

    matrixCmd.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    matrixCmd.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    matrixCmd.on('close', (code) => {
      console.log(`[Frontend] Command completed with code: ${code}`);
      if (jsonMode && code === 0) {
        try {
          const jsonData = JSON.parse(stdout);
          resolve({ success: true, data: jsonData, stdout, stderr });
        } catch (e) {
          console.error(`[Frontend] JSON parse error:`, e);
          resolve({ success: false, stdout, stderr, exitCode: code, error: 'Invalid JSON from CLI' });
        }
      } else if (jsonMode && code !== 0) {
        try {
          const errData = JSON.parse(stdout);
          resolve({ success: false, data: errData, stdout, stderr, exitCode: code });
        } catch (e) {
          resolve({ success: false, stdout, stderr, exitCode: code });
        }
      } else if (code === 0) {
        resolve({ success: true, stdout, stderr });
      } else {
        resolve({ success: false, stdout, stderr, exitCode: code });
      }

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
    });

    matrixCmd.on('error', (error) => {
      console.error(`[Frontend] Command error:`, error);
      reject(error);
    });

    matrixCmd.on('timeout', () => {
      console.error(`[Frontend] Command timeout after ${timeout}ms`);
      matrixCmd.kill();
      resolve({ success: false, stdout, stderr, error: 'Command timeout' });
    });
  });
};

// Routes
app.get('/', async (req, res) => {
  try {
    const result = await executeMatrix('list', [], true);
    const { sites, services } = result.data || { sites: [], services: [] };
    
    res.render('dashboard', {
      title: 'WordPress Matrix Dashboard',
      sites,
      services,
      matrixCommand: './matrix'
    });
  } catch (error) {
    res.render('error', {
      title: 'Error',
      error: error.message
    });
  }
});

app.get('/api/sites', async (req, res) => {
  try {
    const result = await executeMatrix('list', [], true);
    const { sites, services } = result.data || { sites: [], services: [] };
    
    res.json({
      success: true,
      sites,
      services
    });
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

app.post('/api/sites/:action', async (req, res) => {
  const { action } = req.params;
  const { siteName, phpVersion } = req.body;

  if (!VALID_SITE_ACTIONS.includes(action)) {
    return sendError(res, 'INVALID_NAME', `Invalid action: ${action}`, 400);
  }

  if (siteName) {
    const validation = validateSiteName(siteName);
    if (!validation.valid) {
      return sendError(res, validation.code, validation.message);
    }
  } else if (['create', 'start', 'stop', 'remove', 'info', 'url'].includes(action)) {
    return sendError(res, 'INVALID_NAME', 'Site name is required', 400);
  }

  if (phpVersion && !SUPPORTED_PHP_VERSIONS.includes(phpVersion)) {
    return sendError(res, 'INVALID_NAME', `Invalid PHP version: ${phpVersion}. Supported: ${SUPPORTED_PHP_VERSIONS.join(', ')}`, 400);
  }

  try {
    let args;
    if (action === 'create') {
      args = phpVersion ? [siteName, `--php-version=${phpVersion}`] : [siteName];
    } else if (action === 'remove') {
      args = [siteName, '--yes'];
    } else {
      args = [siteName];
    }

    const useJson = ['info'].includes(action);
    const operationName = `${action}_${siteName}`;
    const result = await executeMatrix(action, args, useJson, operationName);

    if (!result.success) {
      if (result.data && result.data.error) {
        return sendError(res, result.data.error.code, result.data.error.message);
      }
      return sendError(res, 'COMMAND_FAILED', result.stderr || 'Command failed');
    }

    const response = { success: true };
    if (useJson && result.data) {
      response.data = result.data;
    } else {
      response.output = result.stdout;
    }
    res.json(response);
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

app.post('/api/environment/:action', async (req, res) => {
  const { action } = req.params;

  if (!VALID_ENV_ACTIONS.includes(action)) {
    return sendError(res, 'INVALID_NAME', `Invalid action: ${action}`, 400);
  }

  try {
    const operationName = action;
    const result = await executeMatrix(action, [], false, operationName);
    
    if (!result.success) {
      return sendError(res, 'COMMAND_FAILED', result.stderr || 'Command failed');
    }

    res.json({
      success: true,
      output: result.stdout
    });
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Frontend management endpoint
app.post('/api/frontend/:action', async (req, res) => {
  const { action } = req.params;
  const validActions = ['start', 'stop', 'restart', 'status'];

  if (!validActions.includes(action)) {
    return sendError(res, 'INVALID_NAME', `Invalid action: ${action}`, 400);
  }

  try {
    const result = await executeMatrix('frontend', [action]);
    
    if (!result.success) {
      return sendError(res, 'COMMAND_FAILED', result.stderr || 'Command failed');
    }

    res.json({
      success: true,
      output: result.stdout
    });
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

app.get('/api/status', async (req, res) => {
  try {
    const result = await executeMatrix('status', [], true);
    
    if (!result.success) {
      if (result.data && result.data.error) {
        return sendError(res, result.data.error.code, result.data.error.message);
      }
      return sendError(res, 'COMMAND_FAILED', result.stderr || 'Command failed');
    }

    res.json({
      success: true,
      data: result.data || null
    });
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

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

app.get('/api/help', async (req, res) => {
  try {
    const result = await executeMatrix('help');
    
    res.json({
      success: true,
      output: result.stdout
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Start server
server.listen(PORT, () => {
  console.log(`🚀 WordPress Matrix Frontend running on http://localhost:${PORT}`);
  console.log(`📊 Dashboard: http://localhost:${PORT}`);
  console.log(`🔗 API Endpoint: http://localhost:${PORT}/api`);
  console.log(`⚡ WebSocket: ws://localhost:${PORT}`);
});