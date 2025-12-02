const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve frontend files
app.use('/', express.static(path.join(__dirname, '../frontend')));

// Middleware to execute wp-simple commands
function runWpCommand(command, callback) {
    const fullCommand = `./wp-simple ${command}`;
    exec(fullCommand, { cwd: path.dirname(require.main.filename) + '/..' }, (error, stdout, stderr) => {
        callback(error, { stdout, stderr, success: !error });
    });
}

// API Routes
app.get('/api/sites', (req, res) => {
    runWpCommand('list', (error, result) => {
        if (error) {
            return res.status(500).json({ error: result.stderr || error.message });
        }
        
        const sites = [];
        const lines = result.stdout.split('\n');
        let foundSites = false;
        
        for (const line of lines) {
            if (line.includes('WordPress Sites:')) {
                foundSites = true;
                continue;
            }
            if (foundSites && !line.startsWith('─') && line.trim() !== '') {
                const parts = line.trim().split(/\s+/).filter(p => p);
                if (parts.length >= 2) {
                    sites.push({
                        name: parts[0],
                        status: parts[1]
                    });
                }
            }
        }
        
        res.json(sites);
    });
});

app.get('/api/services', (req, res) => {
    exec('docker-compose ps --format json', (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: stderr || error.message });
        }
        
        try {
            const lines = stdout.trim().split('\n').filter(line => line.trim());
            const services = lines.map(line => JSON.parse(line)).filter(svc => svc);
            res.json(services);
        } catch (parseError) {
            res.status(500).json({ error: 'Failed to parse docker-compose output' });
        }
    });
});

app.post('/api/create-site', (req, res) => {
    const { name } = req.body;
    if (!name) {
        return res.status(400).json({ error: 'Site name is required' });
    }
    
    runWpCommand(`create ${name}`, (error, result) => {
        if (error) {
            return res.status(500).json({ error: result.stderr || error.message });
        }
        res.json({ success: true, message: result.stdout });
    });
});

app.post('/api/delete-site', (req, res) => {
    const { name } = req.body;
    if (!name) {
        return res.status(400).json({ error: 'Site name is required' });
    }
    
    runWpCommand(`remove ${name}`, (error, result) => {
        if (error) {
            return res.status(500).json({ error: result.stderr || error.message });
        }
        res.json({ success: true, message: result.stdout });
    });
});

app.post('/api/start-site', (req, res) => {
    const { name } = req.body;
    if (!name) {
        return res.status(400).json({ error: 'Site name is required' });
    }
    
    runWpCommand(`start ${name}`, (error, result) => {
        if (error) {
            return res.status(500).json({ error: result.stderr || error.message });
        }
        res.json({ success: true, message: result.stdout });
    });
});

app.post('/api/stop-site', (req, res) => {
    const { name } = req.body;
    if (!name) {
        return res.status(400).json({ error: 'Site name is required' });
    }
    
    runWpCommand(`stop ${name}`, (error, result) => {
        if (error) {
            return res.status(500).json({ error: result.stderr || error.message });
        }
        res.json({ success: true, message: result.stdout });
    });
});

app.post('/api/import-db', (req, res) => {
    const { site, file } = req.body;
    if (!site || !file) {
        return res.status(400).json({ error: 'Site name and file path are required' });
    }
    
    runWpCommand(`import-db ${site} ${file}`, (error, result) => {
        if (error) {
            return res.status(500).json({ error: result.stderr || error.message });
        }
        res.json({ success: true, message: result.stdout });
    });
});

app.post('/api/export-db', (req, res) => {
    const { site, file } = req.body;
    if (!site) {
        return res.status(400).json({ error: 'Site name is required' });
    }
    
    const cmd = file ? `export-db ${site} ${file}` : `export-db ${site}`;
    runWpCommand(cmd, (error, result) => {
        if (error) {
            return res.status(500).json({ error: result.stderr || error.message });
        }
        res.json({ success: true, message: result.stdout });
    });
});

app.listen(PORT, () => {
    console.log(`Dashboard API server running on port ${PORT}`);
});