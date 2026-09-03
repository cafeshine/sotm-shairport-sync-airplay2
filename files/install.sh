#!/bin/bash
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="5.2.2"

echo "=== SOTM shairport-sync AirPlay 2 升级包 v${VERSION} ==="

# 0. 检查运行环境
if [[ "$(uname -r)" != *"fc36"* ]]; then
  echo "⚠️  警告：非 Fedora 36 内核，当前 $(uname -r)，可能存在 glibc/kernel 不兼容"
fi

# 1. 停止旧服务
systemctl stop shairport-sync nqptp 2>/dev/null || true
systemctl disable shairport-sync nqptp 2>/dev/null || true

# 2. 备份旧配置
[[ -f /etc/shairport-sync.conf ]] && cp /etc/shairport-sync.conf /etc/shairport-sync.conf.bak.$(date +%s)

# 3. 安装二进制
install -m 755 "${PKG_DIR}/shairport-sync" /usr/local/bin/shairport-sync
install -m 755 "${PKG_DIR}/nqptp" /usr/local/bin/nqptp

# 4. 安装 systemd 服务
install -m 644 "${PKG_DIR}/nqptp.service" /etc/systemd/system/nqptp.service
install -m 644 "${PKG_DIR}/shairport-sync.service" /etc/systemd/system/shairport-sync.service

# 5. 安装配置（双路径同步：SOTM 管理端读 /etc，进程读 /usr/local/etc）
install -m 644 "${PKG_DIR}/shairport-sync.conf" /etc/shairport-sync.conf
mkdir -p /usr/local/etc
install -m 644 "${PKG_DIR}/shairport-sync.conf" /usr/local/etc/shairport-sync.conf

# 6. 确保用户/组存在
id -u nqptp &>/dev/null || useradd -r -s /sbin/nologin nqptp
usermod -a -G audio nqptp
usermod -a -G audio shairport-sync

# 7. 重载并启动
systemctl daemon-reload
systemctl enable nqptp shairport-sync
systemctl start nqptp
sleep 1
systemctl start shairport-sync

# 8. 验证
echo "=== 部署验证 ==="
systemctl is-active nqptp
systemctl is-active shairport-sync
journalctl -u shairport-sync -u nqptp --no-pager -n 20

echo "=== 完成 ==="
echo "AirPlay 服务名: sMS-1000SQ (mDNS: _airplay._tcp + _raop._tcp)"
echo "配置文件: /etc/shairport-sync.conf (管理端) / /usr/local/etc/shairport-sync.conf (运行时)"