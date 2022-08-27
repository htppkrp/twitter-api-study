#!/bin/bash
#--------------------------------------------------------------------------------
# 処理概要
#   共通設定・定義
# 
# パラメーター
#   なし
#-------------------------------------------------------------------------------
set -u -o pipefail
export LC_ALL=C

#--------------------------------------------------------------------------------
# 設定
#--------------------------------------------------------------------------------
# プロジェクト名
readonly PROJ="twitter-api-study"
# バッチホーム
readonly BAT_HOME=$(cd $(dirname $0); pwd)
# ログ出力先ディレクトリ
readonly LOG_DIR="${BAT_HOME}/logs"
mkdir -p ${LOG_DIR}
# ログバックアップ保管先ディレクトリ
readonly LOG_BAK_DIR="${LOG_DIR}/bak"
mkdir -p ${LOG_BAK_DIR}
# ログ出力先
readonly LOG="${LOG_DIR}/${PROJ}.log"

#--------------------------------------------------------------------------------
# 関数
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
# 処理概要
#   ログ出力
# 
# パラメーター
#   1: ログレベル
#   2: ログメッセージ
#
# 返却(標準出力・標準エラー出力)
#   yyyy-mm-dd HH:MM:SS.SSS {LEVEL} {PID} -- {MESSAGE}
#--------------------------------------------------------------------------------
log() {
  [ $# -eq 2 ] || exit 1

  date_time=`date "+%Y-%m-%d %H:%M:%S.%3N"`
  level=$1
  pid=$$
  message=$2

  echo "${date_time} ${level} ${pid} -- ${message}" |& tee -a ${LOG}
}

#--------------------------------------------------------------------------------
# 処理概要
#   エンコード。
#     パーセントエンコードします。
# 
# パラメーター
#   1: 元文字列
#
# 返却
#   エンコード後文字列
#--------------------------------------------------------------------------------
encode() {
 echo "$(echo -n $1 | curl -s -w '%{url_effective}\n' --data-urlencode @- -G '' | cut -c 3-)"
}

#--------------------------------------------------------------------------------
# 処理概要
#   パラメーターの組み立て。
#     署名されるすべてのキーと値をパーセントエンコードします。
#     パラメーターのリストをエンコードされたキーでアルファベット順に並べ替えます。
#     それぞれのキーと値のペアに対して:
#       出力文字列にエンコードされたキーを追加します。
#       出力文字列に「=」を追加します。
#       出力文字列にエンコードされた値を追加します。
#       キーと値のペアがまだ残っている場合は、出力文字列に「&」を追加します。
# 
# パラメーター
#   1: パラメーターの連想配列名
#
# 返却
#   パラメーター文字列({キー}={値}&{キー}={値}&{キー}={値}...)
#--------------------------------------------------------------------------------
construct_params() {
  local -n ref=$1
  local encoded_params=()

  for param in "${!ref[@]}"; do
    encoded_params+=("$(encode ${param})=$(encode ${ref[${param}]})")
  done
  param_str="$(IFS=$'\n'; echo "${encoded_params[*]}")"
  echo $(echo "${param_str}" | sort -t '=' -k 1) | tr ' ' '&'
}

#--------------------------------------------------------------------------------
# 処理概要
#   署名ベース文字列の作成。
#     HTTPメソッドを大文字に変換し、出力文字列をこの値に設定します。
#     出力文字列に「&」を追加します。
#     URLをパーセントエンコードし、出力文字列に追加します。
#     出力文字列に「&」を追加します。
#     パラメーター文字列をパーセントエンコードし、出力文字列に追加します。
# 
# パラメーター
#   1: HTTPメソッド
#   2: ベースURL
#   3: パラメーター文字列
#
# 返却
#   署名ベース文字列
#--------------------------------------------------------------------------------
create_sig_base() {
  echo "${1^^}&$(encode $2)&$(encode $3)"
}

#--------------------------------------------------------------------------------
# 処理概要
#   署名キーの作成。
# 
# パラメーター
#   1: アクセストークン
#   2: アクセストークンシークレット
#
# 返却
#   署名キー
#--------------------------------------------------------------------------------
create_sig_key() {
  echo "$(encode $1)&$(encode $2)"
}

#--------------------------------------------------------------------------------
# 処理概要
#   署名の作成。
#     署名ベース文字列と署名キーをHMAC-SHA1ハッシュアルゴリズムに渡すことによって署名が計算されます。
#     HMAC署名関数の出力はバイナリー文字列で、署名文字列を生成するためにbase64エンコードする必要があります。
#
# パラメーター
#   1: 署名ベース
#   2: 署名キー
#
# 返却
#   署名
#--------------------------------------------------------------------------------
create_sig() {
  local sig=$(echo -n "$1" | openssl dgst -sha1 -binary -hmac "$2" | base64)
  echo $(encode ${sig})
}
