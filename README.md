# toot-feed
MastodonトゥートのAtomフィードを出力。

## ■設置の手順

### リポジトリをクローン

```
git clone git@github.com:pooza/toot-feed.git
```

### 依存するgemのインストール

```
cd toot-feed
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
```

最大エントリー数は、用途やサーバのスペックに合わせて。

### db.yamlを編集

```
vi config/db.yaml
```

以下、設定例。

```
hos: localhost
user: postgres
password:
dbname: mastodon
port: 5432
```

パスワードは空欄（trust認証）とする。  
この設定例はデフォルト値だが、__これらのパラメータが完全に一致する場合は、db.yamlの作成自体不要。__

### syslog設定

toot-feedというプログラム名で、syslogに出力している。  
必要に応じて、適宜設定。以下、rsyslogでの設定例。

```
:programname, isequal, "toot-feed" -/var/log/toot-feed.log
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

## ■API

### GET /feed/アカウント名

起動後に、設置先サーバに対して以下のGETを行うことで、Atom 1.0フィードを取得できる。  
設置先サーバを mstdn.example.com 、対象ユーザーをpoozaとして。

```
https://mstdn.example.com/feed/pooza
```

この例では、local.yamlで設定したエントリー数（未指定時デフォルト）が使用される。  
もしpoozaが実在しないアカウント（又は鍵アカウント）である場合は、エラーのXML文書（ステータス404）が
返却される。  
また、出力されるフィードは、
- ブースト
- メンション（@）
- 投稿のプライバシーが「公開」以外
であるトゥートを含まない。

以下の方法で、URLからエントリー数の指定を行うことが可能。

```
https://mstdn.example.com/feed/pooza?entries=200
```

但し、local.yamlで設定した上限値を越える値を指定しても無視される。  
なお、実行しているクエリーは以下のもの。

```
SELECT
  toots.uri,
  toots.created_at,
  toots.text
FROM statuses AS toots
  INNER JOIN accounts ON toots.account_id=accounts.id
WHERE (accounts.domain IS NULL)
  AND (accounts.locked='f')
  AND (accounts.username=$1)
  AND (toots.visibility=0)
  AND (toots.text<>'')
  AND (toots.uri IS NOT NULL)
  AND (toots.text !~* '@[.a-z0-9]+')
ORDER BY toots.created_at DESC
LIMIT $2 OFFSET 0;
```

IFTTTではアプレットを15分おきに起動し、都度上記のクエリーが実行されるので、負荷見積もりの
参考にして頂ければ。（config/query.yamlでも確認可能）

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




