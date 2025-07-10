# 🔌 Port-based Direct Access Guide

## Overview

The WordPress Matrix now supports **dual access methods** for maximum development flexibility:

1. **Domain-based Access** (via Traefik) - Production-like environment
2. **Port-based Direct Access** - Development and debugging

## Port Assignments

| Site | Port | Direct URL | Domain URL |
|------|------|------------|------------|
| xandar | 8001 | http://localhost:8001 | https://xandar.127.0.0.1.nip.io |
| sakaar | 8002 | http://localhost:8002 | https://sakaar.127.0.0.1.nip.io |
| wand | 8003 | http://localhost:8003 | https://wand.127.0.0.1.nip.io |
| testsite | 8004 | http://localhost:8004 | https://testsite.127.0.0.1.nip.io |
| portfolio | 8005 | http://localhost:8005 | https://portfolio.127.0.0.1.nip.io |
| demo | 8006 | http://localhost:8006 | https://demo.127.0.0.1.nip.io |
| testfix | 8007 | http://localhost:8007 | https://testfix.127.0.0.1.nip.io |
| gemini | 8008 | http://localhost:8008 | https://gemini.127.0.0.1.nip.io |

## When to Use Each Method

### 🌐 Domain-based Access
**Best for:**
- Production testing
- SSL/HTTPS testing
- Load balancing testing
- Full stack integration testing
- Client demonstrations

**Features:**
- ✅ SSL termination
- ✅ Security headers
- ✅ Load balancing
- ✅ Production-like routing
- ✅ Traefik dashboard monitoring

### 🔌 Port-based Direct Access
**Best for:**
- Development and debugging
- Quick testing
- Bypassing proxy issues
- Performance testing
- Individual site isolation

**Features:**
- ✅ Direct access (no proxy overhead)
- ✅ Faster response times
- ✅ Easier debugging
- ✅ Independent of Traefik
- ✅ Simple HTTP (no SSL overhead)

## Management Commands

```bash
# Check port status for all sites
./scripts/manage.sh port-status

# Start environment (both access methods available)
./scripts/manage.sh start

# Check overall status
./scripts/manage.sh status

# View logs for specific nginx container
./scripts/manage.sh logs nginx-xandar
./scripts/manage.sh logs nginx-sakaar
# ... etc for other sites
```

## Architecture

### Domain-based Flow
```
Browser → Traefik (SSL) → Nginx (unified) → WordPress Container
```

### Port-based Flow
```
Browser → Nginx (individual) → WordPress Container
```

## Troubleshooting

### Port Access Issues

1. **Check if containers are running:**
   ```bash
   ./scripts/manage.sh status
   ```

2. **Check port-specific status:**
   ```bash
   ./scripts/manage.sh port-status
   ```

3. **Check individual nginx logs:**
   ```bash
   ./scripts/manage.sh logs nginx-[sitename]
   ```

4. **Test health endpoint:**
   ```bash
   curl http://localhost:8001/health
   ```

### Common Issues

**Port already in use:**
- Check if another service is using the port
- Modify port assignments in `.env` file

**Container not responding:**
- Check WordPress container status
- Verify nginx configuration
- Check logs for errors

**Permission issues:**
- Ensure proper file permissions
- Check volume mounts

## Configuration

### Port Configuration
Ports are defined in `.env` file:
```bash
XANDAR_PORT=8001
SAKAAR_PORT=8002
WAND_PORT=8003
# ... etc
```

### Nginx Configuration
Each site has its own nginx config:
- `config/nginx/xandar.conf`
- `config/nginx/sakaar.conf`
- `config/nginx/wand.conf`
- ... etc

## Benefits of Dual Access

1. **Development Flexibility**: Choose the right access method for your task
2. **Debugging Efficiency**: Direct port access bypasses proxy layers
3. **Production Testing**: Domain access provides production-like environment
4. **Isolation**: Test individual sites without affecting others
5. **Performance**: Direct access for faster development cycles

## Security Considerations

- Port-based access is HTTP only (no SSL)
- Use domain-based access for production testing
- Firewall rules may need adjustment for port access
- Consider network security when exposing ports

---

**Next Steps:**
- Try both access methods with your sites
- Use port-based access for development
- Use domain-based access for final testing
- Monitor performance differences