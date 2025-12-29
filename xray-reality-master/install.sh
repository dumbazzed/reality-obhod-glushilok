#!/bin/bash

# Update package index and install dependencies
sudo apt-get update
sudo apt-get install -y jq openssl qrencode

# ==================== ЗАМЕНИ ЭТИ ЗНАЧЕНИЯ НА СВОИ ====================
name="Gosuslugi-Reality"     # Имя для ссылки
port="443"                   # Порт сервера (443, 8443, и т.д.)
sni="www.gosuslugi.ru"       # Домен для маскировки (www.microsoft.com, www.yandex.ru)
path="%2F"                   # Путь (оставь %2F)
# =====================================================================

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Берем ТВОЙ config.json из твоего репозитория
json=$(curl -s https://raw.githubusercontent.com/dumbazzed/reality-obhod-glushilok/main/xray-reality-master/config.json)

keys=$(xray x25519)
pk=$(echo "$keys" | awk '/Private key:/ {print $3}')
pub=$(echo "$keys" | awk '/Public key:/ {print $3}')
serverIp=$(curl -s ipv4.wtfismyip.com/text)
uuid=$(xray uuid)
shortId=$(openssl rand -hex 8)

# Генерация ссылки (исправлено: type=http -> type=tcp, добавлен flow)
url="vless://$uuid@$serverIp:$port?type=tcp&security=reality&pbk=$pub&fp=chrome&sni=$sni&sid=$shortId&flow=xtls-rprx-vision#$name"

# Убрал --arg email "$email" и строку с email
newJson=$(echo "$json" | jq \
    --arg pk "$pk" \
    --arg uuid "$uuid" \
    --arg port "$port" \
    --arg sni "$sni" \
    '.inbounds[0].port = ($port | tonumber) |
     .inbounds[0].settings.clients[0].id = $uuid |
     .inbounds[0].streamSettings.realitySettings.dest = ($sni + ":443") |
     .inbounds[0].streamSettings.realitySettings.serverNames = [$sni] |
     .inbounds[0].streamSettings.realitySettings.privateKey = $pk |
     .inbounds[0].streamSettings.realitySettings.shortIds = ["'$shortId'"]')

echo "$newJson" | sudo tee /usr/local/etc/xray/config.json >/dev/null
sudo systemctl restart xray

echo "=========================================="
echo "✅ Reality установлен!"
echo "Ссылка для подключения:"
echo "$url"
echo "=========================================="

qrencode -s 120 -t ANSIUTF8 "$url"
qrencode -s 50 -o qr.png "$url"

exit 0
