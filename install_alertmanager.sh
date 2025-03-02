#!/bin/bash

set -e  # Прерывание скрипта при ошибке

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y wget tar curl

# Получение последней версии Alertmanager
LATEST_VERSION=$(curl -s https://api.github.com/repos/prometheus/alertmanager/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
echo "Latest version: $LATEST_VERSION"

# Загрузка файла
ARCHIVE_NAME="alertmanager${LATEST_VERSION}.linux-amd64.tar.gz"
DOWNLOAD_URL="https://github.com/prometheus/alertmanager/releases/download/${LATEST_VERSION}/${ARCHIVE_NAME}"

echo "Downloading Alertmanager from $DOWNLOAD_URL..."
if curl -L -O "$DOWNLOAD_URL"; then
    echo "Download successful."
else
    echo "Download failed. Exiting."
    exit 1
fi

# Проверка, что файл загружен и имеет правильный формат
if [[ ! -f $ARCHIVE_NAME ]]; then
    echo "Downloaded file not found. Exiting."
    exit 1
fi

# Проверка, что файл действительно в формате gzip
if ! file "$ARCHIVE_NAME" | grep -q "gzip compressed data"; then
    echo "Downloaded file is not in gzip format. Exiting."
    exit 1
fi

# Распаковка архива
echo "Extracting Alertmanager..."
if tar -xzf "$ARCHIVE_NAME"; then
    echo "Extraction successful."
else
    echo "Extraction failed. The file may not be in gzip format. Exiting."
    exit 1
fi

# Перемещение файлов в нужную директорию
echo "Installing Alertmanager..."
sudo mv alertmanager-${LATEST_VERSION}/alertmanager /usr/local/bin/
sudo mv alertmanager-${LATEST_VERSION}/alertmanagerctl /usr/local/bin/

# Удаление ненужного архива
rm "$ARCHIVE_NAME"
rm -rf alertmanager-${LATEST_VERSION}

# Создание пользователя для Alertmanager, если он не существует
if ! id "alertmanager" &>/dev/null; then
    sudo useradd --no-create-home --shell /bin/false alertmanager
fi

# Создание необходимых директорий
sudo mkdir -p /etc/alertmanager
sudo mkdir -p /var/lib/alertmanager

# Создание файла конфигурации Alertmanager
echo "Creating Alertmanager configuration file..."
sudo tee /etc/alertmanager/alertmanager.yml > /dev/null <<EOL
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'your-email@gmail.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-password'

route:
  receiver: 'email'

receivers:
  - name: 'email'
    email_configs:
      - to: 'admin@gmail.com'
EOL

# Создание файла службы для systemd
echo "Creating systemd service file..."
sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOL
[Unit]
Description=Alertmanager
After=network.target

[Service]
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager \
    --web.listen-address="0.0.0.0:9093"
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Перезагрузка systemd и запуск службы
echo "Reloading systemd and starting Alertmanager service..."
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager

# Проверка статуса службы
echo "Checking Alertmanager service status..."
sudo systemctl status alertmanager
