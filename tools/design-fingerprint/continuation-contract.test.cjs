'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const read = file => {
  const target = path.join(root, file);
  return fs.readFileSync(fs.existsSync(target) ? target : path.join(root, '.claude', file), 'utf8');
};

test('entry skill restores an existing task before risk routing', () => {
  const skill = read('skills/ai-collab-start/SKILL.md');
  const restore = skill.indexOf('## 续作恢复优先');
  const channel = skill.indexOf('## 本轮通道');
  const workflow = skill.indexOf('## 工作流程（仅完整通道）');
  assert.ok(restore >= 0 && restore < channel);
  assert.ok(skill.indexOf('1. 续作候选先按“续作恢复优先”定位并读取快照') > workflow);
  assert.ok(skill.indexOf('2. 内部组 `task_card`') > skill.indexOf('1. 续作候选先按“续作恢复优先”定位并读取快照'));
  assert.match(skill, /没有唯一匹配时不得猜目录/);
  assert.match(skill, /不能因用户本轮用了“改\/合并\/修复”等动作词重置/);
});

test('entry and stage handoff keep unchanged continuation on its saved route', () => {
  const entry = read('skills/ai-collab-start/SKILL.md');
  const handoff = read('skills/write-plan/references/stage-handoff.md');
  const implementation = read('skills/implement-change/SKILL.md');
  const analysis = read('skills/analyze-requirement/SKILL.md');
  assert.match(entry, /范围、风险和授权没有变化时，沿用有效的风险确认和授权/);
  assert.match(entry, /旧指纹没有 `hash_version`/);
  assert.match(handoff, /续作优先恢复 `next\.skill`/);
  assert.match(implementation, /用户已明确授权当前范围时不因新一轮消息重复要求启动风险卡/);
  assert.match(analysis, /只有 `next\.skill=analyze-requirement` 或活跃访谈硬门控要求本 Skill 时才可执行/);
});

test('all downstream gates point to one versioned fingerprint implementation', () => {
  const files = [
    'skills/aggregate-design/SKILL.md',
    'skills/check-design/SKILL.md',
    'skills/design-solution/SKILL.md',
    'skills/implement-change/SKILL.md',
    'skills/verify-delivery/SKILL.md',
    'skills/write-plan/references/stage-handoff.md'
  ];
  for (const file of files) assert.match(read(file), /fingerprint-tool\.md/);
  assert.match(read('skills/aggregate-design/SKILL.md'), /design-sha256-v1/);
  assert.ok(fs.existsSync(path.join(root, 'tools/design-fingerprint/fingerprint.cjs')));
  for (const file of ['skills/check-design/SKILL.md', 'skills/aggregate-design/SKILL.md', 'skills/design-solution/SKILL.md', 'skills/implement-change/SKILL.md', 'skills/verify-delivery/SKILL.md'])
    assert.match(read(file), /快照的 `next\.skill`/);
});
