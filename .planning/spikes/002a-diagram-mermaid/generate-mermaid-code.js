const fs = require('fs');
const path = require('path');

const ARCH_JSON = path.resolve(__dirname, '../001-graph-to-arch-json/architecture.json');
const OUTPUT = path.resolve(__dirname, 'code-architecture.md');

const arch = JSON.parse(fs.readFileSync(ARCH_JSON, 'utf8'));

const isCodeFile = (f) => {
  const codeExts = ['.js', '.sh', '.php', '.json', '.yml', '.yaml'];
  const exclude = ['.md'];
  const ext = f.includes('.') ? '.' + f.split('.').pop() : '';
  if (exclude.includes(ext) && !ext.includes('json')) return false;
  if (ext === '.json' && (f.includes('.planning') || f.includes('composer'))) return false;
  return codeExts.includes(ext) || f === 'matrix' || (!ext && f !== 'unknown');
};

const codeFiles = arch.files.filter(f => isCodeFile(f.file));
const topCode = codeFiles.slice(0, 25);

const lines = [];
lines.push('# Code Architecture Diagram');
lines.push('');
lines.push('Shows only code/source files (`.js`, `.sh`) — excludes planning docs and markdown.');
lines.push('');
lines.push('```mermaid');
lines.push('graph TB');

// Code files grouped by type
lines.push('  subgraph FRONTEND["Frontend (JavaScript)"]');
let feCount = 0;
topCode.filter(f => f.file.endsWith('.js')).forEach(f => {
  const fid = `FE${feCount++}`;
  const label = f.file.replace('frontend/', '');
    const meta = `${f.functionCount} funcs, ${f.callCount} calls`;
  lines.push(`    ${fid}["${label}"]`);
  lines.push(`    ${fid}_meta["${meta}"]`);
  lines.push(`    style ${fid}_meta fill:#e0e0e0,stroke:#999`);
});
lines.push('  end');

lines.push('  subgraph BACKEND["Backend (Bash Scripts)"]');
let beCount = 0;
topCode.filter(f => f.file.endsWith('.sh')).forEach(f => {
  const fid = `BE${beCount++}`;
  const label = f.file.startsWith('scripts/graphify-shim/') ? f.file.replace('scripts/graphify-shim/', '') : f.file;
    const meta = `${f.functionCount} funcs, ${f.callCount} calls`;
  lines.push(`    ${fid}["${label}"]`);
  lines.push(`    ${fid}_meta["${meta}"]`);
  lines.push(`    style ${fid}_meta fill:#e0e0e0,stroke:#999`);
});
lines.push('  end');

// File dependencies between code files (filtered)
codeFiles.forEach(f => {
  f.dependsOn.forEach(dep => {
    if (isCodeFile(dep.file)) {
      const fromLabel = f.file.replace(/^.*\//, '');
      const toLabel = dep.file.replace(/^.*\//, '');
      const weight = dep.callCount > 1 ? `|${dep.callCount}|` : '';
      lines.push(`  ${fromLabel}_${toLabel}["${fromLabel} → ${toLabel}"]`);
      lines.push(`  style ${fromLabel}_${toLabel} fill:#fff,stroke:#999,stroke-dasharray:4`);
    }
  });
});

// Cross-file call edges
const edgePairs = {};
arch.files.forEach(f => {
  f.dependsOn.forEach(dep => {
    if (isCodeFile(dep.file) && f.file !== dep.file) {
      const key = `${f.file}|${dep.file}`;
      edgePairs[key] = (edgePairs[key] || 0) + dep.callCount;
    }
  });
});
Object.entries(edgePairs).forEach(([key, count]) => {
  const [from, to] = key.split('|');
  const fromShort = from.replace(/^.*[\/\\]/, '');
  const toShort = to.replace(/^.*[\/\\]/, '');
  const label = count > 1 ? `|${count} calls|` : '';
  lines.push(`  ${fromShort} -->${label} ${toShort}`);
});

lines.push('```');
lines.push('');
lines.push('## Code File Summary');
lines.push('');
lines.push('| File | Functions | Calls | Community |');
lines.push('|------|-----------|-------|-----------|');
topCode.forEach(f => {
  lines.push(`| ${f.file} | ${f.functions} | ${f.calls} | ${f.community} |`);
});

fs.writeFileSync(OUTPUT, lines.join('\n'));
console.log('Code architecture Mermaid written to', OUTPUT);
console.log('Code files rendered:', topCode.length);
