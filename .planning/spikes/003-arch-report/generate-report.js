const fs = require('fs');
const path = require('path');

const ARCH_JSON = path.resolve(__dirname, '../001-graph-to-arch-json/architecture.json');
const OUTPUT = path.resolve(__dirname, 'ARCHITECTURE-REPORT.md');

const arch = JSON.parse(fs.readFileSync(ARCH_JSON, 'utf8'));

const lines = [];
lines.push('# WordPress Matrix — Architecture Report');
lines.push('');
lines.push(`Generated from knowledge graph: ${arch.meta.totalNodes} nodes, ${arch.meta.totalEdges} edges, ${arch.meta.totalFiles} source files, ${arch.meta.totalCommunities} communities.`);
lines.push('');

// System overview
lines.push('## System Overview');
lines.push('');
lines.push('| Metric | Value |');
lines.push('|--------|-------|');
lines.push(`| Total source files in graph | ${arch.meta.totalFiles} |`);
lines.push(`| Files with functions/calls | ${arch.files.length} |`);
lines.push(`| Total function definitions | ${arch.callGraph.totalDefineEdges} |`);
lines.push(`| Total call edges | ${arch.callGraph.totalCallEdges} |`);
lines.push(`| Total import edges | ${arch.callGraph.totalImportEdges} |`);
lines.push(`| Community clusters | ${arch.services.length} (≥3 nodes)`);
lines.push('');

// Top files
lines.push('## Top Files by Function Count');
lines.push('');
lines.push('| # | File | Functions | Calls | Type | Community |');
lines.push('|---|------|-----------|-------|------|-----------|');
arch.topFiles.forEach((f, i) => {
  const ext = f.file.includes('.') ? f.file.split('.').pop() : 'sh';
  lines.push(`| ${i+1} | \`${f.file}\` | ${f.functions} | ${f.calls} | ${ext} | ${f.community} |`);
});
lines.push('');

// Frontend vs Backend split
const jsFiles = arch.files.filter(f => f.file.endsWith('.js'));
const shFiles = arch.files.filter(f => f.file.endsWith('.sh'));
const mdFiles = arch.files.filter(f => f.file.endsWith('.md'));
const otherFiles = arch.files.filter(f => !f.file.endsWith('.js') && !f.file.endsWith('.sh') && !f.file.endsWith('.md'));

lines.push('## Technology Split');
lines.push('');
lines.push('| Layer | Files | Functions | Calls |');
lines.push('|-------|-------|-----------|-------|');
lines.push(`| Frontend (JavaScript) | ${jsFiles.length} | ${jsFiles.reduce((s,f) => s + (f.functionCount||0), 0)} | ${jsFiles.reduce((s,f) => s + (f.callCount||0), 0)} |`);
lines.push(`| Backend (Bash) | ${shFiles.length} | ${shFiles.reduce((s,f) => s + (f.functionCount||0), 0)} | ${shFiles.reduce((s,f) => s + (f.callCount||0), 0)} |`);
lines.push(`| Documentation (Markdown) | ${mdFiles.length} | ${mdFiles.reduce((s,f) => s + (f.functionCount||0), 0)} | ${mdFiles.reduce((s,f) => s + (f.callCount||0), 0)} |`);
lines.push(`| Other | ${otherFiles.length} | ${otherFiles.reduce((s,f) => s + (f.functionCount||0), 0)} | ${otherFiles.reduce((s,f) => s + (f.callCount||0), 0)} |`);
lines.push('');

// Dependency matrix
lines.push('## File Dependencies');
lines.push('');
const withDeps = arch.files.filter(f => f.dependsOn.length > 0);
if (withDeps.length > 0) {
  lines.push('| Source | Dependency | Call Count |');
  lines.push('|--------|------------|------------|');
  withDeps.forEach(f => {
    f.dependsOn.forEach(d => {
      lines.push(`| \`${f.file}\` | \`${d.file}\` | ${d.callCount} |`);
    });
  });
} else {
  lines.push('No cross-file dependencies detected in the graph.');
}
lines.push('');

// Service communities
lines.push('## Community Clusters');
lines.push('');
lines.push('| Community | Node Count | File Count | Top Files |');
lines.push('|-----------|------------|------------|-----------|');
arch.services.slice(0, 15).forEach(s => {
  const topFiles = s.files.slice(0, 3).map(f => `\`${f.replace(/^.*[\\/]/, '')}\``).join(', ');
  lines.push(`| ${s.community} | ${s.nodeCount} | ${s.fileCount} | ${topFiles} |`);
});
lines.push('');

// File-type breakdown (all source files)
const extCounts = {};
arch.files.forEach(f => {
  const ext = f.file.includes('.') ? f.file.split('.').pop() : 'sh';
  extCounts[ext] = (extCounts[ext] || 0) + 1;
});
lines.push('## File Type Distribution');
lines.push('');
lines.push('| Type | Files |');
lines.push('|------|-------|');
Object.entries(extCounts).sort((a,b) => b[1]-a[1]).forEach(([ext, count]) => {
  lines.push(`| \`${ext}\` | ${count} |`);
});
lines.push('');

// Architecture summary
lines.push('## Architecture Summary');
lines.push('');
const totalJs = jsFiles.reduce((s,f) => s + (f.functionCount||0), 0);
const totalSh = shFiles.reduce((s,f) => s + (f.functionCount||0), 0);
lines.push(`- **Frontend:** ${jsFiles.length} JS files with ${totalJs} functions — all Express/Handlebars/Socket.IO`);
lines.push(`- **Backend:** ${shFiles.length} Bash scripts with ${totalSh} functions — the \`matrix\` CLI is the largest (50 functions)`);
lines.push(`- **Call activity:** ${arch.callGraph.totalCallEdges} total calls — frontend JS is call-heavy (76), matrix.sh is definition-heavy (50 funcs, 141 calls)`);
lines.push(`- **Architecture pattern:** Monorepo with a Bash CLI orchestrating Docker containers, managed via a Node.js frontend`);

fs.writeFileSync(OUTPUT, lines.join('\n'));
console.log('Architecture report written to', OUTPUT);
console.log('Report lines:', lines.length);
