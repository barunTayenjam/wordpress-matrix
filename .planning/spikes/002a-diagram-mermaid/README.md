---
spike: 002a
name: diagram-mermaid
type: comparison
validates: "Given architecture JSON, when rendered as Mermaid flowchart, then the diagram is readable and shows component relationships at a glance"
verdict: VALIDATED
related: [001, 002b]
tags: [diagram, mermaid, visualization]
---

# Spike 002a: Mermaid Architecture Diagram

## What This Validates
Can we generate a usable architecture diagram from the architecture JSON using Mermaid syntax?

## Research
Mermaid.js supports `graph TB` flowcharts with subgraphs, styled nodes, and labeled edges. Two variants produced:
- **Full diagram** (`architecture-diagram.md`): All community clusters (top 10) with file dependencies
- **Code-only diagram** (`code-architecture.md`): Filtered to code files only (.js, .sh), grouped by frontend/backend

## How to Run
```
node .planning/spikes/002a-diagram-mermaid/generate-mermaid.js
node .planning/spikes/002a-diagram-mermaid/generate-mermaid-code.js
```
Then open `viewer.html` in a browser to render the Mermaid live.

## What to Expect
- Two .md files with ` ```mermaid ` blocks ready for GitHub/MkDocs rendering
- `viewer.html` renders both diagrams live using Mermaid.js CDN, plus a stats dashboard and file table

## Investigation Trail
- First attempt labeled all 10 community subgraphs — diagram was dominated by planning doc clusters
- Second attempt filtered for .js/.sh code files only, producing a cleaner architecture view
- The code-only view shows clear frontend (3 JS files, 80 funcs) / backend (9 Bash files, 85 funcs) split
- Cross-file dependency edges are sparse because the graph's `calls` edges are mostly intra-file
- Viewer.html added for interactive rendering via Mermaid.js CDN

## Results
**Verdict: VALIDATED** — Mermaid diagrams are effective for code-architecture views. The code-only filter is essential for a useful diagram. Full community view works but is noisy with planning docs.

Recommendation: Use the code-only variant as the default architecture diagram. Add the community view as a secondary reference.
