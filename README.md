## alphapolis-downloader
aplhadlはアルファポリスで公開されている小説を青空文庫形式のテキストファイルでダウンロードするためのツールです。
尚、ダウンロードしたい作品に有料部分が含まれている場合、その部分はダウンロード出来ません。

### 動作環境
Windows10/11上のコマンドプロンプト上で動作します。

### 実行ファイルの作り方
Delphi (XE2以降)でalphadl.dprを開いてビルドしてください。

### 使い方
コマンドプロンプト上で、
alphadl ダウンロードしたいアルファポリス小説トップページのURL (保存したいテキストファイル名)と入力して実行キーを押します。正常に実行されればalphadl.exeがあるフォルダにダウンロードした青空文庫形式のテキストファイルが補zんされます。

尚、保存したファイル名の指定は省略できます。省略した場合はダウンロードした小説のタイトル名からファイル名を作成して保存します。

### アルファポリスのダウンロードについて
アルファポリスサイトのダウンロード制限対応が強化されたようで、Indyライブラリ利用での制限回避が出来なくなりました。
そのため、ダウンロード制限中は処理を待機させて制限解除後にダウンロード、また制限されたら待機、を繰り返すことでダウンロードを確実に完了させるようにしました。このことにより、作品の完全なダウンロードは可能なものの完了するまでに多大な時間がかかるようになりました（目安は２０話ダウンロード毎に５分間待機です：１００話ダウンロードする場合は（１００÷２０）×５分＝２５分＋α必要です）。
もっと実用的な速度でダウンロードしたい場合は、
https://m-and-i.cocolog-nifty.com/freetalk/cat24323473/index.html
からWindows版アプリケーション版のalphadlw.exeをダウンロードして下さい。

### ライセンス
MIT
