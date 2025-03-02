#!/bin/bash

set -e

# Создание пользователя
sudo useradd --no-create-home --shell /bin/false prometheus || true

# Создание директорий
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Определение последней версии Prometheus
VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')

# Скачивание и установка Prometheus
wget "https://github.com/prometheus/prometheus/releases/download/${VERSION}/prometheus-${VERSION#v}.linux-amd64.tar.gz"
tar xvf "prometheus-${VERSION#v}.linux-amd64.tar.gz"
sudo mv "prometheus-${VERSION#v}.linux-amd64"/prometheus /usr/local/bin/
rm -rf "prometheus-${VERSION#v}.linux-amd64.tar.gz" "prometheus-${VERSION#v}.linux-amd64"

# Создание конфигурации Prometheus
cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'openvpn_exporter'
    static_configs:
      - targets: ['localhost:9176']
EOF

# Создание сервиса systemd
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/

[Install]
WantedBy=multi-user.target
EOF

# Запуск службы
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

echo "Prometheus успешно установлен!"
