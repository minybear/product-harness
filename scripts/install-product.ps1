param(
  [string] $Product = "",
  [string] $ProjectRoot = "",
  [string] $HubRoot,
  [string] $Repo,
  [string] $Ref = "main",
  [switch] $Force,
  [switch] $Backup,
  [switch] $SkipExisting,
  [switch] $UpdateClaude,
  [switch] $SkipEntryUpdate,
  [switch] $RewireOnly,
  [switch] $ScaffoldProduct,
  [switch] $NonInteractive
)

$ErrorActionPreference = "Stop"
$RemoteCheckoutRoot = $null

if ($env:OS -ne "Windows_NT") { throw "Host wiring currently requires Windows junctions." }

function Assert-SafeName {
  param([string] $Name)
  if ($Name -notmatch '^[a-z0-9][a-z0-9._-]*$' -or $Name.Contains('..')) {
    throw "Invalid asset or product name: $Name"
  }
}

if ((([int]$Force.IsPresent) + ([int]$Backup.IsPresent) + ([int]$SkipExisting.IsPresent)) -gt 1) {
  throw "Use only one of -SkipExisting, -Backup, or -Force."
}
if ($HubRoot -and $Repo) {
  throw "Use either -HubRoot or -Repo, not both."
}

$ProductId = $Product.Trim()
if ($ProductId) { Assert-SafeName $ProductId }
if (-not $ProjectRoot) {
  $ProjectRoot = (Get-Location).Path
}
$resolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

function Test-InteractiveYes {
  param([string] $Question)
  if ($ScaffoldProduct) { return $true }
  if ($RewireOnly) { return $false }
  $interactive = [Environment]::UserInteractive -and -not $NonInteractive
  if (-not $interactive) {
    Write-Host "[INFO] Non-interactive: skip generating adapter assets. Use -ScaffoldProduct to write kit + skeleton."
    return $false
  }
  $answer = Read-Host "$Question [y/N]"
  return ($answer -match '^[Yy]')
}

function Resolve-LocalHubRoot {
  if ($HubRoot) {
    return (Resolve-Path -LiteralPath $HubRoot).Path
  }
  if ($PSCommandPath) {
    $scriptDir = Split-Path -Parent $PSCommandPath
    return (Resolve-Path -LiteralPath (Join-Path $scriptDir "..")).Path
  }
  throw "Cannot resolve Hub root. Pass -HubRoot <path-to-hub>."
}

function Initialize-RemoteHub {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required for remote install, but it was not found in PATH."
  }
  $tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ai-collab-hub-" + [System.Guid]::NewGuid().ToString("N"))
  $script:RemoteCheckoutRoot = $tmpRoot
  git clone --filter=blob:none --sparse --branch $Ref $Repo $tmpRoot | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "Unable to clone Hub repository." }
  Push-Location $tmpRoot
  try {
    git sparse-checkout set common products skills rules adapters scripts tools | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Unable to select public Hub assets." }
  } finally {
    Pop-Location
  }
  return $tmpRoot
}

function Read-JsonFile {
  param([string] $Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Resolve-SkillSource {
  param(
    [string] $Hub,
    [string] $Name,
    [string] $ProductName
  )
  $candidates = @()
  if ($ProductName) {
    $candidates += (Join-Path $Hub "products\$ProductName\skills\$Name")
  }
  $candidates += (Join-Path $Hub "common\skills\$Name")
  $candidates += (Join-Path $Hub "skills\$Name")
  foreach ($item in $candidates) {
    if (Test-Path -LiteralPath (Join-Path $item "SKILL.md")) {
      return $item
    }
  }
  return $null
}

function Resolve-RuleSource {
  param(
    [string] $Hub,
    [string] $FileName,
    [string] $ProductName
  )
  $candidates = @()
  if ($ProductName) {
    $candidates += (Join-Path $Hub "products\$ProductName\rules\$FileName")
  }
  $candidates += (Join-Path $Hub "common\rules\$FileName")
  $candidates += (Join-Path $Hub "rules\$FileName")
  foreach ($item in $candidates) {
    if (Test-Path -LiteralPath $item) {
      return $item
    }
  }
  return $null
}

function Assert-WithinRoot {
  param([string] $Path, [string] $Root)
  $resolvedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
  $resolvedPath = [System.IO.Path]::GetFullPath($Path)
  if (-not ($resolvedPath -eq $resolvedRoot -or $resolvedPath.StartsWith($resolvedRoot + '\', [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "Refusing to modify path outside destination root: $resolvedPath"
  }
  $cursor = $resolvedPath
  while ($cursor) {
    if (Test-Path -LiteralPath $cursor) {
      if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        throw "Refusing to write through a junction or symlink: $cursor"
      }
    }
    $parent = Split-Path -Parent $cursor
    if ($parent -eq $cursor) { break }
    $cursor = $parent
  }
}

function Move-ToExternalBackup {
  param([string] $Path, [string] $InstallRoot)
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $backupRoot = ($InstallRoot.TrimEnd('\', '/') + "-backups")
  New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
  $stamp = Get-Date -Format "yyyyMMddHHmmssfff"
  $leaf = Split-Path -Leaf $Path
  $backupTarget = Join-Path $backupRoot "$leaf-$stamp"
  Assert-WithinRoot -Path $Path -Root $resolvedProjectRoot
  Assert-WithinRoot -Path $backupTarget -Root $resolvedProjectRoot
  Move-Item -LiteralPath $Path -Destination $backupTarget
  Write-Host "Backed up: $backupTarget"
}

function Install-CopiedItem {
  param(
    [string] $Source,
    [string] $Target,
    [string] $InstallRoot,
    [string] $Label
  )
  Assert-WithinRoot -Path $Target -Root $InstallRoot
  $parent = Split-Path -Parent $Target
  New-Item -ItemType Directory -Path $parent -Force | Out-Null
  if (Test-Path -LiteralPath $Target) {
    if ($SkipExisting) {
      Write-Host "Skip existing $Label : $Target"
      return
    }
    if ($Backup) {
      Move-ToExternalBackup -Path $Target -InstallRoot $InstallRoot
    } elseif ($Force) {
      Remove-Item -LiteralPath $Target -Recurse -Force
    } else {
      throw "Asset already exists: $Target. Use -Backup, -SkipExisting, or -Force."
    }
  }
  Copy-Item -LiteralPath $Source -Destination $Target -Recurse
  Write-Host "Installed $Label -> $Target"
}

function Install-SkillList {
  param(
    [string] $Hub,
    [string[]] $Names,
    [string] $ProductName
  )
  $root = Join-Path $resolvedProjectRoot ".claude\skills"
  New-Item -ItemType Directory -Path $root -Force | Out-Null
  foreach ($name in $Names) {
    Assert-SafeName $name
    $source = Resolve-SkillSource -Hub $Hub -Name $name -ProductName $ProductName
    if (-not $source) {
      throw "Skill not found in Hub: $name"
    }
    Install-CopiedItem -Source $source -Target (Join-Path $root $name) -InstallRoot $root -Label "skill $name"
  }
}

function Install-RuleList {
  param(
    [string] $Hub,
    [string[]] $Files,
    [string] $ProductName
  )
  $root = Join-Path $resolvedProjectRoot ".claude\rules"
  New-Item -ItemType Directory -Path $root -Force | Out-Null
  foreach ($file in $Files) {
    Assert-SafeName $file
    $source = Resolve-RuleSource -Hub $Hub -FileName $file -ProductName $ProductName
    if (-not $source) {
      throw "Rule not found in Hub: $file"
    }
    Install-CopiedItem -Source $source -Target (Join-Path $root $file) -InstallRoot $root -Label "rule $file"
  }
}

function Install-CursorAdapter {
  param([string] $Hub)
  $source = Join-Path $Hub "adapters\00-claude-entry.mdc"
  if (-not (Test-Path -LiteralPath $source)) {
    throw "Cursor adapter not found: $source"
  }
  $root = Join-Path $resolvedProjectRoot ".cursor\rules"
  New-Item -ItemType Directory -Path $root -Force | Out-Null
  $target = Join-Path $root "00-claude-entry.mdc"
  Install-CopiedItem -Source $source -Target $target -InstallRoot $root -Label "cursor adapter"
}

function New-DirectoryJunction {
  param([string] $Link, [string] $Target)
  $parent = Split-Path -Parent $Link
  Assert-WithinRoot -Path $parent -Root $resolvedProjectRoot
  New-Item -ItemType Directory -Path $parent -Force | Out-Null
  if (Test-Path -LiteralPath $Link) {
    $item = Get-Item -LiteralPath $Link -Force
    if ($item.Attributes -match "ReparsePoint") {
      $actualTarget = [System.IO.Path]::GetFullPath([string]@($item.Target)[0])
      if ($actualTarget.TrimEnd('\') -ne ([System.IO.Path]::GetFullPath($Target).TrimEnd('\'))) {
        throw "Existing junction points elsewhere: $Link"
      }
      Write-Host "[OK] junction exists: $Link"
      return
    }
    $children = @(Get-ChildItem -LiteralPath $Link -Force -ErrorAction SilentlyContinue)
    if ($children.Count -eq 0) {
      Remove-Item -LiteralPath $Link -Force
    } else {
      throw "Host skills path is a non-empty regular directory: $Link"
    }
  }
  New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
  Write-Host "[OK] created junction: $Link -> $Target"
}

function Install-HostWiring {
  $skills = Join-Path $resolvedProjectRoot ".claude\skills"
  if (-not (Test-Path -LiteralPath $skills)) {
    throw "Cannot wire hosts: $skills not found. Install common skills first."
  }
  New-DirectoryJunction -Link (Join-Path $resolvedProjectRoot ".cursor\skills") -Target $skills
  New-Item -ItemType Directory -Path (Join-Path $resolvedProjectRoot ".agents") -Force | Out-Null
  New-DirectoryJunction -Link (Join-Path $resolvedProjectRoot ".agents\skills") -Target $skills

  $gitignore = Join-Path $resolvedProjectRoot ".gitignore"
  $ignoreLines = @(".cursor/skills", ".agents/skills")
  if (Test-Path -LiteralPath $gitignore) {
    $existing = Get-Content -LiteralPath $gitignore -Encoding UTF8
    $toAppend = @()
    foreach ($line in $ignoreLines) {
      if ($existing -notcontains $line) { $toAppend += $line }
    }
    if ($toAppend.Count -gt 0) {
      Add-Content -LiteralPath $gitignore -Value ($toAppend -join [Environment]::NewLine) -Encoding UTF8
      Write-Host "[OK] updated .gitignore for host skill junctions"
    }
  } else {
    Set-Content -LiteralPath $gitignore -Value ($ignoreLines -join [Environment]::NewLine) -Encoding UTF8
    Write-Host "[OK] created .gitignore for host skill junctions"
  }

  Ensure-AgentsPointer
}

function Get-InstalledRuleFiles {
  $rulesDir = Join-Path $resolvedProjectRoot ".claude\rules"
  if (-not (Test-Path -LiteralPath $rulesDir)) { return @() }
  return @(Get-ChildItem -LiteralPath $rulesDir -File -Filter "*.md" | ForEach-Object { $_.Name })
}

function Get-AdapterKitText {
  param([string] $RelativePath)
  $candidates = @()
  if ($script:sourceHubRoot) {
    $candidates += (Join-Path $script:sourceHubRoot $RelativePath)
  }
  $scriptDir = if ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { $null }
  if ($scriptDir) {
    $candidates += (Join-Path $scriptDir "..\$RelativePath")
  }
  foreach ($item in $candidates) {
    if ($item -and (Test-Path -LiteralPath $item)) {
      return (Get-Content -LiteralPath $item -Raw -Encoding UTF8).TrimEnd()
    }
  }
  return $null
}

function Ensure-AgentsPointer {
  if ($SkipEntryUpdate) { return }
  $agentsMd = Join-Path $resolvedProjectRoot "AGENTS.md"
  Assert-WithinRoot -Path $agentsMd -Root $resolvedProjectRoot
  $startMarker = "<!-- ai-collab-hub:agents-pointer:start -->"
  $endMarker = "<!-- ai-collab-hub:agents-pointer:end -->"
  $body = Get-AdapterKitText -RelativePath "common\adapter-kit\entry\agents-pointer.md"
  if (-not $body) {
    $body = "Read CLAUDE.md first. Do not copy rules into AGENTS.md."
  }
  $pointer = $startMarker + [Environment]::NewLine + $body + [Environment]::NewLine + $endMarker
  if (-not (Test-Path -LiteralPath $agentsMd)) {
    Set-Content -LiteralPath $agentsMd -Value ($pointer + [Environment]::NewLine) -Encoding UTF8
    Write-Host "[OK] created AGENTS.md pointer"
    return
  }
  $content = Get-Content -LiteralPath $agentsMd -Raw -Encoding UTF8
  $pattern = "(?ms)" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker)
  if ([regex]::IsMatch($content, $pattern)) {
    $content = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $pointer })
  } else {
    $content = $pointer + [Environment]::NewLine + [Environment]::NewLine + $content.TrimStart()
  }
  Set-Content -LiteralPath $agentsMd -Value ($content.TrimEnd() + [Environment]::NewLine) -Encoding UTF8
  Write-Host "[OK] updated AGENTS.md pointer (existing notes kept)"
}

function Update-ClaudeRuleImports {
  param([string[]] $RuleFiles)
  if ($SkipEntryUpdate) { return }
  $files = @($RuleFiles | Where-Object { $_ })
  if (-not $files -or $files.Count -eq 0) {
    $files = Get-InstalledRuleFiles
  }
  if (-not $files -or $files.Count -eq 0) { return }
  $claudeFile = Join-Path $resolvedProjectRoot "CLAUDE.md"
  Assert-WithinRoot -Path $claudeFile -Root $resolvedProjectRoot
  $startMarker = "<!-- ai-collab-hub:capability:product-install:start -->"
  $endMarker = "<!-- ai-collab-hub:capability:product-install:end -->"
  $importLines = $files | ForEach-Object { "@./.claude/rules/" + $_ }
  $route = Get-AdapterKitText -RelativePath "common\adapter-kit\entry\claude-route.md"
  if (-not $route) {
    $route = "Canonical rules live in .claude/rules/. Skills live in .claude/skills/."
  }
  $block = (@($startMarker) + @($importLines) + @("") + @($route) + @($endMarker)) -join [Environment]::NewLine
  $content = if (Test-Path -LiteralPath $claudeFile) {
    Get-Content -LiteralPath $claudeFile -Raw -Encoding UTF8
  } else {
    "# CLAUDE.md" + [Environment]::NewLine
  }
  $pattern = "(?ms)" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker)
  if ([regex]::IsMatch($content, $pattern)) {
    $content = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $block })
  } else {
    $content = $block + [Environment]::NewLine + [Environment]::NewLine + $content.TrimStart()
  }
  Set-Content -LiteralPath $claudeFile -Value ($content.TrimEnd() + [Environment]::NewLine) -Encoding UTF8
  Write-Host "[OK] updated CLAUDE.md entry block (existing project notes kept)"
}

function Copy-AdapterKit {
  param([string] $Hub)
  $source = Join-Path $Hub "common\adapter-kit"
  if (-not (Test-Path -LiteralPath $source)) {
    throw "adapter-kit not found: $source"
  }
  $target = Join-Path $resolvedProjectRoot ".claude\adapter-kit"
  Assert-WithinRoot -Path $target -Root $resolvedProjectRoot
  $root = Join-Path $resolvedProjectRoot ".claude"
  New-Item -ItemType Directory -Path $root -Force | Out-Null
  if ((Test-Path -LiteralPath $target) -and -not $SkipExisting -and -not $Backup -and -not $Force) {
    Write-Host "[INFO] adapter-kit already present: $target"
    return
  }
  if ((Test-Path -LiteralPath $target) -and $Force) {
    Remove-Item -LiteralPath $target -Recurse -Force
  } elseif ((Test-Path -LiteralPath $target) -and $Backup) {
    Move-ToExternalBackup -Path $target -InstallRoot $root
  } elseif ((Test-Path -LiteralPath $target) -and $SkipExisting) {
    Write-Host "Skip existing adapter-kit: $target"
    return
  } elseif (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
  }
  Copy-Item -LiteralPath $source -Destination $target -Recurse
  Write-Host "Installed adapter-kit -> $target"
}

function Write-ProductSkeleton {
  param([string] $Hub, [string] $Id)
  $tpl = Join-Path $Hub "common\adapter-kit\product.yaml.tpl"
  if (-not (Test-Path -LiteralPath $tpl)) {
    throw "product.yaml.tpl not found: $tpl"
  }
  $dest = Join-Path $resolvedProjectRoot ".claude\product.yaml"
  Assert-WithinRoot -Path $dest -Root $resolvedProjectRoot
  if ((Test-Path -LiteralPath $dest) -and -not $Force -and -not $Backup) {
    if ($SkipExisting) {
      Write-Host "Skip existing product.yaml"
      return
    }
    Write-Host "[INFO] product.yaml exists, leave unchanged: $dest"
    return
  }
  $text = Get-Content -LiteralPath $tpl -Raw -Encoding UTF8
  $text = $text -replace 'product_id: ""', "product_id: `"$Id`""
  New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
  if ((Test-Path -LiteralPath $dest) -and $Backup) {
    Move-ToExternalBackup -Path $dest -InstallRoot (Join-Path $resolvedProjectRoot ".claude")
  }
  Set-Content -LiteralPath $dest -Value $text -Encoding UTF8
  Write-Host "Wrote product adapter skeleton -> $dest"
}

function Get-ProductPack {
  param([string] $Hub, [string] $Id)
  if (-not $Id) { return $null }
  $packPath = Join-Path $Hub "products\$Id\pack.json"
  $pack = Read-JsonFile -Path $packPath
  if (-not $pack) {
    return [pscustomobject]@{ id = $Id; status = "missing"; skills = @(); rules = @() }
  }
  return $pack
}

function Test-PackAvailable {
  param($Pack)
  if (-not $Pack) { return $false }
  $status = [string]$Pack.status
  if ($status -eq "missing") { return $false }
  $skillCount = @($Pack.skills).Count
  $ruleCount = @($Pack.rules).Count
  return ($skillCount -gt 0 -or $ruleCount -gt 0)
}

function Write-MissingPackPrompt {
  param([string] $Id)
  Write-Host ""
  Write-Host "Common layer installed. Host wiring done."
  Write-Host "No product pack on Hub for: $Id"
  Write-Host "The installer does not know which modules this repo has."
  Write-Host ""
  Write-Host "If you generate an adapter layer, the installer will only copy Hub instructions:"
  Write-Host "  .claude/adapter-kit/kit.yaml"
  Write-Host "  .claude/adapter-kit/product.yaml.tpl"
  Write-Host "  .claude/adapter-kit/module-skill/SKILL.md.tpl"
  Write-Host "  .claude/adapter-kit/product-rule.md.tpl"
  Write-Host "  .claude/adapter-kit/prompts/generate-product-adapter.md"
  Write-Host "  .claude/adapter-kit/prompts/generate-module-skill.md"
  Write-Host "  .claude/adapter-kit/prompts/generate-product-rules.md"
  Write-Host "Then Agent fills content. No module Skill paths are listed here."
}

try {
  foreach ($relative in @('.claude', '.cursor', '.agents', 'tools', '.gitignore', 'CLAUDE.md', 'AGENTS.md')) {
    Assert-WithinRoot -Path (Join-Path $resolvedProjectRoot $relative) -Root $resolvedProjectRoot
  }
  if ($RewireOnly) {
    if (-not $Repo) {
      try { $script:sourceHubRoot = Resolve-LocalHubRoot } catch { $script:sourceHubRoot = $null }
    }
    Install-HostWiring
    Update-ClaudeRuleImports -RuleFiles @(Get-InstalledRuleFiles)
    Write-Host "Rewire-only completed. Restart Cursor / Claude Code / Codex."
    return
  }

  $script:sourceHubRoot = if ($Repo) { Initialize-RemoteHub } else { Resolve-LocalHubRoot }
  $sourceHubRoot = $script:sourceHubRoot
  $commonPack = Read-JsonFile -Path (Join-Path $sourceHubRoot "common\pack.json")
  if (-not $commonPack) {
    throw "common/pack.json not found under Hub root: $sourceHubRoot"
  }

  # Validate all names and targets before copying any assets.
  $preflightPacks = @($commonPack)
  if ($ProductId) { $preflightPacks += (Get-ProductPack -Hub $sourceHubRoot -Id $ProductId) }
  foreach ($preflightPack in $preflightPacks) {
    foreach ($name in @($preflightPack.skills)) {
      Assert-SafeName $name
      Assert-WithinRoot -Path (Join-Path $resolvedProjectRoot ".claude\skills\$name") -Root $resolvedProjectRoot
    }
    foreach ($name in @($preflightPack.rules)) {
      Assert-SafeName $name
      Assert-WithinRoot -Path (Join-Path $resolvedProjectRoot ".claude\rules\$name") -Root $resolvedProjectRoot
    }
  }
  foreach ($file in @($commonPack.tools)) {
    if ($file -notmatch '^tools/design-fingerprint/[a-zA-Z0-9.-]+$' -or $file.Contains('..')) { throw "Invalid tool path: $file" }
    Assert-WithinRoot -Path (Join-Path $resolvedProjectRoot $file) -Root $resolvedProjectRoot
    if (-not (Test-Path -LiteralPath (Join-Path $sourceHubRoot $file) -PathType Leaf)) { throw "Tool missing: $file" }
  }

  Write-Host "Installing common layer (workflow + unit-test + code-review + collab/doc rules)."
  Install-SkillList -Hub $sourceHubRoot -Names @($commonPack.skills) -ProductName ""
  Install-RuleList -Hub $sourceHubRoot -Files @($commonPack.rules) -ProductName ""
  foreach ($file in @($commonPack.tools)) {
    Install-CopiedItem -Source (Join-Path $sourceHubRoot $file) -Target (Join-Path $resolvedProjectRoot $file) -InstallRoot (Join-Path $resolvedProjectRoot "tools\design-fingerprint") -Label "tool $file"
  }
  Write-Host "Fingerprint dependency: run npm ci --ignore-scripts in tools/design-fingerprint."
  Install-CursorAdapter -Hub $sourceHubRoot
  Install-HostWiring
  Update-ClaudeRuleImports -RuleFiles @($commonPack.rules)

  if (-not $ProductId) {
    Write-Host ""
    Write-Host "Done. Common-only install (no -Product)."
    Write-Host "Next: pass -Product <id> to add a product pack, or keep common-only."
    Write-Host "Restart Cursor / Claude Code / Codex."
    return
  }

  $pack = Get-ProductPack -Hub $sourceHubRoot -Id $ProductId
  if (Test-PackAvailable -Pack $pack) {
    Write-Host "Product pack available: $ProductId"
    Install-SkillList -Hub $sourceHubRoot -Names @($pack.skills) -ProductName $ProductId
    Install-RuleList -Hub $sourceHubRoot -Files @($pack.rules) -ProductName $ProductId
    $allRules = @($commonPack.rules) + @($pack.rules)
    Update-ClaudeRuleImports -RuleFiles $allRules
    Write-Host "Done. Common + product pack '$ProductId'."
    Write-Host "Restart Cursor / Claude Code / Codex."
    return
  }

  Write-MissingPackPrompt -Id $ProductId
  Copy-AdapterKit -Hub $sourceHubRoot

  if (Test-InteractiveYes -Question "Step 1/3 Generate product.yaml skeleton now?") {
    Write-ProductSkeleton -Hub $sourceHubRoot -Id $ProductId
    Write-Host "Ask Agent to read .claude/adapter-kit/prompts/generate-product-adapter.md"
  } else {
    Write-Host "Skipped product.yaml skeleton."
  }

  if (Test-InteractiveYes -Question "Step 2/3 Hand module-skill instructions to Agent? (no Skill folders created)") {
    Write-Host "Do not create module Skill directories yet."
    Write-Host "Ask Agent to read .claude/adapter-kit/prompts/generate-module-skill.md"
    Write-Host "Agent must scan this repo, propose a list, and wait for your confirmation."
  } else {
    Write-Host "Skipped module-skill generation instructions."
  }

  if (Test-InteractiveYes -Question "Step 3/3 Hand product-rule instructions to Agent?") {
    Write-Host "Ask Agent to read .claude/adapter-kit/prompts/generate-product-rules.md"
    Write-Host "Agent must propose rule files, then wait for your confirmation."
  } else {
    Write-Host "Skipped product-rule generation instructions."
  }

  Write-Host ""
  Write-Host "Done. Common installed; product pack '$ProductId' is missing on Hub."
  Write-Host "Full AI prompt: .claude/adapter-kit/prompts/install-with-ai.md"
  Write-Host "Restart Cursor / Claude Code / Codex."
} finally {
  if ($RemoteCheckoutRoot -and (Test-Path -LiteralPath $RemoteCheckoutRoot)) {
    Assert-WithinRoot -Path $RemoteCheckoutRoot -Root ([System.IO.Path]::GetTempPath())
    Remove-Item -LiteralPath $RemoteCheckoutRoot -Recurse -Force
  }
}
