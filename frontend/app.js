const express = require('express');
const exphbs = require('express-handlebars');
const path = require('path');
const cors = require('cors');
const http = require('http');
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
initRedis();

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
const executeMatrix = async (command, args = []) => {
  return new Promise((resolve, reject) => {
    const projectRoot = path.join(__dirname, '..');
    const matrixPath = path.join(projectRoot, 'matrix');

    const isLongRunning = ['check', 'start', 'stop', 'restart', 'create', 'import-db', 'export-db', 'restore', 'clone', 'reset', 'install', 'edit', 'remove', 'backup'].includes(command);
    const timeout = isLongRunning ? 300000 : 30000;

    console.log(`[Frontend] Executing: matrix ${command} ${args.join(' ')}`);

    const matrixCmd = spawn(matrixPath, [command, ...args], {
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
      if (code === 0) {
        resolve({ success: true, stdout, stderr });
      } else {
        resolve({ success: false, stdout, stderr, exitCode: code });
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

// Parse site list output
const parseSiteList = (output) => {
  const lines = output.split('\n');
  const sites = [];
  const services = [];
  let inSitesSection = false;
  let inServicesSection = false;

  for (const line of lines) {
    if (line.includes('WordPress Sites & Services')) {
      inSitesSection = true;
      continue;
    }
    
    if (line.includes('Service') && line.includes('Status')) {
      inSitesSection = false;
      inServicesSection = true;
      continue;
    }

    if (line.includes('─') || line.trim() === '') {
      continue;
    }

    const parts = line.trim().split(/\s{2,}/);
    if (parts.length >= 4) {
      const item = {
        name: parts[0],
        status: parts[1],
        localUrl: parts[2],
        domainUrl: parts[3],
        type: inSitesSection ? 'site' : 'service'
      };

      if (inSitesSection && !item.name.includes('Site')) {
        sites.push(item);
      } else if (inServicesSection && !item.name.includes('Service')) {
        services.push(item);
      }
    }
  }

  return { sites, services };
};

// Routes
app.get('/', async (req, res) => {
  try {
    const result = await executeMatrix('list', ['--json']);
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
  const cacheKey = 'api:sites';
  
  // Try cache first
  const cached = await cacheGet(cacheKey);
  if (cached) {
    return res.json(cached);
  }
  
  try {
    const result = await executeMatrix('list', ['--json']);
    
    // Parse JSON from stdout since --json flag is used
    let data = { sites: [], services: [] };
    if (result.success && result.stdout) {
      try {
        data = JSON.parse(result.stdout);
      } catch (parseErr) {
        console.error('[API] Failed to parse JSON:', parseErr.message);
      }
    }
    
    const response = {
      success: true,
      sites: data.sites || [],
      services: data.services || []
    };
    
    // Cache the response
    await cacheSet(cacheKey, response, CACHE_TTL);
    
    res.json(response);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Specific site action endpoints (must be before /api/sites/:action catch-all)

// Backup endpoint
app.post('/api/sites/backup', async (req, res) => {
  const { siteName } = req.body;

  if (!siteName) {
    return res.status(400).json({ success: false, error: 'Site name required' });
  }

  try {
    const result = await executeMatrix('backup', [siteName]);

    if (result.success) {
      res.json({ success: true, output: result.stdout });
    } else {
      res.status(500).json({ success: false, error: result.stderr });
    }
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Restart site endpoint
app.post('/api/sites/restart', async (req, res) => {
  const { siteName } = req.body;

  if (!siteName) {
    return res.status(400).json({ success: false, error: 'Site name is required' });
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

    res.json({ success: result.success, output: result.stdout, error: result.stderr, exitCode: result.exitCode });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get site URL endpoint
app.post('/api/sites/url', async (req, res) => {
  const { siteName } = req.body;

  if (!siteName) {
    return res.status(400).json({ success: false, error: 'Site name is required' });
  }

  try {
    const result = await executeMatrix('url', [siteName]);
    res.json({ success: result.success, output: result.stdout, error: result.stderr });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Restore site endpoint
app.post('/api/sites/restore', async (req, res) => {
  const { siteName, backupFile } = req.body;

  if (!siteName || !backupFile) {
    return res.status(400).json({ success: false, error: 'Site name and backup file are required' });
  }

  try {
    const result = await executeMatrix('restore', [siteName, backupFile]);
    res.json({ success: result.success, output: result.stdout, error: result.stderr, exitCode: result.exitCode });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Export database endpoint
app.post('/api/sites/export-db', async (req, res) => {
  const { siteName, outputFile } = req.body;

  if (!siteName) {
    return res.status(400).json({ success: false, error: 'Site name is required' });
  }

  try {
    const args = [siteName];
    if (outputFile) args.push(outputFile);
    const result = await executeMatrix('export-db', args);
    res.json({ success: result.success, output: result.stdout, error: result.stderr, exitCode: result.exitCode });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Import database endpoint
app.post('/api/sites/import-db', async (req, res) => {
  const { siteName, dumpFile } = req.body;

  if (!siteName || !dumpFile) {
    return res.status(400).json({ success: false, error: 'Site name and dump file are required' });
  }

  try {
    const result = await executeMatrix('import-db', [siteName, dumpFile]);
    res.json({ success: result.success, output: result.stdout, error: result.stderr, exitCode: result.exitCode });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Edit site endpoint
app.post('/api/sites/edit', async (req, res) => {
  const { siteName, phpVersion } = req.body;

  if (!siteName) {
    return res.status(400).json({ success: false, error: 'Site name is required' });
  }

  try {
    const args = [siteName];
    if (phpVersion) args.push(`--php-version=${phpVersion}`);
    const result = await executeMatrix('edit', args);
    res.json({ success: result.success, output: result.stdout, error: result.stderr, exitCode: result.exitCode });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Clone site endpoint
app.post('/api/sites/clone', async (req, res) => {
  const { sourceName, destName } = req.body;

  if (!sourceName || !destName) {
    return res.status(400).json({ success: false, error: 'Source and destination site names are required' });
  }

  try {
    const result = await executeMatrix('clone', [sourceName, destName]);
    res.json({ success: result.success, output: result.stdout, error: result.stderr, exitCode: result.exitCode });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Reset site endpoint
app.post('/api/sites/reset', async (req, res) => {
  const { siteName } = req.body;

  if (!siteName) {
    return res.status(400).json({ success: false, error: 'Site name is required' });
  }

  try {
    const result = await executeMatrix('reset', [siteName]);
    res.json({ success: result.success, output: result.stdout, error: result.stderr, exitCode: result.exitCode });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Site logs endpoint
app.post('/api/sites/logs', async (req, res) => {
  const { siteName } = req.body;

  if (!siteName) {
    return res.status(400).json({ success: false, error: 'Site name is required' });
  }

  try {
    const result = await executeMatrix('logs', [siteName]);
    res.json({ success: result.success, output: result.stdout, error: result.stderr });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Catch-all for remaining site actions (create, start, stop, remove, info, check)
app.post('/api/sites/:action', async (req, res) => {
  const { action } = req.params;
  const { siteName, phpVersion } = req.body;

  if (!siteName && ['create', 'start', 'stop', 'remove', 'info', 'url'].includes(action)) {
    return res.status(400).json({
      success: false,
      error: 'Site name is required'
    });
  }

  try {
    const args = action === 'create'
      ? [siteName, `--php-version=${phpVersion || '8.3'}`]
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
    
    res.json({
      success: result.success,
      output: result.stdout,
      error: result.stderr,
      exitCode: result.exitCode
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

app.post('/api/environment/:action', async (req, res) => {
  const { action } = req.params;

  if (!['start', 'stop', 'restart', 'status', 'logs', 'clean', 'check', 'health', 'cache', 'cache-clear', 'search-replace', 'update', 'update-core', 'install'].includes(action)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid action'
    });
  }

  try {
    const result = await executeMatrix(action);
    
    res.json({
      success: result.success,
      output: result.stdout,
      error: result.stderr,
      exitCode: result.exitCode
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Frontend management endpoint
app.post('/api/frontend/:action', async (req, res) => {
  const { action } = req.params;

  if (!['start', 'stop', 'restart', 'status'].includes(action)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid action'
    });
  }

  try {
    const result = await executeMatrix('frontend', [action]);
    
    res.json({
      success: result.success,
      output: result.stdout,
      error: result.stderr,
      exitCode: result.exitCode
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
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
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/status', async (req, res) => {
  try {
    const result = await executeMatrix('status');
    
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

// Site health check endpoint
app.get('/api/health/:siteName', async (req, res) => {
  const { siteName } = req.params;
  
  if (!siteName || !/^[a-zA-Z0-9_-]+$/.test(siteName)) {
    return res.status(400).json({ success: false, error: 'Invalid site name' });
  }
  
  try {
    const sitesResult = await executeMatrix('list', ['--json']);
    let sites = [];
    if (sitesResult.stdout) {
      try {
        sites = JSON.parse(sitesResult.stdout).sites || [];
      } catch {}
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
    res.status(500).json({ success: false, error: error.message });
  }
});

// Start server with socket.io
server.listen(PORT, () => {
  console.log(`WordPress Matrix Frontend running on http://localhost:${PORT}`);
  console.log(`Dashboard: http://localhost:${PORT}`);
  console.log(`API Endpoint: http://localhost:${PORT}/api`);
  console.log(`WebSocket: Enabled`);
});