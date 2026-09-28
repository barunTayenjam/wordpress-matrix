import argparse
import csv
import re
import sys
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET

UA = {"User-Agent": "Mozilla/5.0 (compatible; EPBD-SeoVerify/1.0)"}

def fetch(url, timeout):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
        ctype = r.headers.get_content_charset() or "utf-8"
        try:
            html = raw.decode(ctype, errors="replace")
        except Exception:
            html = raw.decode("utf-8", errors="replace")
        headers = {k.lower(): v for k, v in r.headers.items()}
        return headers, html

def norm(u):
    u = (u or "").strip()
    u = u.split("#")[0].split("?")[0].rstrip("/")
    return u.lower()

def robots_of(url, timeout):
    try:
        headers, html = fetch(url, timeout)
    except Exception as e:
        return f"FETCH-FAIL: {e}", "", ""
    x = headers.get("x-robots-tag", "")
    m1 = re.search(r'<meta[^>]+name=["\']robots["\'][^>]*content=["\']([^"\']+)["\']', html, re.I)
    m2 = re.search(r'<meta[^>]+content=["\']([^"\']+)["\'][^>]*name=["\']robots["\']', html, re.I)
    content = (m1.group(1) if m1 else (m2.group(1) if m2 else "")).lower()
    return "", x.lower(), content

def locs_of(xml_text):
    try:
        root = ET.fromstring(xml_text)
    except Exception:
        return []
    out = []
    for el in root.iter():
        if el.tag.endswith("loc") and el.text:
            out.append(el.text.strip())
    return out

def walk_sitemap(url, timeout, urls, maps, depth=0, max_depth=10):
    """Recursively walk a sitemap (index or urlset), collecting page URLs.

    Handles arbitrary nesting: index -> child index -> ... -> urlset.
    Loop-safe via the maps set.
    """
    norm_map = norm(url)
    if norm_map in maps or depth > max_depth:
        return
    maps.add(norm_map)
    try:
        _, xml = fetch(url, timeout)
    except Exception as e:
        print(f"  sitemap fetch fail ({url}): {e}")
        return
    for loc in locs_of(xml):
        if loc.lower().endswith(".xml"):
            walk_sitemap(loc, timeout, urls, maps, depth + 1, max_depth)
        else:
            urls.add(norm(loc))

def sitemap_urls(index_url, timeout):
    urls = set()
    maps = set()
    walk_sitemap(index_url, timeout, urls, maps)
    print(f"sitemap files walked: {len(maps)}")
    return urls

def read_targets(path):
    with open(path, newline="", encoding="utf-8-sig") as f:
        sample = f.read(4096)
        f.seek(0)
        try:
            dialect = csv.Sniffer().sniff(sample, delimiters=[",", "\t", ";"])
            delim = dialect.delimiter
        except Exception:
            delim = "\t" if sample.count("\t") > sample.count(",") else ","
        rows = list(csv.reader(f, delimiter=delim))
    if not rows:
        return []
    head = [h.strip().lower() for h in rows[0]]
    try:
        ui = head.index("to archive pages")
        ri = head.index("response")
    except ValueError:
        sys.exit("headers need 'To Archive Pages' + 'Response'")
    out = []
    for r in rows[1:]:
        url = r[ui].strip() if len(r) > ui else ""
        resp = r[ri].strip().lower() if len(r) > ri else ""
        if url and resp == "remove":
            out.append(url)
    seen = list(dict.fromkeys(out))
    return seen

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--sitemap", default="https://www.searchunify.com/sitemap_index.xml")
    ap.add_argument("--timeout", type=int, default=20)
    a = ap.parse_args()
    targets = read_targets(a.csv)
    print(f"targets: {len(targets)}")
    try:
        sm = sitemap_urls(a.sitemap, a.timeout)
        print(f"sitemap urls: {len(sm)}")
    except Exception as e:
        print(f"sitemap fetch failed: {e}")
        sm = set()
    bad = 0
    for u in targets:
        err, x, content = robots_of(u, a.timeout)
        has_noindex = "noindex" in content or "noindex" in x
        has_nofollow = "nofollow" in content or "nofollow" in x
        in_sm = norm(u) in sm
        ok = (not err) and has_noindex and has_nofollow and (not in_sm)
        if not ok:
            bad += 1
        print(f"{'PASS' if ok else 'FAIL'} {u} noindex={has_noindex} nofollow={has_nofollow} in_sitemap={in_sm} {err} [{content or x}]".rstrip())
    print(f"done: {len(targets)-bad}/{len(targets)} pass")
    sys.exit(1 if bad else 0)

if __name__ == "__main__":
    main()
