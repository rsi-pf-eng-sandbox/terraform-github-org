#!/bin/bash

set -euo pipefail

# 引数チェック
if [ $# -lt 3 ]; then
  echo "Usage: $0 <username> <email> <role>" >&2
  exit 1
fi

USERNAME="$1"
EMAIL="$2"
ROLE="$3"
YAML_FILE="data/members.yaml"

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

# ユーザーが既に存在するか確認
# .members配列から指定されたusernameを持つ要素を検索し、存在すればその内容を出力して終了する
if yq eval ".members[] | select(.username == \"$USERNAME\")" "$YAML_FILE" | grep -q .; then
  echo "Error: User $USERNAME already exists in $YAML_FILE" >&2
  exit 1
fi

# 新しいメンバーを追加
# 1. .members配列に新しいオブジェクト{username, email, role}を追加
# 2. .membersを.usernameフィールドの値で大文字小文字を区別せずにアルファベット順にソート
yq eval ".members += [{\"username\": \"$USERNAME\", \"email\": \"$EMAIL\", \"role\": \"$ROLE\"}] | .members |= sort_by(.username | downcase) | .. style=\"double\"" -i "$YAML_FILE"

echo "Successfully added $USERNAME to $YAML_FILE"
