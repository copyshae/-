#Requires -Version 5.1
# Teacher Desk emergency repair (ASCII-only)
$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/copyshae/-/cursor/teacher-desk-mobile-visibility-fc5d/_export/hello-world/scripts'
$tmp = Join-Path $env:TEMP 'teacher-desk-repair'
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

Write-Host '=== Teacher Desk emergency repair ==='
Write-Host ("PSVersion: " + $PSVersionTable.PSVersion)
Write-Host ("ExecutionPolicy: " + (Get-ExecutionPolicy))
$desk = [Environment]::GetFolderPath('Desktop')
Write-Host ("GetFolderPath Desktop: " + $desk)
Write-Host ("USERPROFILE Desktop:  " + (Join-Path $env:USERPROFILE 'Desktop'))
Write-Host ''

Write-Host 'Downloading...'
Invoke-WebRequest "$base/install-teacher-desk.ps1" -OutFile (Join-Path $tmp 'install-teacher-desk.ps1')
Invoke-WebRequest "$base/teacher-desk-app.ps1" -OutFile (Join-Path $tmp 'teacher-desk-app.ps1')

# Ensure UTF-8 BOM on teacher-desk-app.ps1 so Chinese UI parses on PS 5.1
$appRaw = [System.IO.File]::ReadAllBytes((Join-Path $tmp 'teacher-desk-app.ps1'))
if (-not ($appRaw.Length -ge 3 -and $appRaw[0] -eq 0xEF -and $appRaw[1] -eq 0xBB -and $appRaw[2] -eq 0xBF)) {
  $text = [System.Text.Encoding]::UTF8.GetString($appRaw)
  $utf8Bom = New-Object System.Text.UTF8Encoding $true
  [System.IO.File]::WriteAllText((Join-Path $tmp 'teacher-desk-app.ps1'), $text, $utf8Bom)
  Write-Host 'Added UTF-8 BOM to teacher-desk-app.ps1'
}

Write-Host 'Installing with Bypass...'
$install = Join-Path $tmp 'install-teacher-desk.ps1'
$p = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
  '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $install
) -PassThru -Wait -NoNewWindow
if ($p.ExitCode -ne 0) {
  throw ("Install failed, exit=" + $p.ExitCode)
}

Write-Host ''
Write-Host '=== Desktop TeacherDesk files ==='
Get-ChildItem -LiteralPath $desk -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -like 'TeacherDesk*' -or $_.Name -like ([string][char]0x7FD2 + '*') } |
  ForEach-Object { Write-Host ('  ' + $_.FullName) }

$app = Join-Path $desk 'TeacherDeskApp\teacher-desk-app.ps1'
$work = Join-Path $desk 'TeacherDeskData'
Write-Host ''
Write-Host '=== Launching app (close the green window to continue) ==='
if (-not (Test-Path -LiteralPath $app)) {
  Write-Host ('Missing ' + $app)
} else {
  $p2 = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA',
    '-File', $app,
    '-WorkDir', $work
  ) -PassThru -Wait
  Write-Host ('exit=' + $p2.ExitCode)
  $log = Join-Path $desk 'TeacherDesk-error.txt'
  if (Test-Path -LiteralPath $log) {
    Write-Host '--- TeacherDesk-error.txt ---'
    Get-Content -LiteralPath $log -Encoding UTF8 | Write-Host
  }
}

Write-Host ''
Write-Host 'Next: double-click TeacherDesk-ABS.cmd on Desktop'
Write-Host 'If still no window: copy this PowerShell text to Cursor'
pause
