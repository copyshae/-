#Requires -Version 5.1
# 只處理「桌面\test」裡的掃具請領.xlsx
# 把「其他細項」拆成獨立欄位並加總計
# 結果存在同一個 test 資料夾，不搬到大容量碟歸檔夾
$ErrorActionPreference = "Stop"
$desk = [Environment]::GetFolderPath("Desktop")
$testDir = Join-Path $desk "test"
if (-not (Test-Path -LiteralPath $testDir)) {
  throw "找不到桌面 test 資料夾：$testDir"
}

$src = Get-ChildItem -LiteralPath $testDir -File -Filter "*.xlsx" |
  Where-Object { $_.Name -like "*掃具請領*" -and $_.Name -notlike "*已整理*" -and $_.Name -notlike "~$*" } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1
if (-not $src) {
  $src = Get-ChildItem -LiteralPath $testDir -File -Filter "*.xlsx" |
    Where-Object { $_.Name -like "*掃具請領*" -and $_.Name -notlike "~$*" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}
if (-not $src) {
  throw "桌面 test 裡找不到掃具請領 Excel"
}

Write-Host "來源：$($src.FullName)"
$excel = $null
$wb = $null
try {
  $excel = New-Object -ComObject Excel.Application
  $excel.Visible = $false
  $excel.DisplayAlerts = $false
  $wb = $excel.Workbooks.Open($src.FullName)
  $ws = $wb.Worksheets.Item(1)
  $used = $ws.UsedRange
  $lastRow = $used.Rows.Count
  $lastCol = $used.Columns.Count

  $otherCol = 0
  for ($c = 1; $c -le $lastCol; $c++) {
    $h = [string]$ws.Cells.Item(1, $c).Value2
    if ($h -eq "其他細項" -or $h -eq "其他細項原文") { $otherCol = $c; break }
  }
  if ($otherCol -eq 0) { throw "找不到「其他細項」欄" }

  function Parse-Items([string]$text) {
    $map = @{}
    if ([string]::IsNullOrWhiteSpace($text)) { return $map }
    $t = $text.Trim()
    $t = $t.Replace([char]0x00D7, "x").Replace("＊", "*").Replace("Ｘ", "x").Replace("ｘ", "x")
    $t = $t.Replace("０","0").Replace("１","1").Replace("２","2").Replace("３","3").Replace("４","4")
    $t = $t.Replace("５","5").Replace("６","6").Replace("７","7").Replace("８","8").Replace("９","9")
    $parts = [regex]::Split($t, "[\s　\n、,，；;]+")
    foreach ($part in $parts) {
      $p = $part.Trim()
      if (-not $p) { continue }
      $m = [regex]::Match($p, "^(.+?)[xX\*](\d+)(盒|個|包|組|支|條|張|本|瓶)?$")
      if ($m.Success) {
        $name = $m.Groups[1].Value.Trim()
        $qty = [int]$m.Groups[2].Value
        if ($map.ContainsKey($name)) { $map[$name] += $qty } else { $map[$name] = $qty }
      } else {
        $name = [regex]::Replace($p, "[xX\*]\d+(盒|個|包|組|支|條|張|本|瓶)?$", "").Trim()
        if ($name) {
          if ($map.ContainsKey($name)) { $map[$name] += 1 } else { $map[$name] = 1 }
        }
      }
    }
    return $map
  }

  $allItems = New-Object System.Collections.Generic.List[string]
  $seen = @{}
  $rowMaps = @{}
  $totalRow = 0
  for ($r = 2; $r -le $lastRow; $r++) {
    $rowText = ""
    for ($c = 1; $c -le [Math]::Min(5, $lastCol); $c++) {
      $rowText += " " + [string]$ws.Cells.Item($r, $c).Value2
    }
    if ($rowText -match "總計") { $totalRow = $r; continue }
    $parsed = Parse-Items ([string]$ws.Cells.Item($r, $otherCol).Value2)
    $rowMaps[$r] = $parsed
    foreach ($k in $parsed.Keys) {
      if (-not $seen.ContainsKey($k)) {
        $seen[$k] = $true
        $allItems.Add($k) | Out-Null
      }
    }
  }
  if ($allItems.Count -eq 0) { throw "其他細項沒有可拆的物品" }
  Write-Host ("物品：{0}" -f ($allItems -join "、"))

  $ws.Cells.Item(1, $otherCol).Value2 = "其他細項原文"
  $insertAt = $otherCol + 1
  foreach ($name in $allItems) {
    [void]$ws.Columns.Item($insertAt).Insert()
    $ws.Cells.Item(1, $insertAt).Value2 = $name
  }

  foreach ($r in $rowMaps.Keys) {
    $parsed = $rowMaps[$r]
    for ($i = 0; $i -lt $allItems.Count; $i++) {
      $name = $allItems[$i]
      $qty = 0
      if ($parsed.ContainsKey($name)) { $qty = [int]$parsed[$name] }
      $ws.Cells.Item($r, $insertAt + $i).Value2 = $qty
    }
  }
  if ($totalRow -gt 0) {
    for ($i = 0; $i -lt $allItems.Count; $i++) {
      $col = $insertAt + $i
      $sum = 0
      foreach ($r in $rowMaps.Keys) {
        $v = $ws.Cells.Item($r, $col).Value2
        if ($v -is [int] -or $v -is [double]) { $sum += [int]$v }
      }
      $ws.Cells.Item($totalRow, $col).Value2 = $sum
    }
  }

  $dest = Join-Path $testDir "114學年掃具請領_已整理.xlsx"
  if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
  $wb.SaveAs($dest)
  Write-Host "已寫入同一個資料夾：$dest"
} finally {
  if ($wb) { $wb.Close($false) }
  if ($excel) { $excel.Quit() }
  [System.GC]::Collect()
  [System.GC]::WaitForPendingFinalizers()
}
