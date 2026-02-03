const express = require('express');
const exphbs = require('express-handlebars');
const path = require('path');
const axios = require('axios');
const cors = require('cors');
const { spawn } = require('child_process');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

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
    const matrixCmd = spawn('/app/matrix', [command, ...args], {
      cwd: '/app', // Use the app directory
      timeout: 30000
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
      if (code === 0) {
        resolve({ success: true, stdout, stderr });
      } else {
        resolve({ success: false, stdout, stderr, exitCode: code });
      }
    });

    matrixCmd.on('error', (error) => {
      reject(error);
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
    const result = await executeMatrix('list');
    const { sites, services } = parseSiteList(result.stdout);
    
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
    const result = await executeMatrix('list');
    const { sites, services } = parseSiteList(result.stdout);
    
    res.json({
      success: true,
      sites,
      services,
      raw: result.stdout
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

app.post('/api/sites/:action', async (req, res) => {
  const { action } = req.params;
  const { siteName } = req.body;

  if (!siteName && ['create', 'start', 'stop', 'remove', 'info', 'url'].includes(action)) {
    return res.status(400).json({
      success: false,
      error: 'Site name is required'
    });
  }

  try {
    const args = action === 'create' ? [siteName] : [siteName];
    const result = await executeMatrix(action, args);
    
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

  if (!['start', 'stop', 'restart', 'status', 'logs', 'clean', 'check'].includes(action)) {
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

// Start server
app.listen(PORT, () => {
  console.log(`🚀 WordPress Matrix Frontend running on http://localhost:${PORT}`);
  console.log(`📊 Dashboard: http://localhost:${PORT}`);
  console.log(`🔗 API Endpoint: http://localhost:${PORT}/api`);
});