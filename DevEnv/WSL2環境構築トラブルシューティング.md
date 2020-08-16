# WSL2環境構築トラブルシューティング

## /etc/wsl.conf が効かない  

wsl.conf によって wsl起動時のmountやwindows PATH 環境変数の引き継ぎなどを設定できるが, 
管理者権限のpower shell で明示的に再読み込みに相当と思われる処理を実行しないと, wsl.confファイルが有効にならない.
編集するたびに毎回Restart-Serviceが必要なので, 要注意である.  

すべてのterminalを終了したのち, 管理者権限で実行(Ctrl + shift + Enterで実行)したpowershell 上で

``` powershell
    Restart-Service LxssManager
```

設定値については
https://devblogs.microsoft.com/commandline/automatically-configuring-wsl/ に記述あり.
コメントにRestart-Serviceについて書かれている.

## WSLのshell上で ディレクトリ上で vscode を実行しようとしてもvscodeのGUIが開かない

気が付くと, 以下のような状態になっているかもしれない.

``` bash
/home/your_home_directory/code .
Command is only available in WSL or inside a Visual Studio Code terminal. 
```

このメッセージは、vscode-server のcodeであるコマンドライン (CLI) 版が実行されていることを示している.
vscode-serverのコマンドラインとは, Remote-WSL (やRemote-SSH) でvscodeから接続したときに生成されるものである. 指定したdistributionのterminal上で、localのWindowsのvscode を実行しても生成される. これらはvscodeのGUIを起動し、Remote-WSLで接続するために必要なもののようである. vscodeのGUIから接続したとき, vscode中のterminalではenvを見るとPATHの先頭にvscode-serverのbinが指定されている.
では実行すべきcodeはどれかというと, localのWindowsのvscode である. これに対するpathが通っていれば良い.
特に何も設定していなければ自然にWindowsの%PATH%がdistributionの\$PATHに引き継がれているため, codeを実行できる. 何らかの\$PATHの変更処理を実施しているために生じる問題である.
対策としては, "/mnt/c/Program Files/Microsoft VS Code/bin" をWindows上のcodeのパスとすると,
``` bash
export PATH=\$PATH:"/mnt/c/Program Files/Microsoft VS Code/bin" # double quote で囲むのがポイント.
```
$PATHを通せばよい(\$PATHとして$をエスケープしているのは, bashrc中で既存の設定を毎回引き継ぐため). 
/etc/wsl.conf にて Windows の %PATH% を引き継ぐ設定にしていれば特に対応不要であるが, 恐らく引き継がない設定にしたうえで, 明示的に必要なパスを追加指定するほうが無難だろう.

### 参考

- https://stackoverflow.com/questions/45114147/how-to-set-bash-on-ubuntu-on-windows-environment-variables-from-windows-pat
- よくわからないもの: https://github.com/Microsoft/WSL/issues/1766
- wslpath: 何やらどこかで使えそうなもの. https://laboradian.com/wslpath-command-for-wsl/

## docker コマンドが見つからない  

WSL2対応のdockerをインストールして, WSL Integration の設定がされていれば, distributionのPATH上でWindows上にインストールしたdockerとおそらく等価なexeを実行できる. /usr/bin/docker が存在しているため.

``` bash
$ which docker
/usr/bin/docker
```
```
$ ls -l /usr/bin/
...
lrwxrwxrwx  1 root   root          48  8月  8 19:48  docker -> /mnt/wsl/docker-desktop/cli-tools/usr/bin/docker
lrwxrwxrwx  1 root   root          56  8月  8 19:48  docker-compose -> /mnt/wsl/docker-desktop/cli-tools/usr/bin/docker-compose
...
```
となっている. docker daemonが起動すると /mnt/wsl にファイルが配置されるようである.
docker daemonを起動していないと, docker コマンドは見つからない. /usr/bin/docker 自体はあるが, /mnt/wsl/docker-desktop/cli-tools/ までしか存在しないため.

