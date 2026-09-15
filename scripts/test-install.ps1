param([string] $HubRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ('public-hub-test-' + [guid]::NewGuid().ToString('N'))
$installer = Join-Path $HubRoot 'scripts/install-product.ps1'
$checks = 0
function Assert-Test([bool] $Condition, [string] $Message) {
  if (-not $Condition) { throw "ASSERT FAILED: $Message" }
  $script:checks++
}
function Assert-Fails([scriptblock] $Action, [string] $Message) {
  $failed = $false
  try { & $Action | Out-Null } catch { $failed = $true }
  Assert-Test $failed $Message
}
function New-Project([string] $Name) {
  $dest = Join-Path $sandbox $Name
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  return $dest
}
function Invoke-Install([string] $Dest, [hashtable] $Extra = @{}) {
  & $installer -HubRoot $HubRoot -ProjectRoot $Dest -NonInteractive @Extra | Out-Null
}
function Remove-TestTree([string] $Directory) {
  # Remove junction entries first so recursive cleanup cannot traverse their targets.
  $absolute = [System.IO.Path]::GetFullPath($Directory)
  $safeRoot = [System.IO.Path]::GetFullPath($sandbox)
  if ($absolute -ne $safeRoot -and -not $absolute.StartsWith($safeRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe cleanup target' }
  foreach ($entry in Get-ChildItem -LiteralPath $Directory -Force) {
    if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { [IO.Directory]::Delete($entry.FullName) }
    elseif ($entry.PSIsContainer) { Remove-TestTree $entry.FullName }
    else { Remove-Item -LiteralPath $entry.FullName -Force }
  }
  Remove-Item -LiteralPath $Directory -Force
}
try {
  $project = New-Project 'common'
  Set-Content -LiteralPath (Join-Path $project 'CLAUDE.md') -Value '# Existing project notes' -Encoding UTF8
  Set-Content -LiteralPath (Join-Path $project 'AGENTS.md') -Value '# Existing agent notes' -Encoding UTF8
  Invoke-Install $project
  $pack = Get-Content -LiteralPath (Join-Path $HubRoot 'common/pack.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-Test ((Get-ChildItem (Join-Path $project '.claude/skills') -Directory).Count -eq $pack.skills.Count) 'common skills installed'
  Assert-Test ((Get-ChildItem (Join-Path $project '.claude/rules') -File).Count -eq $pack.rules.Count) 'common rules installed'
  foreach ($file in $pack.tools) {
    Assert-Test ((Get-FileHash (Join-Path $project $file)).Hash -eq (Get-FileHash (Join-Path $HubRoot $file)).Hash) "tool copied: $file"
  }
  Assert-Test ((Get-Content (Join-Path $project 'CLAUDE.md') -Raw) -match '# Existing project notes') 'project notes preserved'
  Assert-Test ((Get-Content (Join-Path $project 'AGENTS.md') -Raw) -match '# Existing agent notes') 'agent notes preserved'
  Assert-Test (-not (Test-Path (Join-Path $project '.claude/product.yaml'))) 'common does not create product'
  foreach ($hostName in @('cursor','agents')) {
    $link = Get-Item (Join-Path $project ".$hostName/skills")
    Assert-Test ($link.LinkType -eq 'Junction') "host junction: $hostName"
    Assert-Test ([IO.Path]::GetFullPath([string]@($link.Target)[0]) -eq [IO.Path]::GetFullPath((Join-Path $project '.claude/skills'))) 'correct junction target'
  }
  Assert-Fails { Invoke-Install $project } 'existing assets require policy'
  $skill = Join-Path $project '.claude/skills/ai-collab-start/SKILL.md'
  Add-Content -LiteralPath $skill -Value 'LOCAL-MARKER' -Encoding UTF8
  Invoke-Install $project @{SkipExisting=$true}
  Assert-Test ((Get-Content $skill -Raw) -match 'LOCAL-MARKER') 'skip preserves local edits'
  Invoke-Install $project @{Backup=$true}
  Assert-Test ((Get-Content $skill -Raw) -notmatch 'LOCAL-MARKER') 'backup replaces active copy'
  $backups = @(Get-ChildItem (Join-Path $project '.claude/skills-backups') -Recurse -File | Where-Object { $_.Name -eq 'SKILL.md' })
  Assert-Test ([bool]($backups | Where-Object { (Get-Content $_.FullName -Raw) -match 'LOCAL-MARKER' })) 'backup retains old content'
  Invoke-Install $project @{Force=$true}
  Invoke-Install $project @{RewireOnly=$true}
  $entry = Get-Content (Join-Path $project 'CLAUDE.md') -Raw
  Assert-Test ([regex]::Matches($entry,'<!-- ai-collab-hub:capability:product-install:start -->').Count -eq 1) 'entry update is idempotent'

  $missing = New-Project 'missing'
  Invoke-Install $missing @{Product='example-app'}
  Assert-Test (Test-Path (Join-Path $missing '.claude/adapter-kit/product.yaml.tpl')) 'missing pack supplies kit'
  Assert-Test (-not (Test-Path (Join-Path $missing '.claude/product.yaml'))) 'noninteractive does not invent adapter'
  Invoke-Install $missing @{Product='example-app';ScaffoldProduct=$true;SkipExisting=$true}
  $productPath = Join-Path $missing '.claude/product.yaml'
  Assert-Test ((Get-Content $productPath -Raw) -match 'product_id: "example-app"') 'skeleton uses requested id'
  Assert-Test ((Get-Content $productPath -Raw) -match 'execution_status: "catalog-only"') 'skeleton stays non-executable'
  Add-Content $productPath '# LOCAL-ADAPTER'
  Invoke-Install $missing @{Product='example-app';ScaffoldProduct=$true;SkipExisting=$true}
  Assert-Test ((Get-Content $productPath -Raw) -match 'LOCAL-ADAPTER') 'scaffold never overrides skip policy'
  Assert-Test ((Get-ChildItem (Join-Path $missing '.claude/skills') -Directory).Count -eq $pack.skills.Count) 'missing product invents no module skills'

  $noEntry = New-Project 'no-entry'
  Invoke-Install $noEntry @{SkipEntryUpdate=$true}
  Assert-Test (-not (Test-Path (Join-Path $noEntry 'CLAUDE.md'))) 'skip entry respected'
  Assert-Test (-not (Test-Path (Join-Path $noEntry 'AGENTS.md'))) 'skip pointer respected'
  Assert-Fails { Invoke-Install $noEntry @{Product='../escape'} } 'product path traversal rejected'
  Assert-Fails { Invoke-Install $noEntry @{Force=$true;Backup=$true} } 'conflicting policies rejected'

  $outside = New-Project 'outside'
  Set-Content (Join-Path $outside 'sentinel.txt') 'KEEP'
  $escape = New-Project 'junction-escape'
  New-Item -ItemType Junction -Path (Join-Path $escape '.claude') -Target $outside | Out-Null
  Assert-Fails { Invoke-Install $escape @{Force=$true} } 'write through external junction rejected'
  Assert-Test ((Get-Content (Join-Path $outside 'sentinel.txt') -Raw).Trim() -eq 'KEEP') 'external data preserved'

  # Exercise the remote branch with a local, synthetic repository; no network or real product data.
  $remote = New-Project 'remote-hub'
  foreach ($name in @('common','skills','rules','adapters','scripts')) { Copy-Item -LiteralPath (Join-Path $HubRoot $name) -Destination (Join-Path $remote $name) -Recurse }
  foreach ($file in $pack.tools) {
    $target = Join-Path $remote $file
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $HubRoot $file) -Destination $target
  }
  $productDir = Join-Path $remote 'products/example-app'
  New-Item -ItemType Directory -Path (Join-Path $productDir 'skills/example-module') -Force | Out-Null
  Set-Content (Join-Path $productDir 'pack.json') '{"id":"example-app","status":"available","skills":["example-module"],"rules":[]}'
  Set-Content (Join-Path $productDir 'skills/example-module/SKILL.md') 'Synthetic test module'
  git -C $remote init -b main 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'git init failed' }
  git -C $remote add .
  if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
  git -C $remote -c user.name=Example -c user.email=example@example.com commit -m 'Synthetic fixture' 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'fixture commit failed' }
  $remoteDest = New-Project 'remote-destination'
  & $installer -Repo $remote -Ref main -ProjectRoot $remoteDest -Product example-app -NonInteractive | Out-Null
  Assert-Test (Test-Path (Join-Path $remoteDest 'tools/design-fingerprint/fingerprint.cjs')) 'remote root layout includes tool'
  Assert-Test (Test-Path (Join-Path $remoteDest '.claude/skills/example-module/SKILL.md')) 'available product installs its module'
  $cli = & node (Join-Path $remoteDest 'tools/design-fingerprint/fingerprint.cjs') file $remoteDest '.claude/skills/example-module/SKILL.md'
  Assert-Test ($LASTEXITCODE -eq 0) 'installed tool runs independently'
  Assert-Test ([bool]$cli) 'installed CLI produces output'
  Write-Output "INSTALL_TESTS_PASSED: $checks assertions"
} finally {
  if (Test-Path -LiteralPath $sandbox) { Remove-TestTree $sandbox }
}
