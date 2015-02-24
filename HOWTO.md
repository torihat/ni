# NetInstaller for xyzzy HOWTO

## 配布方法

1. 配布物の作成

    * 配布物は (si:system-root) をルートに展開できるようにアーカイブする。
        * できればバイトコンパイルしたファイルを同梱する。
    * 自動設定ファイルは、"site-lisp/ni-autoload" 以下に置く。
        * ユーザーが (ni-autoload) する際に load される。
        * "サイト名/パッケージ名.l" など衝突しないファイル名にする。
        * バージョンアップ時に削除されるため、ユーザー編集はしない前提とする。
    * インストール後にロードされるファイル内でバイトコンパイルする場合には、バイト
コンパイルされたファイルがインストール済みファイルリストに入らないため、
ni::add-installed-files で、追加する。
        * 例：(ni::add-installed-files '("site-lisp/foo-mode.lc"))

2. 配布物リストファイル作成

    * 以下のような内容のファイルを作成する。


    ("name"        . "サイト名")
    ("author"      . "配布者")
    ("url"         . "サイトURL")
    ("description" . "サイト説明文")
    ("packages"      (("name"        . "配布物-1")
                      ("version"     . "バージョン")
                      ("author"      . "作成者（省略時はサイト配布者）")
                      ("file"        . "ファイル名")
                      ("src"         . "配布物URL")
                      ("description" . "配布物説明文")
                      ("md5"         . "配布物のmd5sum")
                      ("time"        . タイムスタンプ)
                      ("depends"     "依存する配布物-1" "依存する配布物-2")
                      ("category"     "カテゴリー-1" "カテゴリー-2")
                      ("changes"     . "変更点")
                      ("notice"      . "注意メッセージ")
                      ("load-after-install"    . "インストール後にロードするファイル")
                      ("load-before-uninstall" . "アンインストール前にロードするファイル"))
                     (("name"        . "foo-mode")
                      ("version"     . "0.0.0.1")
                      ("file"        . "foo-mode-0.0.0.1.lzh")
                      ("src"         . "http://www.mirai.ne.jp/~gyo/xyzzy/foo-mode-0.0.0.1.lzh")
                      ("description" . "foo mode")
                      ("md5"         . "9d6f21f9842b55aeb3675433316bd3ba")
                      ("time"        . 3257512712)
                      ("depends"     "bar-mode" "woo-mode")
                      ("category"     "Editing" "Games")
                      ("changes"     . "これこれが変わった")
                      ("notice"      . "これこれに注意")
                      ("load-after-install"    . "site-lisp/foo-mode/install.l")
                      ("load-before-uninstall" . "site-lisp/foo-mode/uninstall.l"))
     )



* local.l （リスト作成支援スクリプト）

    * ni::local-site-manage
        * サイトの新規作成・編集
    * ni::local-app-add
        * 配布物の追加・更新
    * ni::local-app-delete
        * 配布物をリストから削除
    * ni::*local-data-file*
        * 作成するファイル（デフォルトは "~/.netinst/packages.l"）
