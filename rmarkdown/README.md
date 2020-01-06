# RMarkdown know-how

## 日本語とggplot2を利用したpdfファイル出力

### はじめに

RStudioからrmarkdownを用いて簡単にソースコード, text, 動的に得られた図表を埋め込んだ
文書を作成できる. デフォルト設定ではhtmlファイルを出力する場合のみ容易に実現できる.
日本語を用いたpdfファイル出力, さらに日本語文字列を含むggplot2による画像の埋め込みなども行うには, 
LaTeX関連の設定が必要となる. ここではそれをまとめておく.

用いるrmarkdownのバージョンによって設定が異なる点があるので, 要注意.

### 利用環境

動作確認に用いた環境をまとめておく.

- OS: Windows 10 home
- RStudio: 1.2.5019
- R: 3.6.2
- rmarkdown: 1.X (失念したが2.0ではない. 2.0の場合についても言及する.)

### 必要なライブラリ等のinstall

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

### pandoc template file の修正

> rmarkdown 2.0 の場合はpandoc template 指定がなく, yamlでgeometryについて記述しないだけで良い.

knit (rmarkdown::render) を実行すると出てくるエラー

> ! LaTeX Error: Option clash for package geometry.

への対処として, 
yamlでno指定した上で, pandocのtemplateファイル中のgeometry部分をコメントアウト.

knit実行のlogをみると, 下のようにpandocを実行している部分がある.

``` text
"C:/Program Files/RStudio/bin/pandoc/pandoc" +RTS -K512m -RTS sample_fig_float_adjustment.utf8.md --to latex --from markdown+autolink_bare_uris+tex_math_single_backslash --output sample_fig_float_adjustment.tex --template "c:\Users\your_user_name_here\R\win-library\3.6\rmarkdown\rmd\latex\default-1.17.0.2.tex" --highlight-style tango --pdf-engine xelatex --include-in-header preamble_latex.tex --variable graphics=yes --lua-filter "c:/Users/your_user_name_here/R/win-library/3.6/rmarkdown/rmd/lua/pagebreak.lua" --lua-filter "c:/Users/your_user_name_here/R/win-library/3.6/rmarkdown/rmd/lua/latex-div.lua" --variable "compact-title:yes" 
```

この例だと
--template 
で指定されているファイル default-1.17.0.2.tex
について, 下のように%でコメントアウトする.

``` latex
$if(geometry)$
%\usepackage[$for(geometry)$$geometry$$sep$,$endfor$]{geometry}
$endif$
```

ちなみにrmarkdown 2.0の場合は下のようなコマンドが実行される.

``` text
"C:/Program Files/RStudio/bin/pandoc/pandoc" +RTS -K512m -RTS sample_fig_float_adjustment.utf8.md --to latex --from markdown+autolink_bare_uris+tex_math_single_backslash --output sample_fig_float_adjustment.tex --self-contained --highlight-style tango --pdf-engine xelatex --include-in-header preamble_latex.tex --variable graphics --lua-filter "c:/Users/your_user_name/R/win-library/3.6/rmarkdown/rmd/lua/pagebreak.lua" --lua-filter "c:/Users/your_user_name/R/win-library/3.6/rmarkdown/rmd/lua/latex-div.lua" --include-in-header "C:\Users\your_user_name\AppData\Local\Temp\RtmpWGApkP\rmarkdown-str496066c047fe.html" --include-in-header "C:\Users\your_user_name\AppData\Local\Temp\RtmpWGApkP\rmarkdown-str49603faa69d7.html"
```

- ref
  - https://qiita.com/nozma/items/1c6b000b674225fd40d7

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

rmarkdown v2.0の場合は
``` yaml
geometry: no
```
をつけない. つけるとエラーになる.

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


### trouble shooting

``` yaml
output:
  pdf_document: 
    keep_tex: true
    latex_engine: xelatex 
    number_sections: true
```

のように keep_tex: trueとしてtexファイルを確認する.


## 画像出力位置調整

### コードブロックと画像の出力位置が前後しないように順に出力したい.

preamble fileを作成してそれを読み込むことでlatex設定を変えることで実現する.
ただし, yamlのheader_includes と, includes: in_header: は両立できないようである (例外はあるようだが条件不明). そこでpreamble fileを使う場合には,
日本語利用のためのusepackage命令も含めて記述し, header_includesを使わないようにする.

``` yaml
output:
  pdf_document: 
    latex_engine: xelatex 
    number_sections: false
    includes:
      in_header: preamble_latex.tex
documentclass: bxjsarticle
geometry: no

```

preamble_latex.tex 

``` latex
\usepackage{float}
\let\origfigure\figure
\let\endorigfigure\endfigure
\renewenvironment{figure}[1][2] {
    \expandafter\origfigure\expandafter[H]
} {
    \endorigfigure
}
% include_headersで指定していたusepackage文をこちらに書いておく
\usepackage{zxjatype} 
\usepackage[ipa]{zxjafont}
```

- ref
  - https://stackoverflow.com/questions/16626462/figure-position-in-markdown-when-converting-to-pdf-with-knitr-and-pandoc
  - https://github.com/rstudio/rmarkdown/issues/816

- example: fig_float_adjustment

## kableを用いた表のサイズ・位置調整

基本的にknitr::kableを用いて表を出力する. 
kableExtraを用いることで実用上必要な調整が容易となる.

- example: sample_using_Japanese_output_pdf.Rmd

- ref
  - https://haozhu233.github.io/kableExtra/

### カラムが多く横に長い表を, 1 pageに横幅を合わせて収める

特にpdf出力する場合にすべてのカラムが表示されなくなるので用いる.
kableの出力結果に対して適用する.

``` r
kable_styling(latex_options = "scale_down")
```

