param(
  [string] $HubRoot
)

# 在 AI Collab Hub 仓库内重建各宿主（Cursor / Codex）的「skill junction 目录」。
# 这些 junction 与 .claude/skills 一样是 gitignored 的本地链接（git 不携带目录 junction），
# 所以 clone 后需要运行本脚本重建，才能让仓库直接打开 Cursor / Codex 时读得到 skills。
# 规则引用（.cursor/rules/00-claude-entry.mdc、.agents/AGENTS.md）是已提交的入口指针，不在此重建。

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Resolve-LocalHubRoot {
  if ($HubRoot) {
    return (Resolve-Path -LiteralPath $HubRoot).Path
  }
  $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
  return (Resolve-Path -LiteralPath (Join-Path $scriptDir "..")).Path
}

$root = Resolve-LocalHubRoot
$skills = Join-Path $root "skills"
if (-not (Test-Path -LiteralPath $skills -PathType Container)) {
  throw "Skills directory not found: $skills"
}

foreach ($hostDir in @("claude", "cursor", "agents")) {
  $link = Join-Path $root ".$hostDir\skills"
  if (Test-Path -LiteralPath $link) {
    $attrs = (Get-Item -LiteralPath $link -Force).Attributes
    if ($attrs -match "ReparsePoint") {
      Write-Host "OK (already a junction): $link"
    } else {
      Write-Host "SKIP (exists, not a junction — leave as-is): $link"
    }
  } else {
    New-Item -ItemType Directory -Path (Split-Path -Parent $link) -Force | Out-Null
    New-Item -ItemType Junction -Path $link -Target $skills | Out-Null
    Write-Host "CREATED junction: $link -> $skills"
  }
}

Write-Host ""
Write-Host "Done. Restart Cursor / Codex to rescan skills. Rule references:"
Write-Host "  - Cursor : .cursor/rules/00-claude-entry.mdc (routes to CLAUDE.md)"
Write-Host "  - Codex  : .agents/AGENTS.md / 仓库根 AGENTS.md (routes to CLAUDE.md)"
