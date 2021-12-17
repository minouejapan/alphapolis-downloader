## alphapolis-downloader
アルファポリス小説ダウンローダー

### 動作環境
Windows10上のコマンドプロンプト上で動作します。

### 実行に必要なライブラリ
OpenSSL ver1.0.2が必要です。
https://github.com/IndySockets/OpenSSL-Binaries からopenssl-1.0.2q-i386-win32.zipをダウンロードして、zip書庫内の「libeay32.dll」と「ssleay32.dll」をalphadl.exeがあるフォルダにコピーして下さい。

### 実行ファイルの作り方
Delphi (XE2以降)でalphadl.dprを開いてビルドしてください。
または以下にて実行ファイルを入手してください。
http://m-and-i.cocolog-nifty.com/freetalk/cat24323473/index.html

### 使い方
コマンドプロンプト上で、
alphadl ダウンロードしたいアルファポリス小説トップページのURL (保存したいテキストファイル名)と入力して実行キーを押します。正常に実行されればalphadl.exeがあるフォルダにダウンロードした青空文庫形式のテキストファイルが補zんされます。

尚、保存したファイル名の指定は省略できます。省略した場合はダウンロードした小説のタイトル名からファイル名を作成して保存します。

### アルファポリスのダウンロードについて
Windows標準のインターネットAPIであるWinINetを用いたダウンロードでは、各話を連続してダウンロードすると20話程でダウンロード出来なくなります。しかしながらDelphi用のIndyライブラリを使用してダウンロードすると途中でダウンロード出来なくなる事象が発生しないようです。

### ライセンス
Apache2.0
