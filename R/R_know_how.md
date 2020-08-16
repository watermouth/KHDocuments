# R know-how

## RStudio

### breakpoint を設定してsourceするとエラー

- 前提条件
  - Windows 10
  - RStudio: 1.2.5001
  - 日本語を含むRスクリプト (target.Rとする)
  - 対象スクリプトのエンコーディングはUTF-8
  - breakpoint設定済み

ctrl + shift + s で以下のようになる.

```r
> debugSource("target.R", encoding="UTF-8")
Error in parse(filename, encoding = encoding) : 
  invalid multibyte character in parser at line 76
```

対象スクリプトに対してparseを実行してもエラーが出るはずである.

``` r
parse("target.R", encoding="UTF-8")
```

ロケールの設定とencodingのずれが原因である.

``` r
>Sys.getlocale()
[1] "LC_COLLATE=Japanese_Japan.932;LC_CTYPE=Japanese_Japan.932;LC_MONETARY=Japanese_Japan.932;LC_NUMERIC=C;LC_TIME=Japanese_Japan.932"

```

UTF-8のファイルに対して ctlr + shift + s すると, encoding="UTF-8" が付与されてdebugSourceが実行されるのはよいのだが,
locale設定のcp932と整合しないで何やらエラーが出てしまう, ということのようである.

#### 対策

簡単な対策は一時的にでもcp932としてスクリプトを保存しなおすことである.

- ref
  - https://notchained.hatenablog.com/entry/2015/06/19/233502
  - https://github.com/rstudio/rstudio/issues/3026


### ファイルを開くときのデフォルトエンコーディングを指定する

global optionとproject optionがあり, Rのパッケージ開発プロジェクト中ではプロジェクトオプションが優先されることに注意する。


## readxlなどによるExcelファイルのデータ読み込み

Excelファイルにデータを保存して, それをRのreadxlやopenxlsxで読み込んで処理することがある.

### 小数を読み込むとExcel上で見えている数値から小さな値だけずれてしまう

#### 現象  

例えばsample_data_X1.xlsxファイルにExcelのセルA3に書式:標準で, 342.3902という値を入力したとする.
さらにB3セルの書式を文字列に変えてから, 342.3902という値を入力したとする.
Excel上で直接セルを選択するといずれも342.3902と表示されている.
このファイルをreadxlで読み込んで, 文字列として読み込むと, 
A3は 342.39019999999999となる(場合がある. B3は342.3902となる.

``` R
readxl::read_xlsx(path = "sample_data_X1.xlsx", col_types = "text", col_names = F)
New names:
* `` -> ...1
* `` -> ...2
# A tibble: 3 x 2
  ...1               ...2    
  <chr>              <chr>   
1 1.3                1.3     
2 60.1               60.1    
3 342.39019999999999 342.3902
```

ちなみに, 数値として読み込むと, 一見すると小数点以下が無視されるように見えるが, 
data.frameに変換したり直接値要素を表示すると, 342.3902として読み込めていることが確認できる.

``` R
readxl::read_xlsx(path = "sample_data_X1.xlsx", col_types = "numeric", col_names = F)

New names:
* `` -> ...1
* `` -> ...2
# A tibble: 3 x 2
   ...1  ...2
  <dbl> <dbl>
1   1.3   1.3
2  60.1  60.1
3 342.  342. 
 警告メッセージ: 
1:  read_fun(path = enc2native(normalizePath(path)), sheet_i = sheet,  で: 
  Coercing text to numeric in B1 / R1C2: '1.3'
2:  read_fun(path = enc2native(normalizePath(path)), sheet_i = sheet,  で: 
  Coercing text to numeric in B2 / R2C2: '60.1'
3:  read_fun(path = enc2native(normalizePath(path)), sheet_i = sheet,  で: 
  Coercing text to numeric in B3 / R3C2: '342.3902'
```

数値だけの列であれば数値として読み込めば特に問題はない.
文字列と数値が一列中に混在している場合は, 文字列として読み込むと, 意図しないずれが発生する場合があることになる.

#### 対策

1. csvファイルとして出力してから, csvファイルを読み込む  
  Excel上でcsvとして保存しなおすと, Excel上で見えている342.3902のままcsvに出力されることをテキストエディタで確認できる.  
  但し, Excelファイルを直接読み込むことを諦めることになる. シートが多数あるとそれなりに面倒そうであるし, 
  セル範囲を指定して読み込むなどもできなくなる.

2. Excelファイルの書式を文字列としてから値を入力したファイルを読み込む  
  これなら問題なく読み込める.  
  但し, Excelファイルにデータを用意する際にはすべての書式が文字列になっていないだろう. 
  従って, 元のExcelファイルから, 書式を文字列に変えて再入力したExcelファイルを用意する必要がある. 
  手動でやるならば, 以下の手順で用意できる.  

    1. Excelファイルを開いて, 該当シートの該当範囲を選択しコピーして空のテキストファイルに貼り付け  
      これでExcelファイル上での見た目のデータをテキストファイル上に退避できる.
    2. Excelファイルのシートの書式を文字列に変更 (または新しいExcelファイルを作成して全範囲の書式を文字列としておく)  
    3. 開いているテキストファイルの範囲全体をコピーして, 2.のExcelシートに貼り付けて保存する.  
    
    複数シートある場合は当然ながら各シート毎に実施する必要がある.

いろいろググりながら2.の作業を自動化するVBAコードを書いてみた.
xlsmファイル上で実行するようにハードコードしてあったり, セル範囲に対する前提条件があるため, 要注意である.

``` vb
Option Explicit


Sub CheckTempTextFile(filePath As String)
    Dim tempfile As String
    tempfile = filePath
    Dim ret As Variant
    
    If Dir(tempfile) <> "" Then
        ret = MsgBox(filePath & "が既に存在します. 上書きしますか", vbYesNo)
    Else
        ret = 6
    End If
    If ret <> 6 Then End
    
End Sub

Sub CopyToFile(wb As Workbook, sheetName As String, filePath As String)
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    wb.Worksheets(sheetName).Copy ' コピーすると生成してしまう
    ' これで意図通りかは要確認: double quote で囲まれてはいるが、いけそうか。 -> だめっぽい
    ' ActiveWorkbook.SaveAs FileName:=filePath, FileFormat:=xlText
    ' ActiveWorkbook.SaveAs FileName:=filePath, FileFormat:=xlCSV ' カンマ区切り. これもだめ.
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
    ' ここで1スタートに変わることに注意
    bufArray = Range(sheet.Cells(1, 1), sheet.Cells(rowSize, colSize)).Value ' sheetを指定しないと, 意図しないsheetを参照してしまう.
    Open filePath For Output As #1
        n = 0
        Do Until n = rowSize
            n = n + 1
            buf = ""
            For j = 1 To colSize
                buf = buf & bufArray(n, j) & Chr(9)
            Next j
            Print #1, buf
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
        Do Until n = rowSize ' この書き方だと rowSizeまで.
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
    ' A1 sheet の current region のサイズを取得
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
        MsgBox "B1セルに加工対象workbookのファイルパスを入力して下さい"
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
    
    ' 各シートを対象とする
    Dim targetSheet As Worksheet, idxWorkSheet As Long
    For idxWorkSheet = 1 To targetWorkBook.Worksheets.Count
        Set targetSheet = targetWorkBook.Sheets(idxWorkSheet)
        
        Dim sheetName As String
        sheetName = targetSheet.Name
        Dim rowCount As Integer, colCount As Integer
        Call GetRegionShape(targetWorkBook, sheetName, rowCount, colCount)
        
        'Call CopyToFile(targetWorkBook, sheetName, filePath)
        Call CopySheetToTextFile(targetWorkBook.Worksheets(sheetName), filePath, rowCount, colCount)
        ' 書式設定
        Call SetCellFormat(targetWorkBook, sheetName)
        ' テキストファイルからのシートへの貼り付け: ここで改めて貼り付けることに意味がある
        Call PasteTextFileToSheet(filePath, targetWorkBook.Worksheets(sheetName), rowCount, colCount)
        ' tempfile を削除
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

```

Rからreadxlを呼ぶ前に実行すれば, 手作業を挟まずに処理を連続的に実行できるようになる.
RからVBAを呼ぶにはどうすればばよいか. 以下を見ると, RDCOMClient を使えばよいらしい.

https://www.it-swarm.dev/ja/r/r%E3%81%8B%E3%82%89vba%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%97%E3%83%88%E3%82%92%E5%AE%9F%E8%A1%8C%E3%81%99%E3%82%8B/1041487102/

#### 参考

- https://github.com/tidyverse/readxl/issues/360
