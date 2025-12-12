#!/bin/bash
#
# メンバーを指定されたチームに追加するスクリプト
#
# 機能:
#   - 指定されたユーザーを複数のチームに追加
#   - ALL_MEMBERSチームに自動的に追加
#   - 既存メンバーはスキップ
#   - メンバーをアルファベット順にソート
#
# 使用方法:
#   ./add-member-to-teams.sh <username> [team1] [team2] ...
#
# 引数:
#   username: 追加するGitHubユーザー名 (必須)
#   team1, team2, ...: 追加先のチーム名 (任意個数、省略可)
#
# 出力:
#   標準出力: 追加に成功したチームのカンマ区切りリスト (例: "ALL_MEMBERS, DevOps, Backend")
#   標準エラー出力: 警告・エラーメッセージ
#
# 終了コード:
#   0: 成功
#   1: エラー (yqが未インストール、YAMLファイルが存在しない、チームが存在しないなど)
#

set -euo pipefail

# 引数チェック
if [ $# -lt 1 ]; then
  echo "Usage: $0 <username> [team1] [team2] [team3] ..." >&2
  exit 1
fi

USERNAME="$1"
shift
TEAMS=("ALL_MEMBERS" "$@")
YAML_FILE="data/teams.yaml"

# yqがインストールされているか確認
if ! command -v yq &> /dev/null; then
  echo "Error: yq is not installed. Please install yq first." >&2
  exit 1
fi

# YAMLファイルの存在確認
if [ ! -f "$YAML_FILE" ]; then
  echo "Error: $YAML_FILE not found." >&2
  exit 1
fi

# 追加に成功したチームを記録
ADDED_TEAMS=()

# 各チームにメンバーを追加
for TEAM in "${TEAMS[@]}"; do
  # チーム名の前後空白をトリム
  TEAM=$(echo "$TEAM" | xargs)
  
  # 空文字（改行やスペースのみ含むケース）を無視
  if [[ -z "${TEAM//[[:space:]]/}" ]]; then
    continue
  fi

  # チームが存在するか確認
  # .teams配列から指定されたnameを持つチームを検索し、存在しなければその内容を出力し、終了する
  if ! yq eval ".teams[] | select(.name == \"$TEAM\")" "$YAML_FILE" | grep -q .; then
    echo "Error: Team $TEAM not found in $YAML_FILE" >&2
    exit 1
  fi
  
  # メンバーが既にチームに存在するか確認
  # 指定されたチームの.members配列から、$USERNAMEと一致する要素を検索し、存在すればその内容を出力し、スキップする
  if yq eval ".teams[] | select(.name == \"$TEAM\") | .members[] | select(. == \"$USERNAME\")" "$YAML_FILE" | grep -q .; then
    echo "Warning: User $USERNAME already exists in team $TEAM, skipping..." >&2
    continue
  fi
  
  # チームにメンバーを追加
  # 1. 指定されたチームの.members配列に$USERNAMEを追加
  # 2. 追加後、その配列を大文字小文字を区別せずにアルファベット順にソート
  yq eval "(.teams[] | select(.name == \"$TEAM\") | .members) += [\"$USERNAME\"] | (.teams[] | select(.name == \"$TEAM\") | .members) |= sort_by(. | downcase) | .. style=\"double\"" -i "$YAML_FILE"
  
  ADDED_TEAMS+=("$TEAM")
done

# 追加に成功したチームをカンマ区切りで標準出力
IFS=', '
echo "${ADDED_TEAMS[*]}"
