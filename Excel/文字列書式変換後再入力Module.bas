Attribute VB_Name = "Module1"
Option Explicit


Sub CheckTempTextFile(filePath As String)
    Dim tempfile As String
    tempfile = filePath
    Dim ret As Variant
    
    If Dir(tempfile) <> "" Then
        ret = MsgBox(filePath & "�����ɑ��݂��܂�. �㏑�����܂���", vbYesNo)
    Else
        ret = 6
    End If
    If ret <> 6 Then End
    
End Sub

Sub CopyToFile(wb As Workbook, sheetName As String, filePath As String)
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    wb.Worksheets(sheetName).Copy ' �R�s�[����Ɛ������Ă��܂�
    ' ����ňӐ}�ʂ肩�͗v�m�F: double quote �ň͂܂�Ă͂��邪�A�����������B -> ���߂��ۂ�
    ' ActiveWorkbook.SaveAs FileName:=filePath, FileFormat:=xlText
    ' ActiveWorkbook.SaveAs FileName:=filePath, FileFormat:=xlCSV ' �J���}��؂�. ���������.
    ActiveWorkbook.Close
    Application.DisplayAlerts = True
    Application.ScreenUpdating = True
End Sub

Sub SetCellFormat(wb As Workbook, sheetName As String)
    wb.Worksheets(sheetName).Cells.NumberFormatLocal = "@"
End Sub

Sub CopySheetToTextFile(sheet As Worksheet, filePath As String, rowSize As Integer, colSize As Integer)
    Application.ScreenUpdating = False
    Dim buf As String, bufArray As Variant, bufRow As Variant, n As Long, j As Long
    ReDim bufArray(rowSize, colSize)
    ' ������1�X�^�[�g�ɕς�邱�Ƃɒ���
    bufArray = Range(sheet.Cells(1, 1), sheet.Cells(rowSize, colSize)).Value ' sheet���w�肵�Ȃ���, �Ӑ}���Ȃ�sheet���Q�Ƃ��Ă��܂�.
    Open filePath For Output As #1
        n = 1
        Do Until n = rowSize
            buf = ""
            For j = 1 To colSize
                buf = buf & bufArray(n, j) & Chr(9)
            Next j
            Print #1, buf
            n = n + 1
        Loop
    Close #1
    Application.ScreenUpdating = True
End Sub

Sub PasteTextFileToSheet(filePath As String, sheet As Worksheet, rowSize As Integer, colSize As Integer)
    Application.ScreenUpdating = False
    Dim buf As String, bufArray As Variant, bufRow As Variant, n As Long, j As Long
    ReDim bufArray(rowSize, colSize)
    Open filePath For Input As #1
        n = 0
        Do Until n = rowSize - 1
            Line Input #1, buf
            bufRow = Split(buf, Chr(9)) ' tab
            'bufRow = Split(buf, ",")
            For j = 0 To colSize - 1
                bufArray(n, j) = bufRow(j)
            Next j
            n = n + 1
        Loop
    Close #1
    sheet.Range("A1").Resize(rowSize, colSize) = bufArray
    Application.ScreenUpdating = True
End Sub

Sub GetRegionShape(wb As Workbook, sheetName As String, ByRef rowCount As Integer, ByRef colCount As Integer)
    ' A1 sheet �� current region �̃T�C�Y���擾
    Dim ro As Range
    Set ro = wb.Worksheets(sheetName).Range("A1").CurrentRegion
        
    rowCount = ro.Rows.Count
    colCount = ro.Columns.Count
End Sub

Function JudgeAbsolutePathOrRelativePath(filePath As String)
    Dim FSO As Object
    Set FSO = CreateObject("Scripting.FileSystemObject")
    Dim ret As String
    If filePath = "" Then
        ret = ""
    ElseIf filePath = FSO.GetAbsolutePathName(filePath) Then
        ret = "absolute"
    Else
        ret = "relative"
    End If
    JudgeAbsolutePathOrRelativePath = ret
End Function

Sub exec()
    Dim filePath As String
    filePath = ThisWorkbook.Path & "\tempfile.txt"
    Call CheckTempTextFile(filePath)
    
    Dim filePathWorkBook As String
    filePathWorkBook = ThisWorkbook.Worksheets("main").Range("B1").Value
    If filePathWorkBook = "" Then
        MsgBox "B1�Z���ɉ��H�Ώ�workbook�̃t�@�C���p�X����͂��ĉ�����"
        End
    ElseIf JudgeAbsolutePathOrRelativePath(filePathWorkBook) = "relative" Then
        filePathWorkBook = ThisWorkbook.Path & "\" & filePathWorkBook
    End If
    Dim dirpath As String
    Dim FSO As Object
    Set FSO = CreateObject("Scripting.FileSystemObject")
    dirpath = FSO.GetParentFolderName(filePathWorkBook)
    
    Dim targetWorkBook As Workbook
    Set targetWorkBook = Workbooks.Open(filePathWorkBook)
    
    ' �e�V�[�g��ΏۂƂ���
    Dim targetSheet As Worksheet, idxWorkSheet As Long
    For idxWorkSheet = 1 To targetWorkBook.Worksheets.Count
        Set targetSheet = targetWorkBook.Sheets(idxWorkSheet)
        
        Dim sheetName As String
        sheetName = targetSheet.Name
        Dim rowCount As Integer, colCount As Integer
        Call GetRegionShape(targetWorkBook, sheetName, rowCount, colCount)
        
        'Call CopyToFile(targetWorkBook, sheetName, filePath)
        Call CopySheetToTextFile(targetWorkBook.Worksheets(sheetName), filePath, rowCount, colCount)
        ' �����ݒ�
        Call SetCellFormat(targetWorkBook, sheetName)
        ' �e�L�X�g�t�@�C������̃V�[�g�ւ̓\��t��: �����ŉ��߂ē\��t���邱�ƂɈӖ�������
        Call PasteTextFileToSheet(filePath, targetWorkBook.Worksheets(sheetName), rowCount, colCount)
        ' tempfile ���폜
        Kill filePath
    Next idxWorkSheet
    
    Dim newFilePathWorkbook As String
    newFilePathWorkbook = ThisWorkbook.Worksheets("main").Range("B2").Value
    If newFilePathWorkbook = "" Then
        newFilePathWorkbook = dirpath & "\" & "new.xlsx"
    ElseIf JudgeAbsolutePathOrRelativePath(newFilePathWorkbook) = "relative" Then
        newFilePathWorkbook = dirpath & "\" & newFilePathWorkbook
    End If
    targetWorkBook.SaveAs newFilePathWorkbook
    targetWorkBook.Close
    MsgBox "Done!"
End Sub
