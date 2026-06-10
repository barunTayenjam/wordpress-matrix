const fs = require('fs');
const path = require('path');

const GRAPH_PATH = path.resolve(__dirname, '../../../.planning/graphs/graph.json');
const OUTPUT_PATH = path.resolve(__dirname, 'architecture.json');

const raw = JSON.parse(fs.readFileSync(GRAPH_PATH, 'utf8'));
const { nodes, links } = raw;

// Build lookup maps
const nodeMap = {};
nodes.forEach(n => { nodeMap[n.id] = n; });

// Build adjacency
const outgoing = {};
const incoming = {};
links.forEach(l => {
  if (l.relation === 'calls' || l.relation === 'defines' || l.relation === 'imports' || l.relation === 'imports_from') {
    (outgoing[l.source] = outgoing[l.source] || []).push(l);
    (incoming[l.target] = incoming[l.target] || []).push(l);
  }
});

// Group nodes by source file
const files = {};
nodes.forEach(n => {
  const sf = n.source_file || 'unknown';
  if (!files[sf]) {
    files[sf] = {
      file: sf,
      ext: sf.includes('.') ? sf.split('.').pop() : 'no-ext',
      community: n.community,
      functions: [],
      calls: [],
      defines: [],
      totalNodes: 0,
    };
  }
  files[sf].totalNodes++;
  if (n.label && n.label.includes('()')) {
    const funcName = n.label.replace(/\(\)$/, '');
    files[sf].functions.push({
      name: funcName,
      id: n.id,
      calls: (outgoing[n.id] || [])
        .filter(l => l.relation === 'calls')
        .map(l => {
          const target = nodeMap[l.target];
          return {
            target: target ? (target.label || target.id) : l.target,
            targetFile: target ? target.source_file : 'unknown',
          };
        }),
      calledBy: (incoming[n.id] || [])
        .filter(l => l.relation === 'calls')
        .map(l => {
          const source = nodeMap[l.source];
          return {
            caller: source ? (source.label || source.id) : l.source,
            callerFile: source ? source.source_file : 'unknown',
          };
        }),
    });
  }
  if (outgoing[n.id]) {
    outgoing[n.id].forEach(l => {
      if (l.relation === 'calls') {
        const target = nodeMap[l.target];
        files[sf].calls.push({
          from: n.label || n.id,
          to: target ? (target.label || target.id) : l.target,
          toFile: target ? target.source_file : 'unknown',
        });
      }
    });
  }
});

// File dependency matrix (which files call which)
const fileDeps = {};
Object.entries(files).forEach(([file, info]) => {
  info.calls.forEach(call => {
    if (call.toFile && call.toFile !== file) {
      if (!fileDeps[file]) fileDeps[file] = {};
      fileDeps[file][call.toFile] = (fileDeps[file][call.toFile] || 0) + 1;
    }
  });
});

// Community-based service clusters
const communities = {};
nodes.forEach(n => {
  const c = n.community;
  if (c === undefined || c === null) return;
  if (!communities[c]) communities[c] = { community: c, files: new Set(), nodes: 0 };
  communities[c].nodes++;
  if (n.source_file) communities[c].files.add(n.source_file);
});

const architecture = {
  meta: {
    totalNodes: nodes.length,
    totalEdges: links.length,
    totalFiles: Object.keys(files).length,
    totalCommunities: Object.keys(communities).length,
    generatedAt: new Date().toISOString(),
  },
  files: Object.entries(files)
    .filter(([_, info]) => info.functions.length > 0 || info.calls.length > 0)
    .map(([file, info]) => ({
      file,
      ext: info.ext,
      community: info.community,
      functionCount: info.functions.length,
      callCount: info.calls.length,
      functions: info.functions,
      dependsOn: fileDeps[file]
        ? Object.entries(fileDeps[file])
            .sort((a, b) => b[1] - a[1])
            .map(([depFile, count]) => ({ file: depFile, callCount: count }))
        : [],
    }))
    .sort((a, b) => b.functionCount - a.functionCount),
  services: Object.entries(communities)
    .filter(([_, info]) => info.nodes >= 3)
    .map(([id, info]) => ({
      community: Number(id),
      nodeCount: info.nodes,
      fileCount: info.files.size,
      files: [...info.files].sort(),
    }))
    .sort((a, b) => b.nodeCount - a.nodeCount),
  callGraph: {
    totalCallEdges: links.filter(l => l.relation === 'calls').length,
    totalDefineEdges: links.filter(l => l.relation === 'defines').length,
    totalImportEdges: links.filter(l => l.relation === 'imports' || l.relation === 'imports_from').length,
  },
  topFiles: Object.entries(files)
    .sort((a, b) => b[1].functions.length - a[1].functions.length)
    .slice(0, 15)
    .map(([file, info]) => ({
      file,
      functions: info.functions.length,
      calls: info.calls.length,
      community: info.community,
    })),
};

fs.writeFileSync(OUTPUT_PATH, JSON.stringify(architecture, null, 2));
console.log('Architecture JSON written to', OUTPUT_PATH);
console.log('Files with functions/calls:', architecture.files.length);
console.log('Communities (≥3 nodes):', architecture.services.length);
console.log('Top file:', architecture.topFiles[0]?.file);
