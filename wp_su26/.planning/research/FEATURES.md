# Feature Research: WordPress Performance Optimization for 90+ PageSpeed

**Domain:** WordPress corporate marketing site performance optimization (SearchUnify)
**Researched:** 2026-05-04
**Confidence:** HIGH

## Context

This research addresses the specific question: *What performance optimization features/techniques are table stakes for WordPress sites targeting 90+ PageSpeed? What differentiates good from great? What should we deliberately NOT do?*

**Site profile:** B2B enterprise AI platform marketing site. WordPress 6.9.4 with Seoinux parent/child theme, Elementor + Classic Elementor Addons Pro, Revolution Slider, ACF Pro, Yoast SEO, LiteSpeed Cache, Marketo/Calendly integrations, custom REST API, AJAX filtering, ~19K-line stylesheet, no build process.

**Lighthouse 10 scoring weights** (current as of research date):
| Metric | Weight |
|--------|--------|
| Largest Contentful Paint (LCP) | 25% |
| Total Blocking Time (TBT) | 30% |
| Cumulative Layout Shift (CLS) | 25% |
| First Contentful Paint (FCP) | 10% |
| Speed Index (SI) | 10% |

TBT + LCP + CLS = 80% of score. These three metrics are where effort must concentrate.

---

## Table Stakes (Must Have — Missing These = 90+ Is Impossible)

Features that PageSpeed Insights will flag as failures. Every optimized WordPress site has these.

### TS-1: Eliminate Render-Blocking CSS

| Attribute | Detail |
|-----------|--------|
| **Why Expected** | PageSpeed explicitly audits "Eliminate render-blocking resources." A 19K-line CSS file blocking first paint is an automatic score killer. |
| **Complexity** | HIGH |
| **Lighthouse Impact** | FCP (10%), LCP (25%) — directly blocks both |

**Implementation approach:**
- Generate Critical CSS (above-the-fold) for key page templates — LiteSpeed Cache has built-in CCSS generation (`wp-content/litespeed/ccss/`).
- Load remaining CSS asynchronously with `media="print" onload="this.media='all'"` pattern or via LiteSpeed's "Load CSS Asynchronously" option.
- This site has multiple CSS files (style.css, style-v2.css, style-mobile.css, style21.css, style.13.css, style-bkk.css) — all must be handled by the async strategy.
- LiteSpeed Cache can generate per-post-type CCSS (set post types `page`, `post` in CCSS settings).

**Confidence:** HIGH — well-established technique, LiteSpeed has native support.

---

### TS-2: Defer / Async All Non-Critical JavaScript

| Attribute | Detail |
|-----------|--------|
| **Why Expected** | Render-blocking JS tanks TBT (30% of score). This site loads jQuery, Slick, Marketo Forms 2, Moment.js, Bootstrap, Lottie, sticky sidebar, and more — all potentially render-blocking. |
| **Complexity** | MEDIUM |
| **Lighthouse Impact** | TBT (30%), FCP (10%), SI (10%) |

**Implementation approach:**
- WordPress 6.3+ supports `'strategy' => 'defer'` and `'strategy' => 'async'` in `wp_enqueue_script()` `$args` parameter. Use this for all theme scripts.
- Third-party scripts (Marketo, Calendly, Lottie) should use `async` or be loaded on interaction.
- LiteSpeed Cache "Load JS Deferred" option handles bulk deferral; use JS Excludes list for scripts that break when deferred.
- **Critical for this site:** The duplicate JS files (minified/unminified pairs) must be resolved first — only minified versions should be enqueued.

**Confidence:** HIGH — WordPress native API + LiteSpeed built-in feature.

---

### TS-3: Image Optimization Pipeline (WebP + Lazy Loading + Dimensions)

| Attribute | Detail |
|-----------|--------|
| **Why Expected** | PageSpeed audits "Properly size images," "Efficiently encode images," "Offscreen images." Missing any = score penalty. |
| **Complexity** | MEDIUM |
| **Lighthouse Impact** | LCP (25%), CLS (25%), FCP (10%) |

**Implementation approach:**
- **WebP conversion:** LiteSpeed Cache has built-in WebP conversion (requires ImageMagick or GD with WebP support in Docker). Enable "Optimize" and "WebP" in LiteSpeed > Media.
- **Lazy loading:** WordPress core has native lazy loading (`loading="lazy"`) since 5.5. Verify all `<img>` tags without explicit `width`/`height` are fixed (prevents CLS). LiteSpeed lazy load handles background images and iframes too.
- **Explicit dimensions:** Every `<img>` must have `width` and `height` attributes. This is a CLS requirement. Audit shortcodes (especially `top-bar-shortcode.php`) for images missing dimensions.
- **Hero/LCP images:** Must NOT be lazy-loaded. Add `data-no-lazy="1"` or `loading="eager"` for above-the-fold images. LiteSpeed allows excluding specific images from lazy load.
- **Responsive images:** Use `srcset` and `sizes` attributes. WordPress generates these automatically for media library images, but shortcode/inline images (top-bar banners) may not have them.

**Confidence:** HIGH — well-documented, LiteSpeed has native support.

---

### TS-4: Server-Side Caching (Full Page Cache)

| Attribute | Detail |
|-----------|--------|
| **Why Expected** | Without full page caching, every request hits PHP. TTFB > 600ms = automatic LCP penalty. This is the single biggest TTFB lever. |
| **Complexity** | MEDIUM |
| **Lighthouse Impact** | LCP (25%), FCP (10%), SI (10%) — all TTFB-dependent |

**Implementation approach:**
- LiteSpeed Cache provides full-page caching. Enable it with:
  - Cache logged-in users: OFF (or separate cache)
  - Cache REST API: Configure exclusions for `su_rc` routes if they return dynamic data
  - Cache AJAX: Exclude `admin-ajax.php` for event filtering
- **Nginx-level caching** as a second layer (wordpress-matrix uses Nginx as reverse proxy). Configure `proxy_cache` directives for static assets and cached pages.
- **Browser caching:** Set long `Cache-Control` max-age for static assets (CSS, JS, images). Nginx `expires` directives.
- **Object cache:** Redis is available in the wordpress-matrix stack. Configure WordPress object caching for database query results.

**Confidence:** HIGH — standard WordPress infrastructure optimization.

---

### TS-5: CSS/JS Minification and Combination

| Attribute | Detail |
|-----------|--------|
| **Why Expected** | PageSpeed audits "Minify CSS," "Minify JavaScript," "Remove unused CSS," "Remove unused JavaScript." Unminified assets = direct audit failure. |
| **Complexity** | LOW (LiteSpeed handles it) / HIGH (manual cleanup of the 19K-line stylesheet) |
| **Lighthouse Impact** | FCP (10%), LCP (25%), TBT (30%) — fewer/smaller resources = faster everything |

**Implementation approach:**
- **LiteSpeed Cache minification:** Enable CSS Minify and JS Minify in Page Optimization settings. LiteSpeed handles combination and minification server-side.
- **CSS combination:** Enable with caution — the 19K-line stylesheet + style-v2.css conditional logic may break if naively combined. Test thoroughly per template.
- **JS combination:** Same caution — jQuery-dependent scripts have load-order requirements. Use LiteSpeed's JS Excludes for scripts that must not be combined.
- **Manual cleanup:** The 19K-line stylesheet needs dead code removal. This is separate from minification — it's about removing unused rules. LiteSpeed's "Remove Unused CSS" (UCSS) feature can help but is generation-based and may miss dynamic classes.

**Confidence:** HIGH for LiteSpeed features; MEDIUM for the manual stylesheet cleanup (requires careful audit).

---

### TS-6: Gzip/Brotli Compression

| Attribute | Detail |
|-----------|--------|
| **Why Expected** | PageSpeed audits "Enable text compression." Without it, all text resources are 3-5x larger than necessary. |
| **Complexity** | LOW |
| **Lighthouse Impact** | All metrics — affects transfer size of everything |

**Implementation approach:**
- Enable in Nginx: `gzip on; gzip_types text/css application/javascript ...` in the site's Nginx config.
- Brotli preferred if Nginx has `ngx_brotli` module — better compression ratios.
- LiteSpeed Cache also offers Gzip compression at the application level.

**Confidence:** HIGH — single config change, well-documented.

---

### TS-7: Font Display Optimization

| Attribute | Detail |
|-----------|--------|
| **Why Expected** | PageSpeed audits "Ensure text remains visible during webfont load." Custom fonts without `font-display: swap` cause invisible text during load (FOIT). |
| **Complexity** | LOW |
| **Lighthouse Impact** | FCP (10%), LCP (25%) — fonts block text rendering |

**Implementation approach:**
- Add `font-display: swap` to all `@font-face` declarations in child theme CSS.
- If using Google Fonts (likely via Elementor or theme), preconnect: `<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>`.
- LiteSpeed Cache can add `font-display: swap` automatically — enable in Page Optimization > CSS settings.
- Audit for icon fonts (Font Awesome from Classic Elementor Addons Pro) — these should also use `font-display: swap` or be replaced with SVG icons where possible.

**Confidence:** HIGH — straightforward CSS/setting change.

---

### TS-8: Remove Duplicate Scripts and Stylesheets

| Attribute | Detail |
|-----------|--------|
| **Why Expected** | This site has known duplicate JS files (minified/unminified pairs) and inconsistent CDN loading (same library from CDN and local). PageSpeed flags duplicated JavaScript. |
| **Complexity** | MEDIUM |
| **Lighthouse Impact** | TBT (30%), all transfer size metrics |

**Implementation approach:**
- Audit all `wp_enqueue_script` calls in `post-types.php`, `scripts.php`, `min-script.php`, and `minimal-asset-bundles.php`.
- For each library (Slick, Moment, Bootstrap, Lottie, jQuery), pick ONE source: local OR CDN. Never both.
- Remove unminified versions from enqueue; keep only `.min.js` / `.min.css`.
- Deregister scripts that are already loaded by plugins (e.g., don't re-enqueue jQuery if WordPress core already does it).

**Confidence:** HIGH — direct audit of enqueue calls.

---

## Differentiators (Moves Score from 85 → 95+)

Features that separate "good" from "great" performance. These are where the last 10 points come from.

### DIFF-1: Build Process for Theme Assets

| Attribute | Detail |
|-----------|--------|
| **Value Proposition** | Enables tree-shaking, dead code elimination, source maps, and automated minification — things manual optimization can't do. Turns the 19K-line stylesheet into only what each page needs. |
| **Complexity** | HIGH |
| **ROI** | Enabler for DIFF-2, DIFF-3, DIFF-4 |

**Implementation approach:**
- Add a `package.json` and build tool (Vite or Webpack) to the child theme.
- Split the monolithic `style.css` into component-based files: `base/`, `layouts/`, `components/`, `pages/`.
- Build process outputs page-specific CSS bundles (e.g., `home.css`, `resource-center.css`, `product-page.css`).
- Integrate with WordPress: use `wp_enqueue_style` with build output, `filemtime()` for cache busting.
- This replaces the current `style.css` vs `style-v2.css` conditional logic with a proper per-page asset strategy.

**Confidence:** MEDIUM — significant refactoring effort, but standard practice in modern WordPress theme development.

---

### DIFF-2: Per-Page / Per-Template Conditional Asset Loading

| Attribute | Detail |
|-----------|--------|
| **Value Proposition** | Don't load Slick carousel CSS/JS on pages without carousels. Don't load Marketo JS on pages without forms. Don't load Moment.js/date-range-picker on pages without event filters. Eliminates 60-80% of unused CSS/JS. |
| **Complexity** | MEDIUM |
| **ROI** | Massive TBT improvement (30% of score) |

**Implementation approach:**
- In `post-types.php` and `scripts.php`, wrap each `wp_enqueue_script`/`wp_enqueue_style` in conditional checks:
  - Slick: Only on pages with `.slick` carousels (product pages, recognition sliders)
  - Moment.js + bootstrap-daterangepicker: Only on events/archive pages
  - Marketo Forms 2: Only on pages with demo/contact forms
  - Lottie: Only on pages with Lottie animations
  - Sticky sidebar: Only on blog/resource pages
- Use WordPress conditional tags: `is_page()`, `is_singular('event')`, `is_page_template('template-su-*.php')`, or check for shortcode/pattern presence.
- Replace the hardcoded slug-based `style-v2.css` switcher in `functions.php` with template-based conditionals.

**Confidence:** HIGH — this is the single highest-impact optimization for this specific site.

---

### DIFF-3: Replace Moment.js with Native Date APIs

| Attribute | Detail |
|-----------|--------|
| **Value Proposition** | Moment.js is ~300KB uncompressed (72KB gzipped). For event date formatting, `Intl.DateTimeFormat` and native `Date` APIs are sufficient. Removing Moment eliminates a massive JS payload. |
| **Complexity** | LOW-MEDIUM |
| **ROI** | Direct TBT reduction — one of the heaviest scripts on the site |

**Implementation approach:**
- Audit `bootstrap-daterangepicker` usage — if it's the only Moment dependency, consider a lighter alternative like `litepie-datepicker` or flatpickr.
- If Moment is used elsewhere in the theme, replace with `dayjs` (2KB) or native `Intl.DateTimeFormat`.
- Moment.js is officially in maintenance mode per its own docs — migrating away is the recommended path.

**Confidence:** HIGH — Moment.js deprecation is well-documented.

---

### DIFF-4: Replace Revolution Slider with CSS/Lite Alternatives

| Attribute | Detail |
|-----------|--------|
| **Value Proposition** | RevSlider is one of the heaviest WordPress plugins — it loads its own jQuery, processes slides server-side, and generates heavy inline CSS/JS. A CSS-only hero or lightweight carousel eliminates 200-400KB of payload. |
| **Complexity** | MEDIUM-HIGH (depends on hero complexity) |
| **ROI** | Potentially the single biggest payload reduction |

**Implementation approach:**
- Audit which pages use RevSlider heroes.
- For simple hero banners (image + text + CTA), replace with ACF fields + CSS flexbox/grid hero section.
- For animated heroes, consider Swiper.js (40KB) or pure CSS animations.
- If RevSlider cannot be removed from some pages, at minimum: disable it on pages that don't use it (RevSlider has a "Include libraries globally" option — turn it OFF).
- **Risk:** Visual regression if hero animations are complex. Test on staging first.

**Confidence:** MEDIUM — depends on how heavily RevSlider features are used in hero designs.

---

### DIFF-5: Reduce DOM Size

| Attribute | Detail |
|-----------|--------|
| **Value Proposition** | PageSpeed audits DOM size; Elementor is notorious for generating deep DOM trees (div > div > div > div). A DOM > 1500 nodes gets flagged. Large DOM increases TBT and CLS calculation time. |
| **Complexity** | MEDIUM |
| **ROI** | TBT improvement + CLS improvement |

**Implementation approach:**
- Enable Elementor's "DOM Optimization" setting (Elementor > Settings > Features > Improved Asset Loading).
- Enable Elementor's "Optimize DOM Output" if available in current version.
- Audit key pages for Elementor widget nesting depth — reduce unnecessary wrapper sections.
- In custom shortcodes (`top-bar-shortcode.php`), remove unnecessary wrapper divs.
- For the top-bar banner specifically: move from shortcode with inline HTML to a proper template part with cleaner markup.

**Confidence:** MEDIUM — Elementor DOM is partly outside our control, but settings can help significantly.

---

### DIFF-6: Third-Party Script Loading Strategy (Marketo, Calendly, Analytics)

| Attribute | Detail |
|-----------|--------|
| **Value Proposition** | Marketo Forms 2 and Calendly widgets are heavy third-party scripts that execute synchronously and can add 500ms+ to TBT. Loading them on interaction (e.g., after user scrolls to form) or via `facade` pattern dramatically reduces TBT. |
| **Complexity** | MEDIUM |
| **ROI** | High — these are the biggest TBT contributors on form pages |

**Implementation approach:**
- **Marketo Forms 2:** Don't load on page load. Load on interaction — when user scrolls near the form section, or on button click (for popup forms). Pattern: `<div class="marketo-facade" data-form-id="123">` that loads the script only when visible.
- **Calendly:** Use Calendly's inline embed only on pages that need it. For other pages, use a clickable link that opens Calendly in a new tab, or load on interaction.
- **Google Analytics / GTM:** Use `async` attribute. Consider `gtag('consent', ...)` delayed loading if consent management is in play.
- LiteSpeed Cache "Delay JS" feature can automate this — configure to delay third-party scripts until user interaction.

**Confidence:** HIGH — established pattern, LiteSpeed has native delay feature.

---

### DIFF-7: Preload Critical Resources

| Attribute | Detail |
|-----------|--------|
| **Value Proposition** | `<link rel="preload">` for LCP image, critical fonts, and key CSS files lets the browser fetch them before they're discovered in the HTML. Can shave 200-500ms off LCP. |
| **Complexity** | LOW |
| **ROI** | Moderate — easy win for LCP optimization |

**Implementation approach:**
- Identify LCP element per page type (hero image for home, featured image for blog posts).
- Add `<link rel="preload" as="image" href="...">` for LCP images in `wp_head`.
- Add `<link rel="preload" as="font" href="..." crossorigin>` for custom fonts used in above-the-fold text.
- Add `<link rel="preconnect" href="https://cdn.jsdelivr.net">` for CDN-hosted resources.
- Implement via `add_action('wp_head', ...)` with priority 1 in child theme.

**Confidence:** HIGH — simple HTML additions with proven impact.

---

### DIFF-8: Nginx Configuration Optimization

| Attribute | Detail |
|-----------|--------|
| **Value Proposition** | The wordpress-matrix uses Nginx as reverse proxy. Properly tuned Nginx config (keepalive, static asset caching, HTTP/2, worker tuning) provides infrastructure-level speedup that no WordPress plugin can match. |
| **Complexity** | MEDIUM |
| **ROI** | TTFB improvement, better connection reuse |

**Implementation approach:**
- **Enable HTTP/2** in Nginx config if not already — multiplexing eliminates head-of-line blocking.
- **Static asset caching:** `location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff2)$ { expires 1y; add_header Cache-Control "public, immutable"; }`
- **Keepalive connections:** `keepalive_timeout 65;` for connection reuse.
- **Brotli/Gzip** for text compression.
- **Client body/request buffering:** Tune `client_body_buffer_size`, `client_max_body_size`.
- **FastCGI caching** for PHP-FPM responses as alternative/enhancement to LiteSpeed page cache.

**Confidence:** HIGH — standard Nginx optimization, wordpress-matrix provides the config structure.

---

### DIFF-9: PHP-FPM Tuning

| Attribute | Detail |
|-----------|--------|
| **Value Proposition** | PHP-FPM worker configuration directly impacts TTFB for uncached requests. Too few workers = queue delays; too many = memory pressure. OPcache configuration reduces PHP compilation overhead. |
| **Complexity** | MEDIUM |
| **ROI** | Moderate — primarily benefits uncached/admin traffic, but also cache misses |

**Implementation approach:**
- **OPcache:** Ensure `opcache.enable=1`, `opcache.memory_consumption=256`, `opcache.interned_strings_buffer=16`, `opcache.max_accelerated_files=10000`.
- **PHP-FPM pool:** Tune `pm.max_children` based on container memory, `pm.start_servers`, `pm.min/max_spare_servers`.
- **PHP 8.x JIT:** Consider enabling JIT (`opcache.jit=tracing`) for PHP 8.0+ containers.
- wordpress-matrix allows PHP version selection — ensure PHP 8.2+ for best performance.

**Confidence:** MEDIUM — Docker PHP-FPM tuning is well-documented but environment-specific.

---

## Anti-Features (Commonly Attempted, Often Problematic)

Things that seem like good performance optimizations but will break WordPress, Elementor, or this specific site. **Deliberately do NOT do these.**

### ANTI-1: Aggressive CSS Combination Without Testing

| Attribute | Detail |
|-----------|--------|
| **Why Attempted** | "Combine all CSS into one file" seems like an obvious win — fewer HTTP requests. |
| **Why Problematic** | This site has conditional CSS loading by post slug (style.css vs style-v2.css) for a reason — the stylesheets contain conflicting rules for different page designs. Naively combining them will cause specificity conflicts, broken layouts, and visual regressions that are extremely hard to debug. Additionally, Elementor generates per-page CSS that may conflict with theme CSS. |
| **Alternative** | Use LiteSpeed Cache's UCSS (Unused CSS Removal) feature which generates per-URL optimized CSS. Let the tool figure out what's needed per page. Or use a build process (DIFF-1) to create page-specific bundles. |

---

### ANTI-2: Removing jQuery Entirely

| Attribute | Detail |
|-----------|--------|
| **Why Attempted** | jQuery is ~87KB and feels like dead weight. "Remove jQuery" is common performance advice. |
| **Why Problematic** | This site's JavaScript (Slick, Marketo, Bootstrap, sticky sidebar, AJAX filtering) all depend on jQuery. WordPress core admin also requires jQuery. Removing it breaks every interactive feature on the site. The Classic Elementor Addons Pro plugin also depends on jQuery. |
| **Alternative** | Don't remove jQuery — defer it. Load jQuery in footer with `strategy => 'defer'`. The TBT impact of jQuery is primarily when it's render-blocking, not when it's deferred. For the front-end, if Slick can be replaced with a vanilla JS carousel (e.g., Swiper, Embla), that removes a jQuery dependency for that component specifically. |

---

### ANTI-3: Deferring All JavaScript Unconditionally

| Attribute | Detail |
|-----------|--------|
| **Why Attempted** | LiteSpeed Cache has "Load JS Deferred" — enable it globally and done, right? |
| **Why Problematic** | Many WordPress plugins (Elementor, RevSlider, Marketo) have JavaScript that expects certain DOM elements or other scripts to be available at execution time. Globally deferring JS breaks: Elementor frontend init, Slick carousel initialization (depends on jQuery being ready), Marketo form rendering, AJAX event filtering nonce initialization. Debugging deferred-JS breakage is painful because symptoms appear only on specific pages or interactions. |
| **Alternative** | Enable "Load JS Deferred" in LiteSpeed, but build a careful JS Excludes list. Test EVERY page template after enabling. Exclude: Elementor frontend scripts, scripts that use `document.write()`, scripts with inline initialization that depends on external libraries. Enable one script at a time and test. |

---

### ANTI-4: Using Multiple Caching/Optimization Plugins Simultaneously

| Attribute | Detail |
|-----------|--------|
| **Why Attempted** | "LiteSpeed Cache for page cache, Autoptimize for CSS/JS, WP Rocket for lazy loading..." Each plugin has strengths, so use them all, right? |
| **Why Problematic** | LiteSpeed Cache documentation explicitly warns: overlapping optimization functions cause conflicts. Double-minification corrupts CSS/JS. Double-caching serves stale content. Conflicting lazy loaders break image display. This site already has potential plugin overlap (multiple security plugins noted in STACK.md). |
| **Alternative** | Use LiteSpeed Cache as the single optimization plugin. It handles: full page cache, CSS/JS minification + combination, critical CSS generation, WebP conversion, lazy loading, CDN integration, database optimization. Disable any overlapping features in other plugins. |

---

### ANTI-5: Inlining the Entire Stylesheet

| Attribute | Detail |
|-----------|--------|
| **Why Attempted** | "Inline CSS to eliminate render-blocking stylesheet." Common advice for small sites. |
| **Why Problematic** | This site's stylesheet is ~19,000 lines. Inlining it would add 400-600KB of CSS to every HTML response, destroying cache efficiency and inflating TTFB. The HTML response would be larger than the separate CSS file. |
| **Alternative** | Generate critical CSS (above-the-fold only, typically 5-20KB) and inline ONLY that. Load the rest asynchronously. LiteSpeed Cache's CCSS feature handles this automatically. |

---

### ANTI-6: Disabling Plugins via Deactivation Instead of Conditional Loading

| Attribute | Detail |
|-----------|--------|
| **Why Attempted** | "Just disable RevSlider/Elementor on pages that don't use it." |
| **Why Problematic** | WordPress plugin deactivation removes the plugin entirely — it stops loading for ALL pages, including ones that need it. You can't conditionally deactivate plugins per-page. And Elementor-built pages literally break without Elementor active. |
| **Alternative** | Use per-page conditional asset loading (DIFF-2). RevSlider specifically has a "Include libraries globally" setting — turn this OFF so it only loads on pages with sliders. For Elementor, enable "Improved Asset Loading" in settings to only load Elementor assets on Elementor-built pages. |

---

### ANTI-7: Modifying Parent Theme Files

| Attribute | Detail |
|-----------|--------|
| **Why Attempted** | "The parent theme enqueues scripts inefficiently — let's fix it directly in `seoinux/functions.php`." |
| **Why Problematic** | Parent theme modifications are lost on update. The PROJECT.md explicitly constrains: "Parent theme modifications — changes stay in child theme or config." WordPress provides hooks specifically to override parent behavior from the child theme. |
| **Alternative** | Use `wp_dequeue_script()`, `wp_deregister_script()`, `wp_dequeue_style()` in the child theme's `functions.php` to remove unwanted parent assets. Use `remove_action()` / `remove_filter()` to unhook parent behaviors. All overrides stay in the child theme. |

---

### ANTI-8: Image Optimization via JavaScript-Based Lazy Loaders

| Attribute | Detail |
|-----------|--------|
| **Why Attempted** | "Let's use a JavaScript lazy load library for fancy fade-in effects." |
| **Why Problematic** | Native `loading="lazy"` is supported by all modern browsers and adds zero JavaScript overhead. JS-based lazy loaders (Lozad, LazySizes) add their own script payload and can cause hydration issues with cached pages. LiteSpeed Cache also has its own lazy loading — running two lazy loaders causes conflicts. |
| **Alternative** | Use native `loading="lazy"` for all below-fold images. Use LiteSpeed's lazy loading for background images and iframes (which native doesn't handle). If fade-in effects are needed, use the LiteSpeed-provided CSS transitions (`img.litespeed-loaded` class) documented in their docs. |

---

## Feature Dependencies

```
TS-4 (Server Caching)
    └── prerequisite for ──> TS-5 (Minification — must test with cache cleared)

TS-1 (Render-Blocking CSS)
    └── prerequisite for ──> DIFF-1 (Build Process — build process generates critical CSS)

DIFF-1 (Build Process)
    └── enables ──> DIFF-2 (Per-Page Asset Loading)
    └── enables ──> DIFF-5 (DOM Size Reduction via cleaner markup)

TS-8 (Remove Duplicate Scripts)
    └── prerequisite for ──> TS-2 (Defer JS — must know which scripts to keep first)

TS-3 (Image Optimization)
    └── prerequisite for ──> DIFF-7 (Preload LCP Image — need to identify LCP images first)

DIFF-6 (Third-Party Script Strategy)
    └── conflicts with ──> ANTI-3 (Unconditional JS Deferral — must use targeted approach)

DIFF-4 (Replace RevSlider)
    └── enables ──> DIFF-5 (DOM Size Reduction — removes RevSlider's heavy DOM)

TS-5 (Minification)
    └── conflicts with ──> ANTI-1 (Aggressive CSS Combination — use per-page approach)

DIFF-8 (Nginx Config)
    └── enables ──> TS-6 (Gzip/Brotli — configured at Nginx level)
```

### Dependency Notes

- **TS-8 → TS-2:** Duplicate scripts must be identified and removed before deferral can work correctly. If both `slick.js` and `slick.min.js` are deferred, Slick initializes twice.
- **TS-4 → TS-5:** Minification changes must be tested with cache fully purged. Cached pages with old asset URLs will break if minified filenames change without cache bust.
- **DIFF-1 → DIFF-2:** The build process creates the foundation for per-page bundles. Without it, per-page loading requires manual file splitting of the 19K-line stylesheet.
- **DIFF-6 conflicts with ANTI-3:** Third-party script optimization requires targeted loading strategies, not a blanket "defer everything" approach.
- **DIFF-4 → DIFF-5:** RevSlider removal simultaneously reduces DOM depth (RevSlider adds 50-100+ wrapper divs per slider).

---

## MVP Definition (Phase 1 — Target 85+ Score)

Minimum changes to get the biggest score improvement. These can be done without a build process.

### Launch With (Phase 1)

- [ ] **TS-6: Gzip/Brotli** — Enable in Nginx config. Immediate, low-risk, universal benefit.
- [ ] **TS-4: Server-Side Caching** — Configure LiteSpeed Cache page cache + Redis object cache + Nginx static asset caching.
- [ ] **TS-8: Remove Duplicate Scripts** — Audit and fix all duplicate/overlapping enqueue calls.
- [ ] **TS-3: Image Optimization** — Enable LiteSpeed WebP conversion, verify lazy loading, add missing `width`/`height` attributes.
- [ ] **TS-2: Defer Non-Critical JS** — Enable LiteSpeed "Load JS Deferred" with carefully built excludes list. Test every template.
- [ ] **TS-1: Render-Blocking CSS** — Enable LiteSpeed async CSS + critical CSS generation.
- [ ] **TS-7: Font Display** — Add `font-display: swap` to all font-face declarations.
- [ ] **DIFF-7: Preload Critical Resources** — Add preload/preconnect for LCP images and fonts.
- [ ] **DIFF-8: Nginx Optimization** — HTTP/2, static asset caching headers, keepalive tuning.

### Add After Validation (Phase 2 — Target 90+)

- [ ] **DIFF-2: Per-Page Conditional Asset Loading** — After Phase 1 establishes baseline, conditionally load Slick, Moment, Marketo, Lottie only where needed.
- [ ] **DIFF-6: Third-Party Script Strategy** — Implement interaction-based loading for Marketo and Calendly.
- [ ] **DIFF-3: Replace Moment.js** — Migrate event date handling to native APIs or dayjs.
- [ ] **DIFF-5: DOM Size Reduction** — Enable Elementor DOM optimization, clean shortcode markup.

### Future Consideration (Phase 3 — Target 95+)

- [ ] **DIFF-1: Build Process** — Significant refactoring to add Vite/Webpack build pipeline.
- [ ] **DIFF-4: Replace RevSlider** — Redesign hero sections with lighter alternatives.
- [ ] **DIFF-9: PHP-FPM Tuning** — OPcache and JIT optimization after infrastructure is stable.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Target Score Impact |
|---------|------------|---------------------|----------|---------------------|
| TS-6: Gzip/Brotli | HIGH | LOW | P1 | +5-10 points |
| TS-4: Server Caching | HIGH | MEDIUM | P1 | +10-20 points |
| TS-8: Remove Duplicate Scripts | MEDIUM | MEDIUM | P1 | +3-5 points |
| TS-3: Image Optimization | HIGH | MEDIUM | P1 | +5-15 points |
| TS-2: Defer Non-Critical JS | HIGH | MEDIUM | P1 | +10-20 points |
| TS-1: Render-Blocking CSS | HIGH | HIGH | P1 | +10-15 points |
| TS-5: CSS/JS Minification | MEDIUM | LOW | P1 | +3-8 points |
| TS-7: Font Display | MEDIUM | LOW | P1 | +2-5 points |
| DIFF-7: Preload Critical | MEDIUM | LOW | P1 | +3-5 points |
| DIFF-8: Nginx Optimization | HIGH | MEDIUM | P1 | +5-10 points |
| DIFF-2: Per-Page Assets | HIGH | MEDIUM | P2 | +5-15 points |
| DIFF-6: Third-Party Scripts | HIGH | MEDIUM | P2 | +5-10 points |
| DIFF-3: Replace Moment.js | MEDIUM | LOW | P2 | +3-5 points |
| DIFF-5: DOM Size Reduction | MEDIUM | MEDIUM | P2 | +2-5 points |
| DIFF-1: Build Process | HIGH | HIGH | P3 | +5-10 points (enabler) |
| DIFF-4: Replace RevSlider | HIGH | HIGH | P3 | +5-15 points |
| DIFF-9: PHP-FPM Tuning | LOW-MEDIUM | MEDIUM | P3 | +2-5 points |

**Priority key:**
- P1: Phase 1 — infrastructure and plugin configuration changes (no build process needed)
- P2: Phase 2 — requires code changes and template-level optimization
- P3: Phase 3 — significant refactoring or architecture changes

---

## Site-Specific Risk Assessment

| Optimization | Risk Level | Specific Risk for SearchUnify | Mitigation |
|-------------|-----------|------------------------------|------------|
| CSS Async Loading | HIGH | style-v2.css conditional loading by post slug may have specificity conflicts with style.css | Test every template individually; use LiteSpeed UCSS per-URL |
| JS Deferral | HIGH | Slick init depends on jQuery; Marketo form rendering depends on DOM state | Build excludes list carefully; test form pages and carousel pages |
| RevSlider Removal | MEDIUM | Hero banners may use complex animations that CSS can't replicate | Audit each slider's features before deciding on replacement |
| Per-Page Assets | MEDIUM | `post-types.php` mixes CPT registration with enqueue logic — changes here affect all CPTs | Split enqueue logic into separate file first (per CONCERNS.md) |
| Moment.js Removal | LOW | bootstrap-daterangepicker may have hard Moment dependency | Test with dayjs + dateRangePicker plugin first |
| Image Optimization | LOW | Shortcode images (top-bar) may not have attachment IDs for WebP | Handle shortcode images separately; manual WebP + srcset |

---

## Sources

- **Lighthouse Performance Scoring:** https://developer.chrome.com/docs/lighthouse/performance/performance-scoring — Metric weights (LCP 25%, TBT 30%, CLS 25%, FCP 10%, SI 10%)
- **WordPress Script Loading Strategies:** https://developer.wordpress.org/reference/functions/wp_enqueue_script — `'strategy' => 'defer'` / `'async'` in wp_enqueue_script $args (WordPress 6.3+)
- **LiteSpeed Cache Documentation:** https://docs.litespeedtech.com/lscache/lscwp/ — CCSS generation, lazy loading, CSS/JS optimization, CDN configuration, multi-plugin compatibility
- **Elementor Developer Docs:** https://github.com/elementor/elementor-developers-docs — Widget output caching (`is_dynamic_content`), DOM optimization (`has_widget_inner_wrapper`)
- **WordPress Responsive Images:** https://developer.wordpress.org/reference/functions/wp_image_add_srcset_and_sizes/ — srcset/sizes attribute generation
- **Project-specific sources:** `.planning/PROJECT.md`, `.planning/codebase/CONCERNS.md`, `.planning/codebase/STACK.md`, `.planning/codebase/ARCHITECTURE.md`

---
*Feature research for: WordPress performance optimization (SearchUnify marketing site)*
*Researched: 2026-05-04*
