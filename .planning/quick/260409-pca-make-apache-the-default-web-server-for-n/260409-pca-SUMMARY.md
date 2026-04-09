# Quick Task 260409-pca: make apache the default web server for new wordpress sites instead of nginx

**Completed:** 2026-04-09

## Summary

Changed the default web server from nginx to Apache in both `./matrix` and `./frontend/matrix`:

1. Added `DEFAULT_WEB_SERVER="apache"` configuration variable
2. Updated `create_site()` function to use `DEFAULT_WEB_SERVER` instead of hardcoded "nginx"
3. Updated help text to reflect the new default

## How It Works

- New sites created with `./matrix create <name>` now use Apache by default
- Use `./matrix create <name> --web-server=nginx` to use nginx explicitly
- Use `./matrix web-server nginx <site-name>` to switch an existing site to nginx

## Changes Made

- `./matrix`: Added DEFAULT_WEB_SERVER config, updated default value in create_site()
- `./frontend/matrix`: Same changes for frontend compatibility
