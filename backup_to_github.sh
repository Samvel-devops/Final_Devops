#!/bin/bash

# Настройки
BACKUP_DIR="/var/backups"                       # Папка, где хранятся бэкапы
DATE=$(date +%F)                                # Дата в формате ГГГГ-ММ-ДД
BACKUP_FILE="system_backup_$DATE.tar.gz"        # Имя файла бэкапа
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"          # Полный путь к файлу бэкапа

# Папка с локальным GitHub-репозиторием
GITHUB_REPO_DIR="/root/github_backup"  

# Лог файл
LOG_FILE="/var/log/backup_github.log"

# Запись в лог
echo "[$(date)] Запуск бэкапа..." | tee -a $LOG_FILE

# Создание бэкапа всей системы (исключая ненужные директории)
tar --exclude="$BACKUP_DIR" \
    --exclude="/proc" \
    --exclude="/tmp" \
    --exclude="/sys" \
    --exclude="/run" \
    --exclude="/mnt" \
    --exclude="/media" \
    --exclude="/lost+found" \
    -cvpzf "$BACKUP_PATH" / 2>>$LOG_FILE

echo "[$(date)] Бэкап завершён: $BACKUP_PATH" | tee -a $LOG_FILE

# Проверяем, есть ли локальный репозиторий
if [ ! -d "$GITHUB_REPO_DIR/.git" ]; then
    echo "[$(date)] Ошибка: локальный GitHub-репозиторий не найден!" | tee -a $LOG_FILE
    exit 1
fi

# Копируем бэкап в GitHub-репозиторий
cp "$BACKUP_PATH" "$GITHUB_REPO_DIR/"

# Переходим в репозиторий
cd "$GITHUB_REPO_DIR" || exit

# Добавляем, коммитим и пушим в GitHub
git add .
git commit -m "Добавлен бэкап за $DATE"
git push origin main 2>>$LOG_FILE

echo "[$(date)] Бэкап успешно загружен в GitHub!" | tee -a $LOG_FILE
