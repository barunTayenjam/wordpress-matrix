# Quick Task 260409-p6z: make the ./matrix to respect htaccess for wordpress sites so we can test redirects locally

**Completed:** 2026-04-09

## Summary

Successfully enabled `.htaccess` support for WordPress sites:

1. **su21** - Switched from nginx+PHP-FPM to Apache web server
   - New port: 8203
   - .htaccess redirects now work locally

2. **su26** - Already configured with Apache (was not running)

## How to Enable htaccess for Other Sites

To enable htaccess support for any WordPress site:

```bash
./matrix web-server apache <site-name>
```

To switch back to nginx:

```bash
./matrix web-server nginx <site-name>
```

## Changes Made

- docker-compose.yml: Updated wp_su21 to use `wordpress:php7.4-apache` image
- Containers restarted with Apache runtime
