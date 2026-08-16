@echo off
chcp 65001 >nul
echo 更新習作批改（走 commit SHA，避開 raw 分支快取）...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $candidates=@(); $candidates += (Join-Path (Get-Location) '_export\hello-world\scripts\fix-grader-gemini-404.ps1'); $candidates += (Join-Path $env:USERPROFILE 'Desktop\hello-world\scripts\fix-grader-gemini-404.ps1'); $run=$null; foreach($c in $candidates){ if(Test-Path -LiteralPath $c){ $run=$c; break } }; if(-not $run){ $api='https://api.github.com/repos/copyshae/-/commits/cursor/sync-desk-grader-devices-2663'; $wc=New-Object Net.WebClient; $wc.Headers.Add('User-Agent','MathGraderFix'); $j=$wc.DownloadString($api); if($j -notmatch '\"sha\"\s*:\s*\"([0-9a-f]{40})\"'){ throw 'cannot resolve sha' }; $sha=$Matches[1]; $u='https://raw.githubusercontent.com/copyshae/-/'+$sha+'/_export/hello-world/scripts/fix-grader-gemini-404.ps1'; $run=Join-Path $env:TEMP ('fix-grader-'+[guid]::NewGuid().ToString('n')+'.ps1'); $wc2=New-Object Net.WebClient; $wc2.Headers.Add('User-Agent','MathGraderFix'); $wc2.Headers.Add('Cache-Control','no-cache'); $wc2.DownloadFile($u,$run); Write-Host ('Downloaded SHA '+$sha.Substring(0,7)) } else { Write-Host ('Using local '+$run) }; & $run"
echo.
pause
