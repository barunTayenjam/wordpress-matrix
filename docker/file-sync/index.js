const chokidar = require('chokidar');
const Docker = require('dockerode');
const WebSocket = require('ws');
const path = require('path');

class WordPressFileSync {
    constructor() {
        this.docker = new Docker({ socketPath: '/var/run/docker.sock' });
        this.syncPaths = process.env.SYNC_PATHS?.split(',') || [];
        this.reloadContainers = process.env.RELOAD_CONTAINERS?.split(',') || [];
        this.syncDelay = parseInt(process.env.SYNC_DELAY) || 500;
        this.debounceTimers = new Map();
        
        console.log('🔄 WordPress File Sync Service Starting...');
        console.log('📁 Watching paths:', this.syncPaths);
        console.log('🔄 Reload containers:', this.reloadContainers);
    }

    async init() {
        // Setup file watchers
        this.setupFileWatchers();
        
        // Setup WebSocket server for browser reload
        this.setupWebSocketServer();
        
        console.log('✅ File sync service initialized');
    }

    setupFileWatchers() {
        this.syncPaths.forEach(syncPath => {
            if (!syncPath.trim()) return;
            
            console.log(`👀 Watching: ${syncPath}`);
            
            const watcher = chokidar.watch(syncPath, {
                ignored: [
                    '**/node_modules/**',
                    '**/.git/**',
                    '**/cache/**',
                    '**/*.log',
                    '**/wp-content/uploads/**'
                ],
                persistent: true,
                ignoreInitial: true
            });

            watcher
                .on('change', (filePath) => this.handleFileChange(filePath))
                .on('add', (filePath) => this.handleFileChange(filePath))
                .on('unlink', (filePath) => this.handleFileChange(filePath))
                .on('error', (error) => console.error('❌ Watcher error:', error));
        });
    }

    setupWebSocketServer() {
        this.wss = new WebSocket.Server({ port: 3001 });
        
        this.wss.on('connection', (ws) => {
            console.log('🔌 Browser connected for live reload');
            
            ws.on('close', () => {
                console.log('🔌 Browser disconnected');
            });
        });
        
        console.log('🌐 WebSocket server listening on port 3001');
    }

    handleFileChange(filePath) {
        const fileExt = path.extname(filePath);
        const fileName = path.basename(filePath);
        
        console.log(`📝 File changed: ${filePath}`);
        
        // Debounce file changes
        const debounceKey = filePath;
        if (this.debounceTimers.has(debounceKey)) {
            clearTimeout(this.debounceTimers.get(debounceKey));
        }
        
        this.debounceTimers.set(debounceKey, setTimeout(() => {
            this.processFileChange(filePath, fileExt, fileName);
            this.debounceTimers.delete(debounceKey);
        }, this.syncDelay));
    }

    async processFileChange(filePath, fileExt, fileName) {
        try {
            // Handle different file types
            if (this.isPhpFile(fileExt)) {
                await this.handlePhpChange(filePath);
            } else if (this.isCssFile(fileExt)) {
                await this.handleCssChange(filePath);
            } else if (this.isJsFile(fileExt)) {
                await this.handleJsChange(filePath);
            } else if (this.isTemplateFile(fileName)) {
                await this.handleTemplateChange(filePath);
            }
            
            // Notify browsers for live reload
            this.notifyBrowsers(filePath, fileExt);
            
        } catch (error) {
            console.error('❌ Error processing file change:', error);
        }
    }

    async handlePhpChange(filePath) {
        console.log('🐘 PHP file changed, clearing OPcache...');
        
        // Clear OPcache in WordPress containers
        for (const containerName of this.reloadContainers) {
            try {
                const container = this.docker.getContainer(containerName);
                await container.exec({
                    Cmd: ['php', '-r', 'if (function_exists("opcache_reset")) opcache_reset();'],
                    AttachStdout: true,
                    AttachStderr: true
                });
                console.log(`✅ OPcache cleared in ${containerName}`);
            } catch (error) {
                console.error(`❌ Failed to clear OPcache in ${containerName}:`, error.message);
            }
        }
    }

    async handleCssChange(filePath) {
        console.log('🎨 CSS file changed, processing...');
        
        // Could add CSS preprocessing here
        // For now, just trigger browser reload
    }

    async handleJsChange(filePath) {
        console.log('📜 JavaScript file changed, processing...');
        
        // Could add JS minification/bundling here
        // For now, just trigger browser reload
    }

    async handleTemplateChange(filePath) {
        console.log('🎨 Template file changed, clearing template cache...');
        
        // Clear WordPress template cache
        for (const containerName of this.reloadContainers) {
            try {
                const container = this.docker.getContainer(containerName);
                await container.exec({
                    Cmd: ['wp', 'cache', 'flush', '--allow-root', '--path=/var/www/html'],
                    AttachStdout: true,
                    AttachStderr: true
                });
                console.log(`✅ Template cache cleared in ${containerName}`);
            } catch (error) {
                console.error(`❌ Failed to clear template cache in ${containerName}:`, error.message);
            }
        }
    }

    notifyBrowsers(filePath, fileExt) {
        const message = {
            type: 'reload',
            file: filePath,
            extension: fileExt,
            timestamp: Date.now()
        };
        
        this.wss.clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify(message));
            }
        });
        
        console.log('🔄 Browser reload notification sent');
    }

    isPhpFile(ext) {
        return ext === '.php';
    }

    isCssFile(ext) {
        return ['.css', '.scss', '.sass', '.less'].includes(ext);
    }

    isJsFile(ext) {
        return ['.js', '.ts', '.jsx', '.tsx'].includes(ext);
    }

    isTemplateFile(fileName) {
        return fileName.endsWith('.twig') || 
               fileName.endsWith('.html') || 
               fileName.startsWith('template-') ||
               fileName.includes('template');
    }
}

// Start the service
const fileSync = new WordPressFileSync();
fileSync.init().catch(console.error);

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 Shutting down file sync service...');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('🛑 Shutting down file sync service...');
    process.exit(0);
});