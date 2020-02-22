# Python 開発環境に関するメモ

## 開発・分析作業時のディレクトリ構成について

### 動機

- Pythonを用いた開発・分析作業はRと同じように
REPLを使って動作・計算結果確認しながら行いたい.
Jupyter notebookを使えばそれは可能である.
- スクリプトとして実行することやライブラリ作成も行いたいので, 
packageやmoduleの開発に対しても同じように作業したい. 
つまりJupyter notebook上での作業だけを想定するのでは不便である.
- さらに作成したpackageやmoduleをJupyter notebookでimportしたい. 
各プロジェクトで毎回import用のpath(sys.path)を設定するのは手間である.

### 使用ツールと機能

#### vs code の Python Interactive Window 

.pyファイルに対して実行でき, jupyter notebookのように扱える. 
実際Jupyter notebook serverが動いている. 
しかし.ipynbファイルに対する純粋なJupyter notebook とは異なるUIである.

この機能はスクリプトの開発に便利である. 
但し, 他の自作packageやmoduleに依存するスクリプトの場合は, 
それらを参照できるモジュール検索パス(sys.path)となっているかどうかに注意が必要である.

デフォルトのcurrent directoryは,
Interactive Windowの開き方により異なる.
- .pyファイル上で"Run Current File In Python Interactive Window"を実行したときは, そのファイルが置いてあるディレクトリ. [1](#note1)

- command paltette にて"Python: Show Python Interactive Window"
を実行したときは, 自動的に作成される一時ディレクトリ
(ex. '/tmp/26ef657d-4952-4b33-a899-13fac6b8b5b2')

Interactive Window にて
``` python
import os
os.path.abspath(".")
```
により確認してみるとよい.

Interactive Windowを開いたときのcurrent directory を
予め自ら指定したディレクトリとするには, 
workspace directory の settings.json ファイルに
python.dataScience.runStartupCommands
を追記すればよい.
但し, "Show Python Interactive Window"
により実行した場合に限る. また, 
"Run Current File In Python Interactive Window" 
を実行した場合にはそのファイルのディレクトリとなる.[2](#note2)

``` json
{
    "python.dataScience.runStartupCommands": "import os\nos.chdir('DirectoryPathYouSpecify')",
}
```

これは

```
Preferences: Open Workspace Settings
```
の Extensions > Python にて 説明と値を確認したり, 
値を設定することができる.
Workspaceでないsettingsにも設定できるが, 
個別のプロジェクトに対するディレクトリ指定のような内容はworkspaceのsettings.json
に設定するのが良いだろう.

注意点を挙げる.

- "Python Interactive" tab のxボタンをクリックするだけでは
jupyter server は終了しておらず, 再度 Interactive Window 
を開いた際に先ほどの実行状態が残っている場合がある. 
明示的に "Restart IPython Kernel" を実行するとよい.

<small id="note1">*1 これを利用すると,ダミーの.pyファイルを所定のディレクトリにおいて何かprint文だけでも書いておけば,そのファイルに対して実行することでos.chdir関数の代りになる.
</small>

<small id="note2">*2 内部挙動としては "Show Python Interactive Window" の場合は一時ディレクトリをcurrent directory として jupyter notebook が起動 > runStartupCommands の実行 となり, "Run ~"の場合は指定されたファイルのディレクトリを current directory として jupyter notebook が起動している, ということなのかもしれない. いずれにせよ "Reload IPython Kernel" すれば runStartupCommands は実行される.
</small>

#### jupyter notebook



