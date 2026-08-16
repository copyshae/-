@echo off
chcp 65001 >nul
echo 從本機或 GitHub 更新習作批改（避開 IE 快取）...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $desk=[Environment]::GetFolderPath('Desktop'); $local=Join-Path $desk 'hello-world\scripts\fix-grader-gemini-404.ps1'; $alt1=Join-Path $desk '習作台\_export\hello-world\scripts\fix-grader-gemini-404.ps1'; $alt2=Join-Path (Get-Location) '_export\hello-world\scripts\fix-grader-gemini-404.ps1'; $run=$null; foreach($c in @($alt2,$local,$alt1)){ if(Test-Path -LiteralPath $c){ $run=$c; break } }; if(-not $run){ $sha='23b9888'; $u=\"https://raw.githubusercontent.com/copyshae/-/cursor/sync-desk-grader-devices-2663/_export/hello-world/scripts/fix-grader-gemini-404.ps1?nocache=$([guid]::NewGuid())\"; $run=Join-Path $env:TEMP ('fix-grader-'+[guid]::NewGuid().ToString('n')+'.ps1'); $wc=New-Object Net.WebClient; $wc.Headers.Add('Cache-Control','no-cache'); $wc.Headers.Add('Pragma','no-cache'); $wc.DownloadFile($u,$run); Write-Host ('Downloaded '+$run) } else { Write-Host ('Using local '+$run) }; & $run"
echo.
pause
