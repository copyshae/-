#Requires -Version 5.1
# ASCII-only source (PS 5.1 safe on Big5 Windows). Chinese via UTF-8 Base64 at runtime.
param(
  [switch]$Restore,
  [switch]$ShowTip
)

$ErrorActionPreference = "Stop"

function U([string]$B64) {
  return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64))
}

$desk = [Environment]::GetFolderPath("Desktop")
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/restore-desktop-apps-459a" }
$dashBase = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts"
$hwBase = "https://raw.githubusercontent.com/copyshae/hello-world/master/scripts"
$eyeBase = "https://raw.githubusercontent.com/copyshae/hello-world/cursor/eye-care-reminders-433c/scripts"
$utf8Bom = New-Object System.Text.UTF8Encoding $true
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$reportPath = Join-Path $desk (U "5qGM6Z2i56iL5byP57ea57Si5aCx5ZGKLnR4dA==")

$N_grader = U "5pW45a2457+S5L2c5om55pS5"
$N_desk = U "57+S5L2c5Y+w"
$N_hub = U "57+S5L2c5bel5YW36YG45Zau"
$N_eye = U "6K2355y85o+Q6YaS"
$N_scan = U "5o6D5YW35Y+w"
$N_hw = U "aGVsbG8td29ybGQg5YCJ5bqr"
$N_cql = U "Q2hyb21lUXVpY2tMb2dpbiDluLjnlKjntrLlnYDllZ/li5Xlmag="

$S_grader = U "57+S5L2c5om55pS5LnZicw=="
$S_desk = U "57+S5L2c5Y+wLnZicw=="
$S_deskLaunch = U "5ZWf5YuV57+S5L2c5Y+wLnZicw=="
$S_hub = U "57+S5L2c5bel5YW3LnZicw=="
$S_eye = U "6K2355y85o+Q6YaSLnZicw=="
$S_eyeDbg1 = U "6K2355y85o+Q6YaSLemZpOmMry5jbWQ="
$S_eyeDbg2 = U "6K2355y85o+Q6YaSX+mZpOmMry5jbWQ="
$S_scan = U "5o6D5YW35Y+wLmNtZA=="
$S_scanMenu = U "5o6D5o+P6YG45ZauLmNtZA=="
$S_deskCmd = U "57+S5L2c5Y+wLmNtZA=="

$D_deskApp = U "57+S5L2c5Y+w56iL5byP"
$D_deskData = U "57+S5L2c5Y+w6LOH5paZ"
$D_hubApp = U "57+S5L2c5bel5YW356iL5byP"
$D_scanApp = U "5o6D5YW35Y+w56iL5byP"
$D_scanData = U "5o6D5YW35Y+w6LOH5paZ"

$P_pack = U "5omT5YyF5o+b5qmfLnBzMQ=="
$P_startBat = U "5ZWf5YuVLmJhdA=="
$F_ver = U "57+S5L2c56iL5byP54mI5pysLnR4dA=="
$F_err = U "57+S5L2c5Y+w6Yyv6KqkLnR4dA=="
$W_legacyG = U "6IiK5ZCN5o235b6R77yM6KuL5pS5IOe/kuS9nOaJueaUuS52YnM="
$W_legacyD = U "6IiKIGNtZCDmmJPkuK3mlofot6/lvpHlpLHmlZfvvIzoq4vmlLkg57+S5L2c5Y+wLnZicw=="

$catalog = @(
  @{
    Id = "homework-grader"
    Log = "0803"
    LogUrl = "https://copyshae.github.io/hello-world/directory/202608/20260803-learning-log.html"
    Name = $N_grader
    Shortcuts = @($S_grader, "grade-math.vbs", "launch.vbs")
    AppDirs = @("MathGradingApp")
    WorkDirs = @("MathGrading")
    Ps1Names = @("math-homework-grader-app.ps1", "launch-grader.ps1")
    LegacyWarn = @{ "grade-math.vbs" = $W_legacyG }
    Restore = "refresh-desktop-vbs"
    ExpectedBuild = "20260818-fast5"
  }
  @{
    Id = "teacher-desk"
    Log = "0805"
    LogUrl = "https://copyshae.github.io/hello-world/directory/202608/20260805-learning-log.html"
    Name = $N_desk
    Shortcuts = @($S_desk, $S_deskLaunch)
    AppDirs = @($D_deskApp)
    WorkDirs = @($D_deskData)
    Ps1Names = @("teacher-desk-app.ps1", "launch-teacher-desk.ps1")
    LegacyWarn = @{ $S_deskCmd = $W_legacyD }
    Restore = "refresh-desktop-vbs"
    ExpectedBuild = "20260818-fast5"
  }
  @{
    Id = "homework-hub"
    Log = "0818"
    LogUrl = "https://copyshae.github.io/hello-world/directory/202608/20260818-learning-log.html"
    Name = $N_hub
    Shortcuts = @($S_hub)
    AppDirs = @($D_hubApp)
    WorkDirs = @()
    Ps1Names = @("launch-homework-apps.ps1")
    LegacyWarn = @{}
    Restore = "refresh-desktop-vbs"
    ExpectedBuild = "20260818-fast5"
  }
  @{
    Id = "eye-care"
    Log = "0801"
    LogUrl = "https://copyshae.github.io/hello-world/directory/202608/20260801-learning-log.html"
    Name = $N_eye
    Shortcuts = @($S_eye, $S_eyeDbg1, $S_eyeDbg2)
    AppDirs = @("EyeCareReminder")
    WorkDirs = @()
    Ps1Names = @("eye-care-reminder-app.ps1", "launch-with-onedrive.ps1")
    LegacyWarn = @{}
    Restore = "eye-care"
    ExpectedBuild = $null
  }
  @{
    Id = "scan-equip"
    Log = "0819"
    LogUrl = "https://copyshae.github.io/hello-world/directory/202608/20260819-learning-log.html"
    Name = $N_scan
    Shortcuts = @($S_scan, $S_scanMenu)
    AppDirs = @($D_scanApp)
    WorkDirs = @($D_scanData)
    Ps1Names = @("scan-equip-app.ps1")
    LegacyWarn = @{}
    Restore = "scan-equip"
    ExpectedBuild = $null
  }
  @{
    Id = "hello-world"
    Log = "0817"
    LogUrl = "https://copyshae.github.io/hello-world/directory/202608/20260817-learning-log.html"
    Name = $N_hw
    Shortcuts = @()
    AppDirs = @("hello-world")
    WorkDirs = @()
    Ps1Names = @("bootstrap-desktop-apps.ps1", "install-desktop-apps.ps1")
    LegacyWarn = @{}
    Restore = "bootstrap"
    ExpectedBuild = $null
  }
  @{
    Id = "chrome-quick-login"
    Log = "0721"
    LogUrl = "https://copyshae.github.io/hello-world/directory/logs/20260721-chrome-quick-login.html"
    Name = $N_cql
    Shortcuts = @("ChromeQuickLogin.lnk")
    AppDirs = @("ChromeQuickLogin")
    WorkDirs = @()
    Ps1Names = @($P_pack, $P_startBat, "main.py", "app.py")
    LegacyWarn = @{}
    Restore = "chrome-quick-login"
    ExpectedBuild = $null
  }
)

function Test-DesktopItem([string]$Name) {
  Test-Path -LiteralPath (Join-Path $desk $Name)
}

function Get-Ps1Build([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  $t = [System.Text.Encoding]::UTF8.GetString($bytes)
  if ($t.Length -gt 0 -and [int][char]$t[0] -eq 0xFEFF) { $t = $t.Substring(1) }
  if ($t -match "AppBuild\s*=\s*'([^']+)'") { return $Matches[1] }
  return $null
}

function Save-RemoteUtf8Bom([string]$Url, [string]$Dest) {
  $wc = New-Object System.Net.WebClient
  $wc.Encoding = [System.Text.Encoding]::UTF8
  try {
    $text = $wc.DownloadString($Url)
  } finally {
    $wc.Dispose()
  }
  if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) {
    $text = $text.Substring(1)
  }
  [System.IO.File]::WriteAllText($Dest, $text, $utf8Bom)
}

function Invoke-RemotePs1([string]$Url, [hashtable]$ExtraArgs) {
  $tmp = Join-Path $env:TEMP ("scan-clue-" + [guid]::NewGuid().ToString() + ".ps1")
  try {
    Save-RemoteUtf8Bom $Url $tmp
    $arg = @("-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $tmp)
    if ($ExtraArgs) {
      foreach ($k in $ExtraArgs.Keys) {
        if ($ExtraArgs[$k] -is [bool]) {
          if ($ExtraArgs[$k]) { $arg += "-$k" }
        } else {
          $arg += "-$k"
          $arg += [string]$ExtraArgs[$k]
        }
      }
    }
    & powershell.exe @arg
  } finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
  }
}

function Install-FromHelloWorld([string]$RelPath) {
  $hw = Join-Path $desk "hello-world"
  $local = Join-Path $hw $RelPath.Replace("/", [string][char]92)
  if (Test-Path -LiteralPath $local) {
    Write-Host ("Local: {0}" -f $local)
    & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $local
    return
  }
  $url = "$hwBase/$($RelPath.Replace('\','/'))"
  Write-Host ("Download: {0}" -f $url)
  Invoke-RemotePs1 $url @{}
}

$lines = New-Object System.Collections.Generic.List[string]
[void]$lines.Add("Desktop app clues report")
[void]$lines.Add(("Scan time: {0}" -f $stamp))
[void]$lines.Add(("Desktop: {0}" -f $desk))
[void]$lines.Add("")

if (Test-DesktopItem $F_ver) {
  [void]$lines.Add("=== version note (0818) ===")
  [void]$lines.Add([System.IO.File]::ReadAllText((Join-Path $desk $F_ver)).Trim())
  [void]$lines.Add("")
}
if (Test-DesktopItem $F_err) {
  [void]$lines.Add("=== teacher-desk error (0805) ===")
  [void]$lines.Add([System.IO.File]::ReadAllText((Join-Path $desk $F_err)).Trim())
  [void]$lines.Add("")
}

$foundApps = New-Object System.Collections.Generic.List[string]
$needRestore = New-Object System.Collections.Generic.List[string]
$legacyHits = New-Object System.Collections.Generic.List[string]

foreach ($app in $catalog) {
  $hits = New-Object System.Collections.Generic.List[string]
  foreach ($s in $app.Shortcuts) {
    if (Test-DesktopItem $s) { [void]$hits.Add(("shortcut: {0}" -f $s)) }
  }
  foreach ($d in $app.AppDirs) {
    if (Test-DesktopItem $d) { [void]$hits.Add(("app-dir: {0}" -f $d)) }
  }
  foreach ($w in $app.WorkDirs) {
    if (Test-DesktopItem $w) { [void]$hits.Add(("work-dir kept: {0}" -f $w)) }
  }
  foreach ($p in $app.Ps1Names) {
    foreach ($root in @($app.AppDirs)) {
      $pp = Join-Path $desk (Join-Path $root $p)
      if (Test-Path -LiteralPath $pp) {
        $b = Get-Ps1Build $pp
        $tag = if ($b) { "build $b" } else { "no AppBuild" }
        [void]$hits.Add(("ps1: {0}\{1} ({2})" -f $root, $p, $tag))
        if ($app.ExpectedBuild -and $b -and $b -ne $app.ExpectedBuild) {
          [void]$needRestore.Add($app.Id)
        }
      }
    }
  }
  foreach ($k in $app.LegacyWarn.Keys) {
    if (Test-DesktopItem $k) {
      [void]$legacyHits.Add(("{0} -> {1}" -f $k, $app.LegacyWarn[$k]))
    }
  }

  [void]$lines.Add(("=== {0} {1} ===" -f $app.Log, $app.Name))
  [void]$lines.Add(("log: {0}" -f $app.LogUrl))
  if ($hits.Count -gt 0) {
    [void]$foundApps.Add($app.Id)
    foreach ($h in $hits) { [void]$lines.Add(("  found {0}" -f $h)) }
    if ($app.ExpectedBuild) {
      $mainPs1 = $null
      foreach ($root in $app.AppDirs) {
        foreach ($p in $app.Ps1Names) {
          if ($p -like "*-app.ps1") {
            $mainPs1 = Join-Path $desk (Join-Path $root $p)
            break
          }
        }
      }
      if ($mainPs1 -and (Test-Path -LiteralPath $mainPs1)) {
        $cur = Get-Ps1Build $mainPs1
        if (-not $cur) {
          [void]$lines.Add("  suggest: re-download ps1 (no build tag)")
          if ($needRestore -notcontains $app.Id) { [void]$needRestore.Add($app.Id) }
        } elseif ($cur -ne $app.ExpectedBuild) {
          [void]$lines.Add(("  suggest: update to {0} (now {1})" -f $app.ExpectedBuild, $cur))
          if ($needRestore -notcontains $app.Id) { [void]$needRestore.Add($app.Id) }
        } else {
          [void]$lines.Add(("  build OK: {0}" -f $cur))
        }
      } else {
        [void]$lines.Add("  suggest: run refresh-desktop-vbs.ps1")
        if ($needRestore -notcontains $app.Id) { [void]$needRestore.Add($app.Id) }
      }
    }
  } else {
    [void]$lines.Add("  (no desktop clue)")
  }
  [void]$lines.Add("")
}

$extra = @(Get-ChildItem -LiteralPath $desk -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -in @(".vbs", ".cmd", ".lnk") } |
  Select-Object -ExpandProperty Name)
$known = @($catalog | ForEach-Object { $_.Shortcuts } | ForEach-Object { $_ })
$unknown = @($extra | Where-Object { $_ -notin $known })
$vaultZips = @(Get-ChildItem -LiteralPath $desk -Filter "ChromeQuickLogin-vault-*.zip" -ErrorAction SilentlyContinue)
if ($vaultZips.Count -gt 0 -and $foundApps -notcontains "chrome-quick-login") {
  [void]$foundApps.Add("chrome-quick-login")
  [void]$lines.Add("=== 0721 ChromeQuickLogin (from vault zip) ===")
  [void]$lines.Add("log: https://copyshae.github.io/hello-world/directory/logs/20260721-chrome-quick-login.html")
  foreach ($z in $vaultZips) { [void]$lines.Add(("  vault zip: {0}" -f $z.Name)) }
  [void]$lines.Add("  suggest: restore-chrome-quick-login.ps1")
  [void]$lines.Add("")
}
if ($unknown.Count -gt 0) {
  [void]$lines.Add("=== other desktop shortcuts ===")
  foreach ($u in $unknown) { [void]$lines.Add(("  {0}" -f $u)) }
  [void]$lines.Add("")
}
if ($legacyHits.Count -gt 0) {
  [void]$lines.Add("=== legacy shortcuts (avoid) ===")
  foreach ($l in $legacyHits) { [void]$lines.Add(("  {0}" -f $l)) }
  [void]$lines.Add("")
}

[void]$lines.Add("=== restore tips ===")
[void]$lines.Add(("preferred: irm {0}/run-scan-and-restore.ps1 | iex" -f $dashBase))
if ($foundApps -contains "eye-care") {
  [void]$lines.Add("eye-care (0801): install-eye-care-app-to-desktop.ps1")
}
if ($foundApps -contains "scan-equip") {
  [void]$lines.Add("scan-equip (0819): install-scan-equip.ps1")
}
if ($foundApps -contains "chrome-quick-login" -or $foundApps.Count -eq 0) {
  [void]$lines.Add(("ChromeQuickLogin (0721): irm {0}/run-scan-and-restore.ps1 | iex" -f $dashBase))
}
[void]$lines.Add("")

[System.IO.File]::WriteAllText($reportPath, ($lines -join "`r`n"), $utf8Bom)
Write-Host ""
Write-Host ("Wrote: {0}" -f $reportPath)
Write-Host ""
foreach ($ln in $lines) { Write-Host $ln }

if (-not $Restore) {
  Write-Host ""
  Write-Host "To restore, run with -Restore, or:"
  Write-Host ("  irm {0}/run-scan-and-restore.ps1 | iex" -f $dashBase)
  exit 0
}

Write-Host ""
Write-Host "===== restore by clues ====="

$doHomework = ($needRestore -contains "homework-grader") -or
  ($needRestore -contains "teacher-desk") -or
  ($needRestore -contains "homework-hub") -or
  ($foundApps -contains "homework-grader") -or
  ($foundApps -contains "teacher-desk") -or
  ($foundApps -contains "homework-hub") -or
  ($foundApps.Count -eq 0)

if ($doHomework) {
  Write-Host "Restore homework grader / teacher desk / hub ..."
  # Use ASCII runner so nested Chinese scripts get UTF-8 BOM
  $extraArgs = @{ SkipScan = $true }
  if ($ShowTip) { $extraArgs.ShowTip = $true }
  Invoke-RemotePs1 "$dashBase/run-restore-desktop-apps.ps1" $extraArgs
}

if ($foundApps -contains "eye-care") {
  Write-Host "Restore eye-care (0801) ..."
  $hw = Join-Path $desk "hello-world"
  if (-not (Test-Path -LiteralPath $hw)) {
    Write-Host "  clone hello-world ..."
    git clone "https://github.com/copyshae/hello-world.git" $hw
  }
  Push-Location $hw
  try {
    git fetch origin cursor/eye-care-reminders-433c 2>$null
    git checkout origin/cursor/eye-care-reminders-433c -- scripts/install-eye-care-app-to-desktop.ps1 scripts/eye-care-reminder-app.ps1 2>$null
    $eyeInstall = Join-Path $hw "scripts\install-eye-care-app-to-desktop.ps1"
    if (Test-Path -LiteralPath $eyeInstall) {
      & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $eyeInstall
    } else {
      Invoke-RemotePs1 "$eyeBase/install-eye-care-app-to-desktop.ps1" @{}
    }
  } finally {
    Pop-Location
  }
}

if ($foundApps -contains "scan-equip") {
  Write-Host "Restore scan-equip (0819) ..."
  Install-FromHelloWorld "scripts/install-scan-equip.ps1"
}

if ($foundApps -contains "chrome-quick-login") {
  Write-Host "Restore ChromeQuickLogin (0721) ..."
  try {
    Invoke-RemotePs1 "$dashBase/restore-chrome-quick-login.ps1" @{}
  } catch {
    Write-Host ("  failed: {0}" -f $_.Exception.Message)
    Write-Host "  Need private repo access, or copy Desktop\ChromeQuickLogin manually."
  }
}

Write-Host ""
Write-Host ("Done. See report: {0}" -f $reportPath)
