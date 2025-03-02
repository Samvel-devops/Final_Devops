#!/bin/bash

cat <<EOL > /etc/prometheus/alert_rules.yml
groups:
  - name: openvpn_exporter
    rules:
      - alert: OpenVPNDown
        expr: up{job="openvpn"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "OpenVPN server is down"
          description: "The OpenVPN server is not reachable for 1 minutes."
EOL

echo "Файл /etc/prometheus/alert_rules.yml создан."
