# Simplified WordPress Development Platform

A streamlined version of the WordPress Development Platform that maintains core functionality while reducing complexity.

## Key Simplifications

### 🚀 Single Command Interface
- Consolidated all functionality into one script: `matrix`
- Reduced command complexity from multiple scripts to single entry point
- Intuitive command structure with helpful output

### 🏗️ Simplified Architecture
- Removed redundant containers and services
- Streamlined Docker configuration
- Unified networking and volume management
- Reduced memory footprint

### 🌐 Easy Site Management
- Simplified site creation (just one command)
- Automatic port assignment
- One-command site removal
- Clear site status overview

### 📦 Essential Features Only
- Core WordPress functionality preserved
- Essential code quality tools
- Basic monitoring capabilities
- Streamlined configuration

## Quick Start

```bash
# 1. Initial setup
cp .env.simple .env
cp docker-compose.simple.yml docker-compose.yml
./matrix setup

# 2. Create your first site
./matrix create myblog

# 3. Start everything
./matrix start

# 4. Check status
./matrix status

# 5. Access your site
# http://localhost:8001 or https://myblog.127.0.0.1.nip.io
```

## Main Commands

### Site Management
```bash
./matrix create <name>    # Create new WordPress site
./matrix list              # List all sites
./matrix start <name>      # Start specific site
./matrix stop <name>       # Stop specific site
./matrix remove <name>      # Remove site
./matrix info <name>       # Show site details
```

### Environment Management
```bash
./matrix start             # Start all services
./matrix stop              # Stop all services
./matrix restart           # Restart all services
./matrix status            # Show system status
./matrix logs [site]       # Show logs
./matrix clean             # Clean up resources
```

### Code Quality
```bash
./matrix check             # Run quality checks
./matrix test              # Run tests
./matrix fix               # Auto-fix issues
```

### Development Tools
```bash
./matrix shell wp          # Access WordPress CLI
./matrix shell db          # Access database
./matrix shell nginx       # Access proxy
./matrix url <name>        # Show site URLs
```

## Architecture Overview

### Simplified Docker Stack
- **Database**: MySQL 8.0 with health checks
- **Cache**: Redis with memory limits
- **Proxy**: Traefik with automatic SSL
- **Code Quality**: PHP CodeSniffer, PHPStan
- **WordPress**: PHP 8.3-FPM with Nginx

### Site Structure
```
wp_<site_name>/
├── wp-content/
│   ├── themes/
│   ├── plugins/
│   └── uploads/
├── wp-config.php
└── wp-*.php files
```

### Configuration Files
- `.env` - Environment variables
- `docker-compose.yml` - Service definitions
- `config/nginx/default.conf` - Nginx configuration

## Benefits of Simplified Version

### 1. Easier Onboarding
- 70% fewer commands to learn
- Clear, single entry point
- Better error messages and help

### 2. Lower Resource Usage
- Fewer containers running
- Reduced memory footprint
- Faster startup times

### 3. Simpler Configuration
- One environment file
- One Docker compose file
- Streamlined Nginx configuration

### 4. Faster Development
- Quick site creation
- Automatic port management
- One-command operations

## Migration from Complex Version

If you're migrating from the complex version:

Seamless migration is available with migration script:

### 1. Check Readiness
```bash
./migrate-to-simple.sh check
```

### 2. Backup Existing Setup
```bash
./migrate-to-simple.sh backup
```

### 3. Perform Migration
```bash
./migrate-to-simple.sh migrate
```

### 4. Rollback if Needed
```bash
./migrate-to-simple.sh rollback
```

### Manual Migration Steps

If you prefer manual migration:

1. **Backup existing sites**
   ```bash
   ./wp-dev backup
   ```

2. **Copy configurations**
   ```bash
   cp .env.simple .env
   cp docker-compose.simple.yml docker-compose.yml
   ```

3. **Run simplified setup**
   ```bash
   ./matrix setup
   ```

4. **Recreate sites as needed**
   ```bash
   ./matrix create <site-name>
   ```

## Code Quality Tools

The simplified version maintains essential code quality:

- **PHP CodeSniffer**: WordPress coding standards
- **PHPStan**: Static analysis
- **Basic testing**: Unit test framework

Run with:
```bash
./matrix check    # All quality checks
./matrix fix       # Auto-fix issues
```

## Monitoring

Basic monitoring included:

- **Traefik Dashboard**: http://localhost:8080
- **Container health checks**: Automatic
- **Log aggregation**: Docker logs

## Comparison with Complex Version

| Feature | Complex Version | Simplified Version |
|---------|----------------|------------------|
| Commands | 50+ | 20 |
| Scripts | 5+ | 1 |
| Docker Services | 15+ | 8 |
| Memory Usage | High | Medium |
| Setup Time | 10-15 min | 2-5 min |
| Learning Curve | Steep | Gentle |

## Next Steps

1. **Try the simplified version**
   ```bash
   ./matrix setup
   ./matrix create test
   ./matrix start
   ```

2. **Migrate your existing sites**
   - Backup data from complex version
   - Recreate sites using simplified commands

3. **Provide feedback**
   - Report issues
   - Suggest improvements
   - Contribute to development

The simplified version maintains all essential functionality while being much easier to use and maintain.