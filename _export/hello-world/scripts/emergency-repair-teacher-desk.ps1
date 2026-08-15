#Requires -Version 5.1
# 習作台緊急修復 + 診斷（會列出檔案並直接試開）
$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/copyshae/-/cursor/teacher-desk-mobile-visibility-fc5d/_export/hello-world/scripts'
$tmp = Join-Path $env:TEMP 'teacher-desk-repair'
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

Write-Host '=== 習作台緊急修復 ==='
Write-Host ("PSVersion: " + $PSVersionTable.PSVersion)
$desk = [Environment]::GetFolderPath('Desktop')
Write-Host ("GetFolderPath Desktop: " + $desk)
Write-Host ("USERPROFILE Desktop:  " + (Join-Path $env:USERPROFILE 'Desktop'))
Write-Host ''

Write-Host '下載…'
Invoke-WebRequest "$base/install-teacher-desk.ps1" -OutFile (Join-Path $tmp 'install-teacher-desk.ps1')
Invoke-WebRequest "$base/teacher-desk-app.ps1" -OutFile (Join-Path $tmp 'teacher-desk-app.ps1')

Write-Host '安裝…'
& (Join-Path $tmp 'install-teacher-desk.ps1')

Write-Host ''
Write-Host '=== 桌面相關檔案 ==='
Get-ChildItem -LiteralPath $desk -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -like 'TeacherDesk*' -or $_.Name -like '習作台*' } |
  ForEach-Object { Write-Host ('  ' + $_.FullName) }

$app = Join-Path $desk 'TeacherDeskApp\teacher-desk-app.ps1'
$work = Join-Path $desk 'TeacherDeskData'
Write-Host ''
Write-Host '=== 直接啟動（應跳出習作台視窗；關掉後才繼續）==='
if (-not (Test-Path -LiteralPath $app)) {
  Write-Host ('找不到 ' + $app)
} else {
  try {
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
      '-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA',
      '-File', $app,
      '-WorkDir', $work
    ) -PassThru -Wait
    Write-Host ('exit=' + $p.ExitCode)
  } catch {
    Write-Host $_.Exception.Message
  }
  $log = Join-Path $desk 'TeacherDesk-error.txt'
  if (Test-Path -LiteralPath $log) {
    Write-Host '--- TeacherDesk-error.txt ---'
    Get-Content -LiteralPath $log -Encoding UTF8 | Write-Host
  }
}

Write-Host ''
Write-Host '請再雙擊桌面：TeacherDesk-ABS.cmd'
Write-Host '若仍沒視窗：把本視窗從「=== 習作台緊急修復 ===」起整段複製給 Cursor'
pause
