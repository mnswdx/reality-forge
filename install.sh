#!/usr/bin/env bash
# ==============================================================================
# Reality Forge (v1.0.0) — Автоматический установщик VLESS-REALITY + 3x-ui
# Создан для безопасного, быстрого и эталонного развертывания VPN-узлов для людей.
# Лицензия: The Unlicense (Общественное достояние / Public Domain)
# ==============================================================================

set -e

# Цвета для вывода в терминале
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_RED="\033[1;31m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_BLUE="\033[1;34m"
C_CYAN="\033[1;36m"
C_WHITE="\033[1;37m"
C_DIM="\033[2m"

# Проверка прав суперпользователя (root)
if [ "$EUID" -ne 0 ]; then
    echo -e "${C_RED}[!] Ошибка: Этот скрипт должен быть запущен с правами root (sudo).${C_RESET}"
    exit 1
fi

clear

echo -e "${C_CYAN}"
cat << "EOF"
  ____            _ _ _            _____                     
 |  _ \ ___  __ _| (_) |_ _   _   |  ___|__  _ __ __ _  ___  
 | |_) / _ \/ _` | | | __| | | |  | |_ / _ \| '__/ _` |/ _ \ 
 |  _ <  __/ (_| | | | |_| |_| |  |  _| (_) | | | (_| |  __/ 
 |_| \_\___|\__,_|_|_|\__|\__, |  |_|  \___/|_|  \__, |\___| 
                          |___/                  |___/       
EOF
echo -e "${C_RESET}"
echo -e "${C_BOLD}Reality Forge v1.0.0 — Zero-Touch VLESS-REALITY & 3x-ui Deployer${C_RESET}"
echo -e "${C_DIM}Идеальная маскировка под TLS 1.3 | Защита от ТСПУ/РКН | SSH-туннель для панели${C_RESET}"
echo -e "${C_CYAN}--------------------------------------------------------------------------------${C_RESET}\n"

# ==============================================================================
# ⚠️ ГЛАВНОЕ ПРЕДУПРЕЖДЕНИЕ: ПОЧЕМУ НЕЛЬЗЯ MICROSOFT, SONY И GOOGLE
# ==============================================================================
echo -e "${C_YELLOW}┌──────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
echo -e "${C_YELLOW}│  ⚠️  ЗОЛОТОЕ ПРАВИЛО REALITY: ПОЧЕМУ НЕЛЬЗЯ БРАТЬ MICROSOFT / SONY / GOOGLE?   │${C_RESET}"
echo -e "${C_YELLOW}└──────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
echo -e "${C_WHITE}Многие руководства в сети советуют указывать популярные домены (microsoft.com,${C_RESET}"
echo -e "${C_WHITE}sony.com, apple.com, google.com). ${C_RED}Это грубейшая ошибка, приводящая к блокировке!${C_RESET}"
echo ""
echo -e "  ${C_RED}1. IP-SNI Mismatch (Детекция ТСПУ):${C_RESET} Оборудование DPI знает диапазоны IP"
echo -e "     мировых корпораций. Если пакет летит на IP вашего VPS хостинга,"
echo -e "     а в поле SNI указан 'microsoft.com' — ТСПУ мгновенно разрывает связь (TCP RST)."
echo -e "  ${C_RED}2. CDN-ловушки:${C_RESET} Популярные сайты закрыты через Cloudflare / Akamai."
echo -e "     Они блокируются по маске, либо Xray не может выполнить проброс (Fallback)."
echo -e "  ${C_GREEN}3. Правильный подход:${C_RESET} Донор должен быть в той же стране, что и VPS"
echo -e "     (университеты, дата-центры, IXP), иметь чистый TLS 1.3 и протокол HTTP/2 (h2)."
echo ""
echo -e "${C_CYAN}--------------------------------------------------------------------------------${C_RESET}\n"

# 1. Определение внешнего IP-адреса сервера
echo -e "${C_CYAN}[1/8]${C_RESET} Определение внешнего IP-адреса сервера..."
SERVER_IP=$(curl -s4 --max-time 5 ifconfig.me || curl -s4 --max-time 5 api.ipify.org || curl -s4 --max-time 5 icanhazip.com || true)
if [ -z "$SERVER_IP" ]; then
    echo -e "${C_RED}[!] Не удалось автоматически определить IP. Пожалуйста, введите публичный IP сервера вручную:${C_RESET}"
    read -rp "IP сервера: " SERVER_IP
fi
echo -e "  » Обнаружен внешний IP: ${C_GREEN}${SERVER_IP}${C_RESET}"

# 2. Определение геолокации сервера и выбор регионального донора
echo -e "${C_CYAN}[2/8]${C_RESET} Анализ геолокации сервера и подбор оптимального донора..."
GEO_INFO=$(curl -s --max-time 5 "http://ip-api.com/json/${SERVER_IP}?fields=countryCode,country,city,as" || true)

COUNTRY_CODE=$(echo "$GEO_INFO" | grep -o '"countryCode":"[^"]*' | cut -d'"' -f4 || echo "NL")
COUNTRY_NAME=$(echo "$GEO_INFO" | grep -o '"country":"[^"]*' | cut -d'"' -f4 || echo "Netherlands")
CITY_NAME=$(echo "$GEO_INFO" | grep -o '"city":"[^"]*' | cut -d'"' -f4 || echo "Unknown")
AS_INFO=$(echo "$GEO_INFO" | grep -o '"as":"[^"]*' | cut -d'"' -f4 || echo "Hosting AS")

echo -e "  » Локация VPS: ${C_GREEN}${CITY_NAME}, ${COUNTRY_NAME} (${COUNTRY_CODE})${C_RESET} [${C_DIM}${AS_INFO}${C_RESET}]"

# Выбор эталонного донора по стране
case "${COUNTRY_CODE^^}" in
    "NL")
        AUTO_DONOR="speedtest.serverius.net"
        DONOR_DESC="Serverius Data Hub (Нидерланды, чистый TLS 1.3 + h2, без CDN)"
        ;;
    "FI")
        AUTO_DONOR="csc.fi"
        DONOR_DESC="Государственный IT-центр науки Финляндии CSC (Финляндия, TLS 1.3 + h2)"
        ;;
    "LT")
        AUTO_DONOR="vu.lt"
        DONOR_DESC="Вильнюсский университет (Литва, TLS 1.3 + h2)"
        ;;
    "DE")
        AUTO_DONOR="mirror.de.leaseweb.net"
        DONOR_DESC="Leaseweb Mirror Frankfurt (Германия, TLS 1.3 + h2)"
        ;;
    "FR")
        AUTO_DONOR="ovh.com"
        DONOR_DESC="OVHcloud Infrastructure (Франция, TLS 1.3 + h2)"
        ;;
    "SE")
        AUTO_DONOR="sunet.se"
        DONOR_DESC="Шведская академическая сеть SUNET (Швеция, TLS 1.3 + h2)"
        ;;
    "US")
        AUTO_DONOR="gatech.edu"
        DONOR_DESC="Georgia Institute of Technology (США, TLS 1.3 + h2)"
        ;;
    *)
        AUTO_DONOR="speedtest.serverius.net"
        DONOR_DESC="Serverius High-Speed Hub (Европейский эталон, TLS 1.3 + h2)"
        ;;
esac

echo -e "  » Рекомендованный донор для региона: ${C_GREEN}${AUTO_DONOR}${C_RESET}"
echo -e "    ${C_DIM}(${DONOR_DESC})${C_RESET}"

# Запрос подтверждения донора или выбор своего
echo ""
echo -e "Выберите донора для маскировки REALITY:"
echo -e "  ${C_BOLD}[1]${C_RESET} Использовать рекомендованный: ${C_GREEN}${AUTO_DONOR}${C_RESET} (Оптимально, проверено)"
echo -e "  ${C_BOLD}[2]${C_RESET} Ввести свой проверенный домен вручную"
read -rp "Ваш выбор [1]: " DONOR_CHOICE
DONOR_CHOICE=${DONOR_CHOICE:-1}

if [ "$DONOR_CHOICE" == "2" ]; then
    echo -e "${C_YELLOW}Помните: домен должен поддерживать TLS 1.3 и ALPN h2, и НЕ должен быть за Cloudflare!${C_RESET}"
    read -rp "Введите домен: " SELECTED_DONOR
    SELECTED_DONOR=$(echo "$SELECTED_DONOR" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
else
    SELECTED_DONOR="$AUTO_DONOR"
fi

echo -e "  » Выбранный донор для маскировки: ${C_GREEN}${SELECTED_DONOR}${C_RESET}"

# 3. Обновление ОС и установка критически важных утилит
echo -e "\n${C_CYAN}[3/8]${C_RESET} Обновление пакетов и установка зависимостей..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y > /dev/null
apt-get install -y curl wget jq tar python3 openssl ufw fail2ban qrencode > /dev/null
echo -e "  » Системные пакеты успешно установлены."

# 4. Твикинг ядра Linux (Включение TCP BBR и оптимизация сокетов)
echo -e "\n${C_CYAN}[4/8]${C_RESET} Твикинг ядра: включение алгоритма TCP BBR для высокой скорости..."
cat > /etc/sysctl.d/99-reality-forge.conf << EOF
# Reality Forge: TCP BBR Congestion Control & Network Tweaks
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_slow_start_after_idle = 0
EOF
sysctl --system > /dev/null 2>&1 || true

ACTIVE_CC=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}' || echo "bbr")
echo -e "  » Контроль перегрузки TCP: ${C_GREEN}${ACTIVE_CC}${C_RESET} (BBR активен)"

# 5. Установка и настройка 3x-ui
echo -e "\n${C_CYAN}[5/8]${C_RESET} Установка новейшей версии 3x-ui..."
# Официальный установщик 3x-ui (MHSanaei)
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) << EOF
y
EOF

# Остановка x-ui для безопасной конфигурации SQLite базы
systemctl stop x-ui > /dev/null 2>&1 || true

# 6. Генерация секретов и эталонная настройка x-ui.db
echo -e "\n${C_CYAN}[6/8]${C_RESET} Генерация криптографических ключей и конфигурация VLESS-REALITY..."

PANEL_LOCAL_PORT=5541
PANEL_USERNAME="forge_$(openssl rand -hex 2)"
PANEL_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 14)
PANEL_SECRET_PATH="/forge-$(openssl rand -hex 3)/"

# Генерация UUID клиента
CLIENT_UUID=$(python3 -c 'import uuid; print(str(uuid.uuid4()))')

# Генерация ключей x25519 через бинарник xray
XRAY_BIN="/usr/local/x-ui/bin/xray-linux-amd64"
if [ ! -f "$XRAY_BIN" ]; then
    XRAY_BIN="/usr/local/x-ui/bin/xray-linux"
fi

X25519_OUTPUT=$("$XRAY_BIN" x25519 2>/dev/null || true)
PRIVATE_KEY=$(echo "$X25519_OUTPUT" | grep -i "Private" | awk '{print $3}' | tr -d ' ' || true)
PUBLIC_KEY=$(echo "$X25519_OUTPUT" | grep -i "Public" | awk '{print $3}' | tr -d ' ' || true)

# Запасной генератор ключей x25519 через Python, если бинарник вернул неожиданный формат
if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    KEYS=$(python3 - << 'PYEOF'
import subprocess, re
out = subprocess.check_output(['/usr/local/x-ui/bin/xray-linux-amd64', 'x25519'], text=True)
priv = re.search(r'Private(?: key)?:\s*([^\s]+)', out, re.I)
pub = re.search(r'Public(?: key)?:\s*([^\s]+)', out, re.I)
if priv and pub:
    print(f"{priv.group(1)} {pub.group(1)}")
PYEOF
)
    PRIVATE_KEY=$(echo "$KEYS" | awk '{print $1}')
    PUBLIC_KEY=$(echo "$KEYS" | awk '{print $2}')
fi

# Генерация Short ID (8 hex символов)
SHORT_ID=$(openssl rand -hex 4)

# Внедрение настроек в /etc/x-ui/x-ui.db через Python
python3 - << PYEOF
import sqlite3
import json

db_path = "/etc/x-ui/x-ui.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

# 1. Настройка таблицы settings (Веб-панель слушает только локальный сокет!)
settings_updates = [
    ("webPort", "${PANEL_LOCAL_PORT}"),
    ("webCertFile", ""),
    ("webKeyFile", ""),
    ("webBasePath", "${PANEL_SECRET_PATH}"),
    ("webListen", "127.0.0.1"), # Привязка к localhost — админка закрыта от Интернета!
    ("username", "${PANEL_USERNAME}"),
    ("password", "${PANEL_PASSWORD}")
]

for key, val in settings_updates:
    cur.execute("SELECT count(*) FROM settings WHERE key = ?", (key,))
    if cur.fetchone()[0] > 0:
        cur.execute("UPDATE settings SET value = ? WHERE key = ?", (val, key))
    else:
        cur.execute("INSERT INTO settings (key, value) VALUES (?, ?)", (key, val))

# 2. Создание или обновление Inbound VLESS-REALITY (порт 443)
inbound_settings = {
    "clients": [
        {
            "id": "${CLIENT_UUID}",
            "flow": "xtls-rprx-vision",
            "email": "forge_user@reality.local",
            "limitIp": 0,
            "totalGB": 0,
            "expiryTime": 0,
            "enable": True,
            "tgId": "",
            "subId": "",
            "reset": 0
        }
    ],
    "decryption": "none",
    "fallbacks": []
}

stream_settings = {
    "network": "tcp",
    "security": "reality",
    "realitySettings": {
        "show": False,
        "xver": 0,
        "dest": "${SELECTED_DONOR}:443",
        "serverNames": ["${SELECTED_DONOR}"],
        "privateKey": "${PRIVATE_KEY}",
        "minClientVer": "",
        "maxClientVer": "",
        "maxTimeDiff": 0,
        "shortIds": ["${SHORT_ID}"],
        "settings": {
            "publicKey": "${PUBLIC_KEY}",
            "fingerprint": "chrome",
            "serverName": "",
            "spiderX": ""
        }
    },
    "tcpSettings": {
        "acceptProxyProtocol": False,
        "header": {
            "type": "none"
        }
    }
}

sniffing_settings = {
    "enabled": True,
    "destOverride": ["http", "tls", "quic"],
    "metadataOnly": False,
    "routeOnly": False
}

# Проверяем, есть ли уже inbound на порту 443
cur.execute("SELECT id FROM inbounds WHERE port = 443")
row = cur.fetchone()

if row:
    cur.execute("""
        UPDATE inbounds 
        SET protocol = 'vless', 
            settings = ?, 
            stream_settings = ?, 
            sniffing = ?, 
            remark = 'Reality-Forge-Vision',
            enable = 1
        WHERE port = 443
    """, (json.dumps(inbound_settings), json.dumps(stream_settings), json.dumps(sniffing_settings)))
else:
    cur.execute("""
        INSERT INTO inbounds (
            user_id, up, down, total, remark, enable, port, protocol, 
            settings, stream_settings, tag, sniffing
        ) VALUES (
            0, 0, 0, 0, 'Reality-Forge-Vision', 1, 443, 'vless',
            ?, ?, 'inbound-443', ?
        )
    """, (json.dumps(inbound_settings), json.dumps(stream_settings), json.dumps(sniffing_settings)))

conn.commit()
conn.close()
PYEOF

# Запуск службы x-ui с новой конфигурацией
systemctl start x-ui
echo -e "  » Ядро Xray и панель 3x-ui успешно сконфигурированы."

# 7. Настройка файрвола (UFW) и защиты Fail2ban
echo -e "\n${C_CYAN}[7/8]${C_RESET} Настройка файрвола (UFW) и системы предотвращения вторжений..."

# Определение порта SSH
SSH_PORT=$(ss -tlpn | grep sshd | awk '{print $4}' | awk -F':' '{print $NF}' | head -n1 || echo "22")
SSH_PORT=${SSH_PORT:-22}

ufw --force reset > /dev/null 2>&1 || true
ufw default deny incoming > /dev/null
ufw default allow outgoing > /dev/null
ufw allow "${SSH_PORT}/tcp" comment "SSH Port" > /dev/null
ufw allow 443/tcp comment "VLESS-REALITY HTTPS" > /dev/null
ufw allow 443/udp comment "VLESS-REALITY QUIC" > /dev/null
ufw --force enable > /dev/null

# Настройка fail2ban для защиты SSH
systemctl enable fail2ban > /dev/null 2>&1 || true
systemctl restart fail2ban > /dev/null 2>&1 || true

echo -e "  » Файрвол UFW активен:"
echo -e "    - Открыт SSH (порт ${SSH_PORT})"
echo -e "    - Открыт VLESS-REALITY (порт 443)"
echo -e "    - ${C_GREEN}Порт веб-панели (${PANEL_LOCAL_PORT}) ЗАКРЫТ снаружи${C_RESET} (доступ только по SSH-туннелю)"

# 8. Генерация VLESS-ссылки и QR-кода
echo -e "\n${C_CYAN}[8/8]${C_RESET} Генерация клиентской ссылки и QR-кода..."

REMARK="Reality-Forge-${COUNTRY_CODE^^}"
VLESS_LINK="vless://${CLIENT_UUID}@${SERVER_IP}:443?type=tcp&security=reality&pbk=${PUBLIC_KEY}&fp=chrome&sni=${SELECTED_DONOR}&sid=${SHORT_ID}&spx=%2F&flow=xtls-rprx-vision#${REMARK}"

# Ссылка умной маршрутизации SplitStream Turbo (Happ)
ROUTING_BASE64="eyJHZW9zaXRlVXJsIjoiaHR0cHM6XC9cL2docHJveHkubmV0XC9odHRwczpcL1wvZ2l0aHViLmNvbVwva2VwbGVyMTAzYlwvZ2VvLWZvci1ydS1vbmx5XC9yZWxlYXNlc1wvZG93bmxvYWRcL2xhdGVzdFwvZ2Vvc2l0ZS5kYXQiLCJEaXJlY3RJcCI6WyIxMC4wLjAuMFwvOCIsIjEwMC42NC4wLjBcLzEwIiwiMTcyLjE2LjAuMFwvMTIiLCIxOTIuMTY4LjAuMFwvMTYiLCIxNjkuMjU0LjAuMFwvMTYiLCIyMjQuMC4wLjBcLzQiLCIyNTUuMjU1LjI1NS4yNTUiLCJnZW9pcDpnZW9pcC1ydS1kb21lc3RpYyIsImdlb2lwOnByaXZhdGUiXSwiRG9tZXN0aWNETlNJcCI6IjEuMC4wLjEiLCJGYWtlRG5zIjp0cnVlLCJSb3V0ZU9yZGVyIjoiYmxvY2stZGlyZWN0LXByb3h5IiwiRG9tYWluU3RyYXRlZ3kiOiJJUElmTm9uTWF0Y2giLCJMYXN0VXBkYXRlZCI6MTc3NTIxNjMzMiwiQmxvY2tTaXRlcyI6W10sIlVzZUNodW5rRmlsZXMiOnRydWUsIlByb3h5SXAiOltdLCJHZW9pcFVybCI6Imh0dHBzOlwvXC9naHByb3h5Lm5ldFwvaHR0cHM6XC9cL2dpdGh1Yi5jb21cL2tlcGxlcjEwM2JcL2dlby1mb3ItcnUtb25seVwvcmVsZWFzZXNcL2Rvd25sb2FkXC9sYXRlc3RcL2dlb2lwLmRhdCIsIlJlbW90ZUROU0lwIjoiMS4xLjEuMSIsIkdsb2JhbFByb3h5Ijp0cnVlLCJCbG9ja0lwIjpbXSwiTmFtZSI6IlNwbGl0U3RyZWFtIFR1cmJvIFJVIiwiUmVtb3RlRE5TVHlwZSI6IkRvVSIsIlJlbW90ZUROU0RvbWFpbiI6Imh0dHBzOlwvXC9jbG91ZGZsYXJlLWRucy5jb21cL2Rucy1xdWVyeSIsIlByb3h5U2l0ZXMiOltdLCJEbnNIb3N0cyI6eyJjbG91ZGZsYXJlLWRucy5jb20iOiIxLjEuMS4xIiwiZG5zLmdvb2dsZSI6IjguOC44LjgifSwiRG9tZXN0aWNETlNUeXBlIjoiRG9VIiwiRGlyZWN0U2l0ZXMiOlsiZ2Vvc2l0ZTp2ayIsImdlb3NpdGU6a2lub3BvaXNrIiwiZ2Vvc2l0ZTphdmlhc2FsZXMiLCJnZW9zaXRlOmRyd2ViIiwiZ2Vvc2l0ZTp3aWxkYmVycmllcyIsImdlb3NpdGU6cnV0dWJlIiwiZ2Vvc2l0ZTpvem9uIiwiZ2Vvc2l0ZTp3aW5rIiwiZ2Vvc2l0ZToyZ2lzIiwiZ2Vvc2l0ZTprYXNwZXJza3kiLCJnZW9zaXRlOm9rIiwiZ2Vvc2l0ZTp5YW5kZXgiLCJnZW9zaXRlOm9ra28iLCJnZW9zaXRlOmF2aXRvIiwiZ2Vvc2l0ZTptb3NtZXRybyIsImdlb3NpdGU6ZHplbiIsImdlb3NpdGU6bWFpbHJ1IiwiZ2Vvc2l0ZTptYWlscnUtZ3JvdXAiLCJnZW9zaXRlOmNhdGVnb3J5LXRyYXZlbC1ydSIsImdlb3NpdGU6eDUiLCJnZW9zaXRlOmNhdGVnb3J5LWdvdi1ydSIsImdlb3NpdGU6Y2F0ZWdvcnktZW50ZXJ0YWlubWVudC1ydSIsImdlb3NpdGU6Y2F0ZWdvcnktcmV0YWlsLXJ1IiwiZ2Vvc2l0ZTpjYXRlZ29yeS1tZWRpY2luZS1ydSIsImdlb3NpdGU6Y2F0ZWdvcnktbWVkaWEtcnUiLCJnZW9zaXRlOmNhdGVnb3J5LWVjb21tZXJjZS1ydSIsImdlb3NpdGU6Y2F0ZWdvcnktcnUiLCJnZW9zaXRlOmNhdGVnb3J5LWJhbmstcnUiXSwiRG9tZXN0aWNETlNEb21haW4iOiJodHRwczpcL1wvZG5zLmdvb2dsZVwvZG5zLXF1ZXJ5In0="
HAPP_ROUTING_LINK="happ://routing/add/${ROUTING_BASE64}"

CREDENTIALS_FILE="/root/reality-forge-credentials.txt"
cat > "$CREDENTIALS_FILE" << EOF
================================================================================
              REALITY FORGE — РЕКВИЗИТЫ ДОСТУПА К СЕРВЕРУ
================================================================================
Дата создания: $(date -u)
IP сервера: ${SERVER_IP}
Локация: ${CITY_NAME}, ${COUNTRY_NAME} (${COUNTRY_CODE})
Маскировочный донор REALITY: ${SELECTED_DONOR}

--------------------------------------------------------------------------------
1. ДОСТУП К ВЕБ-ПАНЕЛИ 3X-UI (ТОЛЬКО ЧЕРЕЗ SSH-ТУННЕЛЬ)
--------------------------------------------------------------------------------
Локальный порт: ${PANEL_LOCAL_PORT}
Секретный URL-путь: ${PANEL_SECRET_PATH}
Логин: ${PANEL_USERNAME}
Пароль: ${PANEL_PASSWORD}

Команда для запуска SSH-туннеля на вашем ПК (Windows / macOS / Linux):
ssh -N -L ${PANEL_LOCAL_PORT}:127.0.0.1:${PANEL_LOCAL_PORT} -p ${SSH_PORT} root@${SERVER_IP}

После запуска туннеля откройте в браузере:
http://127.0.0.1:${PANEL_LOCAL_PORT}${PANEL_SECRET_PATH}

--------------------------------------------------------------------------------
2. КЛЮЧ ПОДКЛЮЧЕНИЯ VLESS-REALITY (ДЛЯ КЛИЕНТОВ HAPP / V2RAYN / V2BOX)
--------------------------------------------------------------------------------
UUID: ${CLIENT_UUID}
Public Key: ${PUBLIC_KEY}
Short ID: ${SHORT_ID}
SNI: ${SELECTED_DONOR}
Flow: xtls-rprx-vision

Готовая ссылка:
${VLESS_LINK}

--------------------------------------------------------------------------------
3. УМНАЯ МАРШРУТИЗАЦИЯ SPLITSTREAM TURBO (ДЛЯ HAPP)
--------------------------------------------------------------------------------
Ссылка импорта в Happ:
${HAPP_ROUTING_LINK}
================================================================================
EOF
chmod 600 "$CREDENTIALS_FILE"

# Итоговый экран успеха
clear
echo -e "${C_GREEN}"
cat << "EOF"
  ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗███████╗██████╗ 
  ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝██╔════╝██╔══██╗
  ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ █████╗  ██║  ██║
  ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  ██╔══╝  ██║  ██║
  ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   ███████╗██████╔╝
  ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   ╚══════╝╚═════╝ 
EOF
echo -e "${C_RESET}"
echo -e "${C_BOLD}Установка успешно завершена! Ваш узел VLESS-REALITY полностью готов к работе.${C_RESET}\n"

echo -e "${C_YELLOW}╔══════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_YELLOW}║ 🔑 ВАША ГОТОВАЯ ССЫЛКА ПОДКЛЮЧЕНИЯ VLESS-REALITY                             ║${C_RESET}"
echo -e "${C_YELLOW}╚══════════════════════════════════════════════════════════════════════════════╝${C_RESET}"
echo -e "${C_CYAN}${VLESS_LINK}${C_RESET}\n"

# Вывод ASCII QR-кода
echo -e "${C_BOLD}Сканируйте QR-код через Happ / V2Box / v2rayN прямо с экрана:${C_RESET}"
qrencode -t ANSI256 "${VLESS_LINK}" || true
echo ""

echo -e "${C_CYAN}--------------------------------------------------------------------------------${C_RESET}"
echo -e "${C_BOLD}🛡️ ДОСТУП К ВЕБ-ПАНЕЛИ 3X-UI:${C_RESET}"
echo -e "  » Локальный порт:  ${C_GREEN}${PANEL_LOCAL_PORT}${C_RESET} (закрыт снаружи в целях безопасности)"
echo -e "  » Секретный путь:  ${C_GREEN}${PANEL_SECRET_PATH}${C_RESET}"
echo -e "  » Логин:           ${C_GREEN}${PANEL_USERNAME}${C_RESET}"
echo -e "  » Пароль:          ${C_GREEN}${PANEL_PASSWORD}${C_RESET}"
echo ""
echo -e "${C_WHITE}Для входа в панель выполните на своём ПК в терминале:${C_RESET}"
echo -e "  ${C_YELLOW}ssh -N -L ${PANEL_LOCAL_PORT}:127.0.0.1:${PANEL_LOCAL_PORT} -p ${SSH_PORT} root@${SERVER_IP}${C_RESET}"
echo -e "Затем откройте в браузере: ${C_CYAN}http://127.0.0.1:${PANEL_LOCAL_PORT}${PANEL_SECRET_PATH}${C_RESET}"
echo -e "${C_CYAN}--------------------------------------------------------------------------------${C_RESET}"

echo -e "${C_BOLD}⚡ УМНАЯ МАРШРУТИЗАЦИЯ SPLITSTREAM TURBO ДЛЯ HAPP:${C_RESET}"
echo -e "  » Ссылка для Happ: ${C_DIM}${HAPP_ROUTING_LINK}${C_RESET}"
echo -e "  » Банки РФ, Госуслуги, Ozon, WB, Яндекс пойдут напрямую без потерь скорости."
echo -e "  » YouTube (4K), Discord, Telegram, соцсети и заблокированные сайты пойдут через REALITY."
echo -e "${C_CYAN}--------------------------------------------------------------------------------${C_RESET}"

echo -e "Все реквизиты доступа сохранены в файл: ${C_GREEN}${CREDENTIALS_FILE}${C_RESET} (chmod 600)"
echo -e "${C_GREEN}[✓] Развертывание завершено! Приятного свободного и безопасного интернета.${C_RESET}\n"
