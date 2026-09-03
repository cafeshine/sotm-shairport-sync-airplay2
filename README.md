# SOTM shairport-sync AirPlay 2 升级包

基于 shairport-sync 5.2.2 源码编译，支持 AirPlay 1+2，适配 SOTM Eunhasu (Fedora 36)。

## 组件

| 组件 | 版本 | 说明 |
|------|------|------|
| shairport-sync | 5.2.2 | AirPlay 1+2, 源码编译, glibc 2.35 |
| nqptp | 1.2.8 | PTP 时钟同步, AirPlay 2 必需 |

## 关键补丁

`0001-start_threshold.patch` — Diretta 写穿透 ALSA 驱动适配：
- 将 `start_threshold` 强制设为 1 帧
- 防止 PCM 永远不 auto-start（Diretta 无硬件缓冲积累）

## SOTM 适配配置

| 参数 | 值 | 理由 |
|------|-----|------|
| `output_device` | `plughw:0,0` | SOTM: card 0 = DirettaDB16 (Diretta Target:Tone2 Pro) |
| `audio_backend_buffer_desired_length_in_seconds` | `5.0` | 解决 iOS 26.4+ AirPlay seek 卡死 |
| `disable_synchronization` | `yes` | Diretta 写穿透无硬缓冲，禁用 PTP 同步防 xrun |
| `buffer_size` | `96000` | 硬件缓冲 ~2s @ 44.1kHz |

## 实时调度

复用 SOTM 现有 `audio.slice`（与 MPD/Diretta 共享）：

| 参数 | 值 |
|------|-----|
| Nice | -18 |
| CPUSchedulingPolicy | rr |
| CPUSchedulingPriority | 49 |
| LimitRTPRIO | 98 |
| LimitMEMLOCK | infinity |

## 部署

```bash
scp shairport-sync-airplay2-sotm-fc36-v5.2.2.zip root@<sotm-ip>:/tmp/
ssh root@<sotm-ip>
cd /tmp && unzip shairport-sync-airplay2-sotm-fc36-v5.2.2.zip
cd shairport-sync-airplay2-sotm-fc36-v5.2.2
bash install.sh
```

## 回滚

```bash
bash uninstall.sh
```

## 配置文件双路径

SOTM 管理端和 shairport-sync 子进程各自读不同位置的配置：

| 文件 | 读进程 | 用途 |
|------|--------|------|
| `/etc/shairport-sync.conf` | shairport-sync 子进程 | 运行时配置 |
| `/usr/local/etc/shairport-sync.conf` | 备份（与 sysconfdir 同步） | 兼容 |

## mDNS 广播

```
AirPlay 1:  <MAC>@sMS-1000SQ    (_raop._tcp)
AirPlay 2:  sMS-1000SQ          (_airplay._tcp)
```

## 已知约束

- `disable_synchronization=yes` 防 Diretta 写穿透 xrun，但 `nqptp` 仍需运行以维持 AirPlay 2 握手
- 配置硬编码 `plughw:0,0` — Diretta 虚拟声卡必须是系统 Card 0
- `audio_backend_buffer_desired_length_in_seconds=5.0` 会增加播放启动延迟，换取 seek 稳定性

## GitHub Actions 编译

workflow 在 `fedora:36` 容器中编译，产出 zip 发布到 GitHub Releases。

手动触发：
```bash
# 打 tag
git tag shairport-sync-v5.2.2
git push origin shairport-sync-v5.2.2
```

或在 GitHub Actions 页面手动触发 `build.yml`。

## 目录结构

```
shairport-sync-airplay2/
├── patches/
│   └── 0001-start_threshold.patch      # Diretta 写穿透适配
├── files/
│   ├── shairport-sync.conf             # SOTM 适配配置
│   ├── nqptp.service                   # nqptp systemd 服务
│   ├── shairport-sync.service          # shairport-sync systemd 服务
│   ├── install.sh                      # 一键部署脚本
│   └── uninstall.sh                    # 回滚脚本
├── .github/workflows/
│   └── build.yml                       # GitHub Actions 编译 workflow
├── dist/                               # 编译产出（自动生成）
│   └── shairport-sync-airplay2-sotm-fc36-v*.zip
└── README.md                           # 本文档
```

## 编译依赖（Fedora 36）

```
make automake gcc gcc-c++ git autoconf
avahi-devel libconfig-devel openssl-devel popt-devel soxr-devel
ffmpeg ffmpeg-devel libplist-devel libsodium-devel libgcrypt-devel
libuuid-devel vim-common alsa-lib-devel
kernel-devel kernel-headers systemd-devel dbus-devel
```