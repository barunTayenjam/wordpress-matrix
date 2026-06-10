---
spike: 002b
name: diagram-interactive-html
type: comparison
validates: "Given architecture JSON, when rendered as interactive HTML with D3.js, then user can explore, filter, zoom, and inspect the architecture"
verdict: VALIDATED
related: [001, 002a]
tags: [diagram, interactive, visualization, d3]
---

# Spike 002b: Interactive Architecture Explorer (D3.js)

## What This Validates
Can an interactive, force-directed graph provide a better architecture exploration experience than a static Mermaid diagram?

## How to Run
Open `.planning/spikes/002b-diagram-interactive-html/index.html` in a browser.
It fetches `architecture.json` from spike 001 and renders it as a force-directed graph.

## What to Expect
- Force-directed graph of all files with code functions
- Node size = function count, node color = file type
- Drag nodes to rearrange, scroll to zoom
- Filter by type (JS/Bash/PHP/JSON/MD) and minimum function count
- Hover for tooltip with file path, functions list, call count
- Stats bar showing total vs visible counts

## Investigation Trail
- First attempt reused Mermaid viewer approach — functional but static
- Switched to D3.js force-directed graph for true interactivity
- Node sizing by function count gives immediate visual sense of code distribution
- Color coding by file type instantly reveals frontend-vs-backend split
- Filter slider by min functions helps hide utility files and focus on core
- Tooltip on hover provides deep inspection without cluttering the view
- Limitation: cross-file edges are sparse due to graph extraction limits

## Comparison: 002a Mermaid vs 002b D3.js
| Aspect | Mermaid | D3.js Interactive |
|--------|---------|-------------------|
| Setup | Markdown + viewer.html | Standalone HTML |
| Interactivity | Tab switching | Drag, zoom, filter, hover |
| Learnability | Familiar (GitHub renders it) | Requires browser open |
| Detail density | Good for overview | Better for exploration |
| Maintenance | Static text file | JS code |

## Results
**Verdict: VALIDATED** — D3.js interactive explorer provides a superior exploration experience. The Mermaid version is better for embedding in documentation (GitHub-renderable). Best approach: use both — Mermaid for README/docs, D3 for interactive exploration.
