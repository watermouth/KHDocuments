# RMarkdown know-how

## 日本語とggplot2を利用したpdfファイル出力

### はじめに

RStudioからrmarkdownを用いて簡単にソースコード, text, 動的に得られた図表を埋め込んだ
文書を作成できる. 
デフォルト設定ではhtmlファイルを出力する場合のみ容易に実現できる.
日本語を用いたpdfファイル出力, さらに日本語文字列を含むggplot2による画像の埋め込みなども行うには, 
LaTeX関連の設定が必要となる.
ここではそれをまとめておく.

### 利用環境

動作確認に用いた環境をまとめておく.

- OS: Windows 10 home
- RStudio: 1.2.5019
- R: 3.6.2

### 環境構築

- LaTeX環境: TinyTeX
- フォント: ipaex

``` r
install.packages("tinytex") # Rのtinytex パッケージ
tinytex::install_tinytex()  # TinyTeX本体のインストール
tinytex::tlmgr_install("ipaex") # IPAexフォントのインストール
```

- ref
    - https://shohei-doi.github.io/notes/posts/2019-04-12-rmarkdown-pdf/
    - https://www.karada-good.net/analyticsr/r-633

### rmarkdownファイルのyamlヘッダ

日本語pdf出力するために以下のような設定とする.

``` yaml
output:
  pdf_document: 
    latex_engine: xelatex 
    number_sections: true
documentclass: bxjsarticle
header-includes: 
  - \usepackage{zxjatype} 
  - \usepackage[ipa]{zxjafont} 
geometry: no
```

- ref
    - https://shohei-doi.github.io/notes/posts/2019-04-12-rmarkdown-pdf/

### knitrオプション設定

ggplot2で日本語含む図を出力する際に必要となる.

``` r
knitr::opts_chunk$set(
  dev = "cairo_pdf",
  dev.args = list(family = "ipaexg")
)
```

- ref
    - https://www.karada-good.net/analyticsr/r-633


## 画像出力位置調整

### コードブロックと画像の出力位置が前後しないように順に出力したい.

preamble fileを作成してそれを読み込むことでlatex設定を変えることで実現する.

https://stackoverflow.com/questions/16626462/figure-position-in-markdown-when-converting-to-pdf-with-knitr-and-pandoc

## kableを用いた表のサイズ・位置調整

基本的にknitr::kableを用いて表を出力する. 
kableExtraを用いることで実用上必要な調整が容易となる.

- ref
  - https://haozhu233.github.io/kableExtra/

### カラムが多く横に長い表を, 1 pageに横幅を合わせて収める

特にpdf出力する場合にすべてのカラムが表示されなくなるので用いる.
kableの出力結果に対して適用する.

``` r
kable_styling(latex_options = "scale_down")
```

