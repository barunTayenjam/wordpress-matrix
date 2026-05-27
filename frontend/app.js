const express = require('express');
const exphbs = require('express-handlebars');
const path = require('path');
const cors = require('cors');
const http = require('http');
const fs = require('fs');
const { Server } = require('socket.io');
const { spawn } = require('child_process');

let redis = null;
try {
  redis = require('redis');
} catch (e) {
  console.log('[Redis] Module not available');
}

require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const PROJECT_ROOT = path.join(__dirname, '..');
const MATRIX_PATH = path.join(PROJECT_ROOT, 'matrix');

// Load validation config from shared source
const loadValidationConfig = () => {
  const { execSync } = require('child_process');
  const configPath = path.join(PROJECT_ROOT, 'config', 'validation.sh');
  try {
    if (fs.existsSync(configPath)) {
      const output = execSync(`source "${configPath}" && validation_json 2>/dev/null`, {
        cwd: PROJECT_ROOT,
        shell: '/bin/bash',
        encoding: 'utf-8',
        timeout: 5000,
      });
      return JSON.parse(output);
    }
  } catch (e) {
    console.log('[Config] Shared validation not available, using defaults');
  }
  return null;
};

const VALIDATION_CONFIG = loadValidationConfig();

const VALID_SITE_NAME = new RegExp(
  (VALIDATION_CONFIG && VALIDATION_CONFIG.siteNameRegex) || '^[a-zA-Z][a-zA-Z0-9_-]*$'
);
const RESERVED_SITE_NAMES = new Set(
  (VALIDATION_CONFIG && VALIDATION_CONFIG.reservedNames) || ['frontend', 'matrix', 'db', 'redis', 'phpmyadmin', 'nginx', 'content']
);
const SUPPORTED_PHP_VERSIONS = new Set(
  (VALIDATION_CONFIG && VALIDATION_CONFIG.supportedPhpVersions) || ['7.4', '8.0', '8.1', '8.2', '8.3']
);
const DEFAULT_PHP_VERSION = (VALIDATION_CONFIG && VALIDATION_CONFIG.defaultPhpVersion) || '8.3';
const SITE_ACTIONS_REQUIRING_NAME = new Set(['create', 'start', 'stop', 'restart', 'remove', 'delete', 'rm', 'info', 'url', 'logs', 'backup', 'restore', 'edit', 'clone', 'reset', 'export-db', 'import-db', 'check', 'rest', 'xdebug', 'repair']);
const ALLOWED_SITE_ACTIONS = new Set([...SITE_ACTIONS_REQUIRING_NAME]);
const ALLOWED_ENV_ACTIONS = new Set(['start', 'stop', 'restart', 'status', 'logs', 'clean', 'check', 'health', 'cache', 'cache-clear', 'search-replace', 'update', 'update-core', 'install']);
const ALLOWED_FRONTEND_ACTIONS = new Set(['start', 'stop', 'restart', 'status']);
const MUTATING_SITE_ACTIONS = new Set(['create', 'start', 'stop', 'restart', 'remove', 'delete', 'rm', 'backup', 'restore', 'edit', 'clone', 'reset', 'export-db', 'import-db', 'check']);
const MUTATING_ENV_ACTIONS = new Set(['start', 'stop', 'restart', 'clean', 'check', 'cache', 'cache-clear', 'search-replace', 'update', 'update-core', 'install']);
const ERROR_STATUS_MAP = {
  INVALID_ACTION: 400,
  INVALID_NAME: 400,
  INVALID_INPUT: 400,
  COMMAND_FAILED: 500,
  DOCKER_ERROR: 503,
};

// Redis client for caching (optional)
let redisClient = null;
const CACHE_TTL = 30; // 30 seconds cache

const initRedis = async () => {
  if (!redis) return;
  try {
    redisClient = redis.createClient({
      url: process.env.REDIS_URL || 'redis://localhost:6379'
    });
    redisClient.on('error', (err) => console.error('[Redis] Error:', err));
    await redisClient.connect();
    console.log('[Redis] Connected');
  } catch (err) {
    console.log('[Redis] Not available, caching disabled');
  }
};
if (process.env.NODE_ENV !== 'test') {
  initRedis();
}

// Cache middleware
const cacheGet = async (key) => {
  if (!redisClient) return null;
  try {
    const data = await redisClient.get(key);
    return data ? JSON.parse(data) : null;
  } catch { return null; }
};

const cacheSet = async (key, data, ttl = CACHE_TTL) => {
  if (!redisClient) return;
  try {
    await redisClient.setEx(key, ttl, JSON.stringify(data));
  } catch {}
};

const cacheDel = async (key) => {
  if (!redisClient) return;
  try {
    await redisClient.del(key);
  } catch {}
};

const parseJsonOutput = (stdout) => {
  if (!stdout || !stdout.trim()) return null;
  return JSON.parse(stdout);
};

const validateSiteName = (name) => {
  if (!name || typeof name !== 'string') {
    return { valid: false, code: 'INVALID_NAME', message: 'Site name is required' };
  }
  if (!VALID_SITE_NAME.test(name)) {
    return { valid: false, code: 'INVALID_NAME', message: 'Site name must start with a letter and contain only alphanumeric characters, hyphens, and underscores' };
  }
  if (RESERVED_SITE_NAMES.has(name.toLowerCase())) {
    return { valid: false, code: 'INVALID_NAME', message: `"${name}" is a reserved site name` };
  }
  return { valid: true };
};

const validatePhpVersion = (version) => {
  if (!version) return { valid: true };
  if (!SUPPORTED_PHP_VERSIONS.has(String(version))) {
    return { valid: false, code: 'INVALID_INPUT', message: 'Unsupported PHP version' };
  }
  return { valid: true };
};

const validateRelativeFilePath = (value, label) => {
  if (!value || typeof value !== 'string') {
    return { valid: false, code: 'INVALID_INPUT', message: `${label} is required` };
  }
  if (path.isAbsolute(value) || value.includes('..') || /[\0\r\n]/.test(value)) {
    return { valid: false, code: 'INVALID_INPUT', message: `${label} must be a relative path inside the project` };
  }
  return { valid: true };
};

const validateCommandArgs = (args) => {
  if (!Array.isArray(args)) {
    return { valid: false, code: 'INVALID_INPUT', message: 'Command arguments must be an array' };
  }
  for (const arg of args) {
    if (typeof arg !== 'string' || /[\0\r\n]/.test(arg)) {
      return { valid: false, code: 'INVALID_INPUT', message: 'Command arguments contain invalid characters' };
    }
  }
  return { valid: true };
};

const sendError = (res, code, message, overrideStatus) => {
  const status = overrideStatus || ERROR_STATUS_MAP[code] || 500;
  return res.status(status).json({ success: false, error: { code, message } });
};

const getErrorMessage = (result) => {
  if (!result) return 'Unknown error';
  if (result.error && typeof result.error === 'string') return result.error;
  if (result.stderr && result.stderr.trim()) return result.stderr.trim();
  if (result.stdout && result.stdout.trim()) {
    const lines = result.stdout.split('\n').map(line => line.trim()).filter(Boolean);
    return lines[lines.length - 1] || 'Command failed';
  }
  return 'Command failed';
};

const invalidateSitesCache = () => cacheDel('api:sites');

const validateRequestSiteName = (res, siteName) => {
  const validation = validateSiteName(siteName);
  if (!validation.valid) {
    sendError(res, validation.code, validation.message);
    return false;
  }
  return true;
};

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
    const result = await executeMatrix('status', [], { json: true });
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

const startStatusPolling = () => {
  const interval = setInterval(pollStatus, POLL_INTERVAL);
  console.log(`[WebSocket] Status polling started (every ${POLL_INTERVAL/1000}s)`);
  setTimeout(() => {
    pollStatus();
  }, 2000);
  return interval;
};

// Middleware
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
      return callback(null, true);
    }
    return callback(new Error('CORS origin not allowed'));
  }
}));
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
const executeMatrix = async (command, args = [], options = {}) => {
  return new Promise((resolve, reject) => {
    const isLongRunning = ['check', 'start', 'stop', 'restart', 'create', 'logs', 'import-db', 'export-db', 'restore', 'clone', 'reset', 'install', 'edit', 'remove', 'backup'].includes(command);
    const timeout = isLongRunning ? 300000 : 30000;
    const matrixArgs = [command, ...args];

    if (options.json && !matrixArgs.includes('--json')) {
      matrixArgs.push('--json');
    }

    console.log(`[Frontend] Executing: matrix ${matrixArgs.join(' ')}`);

    const matrixCmd = spawn(MATRIX_PATH, matrixArgs, {
      cwd: PROJECT_ROOT,
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
      let data;
      if (options.json && stdout) {
        try {
          data = parseJsonOutput(stdout);
        } catch (parseError) {
          resolve({ success: false, stdout, stderr, exitCode: code, error: `Invalid JSON output: ${parseError.message}` });
          return;
        }
      }

      if (code === 0) {
        resolve({ success: true, stdout, stderr, data });
      } else {
        resolve({ success: false, stdout, stderr, exitCode: code, data });
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
    const result = await executeMatrix('list', [], { json: true });
    let sites = [];
    let services = [];
    
    if (result.success && result.data) {
      sites = (result.data.sites || []).map(s => ({
        ...s,
        status: s.status ? s.status.charAt(0).toUpperCase() + s.status.slice(1) : s.status
      }));
      services = (result.data.services || []).map(s => ({
        ...s,
        status: s.status ? s.status.charAt(0).toUpperCase() + s.status.slice(1) : s.status
      }));
    }
    
    const runningSitesCount = sites.filter(s => s.status && s.status.toLowerCase() === 'running').length;
    res.render('dashboard', {
      title: 'WordPress Matrix Dashboard',
      sites,
      services,
      runningSitesCount,
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
  const cacheKey = 'api:sites';
  
  // Try cache first
  const cached = await cacheGet(cacheKey);
  if (cached) {
    return res.json(cached);
  }
  
  try {
    const result = await executeMatrix('list', [], { json: true });
    
    let data = { sites: [], services: [] };
    if (result.success && result.data) {
      data = result.data;
    } else if (!result.success) {
      return sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
    
    const response = {
      success: true,
      sites: (data.sites || []).map(s => ({
        ...s,
        status: s.status ? s.status.charAt(0).toUpperCase() + s.status.slice(1) : s.status
      })),
      services: (data.services || []).map(s => ({
        ...s,
        status: s.status ? s.status.charAt(0).toUpperCase() + s.status.slice(1) : s.status
      }))
    };
    
    // Cache the response
    await cacheSet(cacheKey, response, CACHE_TTL);
    
    res.json(response);
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Specific site action endpoints (must be before /api/sites/:action catch-all)

// Backup endpoint
app.post('/api/sites/backup', async (req, res) => {
  const { siteName } = req.body;

  if (!validateRequestSiteName(res, siteName)) {
    return;
  }

  try {
    const result = await executeMatrix('backup', [siteName]);

    if (result.success) {
      await invalidateSitesCache();
      res.json({ success: true, output: result.stdout });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Restart site endpoint
app.post('/api/sites/restart', async (req, res) => {
  const { siteName } = req.body;

  if (!validateRequestSiteName(res, siteName)) {
    return;
  }

  try {
    const io = app.get('io');
    if (io) {
      io.emit('site.operation', { type: 'start', operation: 'restart', site: siteName, timestamp: new Date().toISOString() });
    }

    const result = await executeMatrix('restart', [siteName]);

    if (io) {
      io.emit('site.operation', { type: result.success ? 'success' : 'failure', operation: 'restart', site: siteName, timestamp: new Date().toISOString() });
    }

    if (result.success) {
      await invalidateSitesCache();
      res.json({ success: true, output: result.stdout, exitCode: result.exitCode });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Get site URL endpoint
app.post('/api/sites/url', async (req, res) => {
  const { siteName } = req.body;

  if (!validateRequestSiteName(res, siteName)) {
    return;
  }

  try {
    const result = await executeMatrix('url', [siteName]);
    if (result.success) {
      res.json({ success: true, output: result.stdout });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Restore site endpoint
app.post('/api/sites/restore', async (req, res) => {
  const { siteName, backupFile } = req.body;

  if (!validateRequestSiteName(res, siteName)) {
    return;
  }
  const backupValidation = validateRelativeFilePath(backupFile, 'Backup file');
  if (!backupValidation.valid) {
    return sendError(res, backupValidation.code, backupValidation.message);
  }

  try {
    const result = await executeMatrix('restore', [siteName, backupFile]);
    if (result.success) {
      await invalidateSitesCache();
      res.json({ success: true, output: result.stdout, exitCode: result.exitCode });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Export database endpoint
app.post('/api/sites/export-db', async (req, res) => {
  const { siteName, outputFile } = req.body;

  if (!validateRequestSiteName(res, siteName)) {
    return;
  }
  if (outputFile) {
    const outputValidation = validateRelativeFilePath(outputFile, 'Output file');
    if (!outputValidation.valid) {
      return sendError(res, outputValidation.code, outputValidation.message);
    }
  }

  try {
    const args = [siteName];
    if (outputFile) args.push(outputFile);
    const result = await executeMatrix('export-db', args);
    if (result.success) {
      res.json({ success: true, output: result.stdout, exitCode: result.exitCode });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Import database endpoint
app.post('/api/sites/import-db', async (req, res) => {
  const { siteName, dumpFile } = req.body;

  if (!validateRequestSiteName(res, siteName)) {
    return;
  }
  const dumpValidation = validateRelativeFilePath(dumpFile, 'Dump file');
  if (!dumpValidation.valid) {
    return sendError(res, dumpValidation.code, dumpValidation.message);
  }

  try {
    const result = await executeMatrix('import-db', [siteName, dumpFile]);
    if (result.success) {
      await invalidateSitesCache();
      res.json({ success: true, output: result.stdout, exitCode: result.exitCode });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Edit site endpoint
app.post('/api/sites/edit', async (req, res) => {
  const { siteName, phpVersion } = req.body;

  if (!validateRequestSiteName(res, siteName)) {
    return;
  }
  const phpValidation = validatePhpVersion(phpVersion);
  if (!phpValidation.valid) {
    return sendError(res, phpValidation.code, phpValidation.message);
  }

  try {
    const args = [siteName];
    if (phpVersion) args.push(`--php-version=${phpVersion}`);
    const result = await executeMatrix('edit', args);
    if (result.success) {
      await invalidateSitesCache();
      res.json({ success: true, output: result.stdout, exitCode: result.exitCode });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Clone site endpoint
app.post('/api/sites/clone', async (req, res) => {
  const { sourceName, destName } = req.body;

  if (!validateRequestSiteName(res, sourceName)) {
    return;
  }
  const destValidation = validateSiteName(destName);
  if (!destValidation.valid) {
    return sendError(res, destValidation.code, destValidation.message);
  }

  try {
    const result = await executeMatrix('clone', [sourceName, destName]);
    if (result.success) {
      await invalidateSitesCache();
      res.json({ success: true, output: result.stdout, exitCode: result.exitCode });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Reset site endpoint
app.post('/api/sites/reset', async (req, res) => {
  const { siteName } = req.body;

  if (!validateRequestSiteName(res, siteName)) {
    return;
  }

  try {
    const result = await executeMatrix('reset', [siteName]);
    if (result.success) {
      await invalidateSitesCache();
      res.json({ success: true, output: result.stdout, exitCode: result.exitCode });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Site logs endpoint
app.post('/api/sites/logs', async (req, res) => {
  const { siteName } = req.body;

  if (!validateRequestSiteName(res, siteName)) {
    return;
  }

  try {
    const result = await executeMatrix('logs', [siteName]);
    if (result.success) {
      res.json({ success: true, output: result.stdout });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

app.post('/api/sites/rest', async (req, res) => {
  const { siteName } = req.body;
  if (!validateRequestSiteName(res, siteName)) return;
  try {
    const result = await executeMatrix('rest', [siteName]);
    if (result.success) {
      res.json({ success: true, output: result.stdout });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

app.post('/api/sites/xdebug', async (req, res) => {
  const { siteName, enabled } = req.body;
  if (!validateRequestSiteName(res, siteName)) return;
  try {
    const result = await executeMatrix('xdebug', [siteName]);
    if (result.success) {
      res.json({ success: true, output: result.stdout });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

app.post('/api/sites/repair', async (req, res) => {
  const { siteName } = req.body;
  if (!validateRequestSiteName(res, siteName)) return;
  try {
    const result = await executeMatrix('repair', [siteName]);
    if (result.success) {
      res.json({ success: true, output: result.stdout });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

app.post('/api/sites/wp-cli', async (req, res) => {
  const { siteName, command } = req.body;
  if (!validateRequestSiteName(res, siteName)) return;
  if (!command || typeof command !== 'string' || command.length > 500 || /[;&|`$]/.test(command)) {
    return sendError(res, 'INVALID_INPUT', 'Invalid WP-CLI command');
  }
  try {
    const result = await executeMatrix('wp', [siteName, ...command.trim().split(/\s+/)]);
    if (result.success) {
      res.json({ success: true, output: result.stdout });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Catch-all for remaining site actions (create, start, stop, remove, info, check)
app.post('/api/sites/:action', async (req, res) => {
  const { action } = req.params;
  const { siteName, phpVersion } = req.body;

  if (!ALLOWED_SITE_ACTIONS.has(action)) {
    return sendError(res, 'INVALID_ACTION', `Invalid site action: ${action}`);
  }

  if (SITE_ACTIONS_REQUIRING_NAME.has(action) && !validateRequestSiteName(res, siteName)) {
    return;
  }

  if (action === 'create') {
      const phpValidation = validatePhpVersion(phpVersion || DEFAULT_PHP_VERSION);
    if (!phpValidation.valid) {
      return sendError(res, phpValidation.code, phpValidation.message);
    }
  }

  try {
    const args = action === 'create'
      ? [siteName, `--php-version=${phpVersion || DEFAULT_PHP_VERSION}`]
      : ['remove', 'delete', 'rm'].includes(action)
        ? [siteName, '--yes']
        : [siteName];
    
    const io = app.get('io');
    if (io) {
      io.emit('site.operation', {
        type: 'start',
        operation: action,
        site: siteName,
        timestamp: new Date().toISOString()
      });
    }
    
    const result = await executeMatrix(action, args);
    
    if (io) {
      io.emit('site.operation', {
        type: result.success ? 'success' : 'failure',
        operation: action,
        site: siteName,
        timestamp: new Date().toISOString()
      });
    }
    
    if (result.success) {
      if (MUTATING_SITE_ACTIONS.has(action)) {
        await invalidateSitesCache();
      }
      res.json({
        success: true,
        output: result.stdout,
        exitCode: result.exitCode
      });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

app.post('/api/environment/:action', async (req, res) => {
  const { action } = req.params;
  const args = Array.isArray(req.body?.args) ? req.body.args : [];

  if (!ALLOWED_ENV_ACTIONS.has(action)) {
    return sendError(res, 'INVALID_ACTION', `Invalid environment action: ${action}`);
  }
  const argsValidation = validateCommandArgs(args);
  if (!argsValidation.valid) {
    return sendError(res, argsValidation.code, argsValidation.message);
  }

  try {
    if (action === 'restart') {
      // For restart, respond immediately and restart in background
      // to avoid the server killing itself before sending the response
      res.json({
        success: true,
        output: 'Environment restart initiated...',
        exitCode: 0
      });
      
      // Restart environment in background without waiting for completion
      setTimeout(() => {
        const { spawn } = require('child_process');
        const path = require('path');
        const matrixPath = path.join(__dirname, '..', 'matrix');
        const matrixCmd = spawn(matrixPath, ['restart'], {
          detached: true,
          stdio: 'ignore'
        });
        
        matrixCmd.unref(); // Prevent the parent from waiting for the child
      }, 100);
    } else {
      // For other actions, proceed normally
      const result = await executeMatrix(action, args);
      if (result.success) {
        if (MUTATING_ENV_ACTIONS.has(action)) {
          await invalidateSitesCache();
        }
        res.json({
          success: true,
          output: result.stdout,
          exitCode: result.exitCode
        });
      } else {
        sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
      }
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Frontend management endpoint
app.post('/api/frontend/:action', async (req, res) => {
  const { action } = req.params;

  if (!ALLOWED_FRONTEND_ACTIONS.has(action)) {
    return sendError(res, 'INVALID_ACTION', `Invalid frontend action: ${action}`);
  }

  try {
    if (action === 'restart') {
      // For restart, respond immediately and restart in background
      // to avoid the server killing itself before sending the response
      res.json({
        success: true,
        output: 'Frontend restart initiated...',
        exitCode: 0
      });
      
      // Restart frontend in background without waiting for completion
      setTimeout(() => {
        const { spawn } = require('child_process');
        const path = require('path');
        const matrixPath = path.join(__dirname, '..', 'matrix');
        const matrixCmd = spawn(matrixPath, ['frontend', 'restart'], {
          detached: true,
          stdio: 'ignore'
        });
        
        matrixCmd.unref(); // Prevent the parent from waiting for the child
      }, 100);
    } else {
      // For other actions, proceed normally
      const result = await executeMatrix('frontend', [action]);
      if (result.success) {
        res.json({
          success: true,
          output: result.stdout,
          exitCode: result.exitCode
        });
      } else {
        sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
      }
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// List backups endpoint
app.get('/api/backups', async (req, res) => {
  try {
    const fs = require('fs');
    const backupDir = path.join(__dirname, '..', 'backups');
    
    if (!fs.existsSync(backupDir)) {
      return res.json({ success: true, backups: [] });
    }
    
    const files = fs.readdirSync(backupDir)
      .filter(f => f.endsWith('.tar.gz'))
      .map(f => {
        const stats = fs.statSync(path.join(backupDir, f));
        return { name: f, size: stats.size, date: stats.mtime };
      });
    
    res.json({ success: true, backups: files });
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

app.get('/api/status', async (req, res) => {
  try {
    const result = await executeMatrix('status');
    if (result.success) {
      res.json({
        success: true,
        output: result.stdout
      });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

app.get('/api/help', async (req, res) => {
  try {
    const result = await executeMatrix('help');
    if (result.success) {
      res.json({
        success: true,
        output: result.stdout
      });
    } else {
      sendError(res, 'COMMAND_FAILED', getErrorMessage(result));
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Site health check endpoint
app.get('/api/health/:siteName', async (req, res) => {
  const { siteName } = req.params;
  
  if (!validateRequestSiteName(res, siteName)) {
    return;
  }
  
  try {
    const sitesResult = await executeMatrix('list', [], { json: true });
    let sites = [];
    if (sitesResult.success && sitesResult.data) {
      sites = sitesResult.data.sites || [];
    }
    
    const site = sites.find(s => s.name === siteName);
    if (!site || !site.port) {
      return res.json({ success: true, site: siteName, healthy: false, reason: 'Site not running or no port' });
    }
    
    const url = `http://localhost:${site.port}`;
    const startTime = Date.now();
    
    try {
      const response = await fetch(url, { method: 'HEAD', signal: AbortSignal.timeout(5000) });
      const responseTime = Date.now() - startTime;
      
      res.json({
        success: true,
        site: siteName,
        healthy: response.ok,
        status: response.status,
        responseTime: `${responseTime}ms`,
        url
      });
    } catch (fetchError) {
      res.json({
        success: true,
        site: siteName,
        healthy: false,
        error: fetchError.message,
        url
      });
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// Activity log endpoint
app.get('/api/activity', async (req, res) => {
  const logPath = path.join(__dirname, '..', 'logs', 'activity.log');
  const limit = parseInt(req.query.limit) || 50;

  try {
    if (!fs.existsSync(logPath)) {
      return res.json({ success: true, activities: [] });
    }

    const content = fs.readFileSync(logPath, 'utf-8');
    const lines = content.trim().split('\n').filter(l => l.length > 0);
    const activities = lines.slice(-limit).reverse().map(line => {
      const match = line.match(/^\[(.*?)\] (\w+) \| (.*?) \| (.*)$/);
      if (match) {
        return {
          timestamp: match[1],
          action: match[2],
          site: match[3],
          details: match[4]
        };
      }
      return null;
    }).filter(a => a !== null);

    res.json({ success: true, activities });
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).render('error', {
    title: 'Page Not Found',
    layout: 'main',
    error: 'The page you\'re looking for doesn\'t exist.'
  });
});

const startServer = (port = PORT) => {
  startStatusPolling();
  return server.listen(port, () => {
    console.log(`WordPress Matrix Frontend running on http://localhost:${port}`);
    console.log(`Dashboard: http://localhost:${port}`);
    console.log(`API Endpoint: http://localhost:${port}/api`);
    console.log('WebSocket: Enabled');
  });
};

if (require.main === module) {
  startServer();
}

module.exports = {
  app,
  server,
  startServer,
  executeMatrix,
  parseJsonOutput,
  validateSiteName,
  validatePhpVersion,
  validateRelativeFilePath,
  validateCommandArgs,
  sendError,
  constants: {
    ALLOWED_SITE_ACTIONS,
    ALLOWED_ENV_ACTIONS,
    ALLOWED_FRONTEND_ACTIONS,
    SUPPORTED_PHP_VERSIONS,
    RESERVED_SITE_NAMES,
    DEFAULT_PHP_VERSION,
    VALIDATION_CONFIG,
  },
};