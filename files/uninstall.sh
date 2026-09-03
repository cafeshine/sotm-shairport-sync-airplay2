#!/bin/bash
set -euo pipefail

echo "=== 回滚到 Fedora 36 原版 shairport-sync 4.3.3 ==="

systemctl stop shairport-sync nqptp 2>/dev/null || true
systemctl disable shairport-sync nqptp 2>/dev/null || true

# 删除自编译二进制
rm -f /usr/local/bin/shairport-sync /usr/local/bin/nqptp
rm -f /etc/systemd/system/nqptp.service /etc/systemd/system/shairport-sync.service
rm -f /usr/local/etc/shairport-sync.conf

# 恢复原 RPM 服务
systemctl daemon-reload
systemctl enable shairport-sync 2>/dev/null || true

# 恢复备份配置
LATEST_BAK=$(ls -t /etc/shairport-sync.conf.bak.* 2>/dev/null | head -1)
[[ -n "$LATEST_BAK" ]] && cp "$LATEST_BAK" /etc/shairport-sync.conf

systemctl start shairport-sync
echo "已回滚到 4.3.3 (systemd 服务已恢复)"