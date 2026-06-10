---
spike: 003
name: arch-report
type: standard
validates: "Given architecture JSON, when formatted as a markdown report with tables, then a developer can understand the system structure without opening the raw graph"
verdict: VALIDATED
related: [001]
tags: [report, documentation]
---

# Spike 003: Architecture Report

## What This Validates
Can the architecture data be presented as a human-readable markdown report that provides a complete system understanding without needing the raw graph or interactive tools?

## How to Run
```
node .planning/spikes/003-arch-report/generate-report.js
```

## What to Expect
- Produces `ARCHITECTURE-REPORT.md` with sections: System Overview, Top Files, Technology Split, File Dependencies, Community Clusters, File Type Distribution, Architecture Summary
- Tables are GitHub-renderable
- Developer can understand the system at a glance

## Investigation Trail
- Report is fully deterministic — no LLM calls
- Sourced entirely from spike 001's architecture JSON
- The Technology Split table clearly shows the frontend (80 funcs, 81 calls) vs backend (88 funcs, 164 calls) division
- Architecture summary captures the monorepo pattern: Bash CLI + Docker + Node.js frontend
- File dependencies section shows the call relationships between files

## Results
**Verdict: VALIDATED** — The report provides a complete, readable system overview. Best consumed alongside the Mermaid diagram (002a) which visualizes the same data. The report alone answers "what's in the system" but the interactive view (002b) answers "how do things connect."
