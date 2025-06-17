# Hostuno 共享主机 ANYTLS 一键部署脚本

🚀 专为 Hostuno 共享主机优化的 ANYTLS 代理服务器一键部署脚本，支持最新协议和特性。

## ✨ 特色功能

- 🎯 **共享主机优化** - 专门适配共享主机环境限制
- 🔐 **最新协议支持** - Reality TLS + WebSocket + H2Mux
- 🤖 **全自动部署** - 一键安装，无需手动配置
- 🌐 **多架构支持** - x86_64, ARM64, ARMv7
- 📊 **完整管理** - 启动/停止/重启/状态监控
- 🔧 **智能配置** - 自动生成随机端口、UUID、路径

## 🛠️ 支持的协议

- **ANYTLS** - 最新版本
- **Reality TLS** - 真实 TLS 指纹伪装
- **WebSocket** - HTTP 升级传输
- **XTLS-RPRX-Vision** - 高性能流控
- **H2Mux** - HTTP2 多路复用

## 🚀 快速开始

### 一键安装运行

```bash
bash <(curl -Ls https://raw.githubusercontent.com/你的用户名/hostuno-anytls-script/main/hostuno-anytls.sh)
```

### 下载后运行

```bash
# 下载脚本
wget https://raw.githubusercontent.com/你的用户名/hostuno-anytls-script/main/hostuno-anytls.sh

# 赋予执行权限
chmod +x hostuno-anytls.sh

# 运行脚本
./hostuno-anytls.sh
```

## 📋 使用说明

### 交互式菜单

直接运行脚本会显示交互式菜单：

```
========================================
    Hostuno 共享主机 ANYTLS 部署脚本
========================================

1. 安装 ANYTLS
2. 启动服务
3. 停止服务
4. 重启服务
5. 查看状态
6. 查看日志
7. 显示连接信息
8. 卸载
0. 退出
```

### 命令行参数

```bash
./hostuno-anytls.sh install    # 安装并启动服务
./hostuno-anytls.sh start      # 启动服务
./hostuno-anytls.sh stop       # 停止服务
./hostuno-anytls.sh restart    # 重启服务
./hostuno-anytls.sh status     # 查看运行状态
./hostuno-anytls.sh logs       # 查看运行日志
./hostuno-anytls.sh info       # 显示连接信息
./hostuno-anytls.sh uninstall  # 完全卸载
```

## 🖥️ 系统要求

- **操作系统**: Linux (CentOS, Ubuntu, Debian 等)
- **架构**: x86_64, ARM64, ARMv7
- **主机类型**: 共享主机、VPS、独立服务器
- **网络**: 需要访问外网下载程序
- **权限**: 用户目录写入权限

## 📁 安装目录结构

```
~/anytls-proxy/
├── anytls-server          # ANYTLS 服务器程序
├── config.json           # 服务器配置文件
├── anytls.log            # 运行日志
├── anytls.pid            # 进程 ID 文件
└── connection_info.txt   # 连接信息
```

## 🔧 配置说明

脚本会自动生成以下配置：

- **监听端口**: 随机生成 (10000-65535)
- **用户 UUID**: 自动生成唯一标识
- **传输路径**: 随机 8 位字符路径
- **TLS 域名**: 自动获取主机域名
- **Reality 配置**: 伪装目标 www.google.com

## 📱 客户端配置

安装完成后，脚本会自动生成客户端配置信息，保存在 `connection_info.txt` 文件中。

### 支持的客户端

- **V2rayN** (Windows)
- **V2rayNG** (Android)  
- **Shadowrocket** (iOS)
- **Clash** 系列客户端
- **sing-box** 客户端

## 🔍 常见问题

### Q: 安装失败怎么办？
A: 检查网络连接和权限，确保可以访问 GitHub 和下载文件。

### Q: 服务启动失败？
A: 查看日志 `./hostuno-anytls.sh logs`，通常是端口被占用或权限问题。

### Q: 无法连接？
A: 确认防火墙设置，检查端口是否开放，验证客户端配置。

### Q: 共享主机限制？
A: 脚本已优化共享主机环境，自动适配端口和资源限制。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE)。

## ⚠️ 免责声明

本脚本仅供学习和研究使用，请遵守当地法律法规。使用本脚本所产生的任何后果由使用者自行承担。

## 📞 支持

如有问题，请通过以下方式联系：

- 提交 [GitHub Issue](https://github.com/你的用户名/hostuno-anytls-script/issues)
- 发送邮件: your-email@example.com

---

⭐ 如果这个项目对您有帮助，请给一个 Star！
