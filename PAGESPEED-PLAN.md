# Plan: Get searchunify.com Homepage to 95+ (Mobile & Desktop)

**Goal:** Performance ≥ 95 both, CLS < 0.1, LCP < 2.5s.

**Principle:** Every change is verified with Playwright + Lighthouse before it is called done.

**Canonical URL:** `https://www.searchunify.com` (0 redirects, no redirect penalty)

---

## Current State (live, su-performance.php disabled)

| Metric | Value | Target |
|---|---|---|
| Score | 34 | ≥95 |
| FCP | 3.9s | <1.8s |
| LCP | 9.7s | <2.5s |
| TBT | 50ms | <200ms |
| CLS | 0.539 | <0.1 |
| Speed Index | 4.9s | <3.4s |

**Network:** 246 requests, 7,625KB total | **Third-party:** 1,907KB

---

## Phase 1 — In-Theme Fixes (su-performance.php)

### 1.1 Defer `scroll-trigger.min.js` (2,620ms main-thread hog)
**Problem:** `classic-elementor-addons-pro/assets/js/scroll-trigger.min.js` takes **2,620ms** on main thread. It's only needed for scroll animations.

**Fix:** Defer with `script_loader_tag` filter:
```php
add_filter('script_loader_tag', function($tag, $handle, $src) {
    if ($handle === 'scroll-trigger') {
        return str_replace(' src', ' defer src', $tag);
    }
    return $tag;
}, 10, 3);
```

- **Verify:** Lighthouse main-thread work drops.

---

### 1.2 Defer feedback.js, searchbox.js, common.js (407KB combined)
**Problem:** `feedback.js` (500KB, 244KB wasted), `searchbox.js` (391KB, 163KB wasted), `common.js` (149KB, 105KB wasted) load eagerly. They're needed but don't block initial render.

**Fix:** Defer with `script_loader_tag` filter:
```php
add_filter('script_loader_tag', function($tag, $handle, $src) {
    if (strpos($src, 'feedback.js') !== false ||
        strpos($src, 'searchbox.js') !== false ||
        strpos($src, 'suva') !== false) {
        return str_replace(' src', ' defer src', $tag);
    }
    return $tag;
}, 10, 3);
```

- **Verify:** Lighthouse "Reduce unused JavaScript" drops.

---

### 1.3 Defer GTM (143KB, analytics can wait)
**Problem:** Two GTM tags load 176KB each. Analytics doesn't need to block render.

**Fix:** Delay GTM until first user interaction:
```php
add_action('wp_head', function() {
    ?>
    <script>
    var gtmLoaded = false;
    function loadGTM() {
        if (gtmLoaded) return;
        gtmLoaded = true;
        // Your GTM snippet here
    }
    ['click','scroll','touchstart','keydown'].forEach(function(e) {
        document.addEventListener(e, loadGTM, {once:true, passive:true});
    });
    </script>
    <?php
}, 1);
```

- **Verify:** Lighthouse third-party summary shows reduced GTM payload.

---

### 1.4 Defer Lottie.js (53KB, animation can wait)
**Problem:** `bodymovin/5.7.4/lottie.min.js` loads for hero animation but is heavy.

**Fix:** Defer:
```php
add_filter('script_loader_tag', function($tag, $handle, $src) {
    if (strpos($src, 'lottie.min.js') !== false) {
        return str_replace(' src', ' defer src', $tag);
    }
    return $tag;
}, 10, 3);
```

- **Verify:** Main-thread work drops; hero animation still plays.

---

### 1.5 Remove legacy JavaScript (58KB wasted)
**Problem:** Modern browsers receive polyfills they don't need.

**Fix:** Dequeue legacy scripts:
```php
add_action('wp_enqueue_scripts', function() {
    wp_dequeue('jquery-migrate');
    wp_deregister_script('jquery-migrate');
}, 99);
```

- **Verify:** Lighthouse "Avoid serving legacy JavaScript" → green.

---

### 1.6 Lazy-load offscreen images (301KB savings)
**Problem:** 3286KB of images load eagerly. Many are below the fold.

**Fix:** Add `loading="lazy"` to offscreen images:
```php
add_filter('wp_get_attachment_image_attributes', function($attr, $attachment, $size) {
    if (isset($attr['fetchpriority']) && $attr['fetchpriority'] === 'high') return $attr;
    if (isset($attr['class']) && strpos($attr['class'], 'header') !== false) return $attr;
    $attr['loading'] = 'lazy';
    return $attr;
}, 10, 3);
```

- **Verify:** Lighthouse "Defer offscreen images" → green.

---

### 1.7 Add image width/height (CLS reduction)
**Problem:** Images without dimensions cause reflow.

**Fix:** CSS `aspect-ratio` safety net:
```php
add_action('wp_head', function() {
    ?>
    <style>
    img:not([width]):not([height]):not([fetchpriority="high"]) {
        aspect-ratio: auto 16/9;
        width: 100%;
        height: auto;
    }
    </style>
    <?php
}, 1);
```

- **Verify:** CLS improves.

---

## Phase 2 — Cloudflare/Server (You Apply, I Verify)

### 2.1 Enable Brotli compression (741KB savings)
**Problem:** Cloudfront.net assets (feedback.js, searchbox.js, an.js) served uncompressed.

**Fix:** Cloudflare → Speed → Optimization → Content Optimization → Enable Brotli.

**Apply to:**
- `d24f5uogtvlja2.cloudfront.net/*` (your CloudFront distribution)

- **Verify:** `curl -s -H "Accept-Encoding: br" -I "https://d24f5uogtvlja2.cloudfront.net/..." | grep content-encoding` → `br`

---

### 2.2 Apply max cache to all static assets (1,119KB savings)
**Problem:** Many assets have no cache headers.

**Fix:** Cloudflare → Caching → Configuration → Browser Cache TTL → "Respect Existing Headers" AND add Page Rules for long cache:

**Cloudflare Page Rules (create 3):**

| Pattern | Setting |
|---|---|
| `www.searchunify.com/wp-content/*` | Cache Level: Cache Everything, Edge Cache TTL: 1 month |
| `www.searchunify.com/wp-includes/*` | Cache Level: Cache Everything, Edge Cache TTL: 1 month |
| `d24f5uogtvlja2.cloudfront.net/*` | Cache Level: Cache Everything, Edge Cache TTL: 1 month |

**Origin .htaccess (add for your server):**
```apache
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType font/woff2 "access plus 1 year"
    ExpiresByType font/woff "access plus 1 year"
    ExpiresByType application/font-woff2 "access plus 1 year"
</IfModule>

<IfModule mod_headers.c>
    <FilesMatch "\.(css|js|woff2|woff|png|jpg|jpeg|gif|svg|webp|ico)$">
        Header set Cache-Control "public, max-age=31536000, immutable"
    </FilesMatch>
</IfModule>
```

**Assets that will be cached:**
| Asset | Size | Current Cache | After |
|---|---|---|---|
| `d24f5uogtvlja2.cloudfront.net/.../feedback.js` | 501KB | 0s | 1 year |
| `d24f5uogtvlja2.cloudfront.net/.../searchbox.js` | 392KB | 0s | 1 year |
| `d24f5uogtvlja2.cloudfront.net/.../an.js` | 138KB | 0s | 1 year |
| `onemark.grazitti.com/.../embed.js` | 4KB | 0s | 1 year |
| `munchkin.marketo.net/munchkin.js` | 1KB | 0s | 1 year |
| `seoinux-child/style-v2.css` | 81KB | varies | 1 year |
| `seoinux/assets/css/bootstrap.min.css` | 22KB | varies | 1 year |
| All `/wp-content/uploads/*` | varies | varies | 1 year |
| All `/wp-content/plugins/*` JS/CSS | varies | varies | 1 year |

- **Verify:** Lighthouse "Serve static assets with efficient cache policy" → green.

---

### 2.3 Enable Auto Minify (120KB savings)
**Problem:** Unminified CSS and JS on origin.

**Fix:** Cloudflare → Speed → Optimization → Content Optimization → Enable Auto Minify for:
- ✅ JavaScript
- ✅ CSS
- ✅ HTML

**Apply to:**
- `seoinux-child/style-v2.css` (23KB wasted)
- `suva.../common.js` (69KB wasted)
- `suva.../index.js` (22KB wasted)
- `classic-elementor-addons-pro/.../style.css` (6KB wasted)
- `seoinux/style.css` (5KB wasted)
- `seoinux/.../theme-styles.css` (4KB wasted)

- **Verify:** Lighthouse "Minify CSS" + "Minify JavaScript" → green.

---

### 2.4 Reduce server response time (1,220ms TTFB)
**Problem:** Root document takes 1,220ms to respond.

**Fix:**
- Cloudflare → Enable "Always Use HTTPS" + "Early Hints"
- Enable Redis object caching on origin (already in docker-compose)
- Check if origin server needs more RAM/CPU

- **Verify:** Lighthouse "Reduce initial server response time" → green (<600ms).

---

## Phase 3 — What NOT to Touch

| Asset | Why |
|---|---|
| `style-v2.css` (81KB) | Main theme CSS, needed for render |
| `bootstrap.min.css` (22KB) | Layout system, needed for render |
| `theme-styles.css` (20KB) | Theme styles, needed for render |
| `font-awesome.min.css` (6KB) | Icons, needed for render |
| `revslider/.../sr7.js` (90KB) | Hero slider, needed for render |
| `revslider/.../tptools.js` (72KB) | Hero slider tools, needed for render |

---

## Phase 4 — Final Verification

1. Run Lighthouse mobile + desktop on live site
2. **Targets:** Performance ≥ 95, CLS < 0.1, LCP < 2.5s, FCP < 1.8s
3. Confirm: no FOUC, no layout shifts, 0 console errors
4. Confirm: all Phase 1 + Phase 2 items pass their verification gates

---

## Verification Gate Summary

| Step | Check | Pass criterion |
|---|---|---|
| 1.1 | Lighthouse main-thread work | scroll-trigger <500ms |
| 1.2 | Lighthouse unused JS | Drops by ~400KB |
| 1.3 | Lighthouse third-party summary | GTM reduced |
| 1.4 | Lighthouse boot-up-time | lottie.min.js dropped |
| 1.5 | Lighthouse legacy JS | → green |
| 1.6 | Lighthouse lazy-load | → green |
| 1.7 | CLS measurement | Improves |
| 2.1 | curl compression | content-encoding: br |
| 2.2 | Lighthouse cache | → green |
| 2.3 | Lighthouse minify | CSS + JS → green |
| 2.4 | Lighthouse TTFB | <600ms |
| 4 | Lighthouse (live) | ≥95, CLS <0.1, LCP <2.5s |

---

## Priority Order

1. **2.2** — Max cache (biggest impact, Cloudflare rules)
2. **2.1** — Enable Brotli (741KB saved, Cloudflare toggle)
3. **2.3** — Auto Minify (120KB saved, Cloudflare toggle)
4. **1.1** — Defer scroll-trigger.min.js (2,620ms, su-performance.php)
5. **1.2** — Defer feedback.js + searchbox.js + common.js (407KB, su-performance.php)
6. **1.3** — Defer GTM (143KB, su-performance.php)
7. **1.4** — Defer Lottie.js (53KB, su-performance.php)
8. **1.5** — Remove legacy JS (58KB, su-performance.php)
9. **1.6** — Lazy-load offscreen images (301KB, su-performance.php)
10. **2.4** — Reduce TTFB (Cloudflare + Redis)

---

## Responsibilities

- **Phase 1**: All in `su-performance.php`. I implement + verify locally, then you deploy.
- **Phase 2**: Cloudflare/origin config. I write exact rules; you apply (or grant access) and I verify.
