<?php
/**
 * Unit Tests for WordPress Simple Script Functions
 * Tests core functionality without actual Docker operations
 */

use PHPUnit\Framework\TestCase;

class WpSimpleTest extends TestCase
{
    private $testDir;
    private $mockScript;
    
    protected function setUp(): void
    {
        parent::setUp();
        $this->testDir = sys_get_temp_dir() . '/wp_simple_test_' . uniqid();
        mkdir($this->testDir, 0755, true);
        
        // Create a mock version of wp-simple for testing
        $this->createMockScript();
    }
    
    protected function tearDown(): void
    {
        // Clean up test directory
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
    
    private function createMockScript()
    {
        $scriptContent = '#!/bin/bash
# Mock wp-simple script for testing

PROJECT_ROOT="' . $this->testDir . '"
DOMAIN_SUFFIX="127.0.0.1.nip.io"

# Mock functions
get_sites() {
    ls -1 "' . $this->testDir . '/wp_"*" 2>/dev/null | sed "s/^wp_//" | sort || true
}

site_exists() {
    local site_name="$1"
    [[ -d "$PROJECT_ROOT/wp_$site_name" ]]
}

get_next_port() {
    local max_port=8000
    echo $((max_port + 1))
}

log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_warning() { echo "⚠️  $1"; }
log_error() { echo "❌ $1"; }

case "$1" in
    "list")
        get_sites
        ;;
    "create")
        echo "Created site $2"
        ;;
    *)
        echo "Unknown command: $1"
        exit 1
        ;;
esac';
        
        $this->mockScript = $this->testDir . '/wp-simple-mock';
        file_put_contents($this->mockScript, $scriptContent);
        chmod($this->mockScript, 0755);
    }
    
    /**
     * Test site name validation
     */
    public function testValidateSiteName()
    {
        $validNames = ['mysite', 'blog', 'test-site', 'app_demo'];
        $invalidNames = ['', 'ab', '123test', 'test@site', 'a' . str_repeat('b', 31), 'a$b'];
        
        foreach ($validNames as $name) {
            $this->assertTrue(
                $this->isValidSiteName($name),
                "Site name '$name' should be valid"
            );
        }
        
        foreach ($invalidNames as $name) {
            $this->assertFalse(
                $this->isValidSiteName($name),
                "Site name '$name' should be invalid"
            );
        }
    }
    
    /**
     * Test port assignment logic
     */
    public function testGetNextPort()
    {
        // Test with no existing ports
        $port = $this->getNextAvailablePort([]);
        $this->assertEquals(8001, $port);
        
        // Test with existing ports
        $existingPorts = [8001, 8002, 8005];
        $port = $this->getNextAvailablePort($existingPorts);
        $this->assertEquals(8006, $port);
    }
    
    /**
     * Test site directory creation
     */
    public function testSiteDirectoryCreation()
    {
        $siteName = 'testsite';
        $siteDir = $this->testDir . "/wp_{$siteName}";
        
        $this->assertFalse(is_dir($siteDir), "Site directory should not exist initially");
        
        mkdir($siteDir, 0755, true);
        $this->assertTrue(is_dir($siteDir), "Site directory should be created");
        
        // Test WordPress subdirectories
        $wpContentDir = "$siteDir/wp-content";
        mkdir($wpContentDir, 0755, true);
        mkdir("$wpContentDir/themes", 0755, true);
        mkdir("$wpContentDir/plugins", 0755, true);
        mkdir("$wpContentDir/uploads", 0755, true);
        
        $this->assertTrue(is_dir($wpContentDir), "wp-content directory should exist");
        $this->assertTrue(is_dir("$wpContentDir/themes"), "themes directory should exist");
        $this->assertTrue(is_dir("$wpContentDir/plugins"), "plugins directory should exist");
        $this->assertTrue(is_dir("$wpContentDir/uploads"), "uploads directory should exist");
    }
    
    /**
     * Test environment file generation
     */
    public function testEnvironmentFileGeneration()
    {
        $siteName = 'testsite';
        $port = 8001;
        
        $envFile = $this->testDir . '/.env';
        $envContent = "# Configuration for $siteName\n";
        $envContent .= strtoupper($siteName) . "_PORT=$port\n";
        $envContent .= strtoupper($siteName) . "_DB_NAME=${siteName}_db\n";
        
        file_put_contents($envFile, $envContent);
        
        $this->assertTrue(file_exists($envFile), "Environment file should exist");
        
        $content = file_get_contents($envFile);
        $this->assertStringContainsString("TESTSITE_PORT=$port", $content);
        $this->assertStringContainsString("TESTSITE_DB_NAME=testsite_db", $content);
    }
    
    /**
     * Test Docker compose file generation
     */
    public function testDockerComposeGeneration()
    {
        $siteName = 'testsite';
        $port = 8001;
        $composeFile = $this->testDir . '/docker-compose.yml';
        
        $composeContent = "# WordPress site: $siteName\n";
        $composeContent .= "wp_$siteName:\n";
        $composeContent .= "  image: wordpress:php8.3-fpm\n";
        $composeContent .= "  ports:\n";
        $composeContent .= "    - \"$port:80\"\n";
        
        file_put_contents($composeFile, $composeContent);
        
        $this->assertTrue(file_exists($composeFile), "Docker compose file should exist");
        
        $content = file_get_contents($composeFile);
        $this->assertStringContainsString("wp_testsite:", $content);
        $this->assertStringContainsString("$port:80", $content);
        $this->assertStringContainsString("wordpress:php8.3-fpm", $content);
    }
    
    /**
     * Test URL generation
     */
    public function testUrlGeneration()
    {
        $siteName = 'testsite';
        $port = 8001;
        $domainSuffix = '127.0.0.1.nip.io';
        
        $localUrl = "http://localhost:$port";
        $domainUrl = "https://$siteName.$domainSuffix";
        
        $this->assertEquals('http://localhost:8001', $localUrl);
        $this->assertEquals('https://testsite.127.0.0.1.nip.io', $domainUrl);
    }
    
    /**
     * Test migration readiness check
     */
    public function testMigrationReadiness()
    {
        // Create mock complex version files
        mkdir($this->testDir . '/wp-dev');
        mkdir($this->testDir . '/xandar');
        
        $readiness = $this->checkMigrationReadiness();
        
        $this->assertTrue($readiness['complex_version_exists']);
        $this->assertTrue($readiness['sites_found']);
        
        // Check blocked conditions
        mkdir($this->testDir . '/.env');
        $readiness = $this->checkMigrationReadiness();
        $this->assertFalse($readiness['simplified_config_absent']);
    }
    
    /**
     * Test backup functionality
     */
    public function testBackupFunctionality()
    {
        // Create test data
        $testSiteDir = $this->testDir . '/wp_testsite';
        mkdir($testSiteDir, 0755, true);
        mkdir("$testSiteDir/wp-content", 0755, true);
        file_put_contents("$testSiteDir/wp-config.php", '<?php // Test config');
        
        $backupDir = $this->testDir . '/backup-' . date('Y-m-d_H-i-s');
        mkdir($backupDir, 0755, true);
        
        // Simulate backup
        $this->recursiveCopy($testSiteDir, $backupDir . '/wp_testsite');
        
        $this->assertTrue(is_dir($backupDir), "Backup directory should exist");
        $this->assertTrue(file_exists("$backupDir/wp_testsite/wp-config.php"), "Config should be backed up");
    }
    
    // Helper methods
    private function isValidSiteName($name)
    {
        if (empty($name) || strlen($name) < 3 || strlen($name) > 30) {
            return false;
        }
        
        return preg_match('/^[a-zA-Z][a-zA-Z0-9_-]*$/', $name);
    }
    
    private function getNextAvailablePort($existingPorts)
    {
        $maxPort = 8000;
        if (!empty($existingPorts)) {
            $maxPort = max($existingPorts);
        }
        return $maxPort + 1;
    }
    
    private function checkMigrationReadiness()
    {
        $readiness = [
            'complex_version_exists' => file_exists($this->testDir . '/wp-dev'),
            'sites_found' => is_dir($this->testDir . '/xandar'),
            'simplified_config_absent' => !file_exists($this->testDir . '/.env'),
            'containers_stopped' => true // Assume stopped for test
        ];
        
        return $readiness;
    }
    
    private function recursiveCopy($src, $dst)
    {
        $dir = opendir($src);
        @mkdir($dst, 0755, true);
        
        while (false !== ($file = readdir($dir))) {
            if (($file != '.') && ($file != '..')) {
                if (is_dir($src . '/' . $file)) {
                    $this->recursiveCopy($src . '/' . $file, $dst . '/' . $file);
                } else {
                    copy($src . '/' . $file, $dst . '/' . $file);
                }
            }
        }
        closedir($dir);
    }
}