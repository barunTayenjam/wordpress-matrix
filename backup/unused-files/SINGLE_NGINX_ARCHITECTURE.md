# 🏗️ Single Nginx Architecture for WordPress Matrix

## 🎯 **CONCEPT: One Nginx to Rule Them All**

You're absolutely right! Instead of multiple nginx containers, we can have **one unified nginx server** that handles all WordPress sites using **virtual hosts**.

## 📊 **ARCHITECTURE COMPARISON:**

### **❌ CURRENT (Multiple Nginx):**
```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│nginx_xandar │   │nginx_asgard │   │nginx_myproj │  ← 3 containers
└─────────────┘   └─────────────┘   └─────────────┘
       │                 │                 │
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   xandar    │   │   asgard    │   │ myproject   │
│(WordPress)  │   │(WordPress)  │   │(WordPress)  │
└─────────────┘   └─────────────┘   └─────────────┘
```

### **✅ PROPOSED (Single Nginx):**
```
         ┌─────────────────────────────┐
         │      nginx_unified          │  ← 1 container
         │   (Virtual Hosts Router)    │
         └─────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   xandar    │   │   asgard    │   │ myproject   │
│(WordPress)  │   │(WordPress)  │   │(WordPress)  │
└─────────────┘   └─────────────┘   └─────────────┘
```

## 🚀 **BENEFITS OF SINGLE NGINX:**

### **✅ Resource Efficiency:**
- **Before**: 3 nginx containers = 3x memory, 3x CPU
- **After**: 1 nginx container = 1x memory, 1x CPU

### **✅ Simplified Management:**
- **Before**: Update 3 nginx configs separately
- **After**: Update 1 unified config

### **✅ Dynamic Site Addition:**
- **Before**: Create new nginx container + config for each site
- **After**: Just add site to existing config

### **✅ Centralized Routing:**
- **Before**: Multiple Traefik routes
- **After**: Single Traefik route with regex matching

## 🛠️ **IMPLEMENTATION APPROACHES:**

### **Approach 1: Nginx Proxy (Current WordPress Apache)**
```nginx
# Route to existing Apache containers
upstream xandar_backend { server xandar:80; }
upstream asgard_backend { server asgard:80; }

server {
    listen 80;
    server_name xandar.127.0.0.1.nip.io;
    location / { proxy_pass http://xandar_backend; }
}

server {
    listen 80;
    server_name asgard.127.0.0.1.nip.io;
    location / { proxy_pass http://asgard_backend; }
}
```

### **Approach 2: Nginx + FPM (Optimal)**
```nginx
# Direct PHP-FPM communication
map $host $backend {
    ~^xandar\..*$ xandar:9000;
    ~^asgard\..*$ asgard:9000;
    ~^(?<site>[^.]+)\..*$ wordpress_$site:9000;
}

server {
    listen 80 default_server;
    location ~ \.php$ {
        fastcgi_pass $backend;
        # ... fastcgi config
    }
}
```

## 🎯 **YOUR EXISTING DYNAMIC CONFIG:**

You already have `config/nginx/dynamic-sites.conf` that implements this! It uses:

1. **Dynamic mapping** based on hostname
2. **Variable backends** for different sites  
3. **Automatic routing** for new sites

## 🚀 **IMPLEMENTATION PLAN:**

### **Phase 1: Quick Win (Proxy Mode)**
```bash
# 1. Stop individual nginx containers
docker stop nginx_xandar nginx_asgard nginx_myproject

# 2. Create unified nginx with proxy config
# 3. Route domains to existing WordPress Apache containers
```

### **Phase 2: Optimal (FPM Mode)**
```bash
# 1. Convert WordPress containers to FPM
# 2. Use your existing dynamic-sites.conf
# 3. Full nginx + FPM architecture
```

## 📋 **DOCKER COMPOSE STRUCTURE:**

```yaml
services:
  # Single nginx for all sites
  nginx-unified:
    image: nginx:alpine
    container_name: nginx_unified
    volumes:
      - ./config/nginx/dynamic-sites.conf:/etc/nginx/conf.d/default.conf:ro
      - ./xandar:/var/www/xandar:ro
      - ./asgard:/var/www/asgard:ro
      # Mount all WordPress directories
    labels:
      - "traefik.http.routers.wordpress.rule=HostRegexp(`{site:[a-z0-9-]+}.127.0.0.1.nip.io`)"
      # Single Traefik rule for all sites

  # WordPress containers (FPM)
  xandar:
    image: wordpress:fpm-alpine
    # No port mapping needed
    
  asgard:
    image: wordpress:fpm-alpine
    # No port mapping needed
```

## 🎉 **ADVANTAGES FOR SITE MANAGEMENT:**

### **✅ Dynamic Site Creation:**
```bash
# Create new site
./scripts/manage-sites.sh create newsite

# Automatically works with unified nginx
# No need to create new nginx container
```

### **✅ Simplified Scaling:**
- Add 10 sites = Still 1 nginx container
- Remove sites = nginx config auto-adapts
- Update nginx = All sites benefit

### **✅ Better Performance:**
- Shared nginx processes
- Connection pooling
- Unified caching

## 🎯 **NEXT STEPS:**

1. **Test current setup** - Your direct ports work perfectly
2. **Implement unified nginx** - Use proxy mode first
3. **Migrate to FPM** - For optimal performance
4. **Update management scripts** - To use unified architecture

**You're absolutely right - this is a much better architecture!** 🚀

Would you like me to implement the unified nginx approach?