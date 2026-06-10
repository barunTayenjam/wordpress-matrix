const fs = require('fs');
const path = require('path');

const ARCH_JSON = path.resolve(__dirname, '../001-graph-to-arch-json/architecture.json');
const OUTPUT = path.resolve(__dirname, 'architecture-diagram.md');

const arch = JSON.parse(fs.readFileSync(ARCH_JSON, 'utf8'));

const lines = [];
lines.push('# Architecture Diagram');
lines.push('');
lines.push('```mermaid');
lines.push('graph TB');

// Subgraphs for top service communities (top 10)
const topServices = arch.services.slice(0, 10);
const assigned = new Set();

topServices.forEach((svc, idx) => {
  const sid = `S${idx}`;
  lines.push(`  subgraph ${sid}["Community ${svc.community} (${svc.nodeCount} nodes)"]`);
  svc.files.slice(0, 8).forEach(f => {
    const fid = `F${idx}_${f.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 30)}`;
    // Shorten long paths
    const label = f.length > 40 ? '...' + f.substring(f.length - 37) : f;
    lines.push(`    ${fid}["${label}"]`);
    assigned.add(f);
  });
  if (svc.files.length > 8) {
    lines.push(`    ${sid}_more["... +${svc.files.length - 8} more files"]`);
  }
  lines.push('  end');
});

// File-level dependency edges (top files with cross-file deps)
arch.files.forEach(f => {
  f.dependsOn.forEach(dep => {
    const fromId = f.file.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 40);
    const toId = dep.file.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 40);
    const label = dep.callCount > 1 ? `|${dep.callCount}|` : '';
    lines.push(`  ${fromId} -->${label} ${toId}`);
  });
});

// Top-level file nodes that aren't in community subgraphs
arch.files.slice(0, 20).forEach(f => {
  if (!assigned.has(f.file)) {
    const fid = f.file.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 40);
    const label = f.file.length > 50 ? '...' + f.file.substring(f.file.length - 47) : f.file;
    lines.push(`  ${fid}["${label}"]`);
  }
});

lines.push('```');
lines.push('');
lines.push('## File Statistics');
lines.push('');
lines.push('| File | Functions | Calls | Community |');
lines.push('|------|-----------|-------|-----------|');
arch.topFiles.forEach(f => {
  lines.push(`| ${f.file} | ${f.functions} | ${f.calls} | ${f.community} |`);
});

lines.push('');
lines.push('## Call Graph Summary');
lines.push(`- **Total call edges:** ${arch.callGraph.totalCallEdges}`);
lines.push(`- **Define edges:** ${arch.callGraph.totalDefineEdges}`);
lines.push(`- **Import edges:** ${arch.callGraph.totalImportEdges}`);
lines.push(`- **Files with functions/calls:** ${arch.files.length}`);
lines.push(`- **Total source files in graph:** ${arch.meta.totalFiles}`);

fs.writeFileSync(OUTPUT, lines.join('\n'));
console.log('Mermaid diagram written to', OUTPUT);
console.log('Diagram has', topServices.length, 'community subgraphs');
