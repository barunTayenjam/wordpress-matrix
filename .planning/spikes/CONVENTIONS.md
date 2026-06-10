# Spike Conventions

Patterns and stack choices established across spike sessions. New spikes follow these unless the question requires otherwise.

## Stack
- **Runtime:** Node.js (project already uses Node.js for frontend)
- **Visualization:** Mermaid.js for docs-embedded diagrams; D3.js for interactive exploration
- **Data format:** JSON for intermediate data (architecture.json consumed by all downstream spikes)

## Structure
- Spike directories follow `.planning/spikes/NNN-name/` pattern
- Each spike has a `README.md` with YAML frontmatter
- Architecture pipeline: graph.json → extract-architecture.js → architecture.json → diagram/report generators
- Downstream spikes (visualization, reports) consume upstream spike output via relative paths

## Patterns
- **Deterministic extraction:** No LLM calls — all parsing is pure data transformation
- **Filtered views:** Code-only filters produce cleaner architecture diagrams than full-graph views
- **Dual visualization:** Mermaid for docs/README, D3.js for interactive exploration — both served from the same architecture JSON
- **File type color-coding:** JS = yellow, Bash = blue, PHP = purple, JSON = green, MD = gray

## Tools & Libraries
- Node.js built-in `fs` + `path` for all processing scripts (no npm dependencies needed)
- D3.js v7 (CDN) for interactive force-directed graphs
- Mermaid.js 10+ (CDN) for rendered diagrams
