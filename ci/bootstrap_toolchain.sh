#!/usr/bin/env bash
# B0001：安裝 MoonBit 最新穩定版工具鏈。
# 為何裝在 /tmp/moon：MoonBit 工具鏈約 383MB（含 core 原始碼與各後端 bundle），
# 放進工程目錄會把工作區快照撐爆；工具鏈是「可重建的環境」而非交付物。
set -euo pipefail

MOON_HOME_DIR="${MOON_HOME_DIR:-/tmp/moon}"

if [[ -x "$MOON_HOME_DIR/bin/moon" ]]; then
  echo "[bootstrap] 已存在：$("$MOON_HOME_DIR/bin/moon" version)"
  exit 0
fi

echo "[bootstrap] 下載最新穩定版 MoonBit 到 $MOON_HOME_DIR ..."
tmp="$(mktemp -d)"
curl -fsSL https://cli.moonbitlang.com/install/unix.sh -o "$tmp/install.sh"
MOON_HOME="$MOON_HOME_DIR" bash "$tmp/install.sh" >/dev/null
rm -rf "$tmp"
echo "[bootstrap] 完成：$("$MOON_HOME_DIR/bin/moon" version)"
