# 🌐 Dynamic Site Management - Ultimate WordPress Development Matrix

This document explains how to create, manage, and work with multiple WordPress development instances using the dynamic site management system.

## 🚀 Quick Start

### Create Your First Site
```bash
# Interactive site creation
./scripts/manage.sh create-site

# Or use the direct script
./scripts/create-site.sh
```

### List All Sites
```bash
./scripts/manage.sh list-sites
```

### Get Site Information
```bash
./scripts/manage.sh site-info myproject
```

## 📋 Site Creation Process

When you run the site creation command, you'll be prompted for:

### 1. **Site Name**
- Must be 3-30 characters
- Letters, numbers, hyphens, underscores only
- Must start with a letter
- Must be unique

### 2. **Site Description** (Optional)
- Used as the WordPress site title
- Defaults to "WordPress development site: [site-name]"

### 3. **WordPress Version**
- Latest (recommended)
- 6.6, 6.5, 6.4
- Custom version

### 4. **PHP Version**
- PHP 8.3 (recommended)
- PHP 8.2
- PHP 8.1

## 🎯 What Gets Created

For a site named `myproject`, the system creates:

### **Docker Services**
- `wordpress_myproject` - WordPress PHP-FPM container
- `nginx_myproject` - Nginx proxy container

### **File Structure**
```
project-root/
├── wordpress_myproject/          # WordPress files
├── logs/wordpress_myproject/     # WordPress logs
├── config/nginx/myproject.conf   # Nginx configuration
└── .env                         # Updated with database name
```

### **Database**
- Database: `myproject_db`
- Accessible via existing MySQL container

### **URLs**
- Frontend: `https://myproject.127.0.0.1.nip.io`
- Admin: `https://myproject.127.0.0.1.nip.io/wp-admin`

### **Default Credentials**
- Username: `admin`
- Password: `admin`

## 🛠️ Site Management Commands

### **List Sites**
```bash
./scripts/manage-sites.sh list
# Shows all sites with status and URLs
```

### **Start/Stop Sites**
```bash
# Start a site
./scripts/manage-sites.sh start myproject

# Stop a site
./scripts/manage-sites.sh stop myproject

# Restart a site
./scripts/manage-sites.sh restart myproject
```

### **Site Information**
```bash
./scripts/manage-sites.sh info myproject
# Shows detailed information about the site
```

### **Remove Sites**
```bash
./scripts/manage-sites.sh remove myproject
# Permanently removes the site (with confirmation)
```

## 🔧 Advanced Management

### **Direct Docker Commands**
```bash
# View site logs
docker-compose logs wordpress_myproject

# Execute commands in WordPress container
docker-compose exec wordpress_myproject wp --version

# Access database for specific site
docker-compose exec db-primary mysql -u root -p myproject_db
```

### **File Access**
```bash
# WordPress files
cd wordpress_myproject/

# Nginx configuration
nano config/nginx/myproject.conf

# Site logs
tail -f logs/wordpress_myproject/error.log
```

## 🎨 Code Quality Integration

All created sites are automatically integrated with the code quality tools:

### **Automatic Integration**
- PHPCS configuration updated to include new site
- PHPStan configuration updated to include new site
- All quality commands work across all sites

### **Run Quality Checks**
```bash
# Check all sites
./scripts/manage.sh quality

# Quick check all sites
./scripts/manage.sh quick-check

# Individual tools
./scripts/manage.sh lint      # All sites
./scripts/manage.sh analyse   # All sites
```

## 🌐 Networking & SSL

### **Automatic SSL**
- All sites get automatic SSL via Traefik
- Certificates managed automatically
- HTTPS enforced

### **Domain Pattern**
- Format: `https://[site-name].127.0.0.1.nip.io`
- Works without hosts file modification
- Accessible from any device on local network

### **Port Management**
- No manual port configuration needed
- All sites accessible on standard HTTPS port (443)
- Traefik handles routing automatically

## 📊 Site Monitoring

### **Health Checks**
- WordPress containers have health checks
- Nginx containers have health checks
- Automatic restart on failure

### **Logging**
```bash
# WordPress logs
./scripts/manage.sh logs wordpress_myproject

# Nginx logs
./scripts/manage.sh logs nginx_myproject

# All logs
./scripts/manage.sh logs
```

### **Status Monitoring**
```bash
# All services status
./scripts/manage.sh status

# Specific site status
./scripts/manage-sites.sh info myproject
```

## 🔄 Site Lifecycle

### **Development Workflow**
1. **Create Site**: `./scripts/create-site.sh`
2. **Develop**: Edit files in `wordpress_[site-name]/`
3. **Test**: Run quality checks with `./scripts/manage.sh quality`
4. **Deploy**: Use site as development environment

### **Maintenance**
```bash
# Update WordPress core
docker-compose exec wordpress_myproject wp core update

# Update plugins
docker-compose exec wordpress_myproject wp plugin update --all

# Database backup
./scripts/manage.sh backup
```

### **Cleanup**
```bash
# Remove unused sites
./scripts/manage-sites.sh remove old-project

# Clean up Docker
docker system prune
```

## 🚨 Troubleshooting

### **Site Won't Start**
```bash
# Check Docker status
docker-compose ps

# Check logs
./scripts/manage.sh logs wordpress_myproject

# Restart services
./scripts/manage-sites.sh restart myproject
```

### **Database Issues**
```bash
# Check database container
docker-compose ps db-primary

# Access database directly
docker-compose exec db-primary mysql -u root -p

# Recreate database
docker-compose exec db-primary mysql -u root -p -e "DROP DATABASE myproject_db; CREATE DATABASE myproject_db;"
```

### **SSL/Domain Issues**
```bash
# Check Traefik
docker-compose logs traefik

# Restart Traefik
docker-compose restart traefik

# Clear browser cache
# Try incognito/private browsing
```

### **File Permission Issues**
```bash
# Fix WordPress permissions
sudo chown -R $USER:$USER wordpress_myproject/
chmod -R 755 wordpress_myproject/
```

## 💡 Best Practices

### **Site Naming**
- Use descriptive names: `client-website`, `ecommerce-project`
- Avoid special characters
- Keep names short but meaningful

### **Development**
- Use version control for your themes/plugins
- Regular backups before major changes
- Test with code quality tools before deployment

### **Performance**
- Stop unused sites to save resources
- Regular cleanup of old sites
- Monitor Docker resource usage

### **Security**
- Change default admin credentials
- Keep WordPress and plugins updated
- Use strong passwords in production

## 🎯 Integration Examples

### **With Version Control**
```bash
# Create site
./scripts/create-site.sh
# Site name: myproject

# Initialize git in theme
cd wordpress_myproject/wp-content/themes/mytheme/
git init
git add .
git commit -m "Initial theme setup"
```

### **With Code Quality**
```bash
# Develop your theme/plugin
# Then run quality checks
./scripts/manage.sh quality

# Fix issues automatically where possible
./scripts/manage.sh fix

# Re-run analysis
./scripts/manage.sh analyse
```

### **With Multiple Environments**
```bash
# Development site
./scripts/create-site.sh
# Site name: myproject-dev

# Staging site
./scripts/create-site.sh  
# Site name: myproject-staging

# Testing site
./scripts/create-site.sh
# Site name: myproject-test
```

## 🚀 Advanced Features

### **Custom Configurations**
- Modify `config/nginx/[site-name].conf` for custom Nginx settings
- Add custom PHP configurations in `config/php/`
- Environment-specific settings in `.env`

### **Database Management**
- Each site has its own database
- Shared MySQL container for efficiency
- Easy backup/restore per site

### **Scalability**
- No limit on number of sites (resource dependent)
- Automatic service discovery
- Dynamic configuration updates

---

**🎉 You now have a powerful, scalable WordPress development environment that can create unlimited development instances on demand!**

For more information, see:
- [Main README](../README.md)
- [Code Quality Guide](CODE_QUALITY.md)
- [Debugging Guide](DEBUGGING.md)