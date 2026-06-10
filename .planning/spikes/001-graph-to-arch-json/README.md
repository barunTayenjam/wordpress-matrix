---
spike: 001
name: graph-to-arch-json
type: standard
validates: "Given the graph.json with 982 nodes & 1172 edges, when parsed for architecture-relevant nodes, then produces structured architecture JSON with services, dependencies, and call graphs"
verdict: VALIDATED
related: [002a, 002b, 003]
tags: [graph, architecture, extraction]
---

# Spike 001: Graph to Architecture JSON

## What This Validates
Can we extract clean architecture structure — files, functions, call graphs, service clusters — from the knowledge graph data alone, without LLM calls?

## How to Run
```
node .planning/spikes/001-graph-to-arch-json/extract-architecture.js
```

## What to Expect
- Produces `architecture.json` with sections: meta, files (with functions + dependencies), services (community clusters), callGraph stats, topFiles
- Files sorted by function count, dependencies sorted by call count

## Investigation Trail
- First run extracted 19 files with functions/calls from 69 total source files
- Cross-file dependencies are sparse (only 1 file has inter-file deps) because the graph's `calls` edges are mostly intra-file
- Community detection yields 82 clusters ≥3 nodes, but many are single-file
- Key finding: the graph is frontend-heavy in call edges (frontend/public/js/app.js = 76 calls) but the matrix.sh shim now contributes 141 calls

## Results
**Verdict: VALIDATED** — architecture extraction works reliably. Output is deterministic, complete, and usable as input for visualizations and reports.

Limitation: cross-file dependency detection is limited because the knowledge graph's `calls` edges are primarily intra-file. Real architecture diagrams may need post-processing to merge same-file calls into file-level dependency weights.
