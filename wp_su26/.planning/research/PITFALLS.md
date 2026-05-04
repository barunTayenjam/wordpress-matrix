# Pitfalls Research

**Domain:** WordPress performance optimization for a live Elementor-based corporate marketing site (SearchUnify)
**Researched:** 2026-05-04
**Confidence:** HIGH (codebase-verified + documentation-backed)

---

## Critical Pitfalls

### Pitfall 1: Breaking Elementor-Rendered Pages During CSS Refactoring

**What goes wrong:**
Elementor stores inline CSS classes and custom positioning data in the database (`wp_postmeta`). When you refactor or rename CSS classes in `style.css` (19K lines) or `style-v2.css` (25K lines), Elementor pages silently break because their stored data references the old class names. The breakage is visual-only — no PHP errors — making it invisible in logs. You only discover it when a human visits the page and sees misaligned sections, broken layouts, or missing styles.

**Why it happens:**
Elementor generates per-element inline styles and references theme CSS classes. Developers treat the CSS like a normal stylesheet and rename classes, merge selectors, or remove "unused" rules — but Elementor has already baked those class names into its stored widget data. The `style.css` ↔ `style-v2.css` split (controlled by a hardcoded post-slug `if` chain in `functions.php` line 22) means refactoring one file can break pages using the other.

**How to avoid:**
1. **Before any CSS change:** Take visual screenshots of every affected page (use a tool like Percy, Responsively, or manual browser screenshots of key URLs).
2. **Identify which pages use which stylesheet:** Extract the slug list from `seoinux_enqueue_child_theme_styles()` and map to actual pages. This is the `style.css` vs `style-v2.css` boundary.
3. **Never rename or merge Elementor-generated classes** (any class starting with `elementor-`, `e-con-`, `e-`). Only refactor child-theme custom classes.
4. **Test on a staging clone**, not the live site. Compare visual output before/after.
5. **Use `grep` to search the codebase and database** for any class name before removing it from CSS.

**Warning signs:**
- Visual regression on specific pages after CSS edits
- Elementor sections appearing unstyled or with wrong spacing
- Styles that "work in dev but not on live" (cache serving old CSS while Elementor references new classes)

**Phase to address:** Any phase touching CSS files (CSS audit, consolidation, build pipeline)

---

### Pitfall 2: LiteSpeed Cache Serving Stale Content After Incremental Changes

**What goes wrong:**
LiteSpeed Cache is installed but configuration is unclear. When you make incremental PHP, CSS, or JS changes during optimization, LiteSpeed's full-page cache serves stale HTML. You think your change didn't work (or broke something), but the real issue is you're seeing a cached version. This leads to "fixing" things that weren't broken, introducing new bugs on top of the cache problem.

**Why it happens:**
LiteSpeed Cache can cache entire HTML pages. Unless cache is purged after every change — or auto-purge rules are configured for theme file changes — visitors (and developers) see stale content. The `filemtime()` cache-busting on CSS/JS handles asset URLs, but LiteSpeed's full-page cache still serves the old HTML with the old asset URLs embedded. The site runs in Docker/Nginx, so the caching layer may be Nginx, LiteSpeed, or both — unclear ownership of the cache invalidation.

**How to avoid:**
1. **Before starting optimization:** Audit the LiteSpeed Cache configuration. Document which features are enabled (page cache, browser cache, object cache, CSS/JS optimization, lazy load).
2. **Establish a cache-purge workflow:** After every code change, purge all caches (LiteSpeed plugin purge + Nginx cache clear if applicable).
3. **Use `?LSCWP_CTRL=NOCACHE`** on test URLs to view uncached versions during development.
4. **Do NOT enable LiteSpeed's CSS/JS minification/combination** while you're actively refactoring CSS/JS. These features create combined files that obscure which source file a style comes from.
5. **Check `X-LiteSpeed-Cache` response headers** to verify whether a page is being served from cache (`HIT`) or not (`MISS`).

**Warning signs:**
- Changes not appearing on frontend after deploy
- PageSpeed Insights scores not changing despite confirmed code changes
- `X-LiteSpeed-Cache: HIT` header on pages you just modified

**Phase to address:** Phase 1 (before any optimization work begins — establish cache awareness)

---

### Pitfall 3: Revolution Slider DOM Bloat and Render-Blocking

**What goes wrong:**
Revolution Slider injects massive inline CSS and JS on every page where it's used — typically the homepage hero. A single slider can add 50-100KB of inline JavaScript and 20-50KB of inline CSS directly into the HTML `<head>` and `<body>`. This is render-blocking and cannot be deferred. PageSpeed Insights flags it as "Reduce unused JavaScript" and "Eliminate render-blocking resources."

**Why it happens:**
Revolution Slider operates by generating all its configuration, slide data, and animation logic as inline `<script>` and `<style>` blocks. There is no external file to defer or async. Developers try to "fix" this by deferring Revolution Slider's scripts, which breaks the slider entirely (blank hero sections, no animations). The only real fix is to either (a) configure RevSlider to load only on pages that use it, or (b) replace it with a lighter alternative.

**How to avoid:**
1. **Audit which pages use Revolution Slider.** It should only load on pages that actually have a slider. Check if RevSlider has a "Include libraries globally" setting and disable it.
2. **Do NOT try to defer or async RevSlider's inline scripts.** It will break the slider.
3. **If RevSlider is only used on 2-3 pages**, ensure it only loads on those pages. The plugin has a setting for "Include on all pages" — this must be off.
4. **For the long term:** Consider replacing RevSlider hero banners with a static hero section using CSS animations. The marketing impact is identical, the performance gain is 100KB+ per page load.
5. **Check the `sr7-module`, `sr7-adjuster`, `sr7-content` custom elements** visible in `functions.php` line 110-200 — these are Slider Revolution 7 web components that add DOM weight.

**Warning signs:**
- PageSpeed "Avoid enormous network payloads" warning on homepage
- Inline `<style>` blocks with `sr7-` prefixed selectors
- Revolution Slider listed in "Reduce unused JavaScript" audit
- DOM size exceeding 1500+ nodes on pages with sliders

**Phase to address:** Phase 2 (plugin audit) — determine which pages use RevSlider and scope its impact

---

### Pitfall 4: Shortcode-Embedded `<style>` Blocks Cannot Be Cached Separately

**What goes wrong:**
Multiple shortcodes in `functions.php` (`[calendly_booking]`, `[all_resources_show]`, `[all_resources_bfsi]`, etc.) embed `<style>` blocks directly in the shortcode output. These inline styles:
1. Cannot be cached as separate CSS files (they're embedded in HTML)
2. Are duplicated when the same shortcode appears multiple times
3. Increase HTML payload on every page containing the shortcode
4. Cannot be minified or optimized by LiteSpeed's CSS optimization (it only handles `<link>` stylesheets, not inline `<style>` blocks consistently)

**Why it happens:**
The `all_resources_bfsi()` function (line 417-545) and `all_resources()` function (line 286-415) contain nearly identical `<style>` blocks. The `[calendly_booking]` shortcode (line 70-218) has 90+ lines of inline CSS targeting RevSlider elements (`sr7-txt#SR7_15_1-54-25`). Developers add styles inline for convenience — they don't realize this blocks caching optimization.

**How to avoid:**
1. **Extract all shortcode inline styles into dedicated CSS files** (e.g., `shortcodes-resources.css`, `shortcodes-calendly.css`).
2. **Enqueue these files conditionally:** only when the shortcode is rendered. Use `wp_enqueue_style()` inside the shortcode function — WordPress supports this.
3. **Alternatively:** Add shortcode styles to `style-v2.css` / `style.css` and use CSS specificity to scope them.
4. **Deduplicate:** The `all_resources_bfsi()` and `all_resources()` CSS blocks are nearly identical — merge into a single class.

**Warning signs:**
- `<style>` blocks appearing mid-body in HTML output
- Duplicate CSS rules when multiple shortcodes render on the same page
- LiteSpeed CSS optimization not covering all styles (inline blocks bypass it)

**Phase to address:** Phase 3 (CSS consolidation) — extract inline styles during the CSS cleanup phase

---

### Pitfall 5: CDN-Loaded Third-Party Scripts Break During Optimization

**What goes wrong:**
The site loads Slick, Moment.js, Bootstrap, Popper, Lottie, and Marketo from various CDN URLs (cdnjs, jsDelivr, app-lon03.marketo.com) scattered across `post-types.php` and `min-script.php`. During optimization, developers try to:
- Consolidate these into local files → but CDN URLs change between environments
- Defer/async them → breaks initialization order (Slick init depends on Slick which depends on jQuery)
- Remove "unused" CDN scripts → turns out some are used on only one template and break that template

**Why it happens:**
There is no single source of truth for which scripts load where. `post-types.php` (79KB) mixes CPT registration with script enqueuing — a maintainability nightmare. Some scripts load from CDN, some from local copies, and some from both (Slick has both `js/slick.min.js` locally and jsDelivr CDN references in `post-types.php`). The `min-script.php` attempts a whitelist approach for minimal templates but duplicates Slick registration logic.

**How to avoid:**
1. **Create a script inventory table** before touching any `wp_enqueue_script` call. Document: handle name, source URL, dependencies, which pages/templates load it.
2. **Standardize on ONE source per library:** either local or CDN, never both. Prefer local copies for stability (CDNs can be blocked by ad blockers or corporate firewalls).
3. **Test defer/async carefully with jQuery-dependent scripts.** Slick requires jQuery. Slick-init requires Slick. Marketo Forms 2 requires no dependencies but must load before `marketo.js`. The dependency chain must be preserved.
4. **Marketo (`app-lon03.marketo.com/js/forms2/js/forms2.min.js`)** is an external third-party script — it should load async/defer and not block rendering. Wrap Marketo form rendering in a `window.onload` or DOMContentLoaded check.
5. **Never remove a script handle without searching the entire codebase** (including Elementor widget data in the database) for usage.

**Warning signs:**
- JavaScript console errors: `$ is not defined`, `Slick is not a function`, `MktoForms2 is not defined`
- Carousel not initializing after script changes
- Marketo forms not rendering

**Phase to address:** Phase 2 (plugin/asset audit) — document all scripts before consolidating

---

### Pitfall 6: Output Buffering for Accessibility Adds Processing Overhead

**What goes wrong:**
`scripts.php` line 528-583 implements `ob_start("enhance_elementor_accessibility_buffer")` on `template_redirect`, which runs a regex replacement on the entire HTML output of every front-end page. This:
1. Processes every HTML response through 12+ regex patterns
2. Runs on EVERY page load (even cached pages if LiteSpeed doesn't cache the buffer layer)
3. Can interfere with page caching (the buffer callback runs before LiteSpeed caches the output)
4. The regex patterns match on class names like `fb-icon`, `linkedin-icon` etc. — if Elementor changes class names in an update, the regex silently stops matching

**Why it happens:**
Output buffering is an easy way to modify HTML without touching templates. But it's a performance anti-pattern because it processes every response. The accessibility improvement (adding `aria-label` to social links) could be done more efficiently.

**How to avoid:**
1. **Move accessibility attributes into the Elementor widget templates or shortcode output** rather than regex-ing the entire HTML.
2. **If output buffering is kept, ensure it runs BEFORE LiteSpeed caches** — so the cached version already includes the accessibility attributes and the buffer doesn't run on cached responses.
3. **Test whether LiteSpeed's page cache bypasses or respects the output buffer.** If the buffer runs on every request (including cached ones), it's adding latency for no benefit.
4. **Alternatively:** Use JavaScript to add accessibility attributes on DOMContentLoaded. Less server-side overhead, same user-facing result.

**Warning signs:**
- TTFB higher than expected for a "cached" page
- Accessibility attributes present in some responses but not others (inconsistent caching)
- Regex modifications not appearing after page cache is enabled

**Phase to address:** Phase 2 (audit) — determine if this can be moved to a static approach

---

### Pitfall 7: Conditional CSS Loading by Post Slug Is Fragile and Unscalable

**What goes wrong:**
`functions.php` line 18-46 implements CSS loading by checking `$post_name` against a hardcoded list of 25+ slugs in a single `if` statement. This means:
1. Every new page requires a code deploy to add its slug to the list
2. A typo in a slug (e.g., page renamed from "knowbler" to "knowbler-ai") silently loads the wrong stylesheet
3. The list is unmaintainable — 25 slug checks in one line
4. There's no fallback for pages that should use `style-v2.css` but aren't in the list

**Why it happens:**
This was likely a quick solution to load `style-v2.css` on "new design" pages and `style.css` on "old design" pages. It grew organically as more pages were redesigned.

**How to avoid:**
1. **Replace slug-based logic with a theme meta field or ACF field.** Add a "Use V2 Styles" toggle to each page's edit screen. Check this field instead of hardcoding slugs.
2. **Alternatively, use page template detection:** `is_page_template('template-su-*.php')` instead of slug matching. Template assignments are more stable than slugs.
3. **If you must keep slug-based logic,** move the slug list to a configuration array or option. Don't hardcode it in the function.
4. **Test both CSS files load correctly on representative pages** before changing the loading logic.

**Warning signs:**
- New pages looking "wrong" because their slug wasn't added to the list
- Pages loading both stylesheets (if both are enqueued via different paths)
- Developer confusion about which stylesheet governs which page

**Phase to address:** Phase 3 (CSS consolidation) — this is the CSS loading logic that needs restructuring

---

### Pitfall 8: Google Fonts Render-Blocking via Multiple Requests

**What goes wrong:**
`post-types.php` line 2067-2089 (`fix_google_fonts_blocking`) preloads and async-loads 5 different Google Fonts URLs, each requesting multiple families with many weight variations. The Poppins font alone is requested in 4 separate URLs with overlapping weight ranges (100-900 in one, 100-600 in another, 300-700 in another). This means:
1. **Duplicate font downloads** — Poppins weights 300-600 are downloaded 4 times
2. **5 render-blocking preload hints** that compete with LCP image preload
3. **The `media="print" onload="this.media='all'"` trick** causes FOIT (Flash of Invisible Text) on slow connections
4. **Total font payload:** Poppins (9 weights × 2 styles = 18 files) + Raleway (8 weights × 2 styles) + Lato + Roboto Slab + Figtree + Montserrat = potentially 60+ individual font file requests

**Why it happens:**
Fonts were added piecemeal as new designs introduced new typefaces. Nobody audited the cumulative font loading impact.

**How to avoid:**
1. **Consolidate all Google Fonts into a single URL** with only the weights actually used. Remove unused weights (is `Poppins:wght@100` really used? Probably not).
2. **Host fonts locally** instead of relying on Google Fonts CDN. This eliminates DNS lookup and allows better caching.
3. **Limit to 2-3 font families maximum.** Poppins + one serif/display font should cover the entire site.
4. **Use `font-display: swap`** (already present via `display=swap` in URLs) but ensure it's actually working.
5. **Audit which weights are actually used:** Check the CSS for `font-weight` declarations. If only 400 and 600 are used, only request those.

**Warning signs:**
- PageSpeed "Avoid chaining critical requests" warning showing font preload chain
- "Ensure text remains visible during webfont load" audit failing
- Network tab showing 30+ font file requests
- LCP delayed by font loading

**Phase to address:** Phase 3 (CSS consolidation) — audit and consolidate font loading

---

### Pitfall 9: `wp_remote_get` in `minimal-asset-bundles.php` Makes Requests at Runtime

**What goes wrong:**
`minimal-asset-bundles.php` contains a `wp_remote_get` call (referenced in `CONCERNS.md`) to fetch Popper.js from CDN during bundle building. If this runs on every request (instead of only during cache rebuild), it adds an HTTP request to every page load. Even if it's only during bundle generation, a failed CDN request will crash the bundle build and potentially leave the site with broken JS.

**Why it happens:**
The minimal template system tries to create cached CSS/JS bundles by concatenating files. When a library isn't available locally, it fetches from CDN. This is a reasonable idea for a build step but dangerous if it runs at request time.

**How to avoid:**
1. **Verify when the bundle building runs:** Only on cache miss/theme update, or on every request?
2. **Download CDN dependencies to local files** instead of fetching at runtime.
3. **Add error handling:** If `wp_remote_get` fails, fall back to the non-bundled asset loading path.
4. **Consider whether the bundle system is worth the complexity.** If LiteSpeed's own CSS/JS optimization achieves similar results, the custom bundle system may be redundant.

**Warning signs:**
- Intermittent slow TTFB when bundle cache expires
- Fatal errors if CDN is unreachable during bundle rebuild
- `wp_remote_get` timeout errors in PHP error logs

**Phase to address:** Phase 2 (asset audit) — determine if the bundle system is needed or if LiteSpeed handles this

---

### Pitfall 10: Changing PHP File Structure Breaks `require_once` Chains

**What goes wrong:**
When splitting large files like `su-rest-functions.php` (125KB), `post-types.php` (79KB), or `top-bar-shortcode.php` (50KB) into smaller modules, the `require_once` chain in `functions.php` can break silently. If a file is split but `functions.php` still requires the old filename, the old code runs AND the new split files may also be loaded elsewhere, causing "cannot redeclare function" fatal errors.

**Why it happens:**
WordPress doesn't have autoloading for procedural PHP files. Every `require_once` is a manual path reference. When refactoring, developers create new files but forget to remove old references, or create circular dependencies.

**How to avoid:**
1. **Never delete a file until its replacement is verified working.** Keep the old file with a `// DEPRECATED: See inc/new-file.php` comment.
2. **Rename functions when splitting files** to avoid "cannot redeclare" errors during the transition.
3. **Add a PHP fatal error check** to the deployment process: `php -l <file>` syntax check on every modified PHP file.
4. **Use WordPress's `get_stylesheet_directory()` consistently** — don't mix `dirname(__FILE__)` and `get_stylesheet_directory()` as they can resolve differently in Docker.
5. **Test on staging with `WP_DEBUG` enabled** to catch "undefined function" and "cannot redeclare" errors.

**Warning signs:**
- `Fatal error: Cannot redeclare function_name()` in PHP error logs
- White screen of death (WSOD) on specific pages
- Functions defined in split files not being available (file not loaded)

**Phase to address:** Any phase that splits PHP files (code cleanup phase)

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep inline `<style>` in shortcodes | Fast to implement, no file management | 10-50KB of uncacheable CSS per page, duplicate styles across shortcodes | Never for production — extract during optimization |
| Hardcode post slugs in CSS loader | Works immediately for the specific pages | Every new/renamed page requires a code deploy; unmaintainable at 25+ entries | Never — use meta fields or template detection |
| Load all scripts on all pages | No script-missing bugs | 200-500KB of unnecessary JS on pages that don't use those features | Only temporarily during initial optimization audit |
| Keep both minified and unminified JS files | Debugging convenience | Confusion about which file is actually loaded; doubles file count | Never — use a build tool with source maps instead |
| Use `ob_start` regex for HTML modification | No template changes needed | Processes every HTML response; breaks caching; silently stops matching if Elementor changes output | Acceptable only if cached output includes the modifications |
| Leave Revolution Slider for hero sections | Visual impact preserved | 100KB+ inline JS/CSS per page; render-blocking; cannot be optimized away | Acceptable if limited to 1-2 pages with global loading disabled |

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| **Marketo Forms 2** | Loading `forms2.min.js` synchronously in `<head>` | Load async with `wp_enqueue_script('marketo-forms', $url, [], null, true)` (in footer) and initialize forms on `DOMContentLoaded` |
| **Calendly embed** | Hardcoding Calendly URL with UTM params in PHP (no caching possible per-UTM combination) | Use JS to construct the Calendly URL client-side from URL parameters, allowing page-level caching |
| **Google Fonts** | Requesting 5 separate font URLs with overlapping weight ranges | Consolidate into 1 URL with only used weights; self-host if possible |
| **Slick Carousel** | Loading Slick from both local copy AND jsDelivr CDN on different pages | Standardize on local copy only; remove CDN references |
| **Revolution Slider** | Loading RevSlider JS/CSS on all pages globally | Enable "Include libraries only on pages with slider" setting |
| **Classic Elementor Addons Pro** | Theia Sticky Sidebar fallback path check via `file_exists()` on every page load | Cache the result in a transient or wrap in a static variable |
| **Moment.js + Bootstrap Datepicker** | Loading on all pages for the events feature | Only load on pages with the events template or events CPT archive |
| **Lottie** | Loading `lottie.min.js` from CDN on all pages | Only load on pages that contain Lottie animations (detect in template) |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| **19K+25K line monolithic CSS** | PageSpeed "Reduce unused CSS" flag; slow CSS parsing on mobile | Split CSS by page/template; use build tool to generate per-page CSS bundles | Already broken — 44K lines of CSS is far beyond what PageSpeed considers acceptable |
| **79KB `post-types.php` mixing CPT registration + script enqueue** | New developers can't understand which scripts load where; accidental global script loads | Separate CPT registration from asset loading into different files | Already broken — file is unmaintainable |
| **`filemtime()` cache busting without build process** | Every file change forces new URL but no minification, no tree-shaking, no dead code elimination | Implement a build tool (Vite/Webpack) that produces optimized bundles with content hashes | Breaks at ~50K monthly visitors when CSS parsing time exceeds 200ms on mobile |
| **No conditional script loading** | Scripts load on pages that don't need them (e.g., events-ajax.js on non-event pages) | Wrap `wp_enqueue_script` calls in template/page conditionals | Already broken — `events-ajax.js` loads on pages without events |
| **Output buffer regex on every request** | TTFB 50-100ms higher than expected for a cached page | Move accessibility fixes into templates or cached output | Breaks when LiteSpeed is misconfigured and buffer runs on cached responses |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| **Multiple overlapping security plugins** (Defender, Really Simple SSL, SG Security) | Security header conflicts; login lockout race conditions; performance overhead from redundant scanning | Audit which features each provides; disable overlapping functionality; preferably keep only one |
| **`$_GET` parameters directly in shortcode output** (line 74-100 in `functions.php`) | XSS risk if parameters aren't properly escaped before HTML output | Use `esc_url()` for URLs, `esc_attr()` for attributes — verify existing escaping is comprehensive |
| **REST API public `permission_callback`** (`su_rc` namespace) | Unauthenticated access to potentially sensitive data endpoints | Audit each REST route for proper permission callbacks; add authentication to routes returning non-public data |
| **`wp_remote_get` with CDN URLs** in `minimal-asset-bundles.php` | SSRF risk if URLs are constructed from user-controllable data | Ensure URLs are hardcoded allowlist only (they appear to be, but verify) |
| **`wp-file-manager` plugin installed** | File manager plugins are a common attack vector; many have had critical vulnerabilities | Evaluate if needed; if not, remove it; if needed, restrict access to admin-only |

## UX Pitfalls

Common user experience mistakes in WordPress performance optimization.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| **Aggressive CSS deferral causes FOUC** (Flash of Unstyled Content) | Page appears unstyled for 1-2 seconds on load, then "pops" into styled state | Use `preload` for critical CSS; defer only non-critical stylesheets; test on slow 3G connections |
| **Lazy loading above-the-fold images** | Hero images/LCP images don't load until user scrolls, causing blank hero sections | Use `fetchpriority="high"` (already implemented for some preloads) or `loading="eager"` for LCP images; lazy-load only below-fold |
| **Deferring jQuery breaks interactive elements** | Dropdowns, carousels, and mobile menu stop working until jQuery loads | Keep jQuery synchronous (WordPress convention) or test all interactive elements thoroughly after deferral |
| **Removing "unused" CSS that's actually used on hover/active states** | Hover effects, mobile menu styles, and interactive states disappear | Audit CSS usage with Scrolling/Interaction in Chrome DevTools Coverage tab, not just page load |
| **Over-optimizing Google Fonts causing wrong font fallbacks** | Site displays in system fonts (Times New Roman, etc.) for extended periods | Host critical font weights locally; preload the primary font file |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **PageSpeed score 90+:** Often measured on desktop only — verify MOBILE score separately (mobile is harder due to CPU throttling)
- [ ] **CSS consolidation:** Often consolidates `style.css` but misses inline `<style>` blocks in shortcodes, Elementor output, and `post-types.php`
- [ ] **Script deferral:** Often defers all scripts but breaks jQuery-dependent initializations (Slick, sticky sidebar, Marketo forms)
- [ ] **Image optimization:** Often adds WebP versions but doesn't add `width`/`height` attributes, causing CLS (Cumulative Layout Shift)
- [ ] **Cache configuration:** Often enables LiteSpeed cache but doesn't verify it's actually serving cached pages (check response headers!)
- [ ] **RevSlider optimization:** Often "optimizes" by deferring scripts but this breaks the slider entirely — the only real fix is restricting which pages load it
- [ ] **Font optimization:** Often consolidates Google Fonts URLs but doesn't remove unused weight variations (e.g., Poppins wght@100 is probably never used)
- [ ] **Plugin removal:** Often disables a plugin but leaves its shortcode references in page content, causing `[shortcode]` to appear as visible text
- [ ] **Nginx caching:** Often configures Nginx caching but doesn't configure cache invalidation when content is updated from WordPress admin
- [ ] **Mobile CSS:** Often optimizes desktop CSS but the separate `style-mobile.css` (loaded on every page) remains unoptimized

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Broken Elementor page from CSS refactor | HIGH | Revert CSS change; identify which Elementor data references old classes; update Elementor widget data or restore old CSS classes |
| LiteSpeed serving stale content | LOW | Purge all caches from LiteSpeed admin; clear Nginx cache; verify with `?LSCWP_CTRL=NOCACHE` |
| Revolution Slider broken after optimization | MEDIUM | Re-enable all RevSlider scripts; disable any defer/async on RevSlider handles; check "Include globally" setting |
| Shortcode `[text]` visible after plugin removal | LOW | Re-enable the plugin or remove shortcode references from page content via database search/replace |
| JavaScript initialization order broken | MEDIUM | Restore original script dependency chain; re-enable jQuery in `<head>` if needed; test all interactive elements |
| White screen from PHP file splitting | MEDIUM | Revert to original file structure; check `require_once` paths; run `php -l` on all modified files |
| FOUC from aggressive CSS deferral | LOW | Move critical CSS back to synchronous loading; add `rel="preload"` for primary stylesheet |
| Google Fonts not loading after consolidation | LOW | Revert to original font URLs; verify new consolidated URL returns correct CSS; test with ad blockers disabled |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Breaking Elementor pages (CSS refactor) | CSS consolidation phase | Visual regression testing on all key pages before/after |
| LiteSpeed stale cache | Phase 1: Baseline audit | Verify `X-LiteSpeed-Cache` headers; establish cache-purge workflow |
| RevSlider DOM bloat | Plugin audit phase | Audit RevSlider global loading settings; measure inline JS/CSS payload |
| Shortcode inline styles | CSS consolidation phase | Grep for `<style>` in shortcode functions; verify extraction |
| CDN script breakage | Asset audit phase | Create script inventory; test all pages after consolidation |
| Output buffer overhead | Asset audit phase | Measure TTFB with and without buffer; consider alternatives |
| Conditional CSS by slug | CSS consolidation phase | Replace slug check with meta field; test all existing pages |
| Google Fonts bloat | CSS consolidation phase | Consolidate to single URL; audit used weights vs. requested |
| `wp_remote_get` runtime risk | Asset audit phase | Verify bundle timing; download CDN deps locally |
| PHP file splitting errors | Code cleanup phase | PHP syntax check all files; test staging with `WP_DEBUG` |

## Sources

- Elementor developer documentation: `is_dynamic_content()` and widget output caching (https://developers.elementor.com/docs/widgets/widget-output-caching/) — HIGH confidence
- LiteSpeed Cache WordPress plugin documentation (https://docs.litespeedtech.com/lscache/lscwp/) — HIGH confidence
- Codebase analysis: `functions.php`, `inc/scripts.php`, `inc/post-types.php`, `inc/min-script.php`, `inc/minimal-asset-bundles.php`, `.planning/codebase/CONCERNS.md` — HIGH confidence (direct code inspection)
- WordPress enqueue API behavior: `wp_enqueue_script` with `$in_footer = true` and dependency chains — HIGH confidence (WordPress core documentation)
- PageSpeed Insights audit criteria: "Reduce unused CSS", "Eliminate render-blocking resources", "Reduce unused JavaScript" — HIGH confidence (Google documentation)

---
*Pitfalls research for: WordPress performance optimization (SearchUnify / Elementor site)*
*Researched: 2026-05-04*
