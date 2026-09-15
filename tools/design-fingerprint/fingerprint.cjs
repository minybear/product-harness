'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { TextDecoder } = require('node:util');
const VERSION = 'design-sha256-v1';
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
const pack = value => Buffer.from(JSON.stringify(value), 'utf8');
function demand(ok, message) { if (!ok) throw new Error(message); }
function text(bytes) {
  return new TextDecoder('utf-8', { fatal: true }).decode(bytes).replace(/\r\n?/g, '\n');
}
function digest(value) {
  demand(typeof value === 'string' && /^[a-f0-9]{64}$/i.test(value), 'invalid SHA-256');
  return value.toLowerCase();
}
function scalar(value, name) {
  demand(typeof value === 'string' && value.length > 0 && !/[\r\n\0]/.test(value), `invalid ${name}`);
  return value;
}
function relative(value) {
  scalar(value, 'path');
  demand(!value.includes('\\') && !value.includes(':') && !value.startsWith('/') &&
    value.split('/').every(part => part && part !== '.' && part !== '..'), 'path must be canonical repository-relative POSIX');
  return value;
}
function inside(root, name) {
  relative(name);
  const resolvedRoot = fs.realpathSync(root);
  const resolved = fs.realpathSync(path.resolve(root, name));
  const rel = path.relative(resolvedRoot, resolved);
  demand(rel && !rel.startsWith('..' + path.sep) && rel !== '..' && !path.isAbsolute(rel), 'path escapes repository');
  return resolved;
}
function sourcesHash(sources) {
  demand(Array.isArray(sources) && sources.length > 0, 'empty source set');
  const rows = sources.map(s => [relative(s.path), scalar(s.source_revision, 'source_revision'), digest(s.content_hash)]);
  rows.sort((a, b) => Buffer.compare(Buffer.from(a[0]), Buffer.from(b[0])));
  demand(new Set(rows.map(r => r[0])).size === rows.length, 'duplicate source path');
  return sha(pack([VERSION, 'sources', rows]));
}
// Only actual top-level numbered headings count; fenced examples are never boundaries.
function bodyOf(markdown) {
  const lines = markdown.split('\n');
  let fence = null;
  const headings = [];
  for (let i = 0; i < lines.length; i++) {
    const mark = lines[i].match(/^ {0,3}(`{3,}|~{3,})(.*)$/);
    if (mark) {
      if (!fence) fence = mark[1];
      else if (mark[1][0] === fence[0] && mark[1].length >= fence.length && !mark[2].trim()) fence = null;
      continue;
    }
    if (!fence) {
      const h = lines[i].match(/^## +(\d+)[.、．](?:\s|$)/);
      if (h) headings.push({ n: Number(h[1]), i });
    }
  }
  demand(!fence, 'unclosed fenced block');
  const selected = headings.filter(h => h.n !== 0);
  demand(selected.length === 11 && selected.every((h, i) => h.n === i + 1), 'expected exactly chapters 1..11 in order');
  const start = selected[0].i;
  demand(!headings.some(h => h.n === 0 && h.i > start), 'governance chapter after body');
  // Everything from chapter 1 to EOF is bound, including appendices and examples.
  return lines.slice(start).map(l => l.replace(/[\t ]+$/g, '')).join('\n').replace(/\n+$/g, '') + '\n';
}
function metadata(markdown) {
  const head = markdown.split(/^## /m)[0];
  const result = {};
  for (const key of ['task_id', 'artifact_revision', 'hash_version', 'artifact_hash', 'source_set_hash']) {
    const matches = [...head.matchAll(new RegExp('^' + key + '[：:]\\s*([^\\n]+?)\\s*$', 'gm'))];
    demand(matches.length <= 1, `duplicate metadata ${key}`);
    if (matches.length) result[key] = matches[0][1].trim();
  }
  return result;
}
function artifactHash(markdown, taskId, revision, sourceSetHash) {
  return sha(pack([VERSION, 'artifact', scalar(taskId, 'task_id'), scalar(revision, 'artifact_revision'),
    digest(sourceSetHash), bodyOf(markdown)]));
}
function yamlLibrary() {
  try { return require('yaml'); } catch (error) {
    throw new Error('Missing yaml dependency: run npm ci in tools/design-fingerprint');
  }
}
function snapshot(markdown) {
  const matches = [...markdown.matchAll(/^```ya?ml[^\n]*\n([\s\S]*?)^```\s*$/gm)]
    .filter(m => /^workflow_handoff:/m.test(m[1]));
  demand(matches.length === 1, 'expected exactly one workflow_handoff YAML block');
  const document = yamlLibrary().parseDocument(matches[0][1]);
  demand(document.errors.length === 0, `invalid snapshot YAML: ${document.errors.map(e => e.message).join('; ')}`);
  const state = document.toJSON().workflow_handoff;
  demand(state && typeof state === 'object' && !Array.isArray(state), 'invalid workflow_handoff');
  return state;
}
function calculate(root, state, taskId) {
  const inputs = state.design_baseline?.artifacts;
  demand(Array.isArray(inputs) && inputs.length, 'no published sources');
  const sources = inputs.map(s => ({ ...s, content_hash: sha(fs.readFileSync(inside(root, s.path))) }));
  const source_set_hash = sourcesHash(sources);
  const review = state.design_review || {};
  const bytes = fs.readFileSync(inside(root, review.artifact));
  const markdown = text(bytes);
  const meta = metadata(markdown);
  demand(meta.task_id === taskId, 'task_id differs between snapshot document and 03A');
  demand(meta.artifact_revision === String(review.artifact_revision), 'artifact_revision differs between snapshot and 03A');
  return { hash_version: VERSION, sources, source_set_hash,
    artifact_hash: artifactHash(markdown, taskId, meta.artifact_revision, source_set_hash),
    artifact_file_sha256: sha(bytes), meta };
}
function inspect(root, taskPath) {
  const markdown = text(fs.readFileSync(inside(root, taskPath)));
  const taskId = metadata(markdown).task_id;
  scalar(taskId, 'task_id');
  const state = snapshot(markdown);
  const review = state.design_review || {};
  const result = { task: taskPath, task_id: taskId, current_stage: state.current_stage,
    next_skill: state.next?.skill, declared: { ...review }, issues: [], hash_gate_pass: false };
  const inputs = state.design_baseline?.artifacts || [];
  if (!review.artifact) {
    result.status = state.design_baseline?.required || review.required ? 'missing-design-evidence' : 'not-applicable';
    if (result.status !== 'not-applicable') result.issues.push('required-design-missing');
    return result;
  }
  result.source_checks = inputs.map(s => {
    try {
      const current = sha(fs.readFileSync(inside(root, s.path)));
      return { path: s.path, recorded: s.content_hash, current,
        content_match: current === digest(s.content_hash),
        checked_match: s.check_status === 'pass' && s.checked_revision === s.source_revision && current === digest(s.checked_hash) };
    } catch (e) { return { path: s.path, error: e.message, content_match: false, checked_match: false }; }
  });
  if (result.source_checks.some(s => !s.content_match)) result.issues.push('source-content-mismatch-or-missing');
  if (result.source_checks.some(s => !s.checked_match)) result.issues.push('source-check-not-current');
  try { result.candidate = calculate(root, state, taskId); }
  catch (e) { result.issues.push('calculation-error: ' + e.message); }
  if (review.hash_version !== VERSION) {
    result.status = review.hash_version ? 'unsupported-hash-version' : 'legacy-unverifiable';
    result.action = 'Preserve original hashes and approval; recover historical algorithm/content or request scoped migration review. Do not restart requirements.';
    return result;
  }
  const c = result.candidate;
  if (c) {
    for (const key of ['source_set_hash', 'artifact_hash']) {
      try {
        if (digest(review[key]) !== c[key] || digest(c.meta[key]) !== c[key]) result.issues.push(key + '-mismatch');
      } catch (e) { result.issues.push(key + '-invalid'); }
    }
    if (c.meta.hash_version !== VERSION) result.issues.push('03A-hash-version-mismatch');
    if (review.status === 'approved') {
      try {
        if (digest(review.reviewed_hash) !== c.artifact_hash || digest(review.reviewed_source_set_hash) !== c.source_set_hash)
          result.issues.push('approval-binding-mismatch');
      } catch (e) { result.issues.push('approval-binding-invalid'); }
    }
  }
  const required = (state.workstreams || []).filter(w => state.design_baseline.required && w.design_required !== false).map(w => w.id);
  const covered = new Set(inputs.flatMap(s => Array.isArray(s.workstream_ids) ? s.workstream_ids : []));
  if (required.some(id => !covered.has(id))) result.issues.push('workstream-coverage-incomplete');
  result.hash_gate_pass = !!c && result.issues.length === 0;
  result.status = result.hash_gate_pass ? 'hash-match' : 'mismatch';
  // This is a fingerprint check only. Approval, decisions and scoped authorization remain separate gates.
  return result;
}
function walk(dir, name, found = []) {
  for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
    if (item.isSymbolicLink()) continue;
    const target = path.join(dir, item.name);
    if (item.isDirectory()) walk(target, name, found);
    else if (item.name === name) found.push(target);
  }
  return found;
}
function main(args) {
  const [command, rootArg, task] = args;
  demand(['audit', 'verify', 'calculate', 'file'].includes(command) && rootArg, 'Usage: node fingerprint.cjs audit ROOT | verify ROOT TASK_00 | calculate ROOT TASK_00 | file ROOT PATH');
  const root = path.resolve(rootArg);
  if (command === 'audit') {
    const tasks = walk(path.join(root, 'docs'), '00-需求概览.md').filter(p => p.split(path.sep).includes('tasks'));
    const report = tasks.sort().map(p => {
      const name = path.relative(root, p).split(path.sep).join('/');
      try { return inspect(root, name); } catch (e) { return { task: name, status: 'parse-error', error: e.message, hash_gate_pass: false }; }
    });
    console.log(JSON.stringify({ tool_version: VERSION, tasks: report }, null, 2));
    process.exitCode = report.some(r => !['hash-match', 'not-applicable'].includes(r.status)) ? 2 : 0;
  } else if (command === 'verify') {
    const result = inspect(root, task);
    console.log(JSON.stringify(result, null, 2));
    process.exitCode = result.hash_gate_pass ? 0 : 2;
  } else if (command === 'calculate') {
    const md = text(fs.readFileSync(inside(root, task)));
    console.log(JSON.stringify(calculate(root, snapshot(md), metadata(md).task_id), null, 2));
  } else {
    const bytes = fs.readFileSync(inside(root, task));
    console.log(JSON.stringify({ tool_version: VERSION, path: task, content_hash: sha(bytes) }, null, 2));
  }
}
module.exports = { VERSION, sha, pack, text, sourcesHash, bodyOf, metadata, artifactHash, snapshot, calculate, inspect, inside };
if (require.main === module) {
  try { main(process.argv.slice(2)); } catch (e) { console.error(e.message); process.exitCode = 2; }
}
