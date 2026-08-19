' 在已開啟的「114學年掃具請領.xlsx」執行
' 把「其他細項」拆成獨立欄位並加總計；另存同一個資料夾
' 用法：Alt+F11 → 插入 → 模組 → 貼上本檔 → 按 F5 執行 SplitOtherItems

Option Explicit

Function ParseItems(ByVal text As String) As Object
    Dim map As Object
    Set map = CreateObject("Scripting.Dictionary")
    If Len(Trim$(text & "")) = 0 Then
        Set ParseItems = map
        Exit Function
    End If
    Dim t As String, parts() As String, i As Long
    Dim p As String, name As String, qty As Long
    t = Trim$(text)
    t = Replace(t, ChrW(&HD7), "x")
    t = Replace(t, "＊", "*")
    t = Replace(t, "Ｘ", "x")
    t = Replace(t, "ｘ", "x")
    t = Replace(t, "０", "0")
    t = Replace(t, "１", "1")
    t = Replace(t, "２", "2")
    t = Replace(t, "３", "3")
    t = Replace(t, "４", "4")
    t = Replace(t, "５", "5")
    t = Replace(t, "６", "6")
    t = Replace(t, "７", "7")
    t = Replace(t, "８", "8")
    t = Replace(t, "９", "9")
    t = Replace(t, "、", " ")
    t = Replace(t, "，", " ")
    t = Replace(t, ",", " ")
    t = Replace(t, "　", " ")
    Do While InStr(t, "  ") > 0
        t = Replace(t, "  ", " ")
    Loop
    parts = Split(t, " ")
    For i = LBound(parts) To UBound(parts)
        p = Trim$(parts(i))
        If p <> "" Then
            name = ""
            qty = 1
            If ParseOne(p, name, qty) Then
                If map.Exists(name) Then
                    map(name) = CLng(map(name)) + qty
                Else
                    map.Add name, qty
                End If
            End If
        End If
    Next i
    Set ParseItems = map
End Function

Function ParseOne(ByVal p As String, ByRef name As String, ByRef qty As Long) As Boolean
    Dim re As Object, m As Object
    Set re = CreateObject("VBScript.RegExp")
    re.IgnoreCase = True
    re.Pattern = "^(.+?)[xX\*](\d+)(盒|個|包|組|支|條|張|本|瓶)?$"
    Set m = re.Execute(p)
    If m.Count > 0 Then
        name = Trim$(m(0).SubMatches(0))
        qty = CLng(m(0).SubMatches(1))
        ParseOne = (name <> "")
        Exit Function
    End If
    re.Pattern = "[xX\*]\d+(盒|個|包|組|支|條|張|本|瓶)?$"
    name = Trim$(re.Replace(p, ""))
    qty = 1
    ParseOne = (name <> "")
End Function

Sub SplitOtherItems()
    Dim ws As Worksheet
    Set ws = ActiveSheet
    Dim lastCol As Long, lastRow As Long, c As Long, r As Long
    Dim otherCol As Long, h As String
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    If lastRow < 2 Then lastRow = ws.UsedRange.Rows.Count

    otherCol = 0
    For c = 1 To lastCol
        h = Trim$(CStr(ws.Cells(1, c).Value & ""))
        If h = "其他細項" Or h = "其他細項原文" Then
            otherCol = c
            Exit For
        End If
    Next c
    If otherCol = 0 Then
        MsgBox "找不到「其他細項」欄", vbExclamation
        Exit Sub
    End If

    Dim names As Object, rowMaps As Object
    Set names = CreateObject("Scripting.Dictionary")
    Set rowMaps = CreateObject("Scripting.Dictionary")
    Dim totalRow As Long
    totalRow = 0
    Dim parsed As Object, k As Variant
    For r = 2 To lastRow + 5
        Dim probe As String
        probe = CStr(ws.Cells(r, 1).Value & "") & CStr(ws.Cells(r, 2).Value & "") & CStr(ws.Cells(r, 3).Value & "")
        If InStr(probe, "總計") > 0 Then
            totalRow = r
            Exit For
        End If
        If ws.Cells(r, otherCol).Value = "" And ws.Cells(r, 3).Value = "" And r > lastRow Then Exit For
        Set parsed = ParseItems(CStr(ws.Cells(r, otherCol).Value & ""))
        Set rowMaps(r) = parsed
        For Each k In parsed.Keys
            If Not names.Exists(CStr(k)) Then names.Add CStr(k), names.Count
        Next k
    Next r

    If names.Count = 0 Then
        MsgBox "其他細項沒有可拆的物品", vbInformation
        Exit Sub
    End If

    ws.Cells(1, otherCol).Value = "其他細項原文"
    Dim insertAt As Long, i As Long
    insertAt = otherCol + 1
    Dim arr() As String
    ReDim arr(0 To names.Count - 1)
    For Each k In names.Keys
        arr(names(k)) = CStr(k)
    Next k

    For i = 0 To UBound(arr)
        ws.Columns(insertAt).Insert Shift:=xlToRight
        ws.Cells(1, insertAt).Value = arr(i)
    Next i

    Dim rr As Variant, qty As Long
    For Each rr In rowMaps.Keys
        Set parsed = rowMaps(rr)
        For i = 0 To UBound(arr)
            qty = 0
            If parsed.Exists(arr(i)) Then qty = CLng(parsed(arr(i)))
            ws.Cells(CLng(rr), insertAt + i).Value = qty
        Next i
    Next rr

    If totalRow > 0 Then
        Dim sm As Long
        For i = 0 To UBound(arr)
            sm = 0
            For Each rr In rowMaps.Keys
                sm = sm + CLng(Val(ws.Cells(CLng(rr), insertAt + i).Value & ""))
            Next rr
            ws.Cells(totalRow, insertAt + i).Value = sm
        Next i
    End If

    Dim dest As String
    dest = ws.Parent.Path & "\114學年掃具請領_已整理.xlsx"
    Application.DisplayAlerts = False
    ws.Parent.SaveCopyAs dest
    Application.DisplayAlerts = True
    MsgBox "已存到同一個資料夾：" & vbCrLf & dest & vbCrLf & "物品：" & Join(arr, "、"), vbInformation
End Sub
