#Requires -Version 5.1
# 習作台緊急修復：從 GitHub 拉最新腳本並重裝啟動器（純本機執行）
$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/copyshae/-/cursor/teacher-desk-mobile-visibility-fc5d/_export/hello-world/scripts'
$tmp = Join-Path $env:TEMP 'teacher-desk-repair'
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

Write-Host '下載安裝腳本…'
Invoke-WebRequest "$base/install-teacher-desk.ps1" -OutFile (Join-Path $tmp 'install-teacher-desk.ps1')
Invoke-WebRequest "$base/teacher-desk-app.ps1" -OutFile (Join-Path $tmp 'teacher-desk-app.ps1')

Write-Host '執行安裝…'
& (Join-Path $tmp 'install-teacher-desk.ps1')

Write-Host ''
Write-Host '若上面沒有錯誤，請立刻雙擊桌面：TeacherDesk-start.cmd'
Write-Host '（不要用舊的壞掉捷徑；若還一閃就沒，把桌面 TeacherDesk-error.txt 貼給 Cursor）'
pause
