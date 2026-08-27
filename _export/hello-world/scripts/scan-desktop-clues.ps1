#Requires -Version 5.1
<#
.SYNOPSIS
  掃描本機桌面，對照 hello-world 學習日誌找出視窗程式線索並建議恢復。

.DESCRIPTION
  會讀桌面上的 .vbs／.cmd、程式資料夾、版本／錯誤檔，對照學習日誌後寫
  「桌面程式線索報告.txt」。加 -Restore 會依線索呼叫對應安裝腳本。

.PARAMETER Restore
  依掃描結果恢復（習作批改／習作台／習作工具必做；護眼／掃具台／ChromeQuickLogin 若發現線索才做）。

.PARAMETER ShowTip
  習作程式 refresh 完成後跳提示框。
#>
param(
  [switch]$Restore,
  [switch]$ShowTip
)

$ErrorActionPreference = "Stop"
$desk = [Environment]::GetFolderPath("Desktop")
$branch = if ($env:DASH_EXPORT_BRANCH) { $env:DASH_EXPORT_BRANCH } else { "cursor/restore-desktop-apps-459a" }
$dashBase = "https://raw.githubusercontent.com/copyshae/-/$branch/_export/hello-world/scripts"
$hwBase = "https://raw.githubusercontent.com/copyshae/hello-world/master/scripts"
$eyeBase = "https://raw.githubusercontent.com/copyshae/hello-world/cursor/eye-care-reminders-433c/scripts"
$utf8Bom = New-Object System.Text.UTF8Encoding $true
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$reportPath = Join-Path $desk "桌面程式線索報告.txt"

# 學習日誌對照表（桌面線索 → 日誌 → 恢復方式）
$catalog = @(
  @{
    Id = "homework-grader"
    Log = "0803"
    LogUrl = "https://copyshae.github.io/hello-world/directory/202608/20260803-learning-log.html"
    Name = "數學習作批改"
    Shortcuts = @("習作批改.vbs", "grade-math.vbs", "launch.vbs")
    AppDirs = @("MathGradingApp")
    WorkDirs = @("MathGrading")
    Ps1Names = @("math-homework-grader-app.ps1", "launch-grader.ps1")
    LegacyWarn = @{ "grade-math.vbs" = "舊名捷徑，請改 習作批改.vbs" }
    Restore = "refresh-desktop-vbs"
    ExpectedBuild = "20260818-fast5"
  }
  @{
    Id = "teacher-desk"
    Log = "0805"
    LogUrl = "https://copyshae.github.io/hello-world/directory/202608/20260805-learning-log.html"
    Name = "習作台"
    Shortcuts = @("習作台.vbs", "啟動習作台.vbs")
    AppDirs = @("習作台程式")
    WorkDirs = @("習作台資料")
    Ps1Names = @("teacher-desk-app.ps1", "launch-teacher-desk.ps1")
    LegacyWarn = @{ "習作台.cmd" = "舊 cmd 易中文路徑失敗，請改 習作台.vbs" }
    Restore = "refresh-desktop-vbs"
    ExpectedBuild = "20260818-fast5"
  }
  @{
    Id = "homework-hub"
    Log = "0818"
    LogUrl = "https://copyshae.github.io/hello-world/directory/202608/20260818-learning-log.html"
    Name = "習作工具選單"
    Shortcuts = @("習作工具.vbs")
    AppDirs = @("習作工具程式")
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
    Name = "護眼提醒"
    Shortcuts = @("護眼提醒.vbs", "護眼提醒-除錯.cmd", "護眼提醒_除錯.cmd")
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
    Name = "掃具台"
    Shortcuts = @("掃具台.cmd", "掃描選單.cmd")
    AppDirs = @("掃具台程式")
    WorkDirs = @("掃具台資料")
    Ps1Names = @("scan-equip-app.ps1")
    LegacyWarn = @{}
    Restore = "scan-equip"
    ExpectedBuild = $null
  }
  @{
    Id = "hello-world"
    Log = "0817"
    LogUrl = "https://copyshae.github.io/hello-world/directory/202608/20260817-learning-log.html"
    Name = "hello-world 倉庫"
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
    Name = "ChromeQuickLogin 常用網址啟動器"
    Shortcuts = @("ChromeQuickLogin.lnk")
    AppDirs = @("ChromeQuickLogin")
    WorkDirs = @()
    Ps1Names = @("打包換機.ps1", "啟動.bat", "main.py", "app.py")
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
  $t = [System.IO.File]::ReadAllText($Path)
  if ($t -match "AppBuild\s*=\s*'([^']+)'") { return $Matches[1] }
  return $null
}

function Invoke-RemotePs1([string]$Url, [hashtable]$ExtraArgs) {
  $tmp = Join-Path $env:TEMP ("scan-clue-" + [guid]::NewGuid().ToString() + ".ps1")
  try {
    Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing
    $arg = @("-ExecutionPolicy", "Bypass", "-File", $tmp)
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

function Install-FromHelloWorld([string]$RelPath, [string]$RunArg) {
  $hw = Join-Path $desk "hello-world"
  $local = Join-Path $hw $RelPath.Replace("/", [string][char]92)
  if (Test-Path -LiteralPath $local) {
    Write-Host "本機執行：$local"
    if ($RunArg) {
      & powershell.exe -ExecutionPolicy Bypass -File $local @RunArg
    } else {
      & powershell.exe -ExecutionPolicy Bypass -File $local
    }
    return
  }
  $url = "$hwBase/$($RelPath.Replace('\','/'))"
  Write-Host "下載執行：$url"
  Invoke-RemotePs1 $url @{}
}

$lines = New-Object System.Collections.Generic.List[string]
[void]$lines.Add("桌面程式線索報告")
[void]$lines.Add("掃描時間：$stamp")
[void]$lines.Add("桌面路徑：$desk")
[void]$lines.Add("")

# 版本／錯誤線索
if (Test-DesktopItem "習作程式版本.txt") {
  [void]$lines.Add("=== 習作程式版本.txt（0818 線索）===")
  [void]$lines.Add([System.IO.File]::ReadAllText((Join-Path $desk "習作程式版本.txt")).Trim())
  [void]$lines.Add("")
}
if (Test-DesktopItem "習作台錯誤.txt") {
  [void]$lines.Add("=== 習作台錯誤.txt（0805 上次啟動失敗）===")
  [void]$lines.Add([System.IO.File]::ReadAllText((Join-Path $desk "習作台錯誤.txt")).Trim())
  [void]$lines.Add("")
}

$foundApps = New-Object System.Collections.Generic.List[string]
$needRestore = New-Object System.Collections.Generic.List[string]
$legacyHits = New-Object System.Collections.Generic.List[string]

foreach ($app in $catalog) {
  $hits = New-Object System.Collections.Generic.List[string]
  foreach ($s in $app.Shortcuts) {
    if (Test-DesktopItem $s) { [void]$hits.Add("捷徑：$s") }
  }
  foreach ($d in $app.AppDirs) {
    if (Test-DesktopItem $d) { [void]$hits.Add("程式夾：$d") }
  }
  foreach ($w in $app.WorkDirs) {
    if (Test-DesktopItem $w) { [void]$hits.Add("資料夾：$w（保留，不覆蓋）") }
  }
  foreach ($p in $app.Ps1Names) {
    foreach ($root in @($app.AppDirs)) {
      $pp = Join-Path $desk (Join-Path $root $p)
      if (Test-Path -LiteralPath $pp) {
        $b = Get-Ps1Build $pp
        $tag = if ($b) { "版本 $b" } else { "無 AppBuild" }
        [void]$hits.Add("ps1：$root\$p（$tag）")
        if ($app.ExpectedBuild -and $b -and $b -ne $app.ExpectedBuild) {
          [void]$needRestore.Add($app.Id)
        }
      }
    }
  }
  foreach ($k in $app.LegacyWarn.Keys) {
    if (Test-DesktopItem $k) {
      [void]$legacyHits.Add("$k → $($app.LegacyWarn[$k])")
    }
  }

  [void]$lines.Add("=== $($app.Log) $($app.Name) ===")
  [void]$lines.Add("學習日誌：$($app.LogUrl)")
  if ($hits.Count -gt 0) {
    [void]$foundApps.Add($app.Id)
    foreach ($h in $hits) { [void]$lines.Add("  找到 $h") }
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
          [void]$lines.Add("  建議：重下 ps1（找不到版本標記）")
          if ($needRestore -notcontains $app.Id) { [void]$needRestore.Add($app.Id) }
        } elseif ($cur -ne $app.ExpectedBuild) {
          [void]$lines.Add("  建議：更新至 $($app.ExpectedBuild)（目前 $cur）")
          if ($needRestore -notcontains $app.Id) { [void]$needRestore.Add($app.Id) }
        } else {
          [void]$lines.Add("  版本 OK：$cur")
        }
      } else {
        [void]$lines.Add("  建議：執行 refresh-desktop-vbs.ps1")
        if ($needRestore -notcontains $app.Id) { [void]$needRestore.Add($app.Id) }
      }
    }
  } else {
    [void]$lines.Add("  （桌面未發現線索）")
  }
  [void]$lines.Add("")
}

# 掃描桌面所有 .vbs／.cmd／.lnk（未對照到的額外線索）
$extra = @(Get-ChildItem -LiteralPath $desk -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -in @(".vbs", ".cmd", ".lnk") } |
  Select-Object -ExpandProperty Name)
$known = @($catalog | ForEach-Object { $_.Shortcuts } | ForEach-Object { $_ })
$unknown = @($extra | Where-Object { $_ -notin $known })
# ChromeQuickLogin 換機 zip 也算線索
$vaultZips = @(Get-ChildItem -LiteralPath $desk -Filter "ChromeQuickLogin-vault-*.zip" -ErrorAction SilentlyContinue)
if ($vaultZips.Count -gt 0 -and $foundApps -notcontains "chrome-quick-login") {
  [void]$foundApps.Add("chrome-quick-login")
  [void]$lines.Add("=== 0721 ChromeQuickLogin（由換機 zip 推論）===")
  [void]$lines.Add("學習日誌：https://copyshae.github.io/hello-world/directory/logs/20260721-chrome-quick-login.html")
  foreach ($z in $vaultZips) { [void]$lines.Add("  找到 金庫 zip：$($z.Name)") }
  [void]$lines.Add("  建議：執行 restore-chrome-quick-login.ps1")
  [void]$lines.Add("")
}
if ($unknown.Count -gt 0) {
  [void]$lines.Add("=== 其他桌面捷徑（請人工確認）===")
  foreach ($u in $unknown) { [void]$lines.Add("  $u") }
  [void]$lines.Add("")
}

if ($legacyHits.Count -gt 0) {
  [void]$lines.Add("=== 舊版捷徑（學習日誌建議勿用）===")
  foreach ($l in $legacyHits) { [void]$lines.Add("  $l") }
  [void]$lines.Add("")
}

[void]$lines.Add("=== 恢復建議 ===")
if ($needRestore -contains "homework-grader" -or $needRestore -contains "teacher-desk" -or $needRestore -contains "homework-hub" -or $foundApps.Count -eq 0) {
  [void]$lines.Add("習作批改／習作台／習作工具：")
  [void]$lines.Add("  irm $dashBase/restore-desktop-apps.ps1 | iex")
}
if ($foundApps -contains "eye-care") {
  [void]$lines.Add("護眼提醒（0801）：")
  [void]$lines.Add("  cd `$env:USERPROFILE\Desktop\hello-world")
  [void]$lines.Add("  git fetch origin cursor/eye-care-reminders-433c")
  [void]$lines.Add("  git checkout origin/cursor/eye-care-reminders-433c -- scripts/install-eye-care-app-to-desktop.ps1 scripts/eye-care-reminder-app.ps1")
  [void]$lines.Add("  powershell -ExecutionPolicy Bypass -File .\scripts\install-eye-care-app-to-desktop.ps1")
}
if ($foundApps -contains "scan-equip") {
  [void]$lines.Add("掃具台（0819）：")
  [void]$lines.Add("  cd `$env:USERPROFILE\Desktop\hello-world")
  [void]$lines.Add("  powershell -ExecutionPolicy Bypass -File .\scripts\install-scan-equip.ps1")
}
if ($foundApps -contains "chrome-quick-login" -or $foundApps.Count -eq 0) {
  [void]$lines.Add("ChromeQuickLogin（0721）：")
  [void]$lines.Add("  irm $dashBase/restore-chrome-quick-login.ps1 | iex")
  [void]$lines.Add("  （程式私有庫；金庫用桌面 ChromeQuickLogin-vault-*.zip）")
}
[void]$lines.Add("")
[void]$lines.Add("掃描腳本：$dashBase/scan-desktop-clues.ps1")
[void]$lines.Add("加 -Restore 可自動依線索恢復。")

[System.IO.File]::WriteAllText($reportPath, ($lines -join "`r`n"), $utf8Bom)
Write-Host ""
Write-Host "已寫入：$reportPath"
Write-Host ""
foreach ($ln in $lines) { Write-Host $ln }

if (-not $Restore) {
  Write-Host ""
  Write-Host "若要自動恢復，請下載後加 -Restore（勿用 irm|iex 傳參數）："
  Write-Host '  $u = "' + "$dashBase/scan-desktop-clues.ps1" + '"'
  Write-Host '  $i = Join-Path $env:TEMP "scan-desktop-clues.ps1"'
  Write-Host "  Invoke-WebRequest -Uri `$u -OutFile `$i -UseBasicParsing"
  Write-Host "  powershell -ExecutionPolicy Bypass -File `$i -Restore"
  exit 0
}

Write-Host ""
Write-Host "===== 依線索恢復 ====="

$doHomework = ($needRestore -contains "homework-grader") -or
  ($needRestore -contains "teacher-desk") -or
  ($needRestore -contains "homework-hub") -or
  ($foundApps -contains "homework-grader") -or
  ($foundApps -contains "teacher-desk") -or
  ($foundApps.Count -eq 0)

if ($doHomework) {
  Write-Host "恢復習作批改／習作台／習作工具 ..."
  $extra = @{ SkipScan = $true }
  if ($ShowTip) { $extra.ShowTip = $true }
  Invoke-RemotePs1 "$dashBase/restore-desktop-apps.ps1" $extra
}

if ($foundApps -contains "eye-care") {
  Write-Host "恢復護眼提醒（0801）..."
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
      & powershell.exe -ExecutionPolicy Bypass -File $eyeInstall
    } else {
      Invoke-RemotePs1 "$eyeBase/install-eye-care-app-to-desktop.ps1" @{}
    }
  } finally {
    Pop-Location
  }
}

if ($foundApps -contains "scan-equip") {
  Write-Host "恢復掃具台（0819）..."
  Install-FromHelloWorld "scripts/install-scan-equip.ps1" $null
}

if ($foundApps -contains "chrome-quick-login") {
  Write-Host "恢復 ChromeQuickLogin（0721）..."
  try {
    Invoke-RemotePs1 "$dashBase/restore-chrome-quick-login.ps1" @{}
  } catch {
    Write-Host "  失敗：$($_.Exception.Message)"
    Write-Host "  請確認私有庫權限，或手動 clone github.com/copyshae/ChromeQuickLogin 到桌面。"
  }
}

Write-Host ""
Write-Host "恢復完成。請關舊視窗後雙擊對應捷徑。詳見 $reportPath"
