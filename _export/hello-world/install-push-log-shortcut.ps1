# 安裝「學習日誌」快捷詞到本機所有 Cursor 專案。
#
# 用法（每台電腦做一次）：
#   cd <hello-world 倉庫>
#   powershell -ExecutionPolicy Bypass -File .\install-push-log-shortcut.ps1
#
# 來源：本倉庫 .cursor\skills 與 .cursor\rules
# 目標：%USERPROFILE%\.cursor\skills 與 %USERPROFILE%\.cursor\rules

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$srcSkill = Join-Path $root '.cursor\skills\push-learning-log\SKILL.md'
$srcRule = Join-Path $root '.cursor\rules\push-learning-log.mdc'

if (-not (Test-Path -LiteralPath $srcSkill)) {
  throw "找不到 skill 檔，請先 git pull：$srcSkill"
}
if (-not (Test-Path -LiteralPath $srcRule)) {
  throw "找不到 rule 檔，請先 git pull：$srcRule"
}

$destSkillDir = Join-Path $env:USERPROFILE '.cursor\skills\push-learning-log'
$destRuleDir = Join-Path $env:USERPROFILE '.cursor\rules'
New-Item -ItemType Directory -Force -Path $destSkillDir, $destRuleDir | Out-Null

Copy-Item -LiteralPath $srcSkill -Destination (Join-Path $destSkillDir 'SKILL.md') -Force
Copy-Item -LiteralPath $srcRule -Destination (Join-Path $destRuleDir 'push-learning-log.mdc') -Force

Write-Host '已安裝到本機所有 Cursor 專案：'
Write-Host ("  skill：{0}\SKILL.md" -f $destSkillDir)
Write-Host ("  rule：{0}\push-learning-log.mdc" -f $destRuleDir)
Write-Host ''
Write-Host '請重新開一個 Cursor 對話，然後輸入快捷詞：推日誌 或 tui-ri-zhi'
Write-Host '（流程與回覆一律使用繁體中文）'
