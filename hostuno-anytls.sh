#!/bin/bash

# Hostuno 共享主机 ANYTLS 代理部署脚本
# 适用于 s2.hostuno.com 或其他共享主机环境
# 使用最新的 ANYTLS 协议

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
SCRIPT_DIR="$HOME/anytls-proxy"
CONFIG_FILE="$SCRIPT_DIR/config.json"
LOG_FILE="$SCRIPT_DIR/anytls.log"
PID_FILE="$SCRIPT_DIR/anytls.pid"
BINARY_NAME="anytls-server"
DOWNLOAD_URL="https://github.com/XTLS/ANYTLS/releases/latest/download"

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 检查系统架构
get_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "linux-amd64"
            ;;
        aarch64)
            echo "linux-arm64"
            ;;
        armv7l)
            echo "linux-armv7"
            ;;
        *)
            print_message $RED "不支持的架构: $arch"
            exit 1
            ;;
    esac
}

# 检查共享主机环境
check_shared_hosting() {
    print_message $BLUE "检查共享主机环境..."
    
    # 检查是否有足够的权限
    if [ ! -w "$HOME" ]; then
        print_message $RED "错误: 没有写入权限"
        exit 1
    fi
    
    # 检查端口范围 (共享主机通常限制端口)
    local test_port=$(shuf -i 10000-65535 -n 1)
    print_message $GREEN "检测到共享主机环境，将使用端口范围: 10000-65535"
    
    # 检查内存限制
    local mem_limit=$(ulimit -v 2>/dev/null || echo "unlimited")
    print_message $YELLOW "内存限制: $mem_limit"
}

# 生成随机端口
generate_port() {
    local port
    while true; do
        port=$(shuf -i 10000-65535 -n 1)
        if ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo $port
            break
        fi
    done
}

# 生成UUID
generate_uuid() {
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    else
        cat /proc/sys/kernel/random/uuid 2>/dev/null || \
        python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || \
        od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'
    fi
}

# 生成随机路径
generate_path() {
    echo "/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
}

# 下载 ANYTLS 二进制文件
download_anytls() {
    print_message $BLUE "下载 ANYTLS 服务器..."
    
    local arch=$(get_arch)
    local binary_url="${DOWNLOAD_URL}/anytls-${arch}"
    
    mkdir -p "$SCRIPT_DIR"
    cd "$SCRIPT_DIR"
    
    # 下载二进制文件
    if command -v wget >/dev/null 2>&1; then
        wget -O "$BINARY_NAME" "$binary_url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$BINARY_NAME" "$binary_url"
    else
        print_message $RED "错误: 需要 wget 或 curl 来下载文件"
        exit 1
    fi
    
    chmod +x "$BINARY_NAME"
    print_message $GREEN "ANYTLS 服务器下载完成"
}

# 生成配置文件
generate_config() {
    print_message $BLUE "生成 ANYTLS 配置文件..."
    
    local port=$(generate_port)
    local uuid=$(generate_uuid)
    local path=$(generate_path)
    local domain=$(hostname -f 2>/dev/null || echo "localhost")
    
    # 获取服务器IP
    local server_ip=$(curl -s ip.sb 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")
    
    cat > "$CONFIG_FILE" << EOF
{
    "log": {
        "level": "info",
        "output": "$LOG_FILE"
    },
    "inbounds": [
        {
            "type": "mixed",
            "listen": "0.0.0.0",
            "listen_port": $port,
            "users": [
                {
                    "uuid": "$uuid",
                    "flow": "xtls-rprx-vision"
                }
            ],
            "tls": {
                "enabled": true,
                "server_name": "$domain",
                "reality": {
                    "enabled": true,
                    "handshake": {
                        "server": "www.google.com",
                        "server_port": 443
                    },
                    "private_key": "$(openssl rand -base64 32)",
                    "short_id": [
                        "$(openssl rand -hex 8)"
                    ]
                }
            },
            "transport": {
                "type": "ws",
                "path": "$path",
                "headers": {
                    "Host": "$domain"
                },
                "early_data_header_name": "Sec-WebSocket-Protocol"
            },
            "multiplex": {
                "enabled": true,
                "protocol": "h2mux",
                "max_connections": 4,
                "min_streams": 4,
                "max_streams": 0,
                "padding": false
            }
        }
    ],
    "outbounds": [
        {
            "type": "direct",
            "tag": "direct"
        },
        {
            "type": "block",
            "tag": "block"
        }
    ],
    "route": {
        "rules": [
            {
                "geoip": "private",
                "outbound": "direct"
            },
            {
                "geoip": "cn",
                "outbound": "direct"
            }
        ]
    }
}
EOF

    print_message $GREEN "配置文件生成完成"
    
    # 保存连接信息
    cat > "$SCRIPT_DIR/connection_info.txt" << EOF
=== ANYTLS 连接信息 ===
服务器地址: $server_ip
端口: $port
UUID: $uuid
路径: $path
传输协议: WebSocket
TLS: 启用 (Reality)
域名: $domain

=== 客户端配置 ===
{
    "outbounds": [
        {
            "type": "vless",
            "server": "$server_ip",
            "server_port": $port,
            "uuid": "$uuid",
            "flow": "xtls-rprx-vision",
            "tls": {
                "enabled": true,
                "server_name": "$domain",
                "reality": {
                    "enabled": true,
                    "public_key": "从服务器日志获取"
                }
            },
            "transport": {
                "type": "ws",
                "path": "$path",
                "headers": {
                    "Host": "$domain"
                }
            }
        }
    ]
}
EOF
}

# 启动服务
start_service() {
    print_message $BLUE "启动 ANYTLS 服务..."
    
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        print_message $YELLOW "服务已在运行"
        return
    fi
    
    cd "$SCRIPT_DIR"
    nohup ./"$BINARY_NAME" run -c "$CONFIG_FILE" > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    
    sleep 3
    
    if kill -0 $pid 2>/dev/null; then
        print_message $GREEN "ANYTLS 服务启动成功 (PID: $pid)"
    else
        print_message $RED "ANYTLS 服务启动失败"
        cat "$LOG_FILE"
        exit 1
    fi
}

# 停止服务
stop_service() {
    print_message $BLUE "停止 ANYTLS 服务..."
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            kill $pid
            rm -f "$PID_FILE"
            print_message $GREEN "ANYTLS 服务已停止"
        else
            print_message $YELLOW "服务未运行"
            rm -f "$PID_FILE"
        fi
    else
        print_message $YELLOW "PID 文件不存在"
    fi
}

# 查看状态
check_status() {
    print_message $BLUE "检查服务状态..."
    
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        local pid=$(cat "$PID_FILE")
        print_message $GREEN "ANYTLS 服务正在运行 (PID: $pid)"
        
        # 显示端口占用
        if command -v netstat >/dev/null 2>&1; then
            netstat -tuln | grep -E ":($(grep -o '"listen_port": [0-9]*' "$CONFIG_FILE" | cut -d':' -f2 | tr -d ' '))" || true
        fi
    else
        print_message $RED "ANYTLS 服务未运行"
    fi
}

# 查看日志
view_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_message $BLUE "最近的日志:"
        tail -20 "$LOG_FILE"
    else
        print_message $YELLOW "日志文件不存在"
    fi
}

# 显示连接信息
show_connection_info() {
    if [ -f "$SCRIPT_DIR/connection_info.txt" ]; then
        print_message $CYAN "$(cat "$SCRIPT_DIR/connection_info.txt")"
    else
        print_message $RED "连接信息文件不存在"
    fi
}

# 卸载
uninstall() {
    print_message $BLUE "卸载 ANYTLS..."
    
    stop_service
    
    if [ -d "$SCRIPT_DIR" ]; then
        rm -rf "$SCRIPT_DIR"
        print_message $GREEN "ANYTLS 已完全卸载"
    else
        print_message $YELLOW "安装目录不存在"
    fi
}

# 主菜单
show_menu() {
    echo -e "${CYAN}"
    echo "========================================"
    echo "    Hostuno 共享主机 ANYTLS 部署脚本"
    echo "========================================"
    echo -e "${NC}"
    echo "1. 安装 ANYTLS"
    echo "2. 启动服务"
    echo "3. 停止服务"
    echo "4. 重启服务"
    echo "5. 查看状态"
    echo "6. 查看日志"
    echo "7. 显示连接信息"
    echo "8. 卸载"
    echo "0. 退出"
    echo "========================================"
}

# 主函数
main() {
    check_shared_hosting
    
    while true; do
        show_menu
        read -p "请选择操作 [0-8]: " choice
        
        case $choice in
            1)
                download_anytls
                generate_config
                start_service
                show_connection_info
                ;;
            2)
                start_service
                ;;
            3)
                stop_service
                ;;
            4)
                stop_service
                sleep 2
                start_service
                ;;
            5)
                check_status
                ;;
            6)
                view_logs
                ;;
            7)
                show_connection_info
                ;;
            8)
                uninstall
                ;;
            0)
                print_message $GREEN "感谢使用!"
                exit 0
                ;;
            *)
                print_message $RED "无效选择，请重试"
                ;;
        esac
        
        echo
        read -p "按回车键继续..."
        clear
    done
}

# 检查是否以参数形式运行
if [ $# -gt 0 ]; then
    case $1 in
        install)
            check_shared_hosting
            download_anytls
            generate_config
            start_service
            show_connection_info
            ;;
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            stop_service
            sleep 2
            start_service
            ;;
        status)
            check_status
            ;;
        logs)
            view_logs
            ;;
        info)
            show_connection_info
            ;;
        uninstall)
            uninstall
            ;;
        *)
            echo "用法: $0 {install|start|stop|restart|status|logs|info|uninstall}"
            exit 1
            ;;
    esac
else
    main
fi
