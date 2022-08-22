#!/bin/bash
#--------------------------------------------------------------------------------
# 処理概要
#   ユーザーアクセストークンを取得する。
# 
# パラメーター
#   なし。
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
# 設定
#--------------------------------------------------------------------------------
# 共通定義
source $(cd $(dirname $0); pwd)/common.sh
# シークレットファイル
source ${BAT_HOME}/secret.txt
# アクセストークン出力先ディレクトリ
readonly OUTPUT_DIR=${BAT_HOME}/tokens
mkdir -p ${OUTPUT_DIR}

declare -A auth=(
  ["oauth_token"]=""
  ["oauth_token_secret"]=""
  ["user_id"]=""
  ["screen_name"]=""
)

#--------------------------------------------------------------------------------
# 関数
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
# 処理概要
#   認証情報整理。
# 
# パラメーター
#   1: apiトークンレスポンス
#
# 返却
#   なし。
#--------------------------------------------------------------------------------
constructAuth() {
  [ $# -eq 1 ] || exit 1

  response_parts=(${1//&/ })

  for part in ${response_parts[@]}; do
    key_value=(${part//=/ })
    auth[${key_value[0]}]=${key_value[1]}
  done
}

#--------------------------------------------------------------------------------
# 処理概要
#   アクセストークンを保存。
# 
# パラメーター
#   1. 保存先ファイルパス
#
# 返却
#   なし。
#--------------------------------------------------------------------------------
saveAccessToken() {
  [ $# -eq 1 ] || exit 1

  echo "oauth_token=${auth["oauth_token"]}" > $1
  echo "oauth_token_secret=${auth["oauth_token_secret"]}" >> $1
  echo "user_id=${auth["user_id"]}" >> $1
  echo "screen_name=${auth["screen_name"]}" >> $1
}

#--------------------------------------------------------------------------------
# 主処理
#--------------------------------------------------------------------------------
# 処理開始
log "INFO" "処理を開始します。"

# パラメーター数チェック
if [ $# -ne 0 ]; then
  log "ERROR" "パラメーターが誤っています。(入力されたパラメーター: $*)"
  echo " * 実行方法: ./${0##*/}" |& tee -a ${LOG}
  exit 1
fi

# コマンド存在チェック
if !(type "curl" > /dev/null 2>&1); then
  log "ERROR" "curlコマンドが存在しません。"
  exit 1
fi

# リクエストトークンの取得
constructAuth $(curl -fsSw'\n' -X POST -H "Authorization: Bearer ${BEARER_TOKEN}" \
"https://api.twitter.com/oauth/request_token?oauth_consumer_key=${API_KEY}&oauth_callback=oob")

# PIN入力要求
pin=""
while [ -z "$pin" ]; do
  echo "以下のURLをブラウザで開き、「連携アプリを認証」ボタンを押下し、表示されるPINコードを入力してください。"
  echo "  https://api.twitter.com/oauth/authorize?oauth_token=${auth["oauth_token"]}"
  echo -n "PINコード> "
  read pin
done

# リクエストトークンをユーザーアクセストークンに変換
constructAuth $(curl -fsSw'\n' -X POST \
"https://api.twitter.com/oauth/access_token?oauth_verifier=${pin}&oauth_token=${auth["oauth_token"]}")

# アクセストークン保存
output=${OUTPUT_DIR}/${auth[screen_name""]}.txt
log "INFO" "アクセストークンを保存します。(保存先: ${output})"
saveAccessToken ${output}

# 処理終了
log "INFO" "処理を終了します。"
exit 0
