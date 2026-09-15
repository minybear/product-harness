'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const f = require('./fingerprint.cjs');
const body = Array.from({ length: 11 }, (_, i) => `## ${i + 1}. 章节\n内容 ${i + 1}\n`).join('\n');
const source = { path: 'docs/source.md', source_revision: 'r1', content_hash: f.sha('abc') };
test('SHA-256 published abc vector and fixed serialization', () => {
  assert.equal(f.sha('abc'), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  const expected = '["design-sha256-v1","sources",[["docs/source.md","r1","ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"]]]';
  assert.equal(f.sourcesHash([source]), f.sha(Buffer.from(expected, 'utf8')));
});
test('source order and hex case are stable; revision/content changes are detected', () => {
  const second = { ...source, path: 'docs/中文.md' };
  assert.equal(f.sourcesHash([source, second]), f.sourcesHash([second, { ...source, content_hash: source.content_hash.toUpperCase() }]));
  assert.notEqual(f.sourcesHash([source]), f.sourcesHash([{ ...source, source_revision: 'r2' }]));
  assert.notEqual(f.sourcesHash([source]), f.sourcesHash([{ ...source, content_hash: f.sha('abcd') }]));
});
test('reject duplicate, noncanonical, escaped paths and malformed digest', () => {
  for (const p of ['../a', '/a', 'C:/a', 'a\\b', 'a//b', 'a/./b']) assert.throws(() => f.sourcesHash([{ ...source, path: p }]));
  assert.throws(() => f.sourcesHash([source, source]));
  assert.throws(() => f.sourcesHash([{ ...source, content_hash: 'abc' }]));
});
test('artifact BOM, CRLF, trailing space and terminal blank lines normalize identically', () => {
  const crlf = Buffer.from('\ufeff' + body.replace(/\n/g, '  \r\n') + '\r\n');
  assert.equal(f.bodyOf(f.text(crlf)), f.bodyOf(body));
  assert.throws(() => f.text(Buffer.from([0xff])));
});
test('governance excluded; implementation, task, revision, sources and appendices bound', () => {
  const hash = (b, id = 'TASK', r = '1', s = f.sourcesHash([source])) => f.artifactHash(b, id, r, s);
  assert.equal(hash('## 0. 治理\nreviewed_hash: old\n' + body), hash('## 0. 治理\nreviewed_hash: new\n' + body));
  assert.notEqual(hash(body), hash(body.replace('内容 2', '变更')));
  assert.notEqual(hash(body), hash(body + '\n附录修改'));
  assert.notEqual(hash(body), hash(body, 'OTHER'));
  assert.notEqual(hash(body), hash(body, 'TASK', '2'));
  assert.notEqual(hash(body), hash(body, 'TASK', '1', f.sha('other')));
  assert.notEqual(hash(body), hash(body + '\nreviewed_hash: this is body text'));
});
test('chapter parser ignores fenced headings and rejects missing/duplicate/reordered chapters', () => {
  assert.doesNotThrow(() => f.bodyOf(body.replace('内容 1\n', '```md\n## 1. 示例\n```\n')));
  for (const bad of [body.replace('## 5.', '## 6.'), body.replace('## 5.', '### 5.'), body + '\n## 1. 重复', body + '\n```'])
    assert.throws(() => f.bodyOf(bad));
});
test('snapshot rejects duplicate keys and multiple state blocks', () => {
  assert.throws(() => f.snapshot('```yaml\nworkflow_handoff:\n  status: ready\n  status: completed\n```'));
  assert.throws(() => f.snapshot('```yaml\nworkflow_handoff: {}\n```\n```yaml\nworkflow_handoff: {}\n```'));
});
function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'design-fingerprint-test-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, 'docs'));
  fs.writeFileSync(path.join(root, source.path), 'abc');
  const sourceSet = f.sourcesHash([source]);
  const artifact = f.artifactHash(body, 'TASK', '1', sourceSet);
  const review = { status: 'approved', hash_version: f.VERSION, artifact: 'docs/03A.md', artifact_revision: '1',
    artifact_hash: artifact, source_set_hash: sourceSet, reviewed_hash: artifact, reviewed_source_set_hash: sourceSet };
  const state = { current_stage: 'implementation', next: { skill: 'implement-change' },
    design_baseline: { required: true, artifacts: [{ ...source, check_status: 'pass', checked_revision: 'r1', checked_hash: source.content_hash, workstream_ids: ['one'] }] },
    design_review: review, workstreams: [{ id: 'one' }], execution_authorization: { status: 'granted', scope: ['one'] } };
  const artifactMd = `task_id: TASK\nartifact_revision: 1\nhash_version: ${f.VERSION}\nartifact_hash: ${artifact}\nsource_set_hash: ${sourceSet}\n\n` + body;
  fs.writeFileSync(path.join(root, 'docs/03A.md'), artifactMd);
  const save = () => fs.writeFileSync(path.join(root, 'docs/00.md'), 'task_id: TASK\n```yaml\nworkflow_handoff: ' + JSON.stringify(state) + '\n```\n');
  save();
  return { root, state, save, run: () => f.inspect(root, 'docs/00.md') };
}
test('unchanged approved continuation preserves next skill and authorization; checker is read-only', t => {
  const x = fixture(t);
  const before = fs.readFileSync(path.join(x.root, 'docs/00.md'));
  assert.equal(x.run().hash_gate_pass, true);
  assert.equal(x.run().next_skill, 'implement-change');
  assert.deepEqual(fs.readFileSync(path.join(x.root, 'docs/00.md')), before);
  assert.equal(x.state.execution_authorization.status, 'granted');
});
test('legacy and unknown version never pass or overwrite old approval', t => {
  const x = fixture(t);
  delete x.state.design_review.hash_version;
  x.save();
  assert.equal(x.run().status, 'legacy-unverifiable');
  assert.equal(x.run().hash_gate_pass, false);
  x.state.design_review.hash_version = 'unknown'; x.save();
  assert.equal(x.run().status, 'unsupported-hash-version');
});
test('body/source mutations, missing approval and coverage each fail closed', t => {
  const x = fixture(t);
  x.state.design_review.reviewed_hash = ''; x.save();
  assert.equal(x.run().hash_gate_pass, false);
  x.state.design_review.reviewed_hash = x.state.design_review.artifact_hash;
  x.state.workstreams.push({ id: 'missing' }); x.save();
  assert.ok(x.run().issues.includes('workstream-coverage-incomplete'));
  x.state.workstreams.pop(); x.save();
  fs.appendFileSync(path.join(x.root, 'docs/03A.md'), '\n新契约');
  assert.ok(x.run().issues.includes('artifact_hash-mismatch'));
  fs.writeFileSync(path.join(x.root, source.path), 'changed');
  assert.ok(x.run().issues.includes('source-content-mismatch-or-missing'));
});
