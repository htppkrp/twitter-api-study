#!/bin/bash
#--------------------------------------------------------------------------------
# 処理概要
#   ツイートする。
#     事前にユーザーアクセストークンを取得しておくこと。
#
# パラメーター
#   1: ユーザー名(@のうしろ)
#   2: ツイート内容
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
# 設定
#--------------------------------------------------------------------------------
# 共通定義
source $(cd $(dirname $0); pwd)/common.sh
# シークレットファイル
source ${BAT_HOME}/secret.txt
# アクセストークン出力先ディレクトリ
readonly USER_INFO_DIR=${BAT_HOME}/tokens
# HTTPリクエストメソッド
readonly HTTP_METHOD="POST"
# リソースURL
readonly RESOURCE_URL="https://api.twitter.com/1.1/statuses/update.json"
# パラメーター
declare -A params

#--------------------------------------------------------------------------------
# 主処理
#--------------------------------------------------------------------------------
# 処理開始
log "INFO" "処理を開始します。"

# パラメーター数チェック
if [ $# -ne 2 ]; then
  log "ERROR" "パラメーターが誤っています。(入力されたパラメーター: $*)"
  echo " * 実行方法: ./${0##*/} {ユーザー名} {ツイート内容}" |& tee -a ${LOG}
  exit 1
fi

# ユーザー認証情報読み込み
source ${USER_INFO_DIR}/$1.txt

# コマンド存在チェック
if !(type "curl" > /dev/null 2>&1); then
  log "ERROR" "curlコマンドが存在しません。"
  exit 1
fi

# リクエストパラメーターの収集
params['status']=$2
params['oauth_consumer_key']=${API_KEY}
params['oauth_nonce']=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
params['oauth_signature_method']="HMAC-SHA1"
params['oauth_timestamp']=`date +%s`
params['oauth_token']=${oauth_token}
params['oauth_version']="1.0"
param_str=$(construct_params "params")

# 署名ベース文字列の作成
sig_base=$(create_sig_base ${HTTP_METHOD} ${RESOURCE_URL} ${param_str})

# 署名キーの取得
sig_key=$(create_sig_key ${API_KEY_SECRET} ${oauth_token_secret})

# 署名の計算
sig=$(create_sig "${sig_base}" "${sig_key}")

# ツイート
curl -sSw'\n' -X POST \
 -H "Authorization: OAuth oauth_consumer_key=\"${params['oauth_consumer_key']}\", oauth_nonce=\"${params['oauth_nonce']}\", oauth_signature=\"${sig}\", oauth_signature_method=\"${params['oauth_signature_method']}\", oauth_timestamp=\"${params['oauth_timestamp']}\", oauth_token=\"${params['oauth_token']}\", oauth_version=\"${params['oauth_version']}\"" \
 -d "status=$(encode $2)" \
 ${RESOURCE_URL}

# 処理終了
log "INFO" "処理を終了します。"
exit 0
