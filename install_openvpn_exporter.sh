#!/bin/bash

set -e

# Проверка, есть ли уже пользователь
if ! id "openvpn_exporter" &>/dev/null; then
    sudo useradd --no-create-home --shell /bin/false openvpn_exporter
fi

# Установка Go (если не установлен)
if ! command -v go &>/dev/null; then
    echo "Устанавливаем Go..."
    wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
    rm go1.21.6.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
fi

# Скачивание исходников OpenVPN Exporter и сборка
echo "Скачиваем и компилируем OpenVPN Exporter..."
git clone https://github.com/kumina/openvpn_exporter.git /tmp/openvpn_exporter
cd /tmp/openvpn_exporter
go build -o openvpn_exporter

# Перемещение бинарника
sudo mv openvpn_exporter /usr/local/bin/openvpn_exporter
cd ~
rm -rf /tmp/openvpn_exporter

# Создание systemd-сервиса
cat <<EOF | sudo tee /etc/systemd/system/openvpn_exporter.service
[Unit]
Description=OpenVPN Exporter
After=network.target

[Service]
User=openvpn_exporter
ExecStart=/usr/local/bin/openvpn_exporter -openvpn.status_paths /var/log/openvpn/openvpn-status.log

[Install]
WantedBy=multi-user.target
EOF

# Запуск службы
sudo systemctl daemon-reload
sudo systemctl enable openvpn_exporter
sudo systemctl start openvpn_exporter

echo "✅ OpenVPN Exporter установлен и запущен!"
