#!/usr/bin/env bash
# 將 _export/hello-world 同步推上 copyshae/hello-world master（需 HELLO_WORLD_TOKEN 或本機 git 權限）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXPORT="$ROOT/_export/hello-world"
TOKEN="${HELLO_WORLD_TOKEN:-}"

if [ ! -d "$EXPORT/directory" ]; then
  echo "找不到 $EXPORT/directory" >&2
  exit 1
fi

WORKDIR="${TMPDIR:-/tmp}/hw-push-$$"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

if [ -n "$TOKEN" ]; then
  git clone --depth 1 --branch master "https://x-access-token:${TOKEN}@github.com/copyshae/hello-world.git" "$WORKDIR"
else
  echo "未設定 HELLO_WORLD_TOKEN，改用本機已 clone 的 hello-world（若存在）"
  LOCAL="${HELLO_WORLD_PATH:-$HOME/Desktop/hello-world}"
  if [ ! -d "$LOCAL/.git" ]; then
    echo "請設定 HELLO_WORLD_TOKEN，或 clone hello-world 到 $LOCAL" >&2
    exit 1
  fi
  cp -a "$LOCAL" "$WORKDIR"
  cd "$WORKDIR"
  git fetch origin master
  git checkout master
  git pull origin master
fi

mkdir -p "$WORKDIR/directory/apps" "$WORKDIR/directory/202608"

copy_app() {
  local name="$1"
  local src="$2"
  mkdir -p "$WORKDIR/directory/apps/$name"
  cp -a "$src/." "$WORKDIR/directory/apps/$name/"
}

copy_app habits-7 "$EXPORT/directory/apps/habits-7"
copy_app daily-14 "$ROOT/docs/daily-14"
copy_app doc-reader "$ROOT/docs/doc-reader"
copy_app dizigui-41 "$ROOT/docs/dizigui-41"
copy_app taiyang-music "$ROOT/docs/taiyang-music"

for n in 20 21 22 23 24 25 26 27 28 29; do
  f="$EXPORT/directory/202608/202608${n}-learning-log.html"
  [ -f "$f" ] && cp -f "$f" "$WORKDIR/directory/202608/"
done
cp -f "$EXPORT/directory/202608/index.html" "$WORKDIR/directory/202608/"
cp -f "$EXPORT/directory/index.html" "$WORKDIR/directory/"
cp -f "$EXPORT/directory/learning-log.html" "$WORKDIR/directory/"

cd "$WORKDIR"
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A
if git diff --cached --quiet; then
  echo "hello-world 已是最新，無需推送"
  exit 0
fi
git commit -m "同步學習日誌 0821–0829 與 App 匯出（0821 14樣／0822 七習慣／0823 看書文件／0824 弟子規／0825–0829 盛德KTV）"
git push origin master
echo "已推上 hello-world master"
echo "最新：https://copyshae.github.io/hello-world/directory/202608/20260829-learning-log.html"
