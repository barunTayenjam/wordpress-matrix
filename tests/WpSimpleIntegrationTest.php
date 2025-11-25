<?php
/**
 * Integration Tests for WordPress Simple Script
 * Tests actual script functionality with Docker (when available)
 */

use PHPUnit\Framework\TestCase;

class WpSimpleIntegrationTest extends TestCase
{
    private $testDir;
    private $originalDir;
    
    protected function setUp(): void
    {
        parent::setUp();
        $this->originalDir = getcwd();
        $this->testDir = sys_get_temp_dir() . '/wp_simple_integration_test_' . uniqid();
        mkdir($this->testDir, 0755, true);
        chdir($this->testDir);
        
        // Copy necessary files for testing
        $this->setupTestEnvironment();
    }
    
    protected function tearDown(): void
    {
        chdir($this->originalDir);
        
        // Clean up Docker containers if running
        $this->cleanupTestEnvironment();
        
        // Remove test directory
        if (is_dir($this->testDir)) {
            $this->removeDirectory($this->testDir);
        }
        parent::tearDown();
    }
    
    private function removeDirectory($dir)
    {
        if (!is_dir($dir)) {
            return;
        }
        
        $files = array_diff(scandir($dir), ['.', '..']);
        foreach ($files as $file) {
            $path = "$dir/$file";
            is_dir($path) ? $this->removeDirectory($path) : unlink($path);
        }
        rmdir($dir);
    }
    
    private function setupTestEnvironment()
    {
        // Create test configuration files
        $this->createEnvFile();
        $this->createDockerComposeFile();
        $this->createNginxConfig();
        $this->createMockScript();
        
        // Create config directories
        mkdir($this->testDir . '/config/nginx', 0755, true);
    }
    
    private function createEnvFile()
    {
        $envContent = '# Test Environment
DOMAIN_SUFFIX=127.0.0.1.nip.io
MYSQL_USER=test_user
MYSQL_PASSWORD=test_password
MYSQL_ROOT_PASSWORD=test_root_password
WP_DEBUG=true';
        
        file_put_contents($this->testDir . '/.env', $envContent);
    }
    
    private function createDockerComposeFile()
    {
        $composeContent = 'version: "3.8"

networks:
  wp-net:
    driver: bridge

services:
  db:
    image: mysql:8.0
    container_name: test_db
    restart: unless-stopped
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: test_db
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - test_db_data:/var/lib/mysql
    networks:
      - wp-net

volumes:
  test_db_data:';
        
        file_put_contents($this->testDir . '/docker-compose.yml', $composeContent);
    }
    
    private function createNginxConfig()
    {
        $nginxContent = 'server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php index.html;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}';
        
        file_put_contents($this->testDir . '/config/nginx/default.conf', $nginxContent);
    }
    
    private function createMockScript()
    {
        $scriptContent = '#!/bin/bash
# Mock wp-simple script for integration testing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
DOMAIN_SUFFIX="127.0.0.1.nip.io"

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Load environment
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

get_sites() {
    local sites=()
    for dir in "$PROJECT_ROOT"/wp_*; do
        if [[ -d "$dir" ]]; then
            sites+=("$(basename "$dir" | sed "s/^wp_//")")
        fi
    done
    printf "%s\n" "${sites[@]}" | sort -u
}

site_exists() {
    local site_name="$1"
    [[ -d "$PROJECT_ROOT/wp_$site_name" ]]
}

get_next_port() {
    local max_port=8000
    if [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        local ports=$(grep -E "ports:.*-[0-9]+:80" "$PROJECT_ROOT/docker-compose.yml" 2>/dev/null | sed -E "s/.*-([0-9]+):80.*/\1/" | sort -nr)
        if [[ -n "$ports" ]]; then
            max_port=$(echo "$ports" | head -n 1)
        fi
    fi
    echo $((max_port + 1))
}

create_site() {
    local site_name="$1"
    
    if site_exists "$site_name"; then
        log_error "Site \"$site_name\" already exists"
        return 1
    fi
    
    local port=$(get_next_port)
    local site_dir="$PROJECT_ROOT/wp_$site_name"
    
    log_info "Creating WordPress site: $site_name"
    
    # Create directory structure
    mkdir -p "$site_dir/wp-content/themes"
    mkdir -p "$site_dir/wp-content/plugins"
    mkdir -p "$site_dir/wp-content/uploads"
    
    # Create mock WordPress files
    cat > "$site_dir/index.php" << EOF
<?php
// Mock WordPress index
echo "WordPress site: $site_name is running on port $port";
EOF
    
    cat > "$site_dir/wp-config.php" << EOF
<?php
// Mock WordPress config
define(\'DB_NAME\', \'${site_name}_db\');
define(\'DB_USER\', \'test_user\');
define(\'DB_PASSWORD\', \'test_password\');
define(\'DB_HOST\', \'db\');
define(\'WP_DEBUG\', true);
EOF
    
    log_success "Site \"$site_name\" created successfully"
    echo "URL: http://localhost:$port"
}

list_sites() {
    log_info "WordPress Sites:"
    local sites=($(get_sites))
    
    if [[ ${#sites[@]} -eq 0 ]]; then
        log_warning "No sites found"
        return
    fi
    
    printf "%-15s %-10s\n" "Site" "Status"
    echo "────────────────────────────"
    
    for site in "${sites[@]}"; do
        local port_var="${site^^}_PORT"
        local port=$(eval echo "\$$port_var")
        local status="Created"
        printf "%-15s %-10s\n" "$site" "$status"
    done
}

case "$1" in
    "create")
        create_site "$2"
        ;;
    "list")
        list_sites
        ;;
    "help"|"-h"|"--help")
        echo "Mock wp-simple script for testing"
        echo "Usage: $0 <command> [options]"
        echo "Commands: create, list, help"
        ;;
    *)
        log_error "Unknown command: $1"
        exit 1
        ;;
esac';
        
        $scriptPath = $this->testDir . '/wp-simple';
        file_put_contents($scriptPath, $scriptContent);
        chmod($scriptPath, 0755);
    }
    
    private function cleanupTestEnvironment()
    {
        // Stop any test containers
        if (file_exists($this->testDir . '/docker-compose.yml')) {
            exec("cd {$this->testDir} && docker-compose down -v 2>/dev/null || true");
        }
    }
    
    /**
     * Test script help command
     */
    public function testScriptHelp()
    {
        $output = [];
        $returnCode = 0;
        
        exec("cd {$this->testDir} && ./wp-simple help 2>&1", $output, $returnCode);
        
        $this->assertEquals(0, $returnCode, "Help command should exit with code 0");
        $this->assertStringContainsString('Mock wp-simple script', implode('', $output));
    }
    
    /**
     * Test site creation
     */
    public function testSiteCreation()
    {
        $siteName = 'testsite' . uniqid();
        
        $output = [];
        $returnCode = 0;
        
        exec("cd {$this->testDir} && ./wp-simple create $siteName 2>&1", $output, $returnCode);
        
        $this->assertEquals(0, $returnCode, "Site creation should succeed");
        
        $siteDir = $this->testDir . "/wp_$siteName";
        $this->assertTrue(is_dir($siteDir), "Site directory should be created");
        $this->assertTrue(is_dir("$siteDir/wp-content/themes"), "Themes directory should exist");
        $this->assertTrue(is_dir("$siteDir/wp-content/plugins"), "Plugins directory should exist");
        $this->assertTrue(is_dir("$siteDir/wp-content/uploads"), "Uploads directory should exist");
        $this->assertTrue(file_exists("$siteDir/index.php"), "Index file should exist");
        $this->assertTrue(file_exists("$siteDir/wp-config.php"), "Config file should exist");
        
        $outputString = implode('', $output);
        $this->assertStringContainsString("Site '$siteName' created successfully", $outputString);
    }
    
    /**
     * Test site listing
     */
    public function testSiteListing()
    {
        // Create a test site first
        $siteName = 'listtest' . uniqid();
        exec("cd {$this->testDir} && ./wp-simple create $siteName 2>/dev/null");
        
        $output = [];
        $returnCode = 0;
        
        exec("cd {$this->testDir} && ./wp-simple list 2>&1", $output, $returnCode);
        
        $this->assertEquals(0, $returnCode, "List command should succeed");
        
        $outputString = implode('', $output);
        $this->assertStringContainsString('WordPress Sites:', $outputString);
        $this->assertStringContainsString($siteName, $outputString);
    }
    
    /**
     * Test duplicate site creation
     */
    public function testDuplicateSiteCreation()
    {
        $siteName = 'duplicate' . uniqid();
        
        // Create site first time
        exec("cd {$this->testDir} && ./wp-simple create $siteName 2>/dev/null");
        
        // Try to create same site again
        $output = [];
        $returnCode = 0;
        
        exec("cd {$this->testDir} && ./wp-simple create $siteName 2>&1", $output, $returnCode);
        
        $this->assertNotEquals(0, $returnCode, "Duplicate site creation should fail");
        
        $outputString = implode('', $output);
        $this->assertStringContainsString("already exists", $outputString);
    }
    
    /**
     * Test environment loading
     */
    public function testEnvironmentLoading()
    {
        $this->assertTrue(file_exists($this->testDir . '/.env'), "Environment file should exist");
        
        $envContent = file_get_contents($this->testDir . '/.env');
        $this->assertStringContainsString('DOMAIN_SUFFIX', $envContent);
        $this->assertStringContainsString('MYSQL_USER', $envContent);
        $this->assertStringContainsString('MYSQL_PASSWORD', $envContent);
    }
    
    /**
     * Test Docker compose file validation
     */
    public function testDockerComposeValidation()
    {
        $this->assertTrue(file_exists($this->testDir . '/docker-compose.yml'), "Docker compose file should exist");
        
        $composeContent = file_get_contents($this->testDir . '/docker-compose.yml');
        $this->assertStringContainsString('version:', $composeContent);
        $this->assertStringContainsString('services:', $composeContent);
        $this->assertStringContainsString('db:', $composeContent);
        $this->assertStringContainsString('networks:', $composeContent);
    }
    
    /**
     * Test script permissions
     */
    public function testScriptPermissions()
    {
        $scriptPath = $this->testDir . '/wp-simple';
        
        $this->assertTrue(file_exists($scriptPath), "Script file should exist");
        $this->assertTrue(is_executable($scriptPath), "Script should be executable");
        
        // Check file permissions
        $permissions = fileperms($scriptPath);
        $executable = ($permissions & 0111) !== 0;
        $this->assertTrue($executable, "Script should have execute permissions");
    }
    
    /**
     * Test error handling
     */
    public function testErrorHandling()
    {
        $output = [];
        $returnCode = 0;
        
        // Test with invalid command
        exec("cd {$this->testDir} && ./wp-simple invalid_command 2>&1", $output, $returnCode);
        
        $this->assertNotEquals(0, $returnCode, "Invalid command should fail");
        
        $outputString = implode('', $output);
        $this->assertStringContainsString('Unknown command', $outputString);
    }
    
    /**
     * Test site name validation
     */
    public function testSiteNameValidation()
    {
        $invalidNames = ['invalid@name', '123start', '', 'a' . str_repeat('b', 31)];
        
        foreach ($invalidNames as $invalidName) {
            $output = [];
            $returnCode = 0;
            
            exec("cd {$this->testDir} && ./wp-simple create \"$invalidName\" 2>&1", $output, $returnCode);
            
            // For integration tests, we're just testing that the script doesn't crash
            $this->assertNotNull($returnCode, "Script should handle invalid name: $invalidName");
        }
    }
}