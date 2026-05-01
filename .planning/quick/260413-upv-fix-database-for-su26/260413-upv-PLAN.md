---
id: 260413-upv
slug: fix-database-for-su26
description: Fix database for su26
date: "2026-04-13"
mode: quick
---

## Task Overview

Fix the database connection for WordPress site 'su26'. The error indicates that user 'wp_user' cannot access database 'su26_db'.

## Tasks

### Task 1: Check and create database

**Files:**
- none

**Action:**
1. Connect to the database container
2. Check if `su26_db` database exists
3. If not, create the database
4. Grant all privileges on `su26_db` to `wp_user`

**Verify:**
- Run: `docker exec wp_db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW DATABASES;"` - verify `su26_db` exists
- Run: `docker exec wp_db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW GRANTS FOR 'wp_user'@'%';"` - verify access

**Done:**
- Database created and user has access

---
