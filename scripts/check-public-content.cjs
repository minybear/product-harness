'use strict';
// Optional private terms stay in the caller's environment, outside the public tree.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const yaml = require('../tools/design-fingerprint/node_modules/yaml');
const extra = JSON.parse(process.env.PUBLIC_FORBIDDEN_TERMS || '[]');
const failures = [];
const files = [];
const fail = (file, reason) => failures.push(`${file}: ${reason}`);
function walk(dir) {
  for (const entry of fs.readdirSync(dir, {withFileTypes:true})) {
    if (['.git', 'node_modules'].includes(entry.name)) continue;
    const absolute = path.join(dir, entry.name);
    const relative = path.relative(root, absolute).replaceAll('\\', '/');
    if (entry.isSymbolicLink()) {
      if (!['.claude/skills', '.cursor/skills', '.agents/skills'].includes(relative)) fail(relative, 'unexpected symbolic link');
      continue;
    }
    if (entry.isDirectory()) walk(absolute);
    else if (entry.isFile()) files.push(relative);
  }
}
walk(root);
const pack = JSON.parse(fs.readFileSync(path.join(root, 'common/pack.json'), 'utf8'));
const exists = name => fs.existsSync(path.join(root, name));
for (const skill of pack.skills) {
  if (!/^[a-z][a-z0-9-]*$/.test(skill) || !exists(`skills/${skill}/SKILL.md`)) fail('common/pack.json', 'invalid or missing skill');
}
for (const name of [...pack.rules.map(x => `rules/${x}`), ...pack.tools, pack.adapter]) {
  if (!exists(name)) fail('common/pack.json', `missing asset ${name}`);
}
const actualSkills = fs.readdirSync(path.join(root, 'skills')).filter(x => fs.statSync(path.join(root, 'skills', x)).isDirectory()).sort();
if (JSON.stringify(actualSkills) !== JSON.stringify([...pack.skills].sort())) fail('skills', 'skill directories differ from public pack');
if (JSON.stringify(fs.readdirSync(path.join(root, 'rules')).sort()) !== JSON.stringify([...pack.rules].sort())) fail('rules', 'rule files differ from public pack');
for (const file of files) {
  if (/(^|\/)(?:\.env(?:\..*)?|credentials\.json|secrets\.[^/]+)$|\.(?:pem|key|p12|pfx|jks|keystore)$/i.test(file) && !file.endsWith('.env.example')) fail(file, 'credential-like filename');
  if (/(^|\/)(?:backups|\.codex-staging|skills-backups|rules-backups)(\/|$)/.test(file)) fail(file, 'private working artifact');
  const bytes = fs.readFileSync(path.join(root, file));
  if (bytes.includes(0)) { fail(file, 'unexpected binary'); continue; }
  const text = bytes.toString('utf8');
  for (const term of extra) if (text.toLowerCase().includes(String(term).toLowerCase()) || file.toLowerCase().includes(String(term).toLowerCase())) fail(file, 'private term detected');
  if (file !== 'scripts/check-public-content.cjs') {
    if (/(?:[A-Z]:[\\/](?:Users|home|work|projects)[\\/]|https?:\/\/(?:10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(?:1[6-9]|2\d|3[01])\.\d+\.\d+))/i.test(text)) fail(file, 'machine path or private network URL');
    if (/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|\b(?:AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|sk-[A-Za-z0-9]{32,})\b/.test(text)) fail(file, 'credential pattern');
    if (/(?:password|api_key|client_secret)\s*[:=]\s*["'][A-Za-z0-9+/=_-]{12,}["']/i.test(text)) fail(file, 'possible hardcoded credential');
  }
  if (file.endsWith('SKILL.md')) {
    const match = text.match(/^---\n([\s\S]*?)\n---/);
    if (!match) { fail(file, 'missing frontmatter'); continue; }
    const doc = yaml.parseDocument(match[1]);
    if (doc.errors.length) fail(file, 'invalid frontmatter');
    else {
      const meta = doc.toJSON();
      if (meta.name !== file.split('/')[1] || !meta.version || !meta.description) fail(file, 'invalid skill metadata');
    }
  }
  if (/\.(?:json|yaml|yml)$/.test(file) || file.endsWith('.yaml.tpl')) {
    try {
      if (file.endsWith('.json')) JSON.parse(text);
      else if (yaml.parseDocument(text).errors.length) fail(file, 'invalid YAML');
    } catch { fail(file, 'invalid structured document'); }
  }
  if (file.endsWith('.md')) {
    const prose = text.replace(/^```[^\n]*\n[\s\S]*?^```/gm, '');
    for (const m of prose.matchAll(/\[[^\]\n]*\]\(([^)\n]+)\)/g)) {
      const link = m[1].split('#')[0];
      if (!link || /^(?:https?:|mailto:|#)/.test(link) || /[{}<>]/.test(link)) continue;
      if (!fs.existsSync(path.resolve(root, path.dirname(file), decodeURIComponent(link)))) fail(file, `broken link ${link}`);
    }
  }
}
if (failures.length) {
  for (const item of failures) console.error(item);
  process.exitCode = 1;
} else console.log(`PUBLIC_CONTENT_CHECK_PASSED: ${files.length} files, ${pack.skills.length} skills, ${pack.rules.length} rules`);
