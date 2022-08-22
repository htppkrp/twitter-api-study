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
