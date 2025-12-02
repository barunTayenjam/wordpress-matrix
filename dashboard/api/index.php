<?php
// WordPress Matrix Dashboard API
// This script acts as an API bridge to execute wp-simple commands

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Define response helper
function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode($data);
    exit();
}

// Get request method and path
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$requestPath = str_replace(['/api/', '/dashboard/api/'], '', $path);

// Execute wp-simple command securely
function runWpCommand($command) {
    // Sanitize command to prevent injection
    $command = preg_replace('/[^a-zA-Z0-9\-_\.\s\/]/', '', $command);
    
    // Build the command - assuming wp-simple is in the parent directory
    $fullCmd = __DIR__ . '/../../wp-simple ' . escapeshellcmd($command) . ' 2>&1';
    
    $output = [];
    $returnCode = 0;
    exec($fullCmd, $output, $returnCode);
    
    return [
        'output' => $output,
        'success' => $returnCode === 0,
        'return_code' => $returnCode,
        'command' => $command
    ];
}

// Extract site names from directory structure
function getSitesFromDirectories() {
    $sites = [];
    $baseDir = __DIR__ . '/../../';
    
    // Scan for wp_* directories
    $dirContents = scandir($baseDir);
    foreach ($dirContents as $item) {
        if (preg_match('/^wp_(.+)$/', $item, $matches)) {
            $siteName = $matches[1];
            // Check if it's a directory
            if (is_dir($baseDir . $item)) {
                $sites[] = [
                    'name' => $siteName,
                    'path' => $baseDir . $item,
                    'exists' => true
                ];
            }
        }
    }
    return $sites;
}

// Route handlers
switch ($method . ' ' . $requestPath) {
    case 'GET sites':
        // Get sites by scanning directories
        $sites = getSitesFromDirectories();
        $result = runWpCommand('list');
        
        // Parse wp-simple output to add status info
        $response = [];
        $siteStatusMap = [];
        
        if ($result['success']) {
            $output = implode("\n", $result['output']);
            $lines = explode("\n", $output);
            $foundSites = false;
            
            foreach ($lines as $line) {
                $line = trim($line);
                if (strpos($line, 'WordPress Sites:') !== false) {
                    $foundSites = true;
                    continue;
                }
                if ($foundSites && strpos($line, '-') !== 0 && !empty($line) && !preg_match('/^Site\s+Status\s+/', $line)) {
                    $parts = preg_split('/\s+/', $line, 4);
                    if (count($parts) >= 2) {
                        $siteName = $parts[0];
                        $siteStatus = $parts[1];
                        
                        // Add URL information
                        $accessUrl = "http://localhost:8100"; // We'd need to determine the actual port
                        if ($siteName !== 'consulting-su') { // Assuming this is the first site
                            // Calculate port based on position or get from compose file
                            $port = 8100 + count($response);
                            $accessUrl = "http://localhost:" . $port;
                        }
                        
                        $response[] = [
                            'name' => $siteName,
                            'status' => $siteStatus,
                            'access_url' => $accessUrl
                        ];
                        $siteStatusMap[$siteName] = $siteStatus;
                    }
                }
            }
        }
        
        // Ensure all directories are represented
        foreach ($sites as $site) {
            $found = false;
            foreach ($response as $existingSite) {
                if ($existingSite['name'] === $site['name']) {
                    $found = true;
                    break;
                }
            }
            if (!$found) {
                $response[] = [
                    'name' => $site['name'],
                    'status' => 'Unknown',
                    'access_url' => 'Not configured'
                ];
            }
        }
        
        sendResponse($response);
        break;

    case 'GET services':
        // Get Docker container status
        $cmd = 'docker-compose ps --format json 2>/dev/null';
        $output = [];
        exec($cmd, $output);
        
        $containers = [];
        foreach ($output as $line) {
            if (!empty(trim($line))) {
                $decoded = json_decode(trim($line), true);
                if ($decoded) {
                    $containers[] = $decoded;
                }
            }
        }
        
        sendResponse($containers);
        break;

    case 'POST create-site':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['name'])) {
            sendResponse(['error' => 'Site name is required'], 400);
        }
        
        // Validate site name (only alphanumeric, hyphens, underscores)
        if (!preg_match('/^[a-zA-Z0-9_-]+$/', $input['name'])) {
            sendResponse(['error' => 'Invalid site name. Use only letters, numbers, hyphens, and underscores.'], 400);
        }
        
        $result = runWpCommand('create ' . escapeshellarg($input['name']));
        sendResponse([
            'success' => $result['success'],
            'message' => implode("\\n", $result['output']),
            'data' => $result
        ]);
        break;

    case 'POST delete-site':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['name'])) {
            sendResponse(['error' => 'Site name is required'], 400);
        }
        
        $result = runWpCommand('remove ' . escapeshellarg($input['name']));
        sendResponse([
            'success' => $result['success'],
            'message' => implode("\\n", $result['output']),
            'data' => $result
        ]);
        break;

    case 'POST start-site':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['name'])) {
            sendResponse(['error' => 'Site name is required'], 400);
        }
        
        $result = runWpCommand('start ' . escapeshellarg($input['name']));
        sendResponse([
            'success' => $result['success'],
            'message' => implode("\\n", $result['output']),
            'data' => $result
        ]);
        break;

    case 'POST stop-site':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['name'])) {
            sendResponse(['error' => 'Site name is required'], 400);
        }
        
        $result = runWpCommand('stop ' . escapeshellarg($input['name']));
        sendResponse([
            'success' => $result['success'],
            'message' => implode("\\n", $result['output']),
            'data' => $result
        ]);
        break;

    case 'POST import-db':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['site']) || empty($input['file'])) {
            sendResponse(['error' => 'Site name and file path are required'], 400);
        }
        
        // Validate file path
        $file = $input['file'];
        if (!preg_match('/^[a-zA-Z0-9_\-\.\/\:~]+$/', $file)) {
            sendResponse(['error' => 'Invalid file path'], 400);
        }
        
        $result = runWpCommand('import-db ' . escapeshellarg($input['site']) . ' ' . escapeshellarg($file));
        sendResponse([
            'success' => $result['success'],
            'message' => implode("\\n", $result['output']),
            'data' => $result
        ]);
        break;

    case 'POST export-db':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (empty($input['site'])) {
            sendResponse(['error' => 'Site name is required'], 400);
        }
        
        $fileName = isset($input['file']) && !empty($input['file']) ? $input['file'] : '';
        
        if ($fileName && !preg_match('/^[a-zA-Z0-9_\-\.\/\:~]+$/', $fileName)) {
            sendResponse(['error' => 'Invalid output file path'], 400);
        }
        
        $cmd = $fileName ? 
            'export-db ' . escapeshellarg($input['site']) . ' ' . escapeshellarg($fileName) :
            'export-db ' . escapeshellarg($input['site']);
            
        $result = runWpCommand($cmd);
        sendResponse([
            'success' => $result['success'],
            'message' => implode("\\n", $result['output']),
            'data' => $result
        ]);
        break;

    default:
        sendResponse(['error' => 'Endpoint not found'], 404);
        break;
}

http_response_code(404);
echo json_encode(['error' => 'Endpoint not found']);
?>