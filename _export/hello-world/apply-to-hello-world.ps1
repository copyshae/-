# 把暫存的 20260801 學習日誌與繁體中文捷徑套用到本機 hello-world。
# 用法（在此倉庫根目錄）：
#   powershell -ExecutionPolicy Bypass -File .\_export\hello-world\apply-to-hello-world.ps1

$ErrorActionPreference = 'Stop'
$candidates = @(
  (Join-Path $env:USERPROFILE 'Desktop\hello-world'),
  (Join-Path $env:USERPROFILE 'hello-world')
)
$dest = $candidates | Where-Object { Test-Path (Join-Path $_ '.git') } | Select-Object -First 1
if (-not $dest) {
  throw '找不到本機 hello-world。請先 clone 到 Desktop\hello-world。'
}

$src = $PSScriptRoot
Push-Location $dest
try {
  git pull origin master
  New-Item -ItemType Directory -Force -Path `
    (Join-Path $dest 'directory\logs\prompts'), `
    (Join-Path $dest '.cursor\skills\push-learning-log'), `
    (Join-Path $dest '.cursor\rules') | Out-Null

  Copy-Item (Join-Path $src 'directory\logs\20260801-learning-log.html') (Join-Path $dest 'directory\logs\20260801-learning-log.html') -Force
  Copy-Item (Join-Path $src 'directory\logs\index.html') (Join-Path $dest 'directory\logs\index.html') -Force
  Copy-Item (Join-Path $src 'directory\index.html') (Join-Path $dest 'directory\index.html') -Force
  Copy-Item (Join-Path $src '.cursor\skills\push-learning-log\SKILL.md') (Join-Path $dest '.cursor\skills\push-learning-log\SKILL.md') -Force
  Copy-Item (Join-Path $src '.cursor\rules\push-learning-log.mdc') (Join-Path $dest '.cursor\rules\push-learning-log.mdc') -Force
  Copy-Item (Join-Path $src 'directory\logs\prompts\push-learning-log.md') (Join-Path $dest 'directory\logs\prompts\push-learning-log.md') -Force
  Copy-Item (Join-Path $src 'install-push-log-shortcut.ps1') (Join-Path $dest 'install-push-log-shortcut.ps1') -Force

  git add directory/logs/20260801-learning-log.html directory/logs/index.html directory/index.html `
    .cursor/skills/push-learning-log/SKILL.md .cursor/rules/push-learning-log.mdc `
    directory/logs/prompts/push-learning-log.md install-push-log-shortcut.ps1
  git commit -m '新增 20260801 學習日誌：LINE 轉發雛形與看診備忘歸檔；捷徑流程改繁體中文。'
  git push origin master
  powershell -ExecutionPolicy Bypass -File .\install-push-log-shortcut.ps1
  Write-Host '完成：https://copyshae.github.io/hello-world/directory/logs/20260801-learning-log.html'
}
finally {
  Pop-Location
}
