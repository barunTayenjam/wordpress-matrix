# Spike Manifest

## Idea
Analyze the project's knowledge graph (982 nodes, 1172 edges) and produce an architectural diagram — extracting service/component relationships, call dependencies, and file-level structure into visual and report formats that a developer can use to understand the system.

## Requirements

- Must use the existing `.planning/graphs/graph.json` as the sole data source
- Must produce files in `.planning/spikes/` directory
- Architecture extraction must be deterministic (no LLM calls)
- Visual output must be viewable in a browser
- Must handle the full 982-node graph without crashing

## Spikes

| # | Name | Type | Validates | Verdict | Tags |
|---|------|------|-----------|---------|------|
| 001 | graph-to-arch-json | standard | Given graph.json, when parsed for architecture-relevant nodes, then produces structured architecture JSON | ✓ VALIDATED | graph, architecture, extraction |
| 002a | diagram-mermaid | comparison | Given arch JSON, when rendered as Mermaid flowchart, then readable with component relationships | ✓ BEST FOR DOCS | diagram, mermaid, visualization |
| 002b | diagram-interactive-html | comparison | Given arch JSON, when rendered as interactive HTML, then user can explore and filter | ✓ BEST FOR EXPLORATION | diagram, interactive, visualization |
| 003 | arch-report | standard | Given arch JSON, when formatted as markdown with tables, then developer understands system structure | ✓ VALIDATED | report, documentation |
