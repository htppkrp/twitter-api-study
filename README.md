# 3レッグ認証OAuthフロー
## 概要
- アプリの開発者アカウント以外のほかのユーザーのアクセストークンを取得する認証フロー。
  - ほかのユーザーに代わってツイートしたりするときなどはこの認証を使うようだ。

## 流れ
### 1. リクエストトークンを取得。
  ```
  POST https://api.twitter.com/oauth/request_token?oauth_consumer_key=${アプリのキー}&oauth_callback=oob"
  ```
  - https://developer.twitter.com/ja/docs/authentication/api-reference/request_token
  - oobはout-of-band OAuthの略で、リダイレクトを伴わない認証になるようだ。
    - PINベース認証などというようだ。
  - リクエストヘッダ―にベアラートークンが必要なようだ。
    ```
    curlの場合: -H "Authorization: Bearer {ベアラートークン}"
    ```

### 2. ユーザーにブラウザで「連携アプリを認証」ボタンを押下し、その後表示されるPINを入力してもらう。
  ```
  GET https://api.twitter.com/oauth/authorize?oauth_token={リクエストトークン}
  ```
  - https://developer.twitter.com/ja/docs/authentication/api-reference/authorize

### 3. ユーザーのアクセストークンを取得。
  ```
  POST https://api.twitter.com/oauth/access_token?oauth_verifier=${PIN}&oauth_token=${リクエストトークン}
  ```
  - https://developer.twitter.com/ja/docs/authentication/api-reference/access_token

## 実装
- get_access_token.sh

## 参考
- https://developer.twitter.com/ja/docs/authentication/oauth-1-0a/obtaining-user-access-tokens

# ツイートする
## 概要
- とてもめんどい。
- 動いたっぽいけどなんかよくわからない。
- 3日くらいたったら内容もう忘れてそう。

## 流れ
### 1. HTTPリクエストメソッドとURL
1. HTTPリクエストメソッドを調べる。
    - post
1. リソースURLを調べる。
    - https://api.twitter.com/1.1/statuses/update.json

### 2. パラメーターの収集
1. ツイートに必要なパラメーターを集める。
    |No|キー|説明|
    |:--|:--|:--|
    | 1 | status | ツイートする内容 |
    | 2 | oauth_consumer_key | アプリのキー |
    | 3 | oauth_nonce | リクエストごとにアプリで生成する一意のトークン |
    | 4 | oauth_signature_method | HMAC-SHA1固定 |
    | 5 | oauth_timestamp | UNIXエポック |
    | 6 | oauth_token | ツイートするユーザーのアクセストークン |
    | 7 | oauth_version | 1.0固定 |

1. キー、値をパーセントエンコードする。
1. キーでアルファベット順にソートする。
1. 「{キー}={値}&{キー}={値}&{キー}={値}...」のような感じでつなげる。

### 3. 署名ベース文字列の作成
1. 上記で調べたものを加工する。
    - HTTPリクエストメソッド --> 大文字にする。
    - リソースURL --> パーセントエンコードする。
    - パラメーター --> パーセントエンコードする。
1. 「{HTTPリクエストメソッド}&{リソースURL}&{パラメーター}」のような感じでつなげる。

### 4. 署名キーの取得
1. APIキーのシークレットとアクセストークンシークレットをパーセントエンコードする。
1. 「{APIキーのシークレット}&{アクセストークンシークレット}」のような感じでつなげる。

### 5. 署名の計算
1. 上記の署名ベース文字列を署名キーでハッシュ化する。(アルゴリズム: HMAC-SHA1)
1. BASE64でエンコードする。

### 6. ツイート
1. パラメーターと署名をリクエストヘッダーに混ぜてPOSTリクエスト送信。  
    - https://api.twitter.com/1.1/statuses/update.json

## 参考
- https://developer.twitter.com/ja/docs/authentication/oauth-1-0a/creating-a-signature
- https://developer.twitter.com/en/docs/twitter-api/v1/tweets/post-and-engage/api-reference/post-statuses-update
