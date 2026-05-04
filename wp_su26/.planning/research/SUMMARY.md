# Project Research Summary

**Project:** SearchUnify Marketing Site — Performance & Code Quality
**Domain:** WordPress corporate marketing site performance optimization (Elementor-based)
**Researched:** 2026-05-04
**Confidence:** HIGH

## Executive Summary

This is a performance optimization project for an existing B2B enterprise marketing site built on WordPress 6.9.4 with Elementor, a heavily customized Seoinux child theme, and Docker/Nginx infrastructure. The site has ~44K lines of CSS across multiple files, no build process, duplicate JS files, inconsistent CDN usage, and a fragile slug-based CSS loading system. The goal is 90+ PageSpeed Insights on both mobile and desktop without visual regressions.

Research converges on a three-phase approach: **infrastructure first, then plugin-level optimization, then CSS/JS architecture.** Infrastructure changes (Nginx gzip + FastCGI cache, PHP-FPM OPcache, Redis object cache) deliver the biggest TTFB wins with near-zero risk of breaking visual design. Plugin configuration (LiteSpeed Cache optimization features, image WebP conversion, JS deferral) handles the "table stakes" PageSpeed audits. A Vite build pipeline and CSS/JS refactoring are essential for long-term maintainability but are deferred to the final phase because they carry the highest regression risk on an Elementor-powered site.

The single most critical finding is that **LiteSpeed Cache's page caching does not work on Nginx** — only its optimization features (CSS/JS minify, image optimization, lazy loading) function without a LiteSpeed server. Page caching must be handled by Nginx FastCGI cache. The second critical finding is that Elementor stores CSS class references in the database, so any CSS refactoring that renames or removes classes will silently break page layouts — visual regression testing is mandatory before any CSS change ships.

## Key Findings

### Recommended Stack

The stack adds a Vite build pipeline and optimizes existing infrastructure; nothing is replaced wholesale. The existing WordPress + Elementor + LiteSpeed Cache + Redis + Nginx + PHP-FPM stack is retained and properly configured.

**Core additions/changes:**

- **Vite 8.x**: Build tool for CSS/JS compilation, minification, multi-entry bundling — fastest build tool available (Oxc minifier), replaces the non-existent build process, maps naturally to WordPress per-page asset loading
- **Lightning CSS** (bundled with Vite): CSS transformation, autoprefixing, minification — eliminates need for separate PostCSS/Autoprefixer/cssnano stack
- **Nginx FastCGI cache**: Full-page caching at the Nginx layer — required because LiteSpeed Cache page caching doesn't work on Nginx (server component required)
- **Nginx gzip compression**: Text compression (60-80% reduction) — universally supported, zero downside for text content
- **PHP-FPM OPcache tuning**: Compiled PHP bytecode caching — single biggest PHP performance win; current defaults (128MB memory, 4000 files) are too low for WordPress + Elementor + ACF + Yoast
- **Redis object cache**: Already in docker-compose, just needs connection via LiteSpeed Cache Object Cache tab — database query and transient caching
- **PHPStan + PHPCS**: Code quality tools already in docker-compose — PHPStan starting at level 1, PHPCS with relaxed WordPress-Core rules

**Critical version/deployment note:** LiteSpeed Cache optimization features work on Nginx; page caching does NOT. Redis object cache via LiteSpeed Cache's UI may work (PHP-level) but needs verification during implementation.

### Expected Features

**Must have (table stakes — 90+ impossible without these):**

- TS-1: Eliminate render-blocking CSS (async CSS + critical CSS via LiteSpeed CCSS)
- TS-2: Defer/async all non-critical JavaScript (with carefully built excludes list)
- TS-3: Image optimization pipeline (WebP + lazy loading + explicit dimensions)
- TS-4: Server-side full-page caching (Nginx FastCGI, not LiteSpeed page cache)
- TS-5: CSS/JS minification and combination (LiteSpeed Page Optimization)
- TS-6: Gzip compression (Nginx config)
- TS-7: Font display optimization (`font-display: swap`, consolidate Google Fonts URLs)
- TS-8: Remove duplicate scripts/stylesheets (audit all enqueue calls, standardize CDN vs local)

**Should have (differentiators — push from 85 to 95+):**

- DIFF-2: Per-page/per-template conditional asset loading (highest-impact optimization for this specific site — don't load Slick/Marketo/Moment on pages that don't use them)
- DIFF-6: Third-party script loading strategy (Marketo/Calendly loaded on interaction, not page load)
- DIFF-7: Preload critical resources (LCP image, critical fonts)
- DIFF-8: Nginx configuration optimization (HTTP/2, static asset caching headers, keepalive)
- DIFF-9: PHP-FPM tuning (OPcache memory, max_children, JIT)

**Defer (Phase 3 / v2+):**

- DIFF-1: Build process (Vite) — significant refactoring, enabler but not required for 90+
- DIFF-3: Replace Moment.js with Day.js — dependency migration
- DIFF-4: Replace Revolution Slider — hero redesign, highest visual regression risk
- DIFF-5: DOM size reduction — Elementor output largely outside our control

### Architecture Approach

The site is a WordPress monolith with parent theme `seoinux` (ZozoThemes) providing base layout/options and child theme `seoinux-child` owning all site-specific behavior. Pages combine PHP templates, Elementor-built layouts, shortcodes with inline HTML/CSS, and custom REST/AJAX handlers. The child theme's `functions.php` uses `require_once` to load module files (`inc/scripts.php`, `inc/post-types.php`, `inc/su-rest-functions.php`, etc.) — no autoloading. Assets are enqueued via `wp_enqueue_script`/`wp_enqueue_style` with the main CSS loading logic in `functions.php` (slug-based `style.css` vs `style-v2.css` switch) and script registration split across `scripts.php`, `post-types.php`, and `min-script.php`.

**Major components:**

1. **Asset loading pipeline** (`functions.php` → `inc/scripts.php` + `inc/post-types.php` + `inc/min-script.php`) — the primary target for optimization; currently loads scripts globally instead of conditionally
2. **Nginx reverse proxy** (`su26.conf`) — currently bare-bones config with no gzip, caching, or performance tuning
3. **LiteSpeed Cache plugin** — installed but underutilized; optimization features (CSS/JS minify, image WebP, lazy load) work on Nginx; page caching does not
4. **PHP-FPM + Redis** (Docker) — default configuration with no OPcache tuning or Redis object cache connection
5. **REST API** (`inc/su-rest-functions.php`, 125KB) — custom `su_rc` namespace with public endpoints; must be excluded from page caching

### Critical Pitfalls

1. **Breaking Elementor-rendered pages during CSS refactoring** — Elementor stores CSS class references in the database; renaming/removing classes silently breaks layouts with no PHP errors. Mitigation: visual regression testing before any CSS change; never rename `elementor-*` classes.
2. **LiteSpeed Cache serving stale content during development** — full-page cache + Nginx cache can mask or double-serve changes. Mitigation: establish cache-purge workflow first; use `?LSCWP_CTRL=NOCACHE` during testing; check `X-LiteSpeed-Cache` headers.
3. **LiteSpeed page caching not working on Nginx** — optimization features work but page caching requires LiteSpeed server. Mitigation: use Nginx FastCGI cache as primary page cache strategy.
4. **Revolution Slider render-blocking inline JS/CSS** — cannot be deferred/async'd (breaks the slider). Mitigation: limit to pages that use it (disable "Include libraries globally"); consider replacing long-term.
5. **Shortcode inline `<style>` blocks bypass CSS optimization** — shortcodes embed CSS that can't be cached separately or minified by LiteSpeed. Mitigation: extract to external CSS files enqueued conditionally.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Infrastructure & Caching Foundation
**Rationale:** Biggest TTFB wins with lowest risk of breaking visual design. No CSS/JS file changes required — only server configuration.
**Delivers:** Nginx gzip, FastCGI page cache, static asset caching headers, PHP-FPM OPcache tuning, Redis object cache connection, LiteSpeed Cache configuration audit
**Addresses:** TS-4 (server caching), TS-6 (gzip), DIFF-8 (Nginx optimization), DIFF-9 (PHP-FPM tuning)
**Avoids:** Pitfall 2 (stale cache) — establishes cache awareness and purge workflow before making content changes
**Estimated impact:** +10-25 PageSpeed points (primarily TTFB-driven metrics)

### Phase 2: Plugin-Level Optimization & Asset Cleanup
**Rationale:** With caching infrastructure in place, optimize what the cache serves — configure LiteSpeed optimization features, clean up duplicate scripts, defer JS, handle images. Still no CSS architecture changes.
**Delivers:** LiteSpeed CSS/JS minify + async CSS + critical CSS, image WebP conversion, lazy loading audit, JS deferral with excludes list, duplicate script removal, font optimization, third-party script strategy (Marketo/Calendly deferred), preload hints for LCP images/fonts
**Addresses:** TS-1 (render-blocking CSS), TS-2 (defer JS), TS-3 (images), TS-5 (minification), TS-7 (fonts), TS-8 (duplicate scripts), DIFF-6 (third-party scripts), DIFF-7 (preload)
**Avoids:** Pitfall 3 (RevSlider) — audit but don't try to defer its inline scripts; Pitfall 5 (CDN scripts) — create script inventory before consolidation
**Estimated impact:** +15-25 PageSpeed points (primarily TBT/CLS/LCP improvements)
**Research flag:** LiteSpeed Cache optimization features on Nginx need verification during implementation — behavior may differ from documented behavior on LiteSpeed server.

### Phase 3: CSS/JS Architecture & Build Pipeline
**Rationale:** Only after Phases 1-2 establish a stable baseline and we know the current score ceiling without structural changes. The build pipeline (Vite) is an enabler for long-term maintainability and the final 5-10 points.
**Delivers:** Vite build pipeline in child theme, CSS split into per-page/template bundles, Moment.js replacement (Day.js), shortcode inline styles extracted to external CSS, slug-based CSS loader replaced with template/meta field detection, per-page conditional asset loading, Revolution Slider scope limitation (or replacement on key pages)
**Addresses:** DIFF-1 (build process), DIFF-2 (per-page assets), DIFF-3 (Moment.js), DIFF-4 (RevSlider), DIFF-5 (DOM size), Pitfalls 4 (shortcode inline styles), 7 (slug-based CSS), 10 (PHP file splitting)
**Avoids:** Pitfall 1 (breaking Elementor pages) — mandatory visual regression testing; Pitfall 8 (Google Fonts bloat) — consolidate font loading
**Estimated impact:** +5-10 PageSpeed points + significant codebase maintainability improvement
**Research flag:** CSS splitting strategy for a 44K-line stylesheet with Elementor dependencies needs careful planning; the exact split points per template should be researched during phase planning.

### Phase Ordering Rationale

- **Infrastructure before optimization:** Nginx FastCGI cache and PHP-FPM tuning must be in place before measuring the impact of CSS/JS changes — otherwise you're measuring against an uncontrolled baseline.
- **Plugin config before code changes:** LiteSpeed's built-in CSS/JS minification, async loading, and image optimization handle 60-80% of PageSpeed audits without touching source files. Only after exhausting plugin-level optimization should we refactor CSS architecture.
- **Build pipeline last:** Vite requires restructuring the entire asset loading pipeline (PHP enqueue paths, file splitting, source maps). It's high-value long-term but carries the highest regression risk and should only be attempted on a stable, well-measured baseline.
- **Feature dependencies respected:** TS-8 (remove duplicates) → TS-2 (defer JS) — you must know which scripts exist before deferring them. TS-4 (caching) → TS-5 (minification) — minified filenames must be cache-busted properly. DIFF-1 (build process) → DIFF-2 (per-page assets) — build process creates the bundles that per-page loading uses.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** LiteSpeed Cache optimization behavior on Nginx (vs LiteSpeed server) needs runtime verification — some features may behave differently than documented.
- **Phase 3:** CSS splitting strategy for 44K lines of CSS with Elementor class dependencies is complex — needs audit of which CSS rules apply to which templates before splitting.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Nginx gzip, FastCGI cache, PHP-FPM OPcache, Redis connection — all well-documented, established patterns with extensive documentation.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Vite, Nginx, PHP-FPM, Redis are mature technologies with extensive documentation. LiteSpeed Cache behavior on Nginx is the one gap. |
| Features | HIGH | Lighthouse scoring weights are well-documented. LiteSpeed Cache feature compatibility verified against official docs. Feature dependencies mapped from codebase analysis. |
| Architecture | MEDIUM | Codebase architecture is well-analyzed but research ARCHITECTURE.md was not produced by the researcher agent. Supplementing from codebase analysis. |
| Pitfalls | HIGH | 10 pitfalls identified and verified against codebase (functions.php, scripts.php, post-types.php). All pitfall scenarios are directly observable in the source code. |

**Overall confidence:** HIGH

### Gaps to Address

- **LiteSpeed Cache Redis object cache on Nginx:** Research could not confirm whether LiteSpeed Cache's Object Cache tab successfully connects to Redis when running on Nginx (vs LiteSpeed server). This should be tested during Phase 1 implementation — if it doesn't work, fall back to a standalone Redis object cache plugin (e.g., Redis Object Cache by Till Krüss).
- **LiteSpeed Cache CCSS/UCSS generation on Nginx:** Critical CSS and Unused CSS Removal features rely on QUIC.cloud service. Need to verify they function correctly without LiteSpeed server during Phase 2.
- **CSS split points:** The exact mapping of which CSS rules belong to which page templates requires a detailed audit of the 44K-line stylesheet during Phase 3 planning. This cannot be fully resolved during research.
- **Revolution Slider usage scope:** Which pages use RevSlider and how complex their animations are determines whether Phase 3 includes replacement or just scoping. This audit should happen during Phase 2.
- **Security plugin overlap:** Multiple security plugins (Defender, Really Simple SSL, SG Security) create performance overhead and potential conflicts. Audit which features each provides during Phase 2 and consolidate to one.

## Sources

### Primary (HIGH confidence)
- Context7 `/vitejs/vite` — Vite build configuration, Lightning CSS integration, multi-entry builds
- Context7 `/websites/litespeedtech` — LiteSpeed Cache WordPress plugin capabilities, Nginx compatibility limitations
- Context7 `/websites/nginx` — Nginx gzip, FastCGI cache, static file serving configuration
- Context7 `/phpstan/phpstan` — PHPStan configuration, rule levels, neon config format
- Context7 `/phpcsstandards/php_codesniffer` — PHPCS ruleset configuration, WordPress coding standards
- Official LiteSpeed docs (docs.litespeedtech.com/lscache/lscwp/) — Page caching requires LiteSpeed server; optimization features work on any server
- Lighthouse Performance Scoring (developer.chrome.com/docs/lighthouse) — Metric weights: TBT 30%, LCP 25%, CLS 25%, FCP 10%, SI 10%
- WordPress Developer Docs — `wp_enqueue_script` strategy parameter (6.3+), `wp_localize_script`

### Secondary (MEDIUM confidence)
- Context7 `/websites/wp-rocket_me` — WP Rocket best practices (used for comparison, confirmed LiteSpeed Cache covers equivalent features)
- Context7 `/kasparsd/wp-docs-md` — WordPress asset enqueueing best practices
- Elementor developer docs — Widget output caching, DOM optimization settings
- Codebase analysis — `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONCERNS.md`

### Tertiary (LOW confidence / needs validation)
- LiteSpeed Cache Redis object cache on Nginx — documented as PHP-level feature but not runtime-verified
- LiteSpeed Cache CCSS/UCSS via QUIC.cloud on Nginx — service-level feature, may require specific server configuration
- PHP 8.x JIT performance impact on WordPress — theoretical benefit, environment-specific

---
*Research completed: 2026-05-04*
*Ready for roadmap: yes*
