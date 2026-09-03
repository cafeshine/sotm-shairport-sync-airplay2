#!/bin/bash
set -euo pipefail

# 本地打包脚本（不编译，直接打包 files/ + patches/ 为分发包）
# 编译产出的二进制需手动放入 files/ 目录

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${1:-5.2.2}"
PKG="shairport-sync-airplay2-sotm-fc36-v${VERSION}"
DIST_DIR="${SCRIPT_DIR}/dist"

echo "=== 打包 ${PKG} ==="

# 检查必要文件
for f in shairport-sync nqptp; do
  if [[ ! -f "${SCRIPT_DIR}/files/${f}" ]]; then
    echo "❌ 缺少 files/${f}，请先通过 GitHub Actions 编译或手动编译后放入 files/"
    exit 1
  fi
done

# 创建临时目录
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

mkdir -p "${TMP}/usr/local/bin" "${TMP}/etc" "${TMP}/usr/lib/systemd/system" "${TMP}/usr/local/etc"

# 复制文件
cp "${SCRIPT_DIR}/files/shairport-sync" "${TMP}/usr/local/bin/"
cp "${SCRIPT_DIR}/files/nqptp" "${TMP}/usr/local/bin/"
cp "${SCRIPT_DIR}/files/shairport-sync.conf" "${TMP}/etc/"
cp "${SCRIPT_DIR}/files/shairport-sync.conf" "${TMP}/usr/local/etc/"
cp "${SCRIPT_DIR}/files/nqptp.service" "${TMP}/usr/lib/systemd/system/"
cp "${SCRIPT_DIR}/files/shairport-sync.service" "${TMP}/usr/lib/systemd/system/"
cp "${SCRIPT_DIR}/files/install.sh" "${TMP}/"
cp "${SCRIPT_DIR}/files/uninstall.sh" "${TMP}/"
echo "${VERSION}" > "${TMP}/VERSION"

chmod +x "${TMP}/install.sh" "${TMP}/uninstall.sh" "${TMP}/usr/local/bin/"*

# 打包
mkdir -p "${DIST_DIR}"
cd "${TMP}" && zip -r "${DIST_DIR}/${PKG}.zip" .

echo "✅ ${DIST_DIR}/${PKG}.zip ($(du -h "${DIST_DIR}/${PKG}.zip" | cut -f1))"
echo "   部署: scp ${DIST_DIR}/${PKG}.zip root@<sotm-ip>:/tmp/"