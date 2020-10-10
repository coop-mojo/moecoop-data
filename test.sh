#!/bin/sh

if !(type ajv > /dev/null 2>&1); then
    echo "Command not found: ajv"
    exit 1
fi

if !(type jq > /dev/null 2>&1); then
    echo "Command not found: jq"
    exit 1
fi

if [ "$1" = "--dry-run" ]; then
    # --dry-run 時には validate 用のコマンドを表示するだけ
    eval_cmd=echo
else
    eval_cmd=eval
fi

cat .vscode/settings.json | \
# コメント行を削除
grep -v '//' | \
# fileMatch と url のペアからなる行を作成 || (.fileMatch | join(" "))
jq -r '.["json.schemas"] | map([.fileMatch[0], .url]) | .[] | @sh' | \
# URL decode
node -e 'console.log(decodeURI(require("fs").readFileSync("/dev/stdin", "utf8")))' | \
# 直前の console.log で生成された末尾の空行を削除
grep -v '^\s*$' | \
# 実行コマンドを生成
awk '{ printf "ajv --multiple-of-precision -s %s -d %s\n", $2, $1; }' | \
# パスを / 開始の絶対パスから ./ 開始の相対パスに変換
sed -e "s|'/|'./|g" | \
# 生成したコマンドを eval で実行
while read -r validate_cmd;
do
    $eval_cmd "$validate_cmd"
done
