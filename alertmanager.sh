#!/bin/bash

cat <<EOL > /etc/alertmanager/alertmanager.yml
route:
  group_by: ['alertname']         # Группировка оповещений по имени оповещения
  group_wait: 10s                 # Время ожидания для группы оповещений перед отправкой
  group_interval: 1m              # Интервал между отправкой групп оповещений
  repeat_interval: 1h             # Интервал повторной отправки существующих оповещений
  receiver: 'email'               # Получатель для оповещений

receivers:
  - name: 'email'
    email_configs:
      - to: 'axalqalqaci@gmail.com'                # Адрес, на который нужно отправлять оповещения
        from: '007-sem@mail.ru'                     # Адрес отправителя
        smarthost: 'smtp.mail.ru:587'               # SMTP сервер для отправки писем (замените на корректный)
        auth_username: '007-sem@mail.ru'            # Логин SMTP
        auth_password: 'Samvel1986Anush1987'        # Пароль SMTP
        smtp_require_tls: true                       # Требуется TLS для шифрования

  - name: 'web.hook'          # Получатель для отправки через webhook
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'  # URL для отправки оповещений через webhook

inhibit_rules:
  - source_match:
      severity: 'critical'  # Если есть критическое оповещение
    target_match:
      severity: 'warning'    # Не отправлять оповещения о предупреждениях
    equal: ['alertname', 'dev', 'instance']  # Поля, по которым будет производиться сравнение
EOL

echo "Файл /etc/alertmanager/alertmanager.yml создан."
