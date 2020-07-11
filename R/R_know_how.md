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

