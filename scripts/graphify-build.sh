#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Setting up graphify shims ==="

# Create shim for `matrix` (no extension → Bash)
MATRIX_SHIM="scripts/graphify-shim/matrix.sh"
if [ ! -L "$MATRIX_SHIM" ]; then
  ln -sf ../../matrix "$MATRIX_SHIM"
fi

echo "  shims ready: matrix.sh, docker-compose.md"

echo "=== Running graphify update ==="
graphify update .

echo "=== Copying artifacts ==="
mkdir -p .planning/graphs
cp graphify-out/graph.json .planning/graphs/graph.json
cp graphify-out/graph.html .planning/graphs/graph.html
cp graphify-out/GRAPH_REPORT.md .planning/graphs/GRAPH_REPORT.md

echo "=== Writing diff snapshot ==="
node "/Users/barun.tayenjam/.config/opencode/get-shit-done/bin/gsd-tools.cjs" graphify build snapshot

echo "=== Build summary ==="
node "/Users/barun.tayenjam/.config/opencode/get-shit-done/bin/gsd-tools.cjs" graphify status

echo "=== Done ==="
