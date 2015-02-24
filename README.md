# NetInstaller for xyzzy

xyzzy のユーザー拡張ものへなちょこインストーラです。

## Requirement

* xyzzy-0.2.2.233+（で作ったので）
* 解凍用アーカイバDLL各種

## Install

解凍したら ni フォルダをsite-lisp以下に置いてください。

## Configuration

.xyzzyなどへ設定

    (require "ni/setup")
    ;; 自動設定を利用する
    (ni-autoload)
    ;; PROXYを通す場合
    ;(setq ni::*http-proxy-host* "proxy.host")  ; PROXY のホスト
    ;(setq ni::*http-proxy-port* 8080)          ; PROXY のポート

## Usage

    M-x netinstaller

最初はサイトが登録されていませんので、

    "a" => "http://www7a.biglobe.ne.jp/~hat/xyzzy/packages.l"

で登録してください。

配布サイト一覧は[xyzzy Wiki の NetInstaller/配布パッケージ一覧](http://xyzzy.s53.xrea.com/wiki/index.php?NetInstaller%2F%C7%DB%C9%DB%A5%D1%A5%C3%A5%B1%A1%BC%A5%B8%B0%EC%CD%F7)をご覧下さい。

## Key Binding

### サイト一覧
|キー|動作|
|----|----|
|Enter|パッケージ一覧を開く|
|Space|同上|
|r|その行のサイトを更新|
|R|全サイトを更新|
|a|URLまたはローカルファイルからサイトを追加|
|d|その行のサイトを削除|
|C-k|その行のサイトを切り取り|
|C-y|切り取ったサイトを貼り付け|
|o|サイトをブラウザで開く|
|q|終了|

### パッケージ一覧
|キー|動作|
|----|----|
|Enter|その行のパッケージのマークをつける／はずす|
|U|アップデートされたパッケージにマークをつける|
|a|全てのパッケージにマークをつける|
|A|全てのパッケージのマークをはずす|
|i|その行のパッケージをインストール|
|I|マークしたパッケージをインストール|
|d|その行のパッケージをアンインストール|
|D|マークしたパッケージをアンインストール|
|Space|その行のパッケージ詳細を表示|
|n|次の行のパッケージ詳細を表示|
|p|前の行のパッケージ詳細を表示|
|t|表示パッケージをトグル|
|q|パッケージ一覧を閉じる|

### パッケージ詳細
|キー|動作|
|----|----|
|Enter|詳細を閉じる|
|q|同上|
|f|その行のインストール済みファイルを開く|
|Space|次ページもしくは詳細を閉じる|
|n|次のパッケージ詳細を表示|
|p|前のパッケージ詳細を表示|

### インストール済みファイル
|キー|動作|
|----|----|
|Enter|ファイルを閉じる|
|Space|次ページ|
|BS|前ページ|
|q|ファイルを閉じる|

## Issues

* アンインストール時にディレクトリが消せない。
* その他たぶんいろいろあるでしょう。

## Misc

* NetInstaller向け配布方法は [HOWTO](HOWTO.md) を読んで下さい。

## Todo

* アップデートの時の処理とか。
* 依存関係をみるとか。

## Licence
[修正BSD](LICENCE.txt)

## Author
[torihat](https://github.com/torihat)
