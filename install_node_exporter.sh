#!/bin/bash

set -e

# Создание пользователя
sudo useradd --no-create-home --shell /bin/false node_exporter || true

# Определение последней версии
VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')

# Скачивание и установка
wget "https://github.com/prometheus/node_exporter/releases/download/${VERSION}/node_exporter-${VERSION#v}.linux-amd64.tar.gz"
tar xvf "node_exporter-${VERSION#v}.linux-amd64.tar.gz"
sudo mv "node_exporter-${VERSION#v}.linux-amd64"/node_exporter /usr/local/bin/
rm -rf "node_exporter-${VERSION#v}.linux-amd64.tar.gz" "node_exporter-${VERSION#v}.linux-amd64"

# Системный сервис
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Запуск
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "✅ Node Exporter успешно установлен!"
