# Stack Research: Performance Optimization

**Domain:** WordPress marketing site (SearchUnify) — performance optimization & code quality
**Researched:** 2026-05-04
**Confidence:** HIGH (infrastructure/tooling), MEDIUM (LiteSpeed Cache feature compatibility with Nginx)

## Context

This is NOT a greenfield stack. The site already runs WordPress 6.9.4 on Docker (Nginx + PHP 8.3-FPM) with Elementor, ACF Pro, Yoast SEO, LiteSpeed Cache, Revolution Slider, Slick Carousel, Marketo, Calendly, jQuery, Bootstrap, Moment.js, and Lottie. The child theme has no build process, ~19K lines in style.css, duplicate min/unmin JS files, and inconsistent CDN usage.

**This stack recommendation covers only WHAT TO ADD/CHANGE for performance optimization.**

---

## Recommended Stack

### 1. Build Pipeline (NEW — does not exist today)

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| **Vite** | 8.0.x | Build tool for CSS/JS compilation, minification, bundling | Fastest build tool available (Oxc minifier 30-90x faster than Terser). Native CSS minification via Lightning CSS. Replaces the current non-existent build process. Lightweight config. Supports multi-entry builds needed for WordPress page-specific CSS/JS. | HIGH |
| **Lightning CSS** | 1.32.x (bundled with Vite) | CSS transformation, minification, autoprefixing | Built into Vite as default CSS minifier. Handles vendor prefixing, nesting, color mixing. Eliminates need for separate PostCSS + Autoprefixer + cssnano. | HIGH |
| **@vitejs/plugin-legacy** | 8.0.x | Legacy browser support (IE11-era fallback not needed, but provides broader compatibility) | **Optional.** Only include if analytics show significant pre-es2015 traffic. For a B2B marketing site, modern-only builds are likely sufficient. | MEDIUM |

**Why Vite over Webpack/Parcel/Gulp:**
- Webpack: Overkill for WordPress theme asset building. Complex config. Slow.
- Gulp: Legacy approach, requires manual plugin chain for each transformation.
- Parcel: Zero-config is nice but less control over WordPress-specific entry points.
- **Vite wins** because: instant dev server, multi-entry builds map well to WordPress page-specific assets, Lightning CSS handles CSS pipeline in one step, Oxc minifier is fastest available.

**How Vite fits this WordPress theme:**
The child theme loads CSS/JS via `wp_enqueue_script`/`wp_enqueue_style` in `inc/scripts.php` and `inc/post-types.php`. Vite builds output to `dist/` within the theme, and the PHP enqueue code references those built files with `filemtime()` cache busting. No WordPress hooks need to change — only the file paths.

```bash
# Install in child theme root
cd wp-content/themes/seoinux-child/
npm init -y
npm install -D vite lightningcss
```

**Vite config pattern for WordPress multi-entry:**
```javascript
// vite.config.js
import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    manifest: true,              // generates manifest.json for PHP to read
    minify: 'oxc',               // fastest minifier (Vite default)
    cssMinify: true,             // Lightning CSS by default
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'src/js/main.js'),
        events: resolve(__dirname, 'src/js/events-ajax.js'),
        slick: resolve(__dirname, 'src/js/slick-init.js'),
        marketo: resolve(__dirname, 'src/js/marketo.js'),
        sidebar: resolve(__dirname, 'src/js/sticky-sidebar-init.js'),
        'main-style': resolve(__dirname, 'src/css/main.scss'),
        'v2-style': resolve(__dirname, 'src/css/style-v2.scss'),
        'mobile-style': resolve(__dirname, 'src/css/mobile.scss'),
      },
      output: {
        entryFileNames: 'js/[name]-[hash].js',
        chunkFileNames: 'js/[name]-[hash].js',
        assetFileNames: 'css/[name]-[hash][extname]',
      },
    },
  },
})
```

### 2. Caching Layers (OPTIMIZE — LiteSpeed Cache already installed)

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| **LiteSpeed Cache** | Already installed | Page cache, CSS/JS optimization, image optimization, object cache, browser cache | Already in the plugin stack. Feature-rich: CSS/JS minify+combine+defer, critical CSS (CCSS), unique CSS (UCSS), WebP/AVIF conversion, lazy loading, HTML minify, Redis object cache, browser cache TTL. No need to add another caching plugin. Just needs proper configuration. | HIGH |
| **Redis Object Cache** | Already in docker-compose | Database query caching, transient caching, session storage | Already running as `redis:alpine` in docker-compose. LiteSpeed Cache has native Redis support via its Object Cache tab. Just needs to be enabled and connected (`redis:6379` on the `wp-net` Docker network). | HIGH |
| **Nginx FastCGI Cache** | Built-in Nginx | Full-page cache served by Nginx without hitting PHP-FPM at all | **Conditional recommendation.** LiteSpeed Cache provides page caching, but it requires LiteSpeed server or QUIC.cloud. Since this site runs on Nginx (not LiteSpeed server), LiteSpeed Cache's page caching may not work for server-level caching — only the optimization features (CSS/JS minify, image optimization) will work. **Therefore, Nginx FastCGI cache is the primary page cache strategy.** | HIGH |

**Critical note about LiteSpeed Cache on Nginx:**
Per the official LiteSpeed docs (verified 2026-05-04): "It is possible to use the LSCache plugin for WordPress without a LiteSpeed server product, however you will only access to the optimization features. The caching functions require the LSCache server component to work."

This means:
- ✅ LiteSpeed Cache optimization features work on Nginx: CSS minify/combine/defer, JS minify/combine/defer, HTML minify, lazy load images, image optimization (WebP/AVIF via QUIC.cloud), remove emoji, DNS prefetch/preconnect, remove query strings
- ❌ LiteSpeed Cache page caching does NOT work on Nginx — use Nginx FastCGI cache instead
- ❌ LiteSpeed Cache object cache (Redis) via its UI may still work as it's PHP-level, not server-level — **needs verification** (MEDIUM confidence)

### 3. Nginx Configuration (OPTIMIZE — currently minimal)

The current `su26.conf` is a bare-bones config with no performance tuning:

```nginx
# CURRENT: Minimal — no gzip, no caching, no optimization
```

| Optimization | Purpose | Why | Confidence |
|-------------|---------|-----|------------|
| **Gzip compression** | Compress text-based responses (HTML, CSS, JS, JSON, XML, SVG) | Reduces transfer size by 60-80%. Zero downside for text content. Essential for PageSpeed score. | HIGH |
| **FastCGI cache** | Serve cached PHP responses without invoking PHP-FPM | Eliminates PHP processing for cached pages. Biggest single performance win. Must be configured with proper purge rules (purge on post save/update). | HIGH |
| **Static asset caching headers** | `Cache-Control: public, max-age=31536000, immutable` for hashed assets | Tells browsers to cache built assets (with content hashes from Vite) for a year. Only possible after Vite build adds hashes to filenames. | HIGH |
| **Security headers** | X-Content-Type-Options, X-Frame-Options, etc. | Replace some of the overlapping security plugin functions (Defender, SG Security). | HIGH |

**Recommended Nginx config additions:**

```nginx
# Gzip compression
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_min_length 1000;
gzip_types
    text/plain
    text/css
    text/xml
    text/javascript
    application/json
    application/javascript
    application/xml
    application/xml+rss
    image/svg+xml;

# FastCGI cache zone (in http block or separate conf)
fastcgi_cache_path /var/cache/nginx/su26 levels=1:2
    keys_zone=su26_cache:100m
    max_size=1g
    inactive=60m
    use_temp_path=off;

# Browser cache for static assets
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp|avif)$ {
    expires 365d;
    add_header Cache-Control "public, immutable";
    add_header X-Content-Type-Options "nosniff";
    log_not_found off;
    access_log off;
}
```

**What NOT to add to Nginx:**
- **Brotli module**: Requires custom Nginx build. Gzip at level 6 is sufficient and universally supported. The compression gain (10-15% over gzip) does not justify the operational complexity of maintaining a custom Nginx image for a marketing site. If Brotli becomes available in the default `nginx:alpine` image, enable it then.

### 4. PHP-FPM Tuning (OPTIMIZE — currently default)

| Setting | Recommended Value | Why | Confidence |
|---------|-------------------|-----|------------|
| **opcache.enable** | 1 (enable if not already) | Caches compiled PHP bytecode. Eliminates PHP parsing on every request. Single biggest PHP performance win. | HIGH |
| **opcache.memory_consumption** | 256 | Default 128MB may be insufficient for WordPress + Elementor + ACF Pro + Yoast combined opcode. | HIGH |
| **opcache.interned_strings_buffer** | 16 | WordPress uses many string literals. Default 8MB causes cache eviction. | HIGH |
| **opcache.max_accelerated_files** | 40000 | WordPress core + plugins + theme = thousands of PHP files. Default 4000 is too low. | HIGH |
| **opcache.validate_timestamps** | 0 (production), 1 (dev) | In production, disable timestamp checks and clear OPcache on deploy. Eliminates stat() calls. | HIGH |
| **pm.max_children** | Based on available RAM | Default often too low. Calculate: `available_RAM / per-process_memory`. WordPress + Elementor processes use ~80-120MB each. With 2GB RAM allocated: ~15-20 children. | HIGH |
| **pm.max_requests** | 500 | Prevents memory leaks in long-running PHP processes by recycling workers. | HIGH |

**How to apply:** Add a custom `php.ini` or `conf.d/` file mounted into the Docker container, or set via `WORDPRESS_CONFIG_EXTRA` in docker-compose environment.

### 5. Code Quality Tooling (OPTIMIZE — already in docker-compose)

| Tool | Version | Purpose | Why Recommended | Confidence |
|------|---------|---------|-----------------|------------|
| **PHPStan** | Latest (via `ghcr.io/phpstan/phpstan:latest`) | Static analysis for PHP | Already in docker-compose as a `tools` profile service. Start at level 1 and gradually increase. The child theme's large PHP files (`su-rest-functions.php`, `top-bar-shortcode.php`, `post-types.php`) will benefit most from type analysis. | HIGH |
| **PHP_CodeSniffer (phpcs)** | Latest (via `wpengine/phpcs:latest`) | WordPress coding standards enforcement | Already in docker-compose. The `wpengine/phpcs` image includes WordPress Coding Standards (WPCS) pre-installed. Configure ruleset to focus on child theme only. | HIGH |

**PHPStan configuration for this project:**
```yaml
# phpstan.neon in child theme root
parameters:
    level: 1                    # Start low, increase gradually
    paths:
        - functions.php
        - inc/
        - includes/
        - modules/
    excludePaths:
        - vendor/*
        - node_modules/*
    phpVersion: 80300           # PHP 8.3
    bootstrapFiles:
        - phpstan-bootstrap.php # Define WordPress functions/stubs
```

**PHPCS ruleset for this project:**
```xml
<?xml version="1.0"?>
<ruleset name="Seoinux Child Theme">
    <description>Coding standards for seoinux-child</description>
    <file>.</file>
    <arg name="extensions" value="php"/>
    <exclude-pattern>*/vendor/*</exclude-pattern>
    <exclude-pattern>*/node_modules/*</exclude-pattern>
    <exclude-pattern>*/dist/*</exclude-pattern>
    <!-- WordPress standards, relaxed for existing codebase -->
    <rule ref="WordPress-Core">
        <!-- Relax during initial cleanup -->
        <exclude name="WordPress.Files.FileName"/>
        <exclude name="WordPress.NamingConventions.ValidVariableName"/>
    </rule>
</ruleset>
```

### 6. Image Optimization

| Tool | Purpose | Why | Confidence |
|------|---------|-----|------------|
| **LiteSpeed Cache Image Optimization** (via QUIC.cloud) | WebP/AVIF conversion, lossy/lossless compression | Already built into the installed plugin. Free tier covers standard queue (unlimited). AVIF requires paid quota. Start with WebP. | HIGH |
| **Native WordPress lazy loading** | `loading="lazy"` on images below fold | WordPress 5.5+ adds this automatically. LiteSpeed Cache enhances it with placeholder images. Audit to ensure hero images have `loading="eager"` or `fetchpriority="high"`. | HIGH |
| **Vite image optimization** (via `vite-plugin-imagemin` or similar) | Optimize images during build | **Not recommended.** Build-time image optimization is for custom assets (icons, logos). Media library images are managed by LiteSpeed Cache. Don't add complexity where it's not needed. | — |

### 7. CDN Strategy

| Approach | Recommendation | Why | Confidence |
|----------|---------------|-----|------------|
| **CDN for static assets** | Cloudflare (free tier) or QUIC.cloud | Cloudflare free tier provides CDN, DNS, basic WAF, and Brotli/gzip at the edge. QUIC.cloud integrates natively with LiteSpeed Cache. Either is valid. For a marketing site expecting global traffic, Cloudflare is the more established choice. | MEDIUM |
| **Self-host third-party libraries** | Move Slick, Bootstrap, Lottie, Moment.js to local builds via Vite | Current approach loads some from CDN, some local — inconsistent. Self-hosting via Vite gives version control, hashing, tree-shaking, and eliminates external DNS lookups. For a marketing site, reducing third-party dependency is better than CDN distribution. | HIGH |

**Why self-host instead of CDN for these libraries:**
- Slick Carousel: Only needed on specific pages. Vite can code-split so it only loads where needed.
- Bootstrap: Likely only using a fraction of components. Vite + Lightning CSS tree-shakes unused CSS.
- Moment.js: 72KB minified. Replace with native `Intl.DateTimeFormat` or `date-fns` (2KB tree-shaken) if only formatting dates.
- Lottie: Already a local file. Keep in build process.

### 8. CSS Architecture (REFACTOR)

| Approach | Purpose | Why | Confidence |
|----------|---------|-----|------------|
| **Vite multi-entry CSS** | Split the 19K-line `style.css` into page-specific bundles | Instead of one monolithic CSS file, Vite builds separate CSS per page/template. The PHP enqueue code (`inc/scripts.php`) already loads CSS conditionally per template. Map each to its own Vite entry. | HIGH |
| **Lightning CSS** | Remove unused CSS, autoprefix, minify | Lightning CSS (built into Vite) handles browser compatibility and minification. For dead code elimination, use Vite's `manualChunks` + per-page CSS entries to naturally limit CSS to what each page needs. | HIGH |
| **Critical CSS** | Inline above-the-fold CSS for faster FCP | LiteSpeed Cache can generate Critical CSS (CCSS) via QUIC.cloud service. If that's not available (no LiteSpeed server), use `vite-plugin-critical` or manually extract critical CSS for key templates. | MEDIUM |

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| **Vite** | Webpack | Webpack is slower, more complex, and overkill for a WordPress theme. Vite handles the same use case in a fraction of the config. |
| **Vite** | Gulp | Gulp is a task runner, not a bundler. Requires manual plugin chain for each transformation. No tree-shaking, no code-splitting. Legacy approach. |
| **Vite** | No build tool (status quo) | Status quo means 19K lines of unminified CSS, duplicate JS files, no cache-busting hashes, no tree-shaking. Cannot hit 90+ PageSpeed without a build process. |
| **LiteSpeed Cache optimization** | Autoptimize | Autoptimize is a good free plugin for CSS/JS optimization, but LiteSpeed Cache is already installed and has equivalent features (plus image optimization, object cache). Adding Autoptimize would create conflicts and overlap. |
| **LiteSpeed Cache optimization** | WP Rocket ($59/year) | WP Rocket is excellent but redundant since LiteSpeed Cache already covers CSS/JS optimization, lazy loading, and database cleanup. Adding WP Rocket creates plugin overlap. If LiteSpeed Cache's optimization features prove insufficient on Nginx, THEN consider WP Rocket as a fallback. |
| **Nginx FastCGI cache** | Redis page cache | Redis is for object caching (database queries, transients), not full-page HTML caching. FastCGI cache is the right layer for Nginx full-page caching. |
| **Gzip** | Brotli | Brotli requires custom Nginx module compilation. Gzip at level 6 achieves 60-80% compression and is universally supported. The incremental benefit of Brotli (~10-15% better compression) does not justify maintaining a custom Docker image. |
| **PHPStan** | Psalm | Both are excellent. PHPStan is already in the docker-compose setup. No reason to add a second static analysis tool. |
| **date-fns** (to replace Moment.js) | Day.js | Both are Moment.js alternatives. Day.js is a drop-in API clone (2KB). date-fns is tree-shakable and functional. Either works. Day.js is slightly easier to migrate to since it mirrors Moment's API. Recommend **Day.js** for this project specifically because of API compatibility. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Autoptimize** | Conflicts with LiteSpeed Cache's CSS/JS optimization. Two plugins trying to minify/combine the same resources causes broken layouts. | LiteSpeed Cache Page Optimization tab |
| **WP Rocket** (for now) | Redundant with LiteSpeed Cache + Nginx FastCGI cache. Only add if LiteSpeed Cache's optimization features don't work well on Nginx without LiteSpeed server. | LiteSpeed Cache + Nginx FastCGI cache |
| **W3 Total Cache** | Legacy, complex configuration, known issues with Elementor. Overkill. | LiteSpeed Cache + Nginx FastCGI cache |
| **Brotli Nginx module** | Requires custom Docker image. Gzip is sufficient for this use case. | Gzip compression |
| **npm-based image optimization** (sharp, imagemin) | Media library images are managed by LiteSpeed Cache + QUIC.cloud. Build-time optimization is for theme assets only. | LiteSpeed Cache Image Optimization |
| **Multiple security plugins** (Defender + Really Simple SSL + SG Security) | Overlapping functionality increases PHP processing on every request. Each plugin adds hooks that fire on page load. | Consolidate to one security plugin (Really Simple SSL for HTTPS + Wordfence or keep SG Security). Remove others. |
| **Revolution Slider** (for new content) | RevSlider generates heavy DOM, inline CSS/JS, and multiple HTTP requests. It's a known PageSpeed killer. Keep existing sliders but don't create new ones. | CSS animations or lightweight alternatives for new content |
| **Multiple caching plugins simultaneously** | LiteSpeed Cache + another caching plugin = unpredictable cache behavior, stale content, broken dynamic elements. | One caching strategy (LiteSpeed optimization + Nginx FastCGI) |
| **CDN for theme assets** | Current approach mixes CDN and local — worst of both worlds. Self-hosted via Vite with content hashing gives better cache control and fewer DNS lookups. | Vite build with content-hashed filenames + Nginx cache headers |

---

## Stack Patterns by Phase

### If doing infrastructure first (recommended):
- Configure Nginx gzip + FastCGI cache + static asset headers
- Connect Redis as object cache via LiteSpeed Cache
- Tune PHP-FPM OPcache settings
- **Rationale:** Biggest performance wins with least risk of breaking visual design

### If doing CSS/JS build pipeline first:
- Set up Vite in child theme
- Split `style.css` into source files by template/page
- Build and verify output matches current visual
- Update PHP enqueue paths to built files
- **Rationale:** Enables all subsequent CSS/JS optimizations

### If doing code quality first:
- Run PHPStan at level 1 on child theme
- Run PHPCS with relaxed WordPress-Core rules
- Fix critical issues (undefined variables, missing escaping)
- **Rationale:** Improves codebase health before refactoring, catches bugs early

---

## Installation

```bash
# Build pipeline (in child theme directory)
cd wp-content/themes/seoinux-child/
npm init -y
npm install -D vite

# That's it. Lightning CSS is bundled with Vite.
# No additional CSS/JS tooling packages needed.

# Code quality tools are already in docker-compose as profile services:
docker compose --profile tools run --rm phpcs --standard=WordPress-Core wp-content/themes/seoinux-child/
docker compose --profile tools run --rm phpstan analyse wp-content/themes/seoinux-child/
```

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Vite 8.0.x | Node.js 18+ | Verify Docker host Node version |
| Lightning CSS 1.32.x | Vite 6+ | Bundled as Vite's default CSS minifier |
| PHPStan latest | PHP 8.0+ | Use `phpVersion: 80300` in config for PHP 8.3 runtime |
| phpcs (wpengine/phpcs) | PHP 7.4+ | Includes WPCS pre-installed |
| Redis (alpine) | LiteSpeed Cache Object Cache tab | Connect to `redis:6379` on wp-net Docker network |
| LiteSpeed Cache (current) | WordPress 5.3+, PHP 7.2+ | Already installed. Optimization features work on Nginx; page caching requires LiteSpeed server. |

---

## Key Risk: LiteSpeed Cache Page Caching on Nginx

**This is the single most important finding.**

Per the official LiteSpeed documentation (verified 2026-05-04 at https://docs.litespeedtech.com/lscache/lscwp/installation/):

> "It is possible to use the LSCache plugin for WordPress without a LiteSpeed server product, however you will only access to the optimization features. The caching functions require the LSCache server component to work."

This means:
1. **LiteSpeed Cache optimization features DO work on Nginx** — CSS/JS minify/combine/defer, HTML minify, lazy loading, image optimization, DNS prefetch, emoji removal, query string removal. These are PHP-level transformations, not server-level.
2. **LiteSpeed Cache page caching does NOT work on Nginx** — The server-level LSCache engine is required for full-page caching. LiteSpeed Cache's Cache tab settings will have no effect.
3. **Redis object cache via LiteSpeed Cache** — The Object Cache tab connects PHP to Redis. This should work on Nginx since it's PHP-level, but **this needs verification** during implementation.

**Implication:** The page caching strategy must be Nginx FastCGI cache, not LiteSpeed Cache. LiteSpeed Cache is retained purely for its optimization features (CSS/JS/HTML/image).

---

## Sources

- Context7 `/vitejs/vite` — Vite build configuration, minification options, Lightning CSS integration
- Context7 `/websites/litespeedtech` — LiteSpeed Cache for WordPress API, server prerequisites
- Context7 `/websites/wp-rocket_me` — WP Rocket best practices for comparison (confirmed LiteSpeed Cache covers equivalent features)
- Context7 `/websites/nginx` — Nginx gzip, FastCGI cache, static file serving
- Context7 `/phpstan/phpstan` — PHPStan configuration, rule levels, neon config format
- Context7 `/phpcsstandards/php_codesniffer` — PHPCS ruleset configuration, WordPress standards
- Context7 `/kasparsd/wp-docs-md` — WordPress `wp_enqueue_script`/`wp_enqueue_style` best practices
- Official LiteSpeed docs (https://docs.litespeedtech.com/lscache/lscwp/) — LSCache WordPress plugin capabilities, Nginx compatibility note
- Official LiteSpeed docs (https://docs.litespeedtech.com/lscache/lscwp/pageopt/) — CSS/JS/HTML/Media optimization settings
- Official LiteSpeed docs (https://docs.litespeedtech.com/lscache/lscwp/imageopt/) — Image optimization, WebP/AVIF settings
- npm registry — Vite 8.0.10, @vitejs/plugin-legacy 8.0.1, Lightning CSS 1.32.0 verified current versions
- Project codebase — `su26.conf` (Nginx config), `docker-compose.yml`, child theme directory structure

---
*Stack research for: SearchUnify WordPress performance optimization*
*Researched: 2026-05-04*
