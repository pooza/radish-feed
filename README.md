# radish-feed

MastodonトゥートのAtomフィードを出力。

## ■設置の手順

### リポジトリをクローン

```
git clone git@github.com:pooza/radish-feed.git
```
クローンを行うとローカルにリポジトリが作成されるが、このディレクトリの名前は
変更しないことを推奨。（syslogのプログラム名や、設定ファイルのパス等に影響）

### 依存するgemのインストール

```
cd radish-feed
bundle install
```

Mastodonが既にインストールされているサーバで行えば、必要なライブラリはインストール済みのはず。  
万一エラーが出たら、都度必要なライブラリをインストール。

### local.yamlを編集

```
vi config/local.yaml
```

以下、設定例。

```
root_url: https://mstdn.example.com/ #インスタンスのルートURL
tz_offset: 9                         #タイムゾーン
entries:                             #フィードに出力するエントリー数
  max: 200                           #  上限
  default: 20                        #  未指定時デフォルト
slack:
  hook:
    url: https://hooks.slack.com/services/*********/*********/************************
```

- 上限エントリー数は、用途やサーバのスペックに合わせて。
- SlackのWebフックを指定すれば、実行中の例外がSlackに通知されるようになる。（省略可）  
  DiscordのSlack互換Webフックでの動作も確認済み。

### db.yamlを編集

```
vi config/db.yaml
```

以下、設定例。

```
host: localhost
user: postgres
password:
dbname: mastodon
port: 5432
```

パスワードは空欄（trust認証）とする。  
この設定例はデフォルト値だが、__完全に一致する場合は、db.yamlの作成自体不要。__

### syslog設定

radish-feedというプログラム名で、syslogに出力している。  
以下、rsyslogでの設定例。

```
:programname, isequal, "radish-feed" -/var/log/radish-feed.log
```

### リバースプロキシ設定

通常はMastodonインスタンスがインストールされたサーバに設置するだろうから、Mastodon本体同様、
nginxにリバースプロキシを設定。以下、nginx.confでの設定例。

```
  location ^~ /feed {
    proxy_pass http://localhost:3001;
  }
```

該当するserverブロックに上記追記し、nginxを再起動。

## ■操作

インストール先ディレクトリにchdirして、rakeタスクを実行する。  
root権限不要。

### 起動

```
bundle exec rake start
```

### 停止

```
bundle exec rake stop
```

### 再起動

```
bundle exec rake restart
```

## ■API

### GET /feed/v1.1/account/アカウント名

起動後に、設置先サーバに対して以下のGETを行うことで、Atom 1.0フィード
（IFTTT等からツイートを行うソースとしの用途を想定されたもの）を取得できる。  
設置先サーバを mstdn.example.com 、対象ユーザーをpoozaとして。

```
https://mstdn.example.com/feed/v1.1/account/pooza
```

この例では、local.yamlで設定したエントリー数（未指定時デフォルト）が使用される。  
もしpoozaが実在しないアカウント（又は鍵アカウント）である場合は、エラーのXML文書（ステータス404）が
返却される。  
また、出力されるフィードは、

- ブースト
- メンション（@）
- 投稿のプライバシーが「公開」以外

であるトゥートを含まない。  
tweetable=1&length=114がデフォルト。（後述）

### GET /feed/v1.1/local

ローカルタイムラインのAtom 1.0フィードを返す。  
出力されるフィードは、

- ブースト
- 投稿のプライバシーが「公開」以外
- 鍵アカウントからのもの

であるトゥートを含まない。  
個人のタイムラインと異なり、メンションも含むことに注意。

この抽出条件は、本来のローカルタイムラインと異なるかもしれない。  
ローカルタイムラインと同じものを出力することを優先したいので、予告なく仕様変更する
可能性がある。あしからず。

tweetable=0がデフォルト。（後述）

### GET /about

上記設定例ではリバースプロキシを設定していない為、一般ユーザーには公開されないが、
現状はプログラム名とバージョン情報だけを含んだ、簡単なXML文書を出力する。

curlがインストールされているなら、設置先サーバ上で以下実行。

```
curl http://localhost:3001/about
```

以下、レスポンス例。

```
HTTP/1.1 200 OK
Content-Type: application/xml;charset=utf-8
Content-Length: 109
X-Content-Type-Options: nosniff
Connection: close
Server: thin

<?xml version='1.0' encoding='UTF-8'?><result><status>200</status><message>toot-feed 0.3.0</message></result>
```

必要に応じて、監視などに使って頂くとよいと思う。

## ■オプション

/feed/v1.1/ から始まるAPIは、以下のオプションを指定可能。

### entries

以下のように、URLからエントリー数の指定を行うことが可能。  
但し、local.yamlで設定した上限値を越える値を指定しても無視される。

```
https://mstdn.example.com/feed/v1.1/account/pooza?entries=200
```

### tweetable

トゥート本文に手を加えない場合は、0又は空白。  
ツイート用の短い本文を出力する場合は、それ以外を指定。

通常、個人フィードはツイート用に短縮されるが、以下の様に指定を行えば全文が出力される。

```
https://mstdn.example.com/feed/v1.1/account/pooza?tweetable=0
```

### length

上記のtweetableが有効である場合に、本文の長さを指定。  
デフォルトは114、ツイート本文の末尾に短縮URLがひとつ入る想定の長さ。
また、半角文字はTwitterの仕様に従って0.5文字扱いとなる。

以下の様に指定すれば、本文の長さが100文字に。

```
https://mstdn.example.com/feed/v1.1/account/pooza?length=100
```

## ■設定ファイルの検索順

local.yamlやdb.yamlは、上記設置例ではconfigディレクトリ内に置いているが、
実際には以下の順に検索している。（ROOT_DIRは設置先）

- /usr/local/etc/radish-feed/local.yaml
- /usr/local/etc/radish-feed/local.yml
- /etc/radish-feed/local.yaml
- /etc/radish-feed/local.yml
- __ROOT_DIR__/config/local.yaml
- __ROOT_DIR__/config/local.yml
