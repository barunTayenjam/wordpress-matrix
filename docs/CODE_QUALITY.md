# 🎯 Code Quality Tools - Ultimate WordPress Development Matrix

This document outlines the comprehensive code quality tools integrated into the WordPress Development Matrix.

## 🔍 Available Tools

### 1. **PHP Code Sniffer (PHPCS) - Level 9 WordPress Standards**
- **Purpose**: Enforces WordPress coding standards and best practices
- **Standards Included**:
  - WordPress-Core, WordPress-Docs, WordPress-Extra
  - WordPress-VIP-Go (Enterprise standards)
  - PSR1, PSR12 (PHP Standards)
  - PHP Compatibility checks
  - Variable analysis
  - Slevomat coding standards

### 2. **PHPStan - Level 9 Static Analysis**
- **Purpose**: Advanced static analysis with WordPress-specific rules
- **Features**:
  - Level 9 analysis (strictest)
  - WordPress function/class recognition
  - Type checking and inference
  - Dead code detection
  - Strict rules enabled

### 3. **PHP Mess Detector (PHPMD)**
- **Purpose**: Detects code smells and potential issues
- **Rules**:
  - Clean code violations
  - Code size issues
  - Design problems
  - Naming conventions
  - Unused code detection

### 4. **Psalm - Advanced Static Analysis**
- **Purpose**: Deep static analysis with type checking
- **Features**:
  - WordPress plugin integration
  - Advanced type inference
  - Security issue detection
  - Performance optimization hints

### 5. **PHPUnit - Unit Testing Framework**
- **Purpose**: Comprehensive testing with WordPress integration
- **Features**:
  - WordPress test case support
  - Code coverage reporting
  - Integration testing
  - Mocking capabilities

## 🚀 Quick Start

### Run All Quality Checks
```bash
./scripts/manage.sh quality
```

### Run Individual Tools
```bash
# PHP Code Sniffer (WordPress Standards)
./scripts/manage.sh lint

# Auto-fix PHPCS issues
./scripts/manage.sh fix

# PHPStan Static Analysis (Level 9)
./scripts/manage.sh analyse

# PHP Mess Detector
./scripts/manage.sh phpmd

# Psalm Static Analysis
./scripts/manage.sh psalm

# PHPUnit Tests
./scripts/manage.sh test

# Quick essential checks only
./scripts/manage.sh quick-check
```

## 📊 Understanding Reports

### PHPCS Output
- **Errors**: Must be fixed (coding standard violations)
- **Warnings**: Should be reviewed (potential issues)
- **Fixable**: Can be auto-fixed with `./scripts/manage.sh fix`

### PHPStan Output
- **Level 9**: Strictest analysis level
- **Error Types**:
  - Type mismatches
  - Undefined variables/methods
  - Dead code
  - Logic errors

### PHPMD Output
- **Priority Levels**:
  - 1: High priority (critical issues)
  - 2: Medium priority (important issues)
  - 3: Low priority (minor issues)

### Psalm Output
- **Issue Types**:
  - ERROR: Critical issues
  - INFO: Informational messages
  - Taint analysis for security

### PHPUnit Output
- **Coverage Reports**: Available in `./tests/coverage/`
- **Test Results**: Pass/Fail status for each test
- **Performance**: Execution time and memory usage

## 🎯 Best Practices

### 1. **Development Workflow**
```bash
# Before committing code
./scripts/manage.sh quick-check

# Before releasing
./scripts/manage.sh quality
```

### 2. **Fixing Issues**
1. **Start with PHPCS**: Fix coding standards first
   ```bash
   ./scripts/manage.sh fix  # Auto-fix what's possible
   ./scripts/manage.sh lint # Check remaining issues
   ```

2. **Run PHPStan**: Fix type and logic issues
   ```bash
   ./scripts/manage.sh analyse
   ```

3. **Check for Code Smells**: Review PHPMD output
   ```bash
   ./scripts/manage.sh phpmd
   ```

4. **Run Tests**: Ensure functionality works
   ```bash
   ./scripts/manage.sh test
   ```

### 3. **Configuration Customization**

#### PHPCS Configuration (`config/phpcs/phpcs.xml`)
- Modify excluded patterns
- Adjust line length limits
- Add custom text domains
- Configure minimum WordPress version

#### PHPStan Configuration (`config/phpstan/phpstan.neon`)
- Adjust analysis level (1-9)
- Add custom ignore patterns
- Configure WordPress-specific settings
- Enable/disable strict rules

#### PHPMD Configuration (`config/phpmd/phpmd.xml`)
- Customize rule thresholds
- Enable/disable specific rules
- Adjust complexity limits

#### Psalm Configuration (`config/psalm/psalm.xml`)
- Set error level (1-8)
- Configure WordPress plugin settings
- Add custom issue handlers

#### PHPUnit Configuration (`config/phpunit/phpunit.xml`)
- Configure test suites
- Set coverage requirements
- Adjust memory limits

## 🔧 Advanced Usage

### Custom PHPCS Rules
```bash
# Run with specific standard
docker-compose run --rm phpcs phpcs --standard=WordPress-VIP-Go /data/xandar/wp-content/themes/your-theme

# Generate detailed report
docker-compose run --rm phpcs phpcs --report=full --report-file=/tmp/detailed-report.txt
```

### PHPStan with Custom Configuration
```bash
# Run with different level
docker-compose run --rm phpstan analyse --level=8 /app/xandar/wp-content/themes/your-theme

# Generate baseline (ignore existing issues)
docker-compose run --rm phpstan analyse --generate-baseline
```

### PHPMD Custom Analysis
```bash
# Analyze specific directory with custom rules
docker-compose run --rm phpmd phpmd /app/xandar/wp-content/themes/your-theme text cleancode,codesize,design
```

### PHPUnit with Coverage
```bash
# Run tests with HTML coverage report
docker-compose run --rm phpunit phpunit --coverage-html=/app/tests/coverage/html --coverage-clover=/app/tests/coverage/clover.xml
```

## 📈 Performance Optimization

### Memory Limits
- **PHPCS**: 512M (configured in Dockerfile)
- **PHPStan**: 1G (configured in manage.sh)
- **Psalm**: Uses composer cache for performance
- **PHPUnit**: Configurable in phpunit.xml

### Parallel Processing
- **PHPCS**: Uses 8 parallel processes
- **PHPStan**: Automatic parallel processing
- **PHPMD**: Single-threaded by design

### Caching
- **PHPStan**: Uses composer cache volume
- **Psalm**: Uses composer cache volume
- **PHPUnit**: Results cached between runs

## 🎉 Integration with IDEs

### VS Code
1. Install PHP extensions:
   - PHP Intelephense
   - PHP Debug
   - phpcs
   - PHPStan

2. Configure settings.json:
```json
{
    "php.validate.executablePath": "/usr/local/bin/php",
    "phpcs.executablePath": "docker-compose run --rm phpcs phpcs",
    "phpstan.path": "docker-compose run --rm phpstan"
}
```

### PHPStorm
1. Configure PHP interpreter to use Docker
2. Set up PHPCS inspection with custom ruleset
3. Configure PHPStan plugin
4. Set up PHPUnit test runner

## 🚨 Troubleshooting

### Common Issues

#### PHPCS "No files to process"
```bash
# Check file paths in phpcs.xml
# Ensure WordPress files exist in specified directories
```

#### PHPStan "Class not found"
```bash
# Ensure WordPress is properly loaded
# Check bootstrap files configuration
# Verify composer dependencies
```

#### PHPMD "No input files specified"
```bash
# Check directory paths
# Ensure PHP files exist in target directories
```

#### PHPUnit "Bootstrap file not found"
```bash
# Check bootstrap.php path in phpunit.xml
# Ensure WordPress test environment is set up
```

### Performance Issues
- Increase Docker memory allocation
- Use SSD storage for better I/O
- Exclude large directories (uploads, cache)
- Use baseline files for gradual adoption

## 📚 Further Reading

- [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/)
- [PHPStan Documentation](https://phpstan.org/user-guide/getting-started)
- [PHPMD Rules](https://phpmd.org/rules/index.html)
- [Psalm Documentation](https://psalm.dev/docs/)
- [PHPUnit Documentation](https://phpunit.de/documentation.html)

---

**🎯 Remember**: Code quality is not about perfection, it's about consistency, maintainability, and security. Start with the basics and gradually improve your codebase!