#!/bin/bash

# ==========================================
# monitor.sh
# Alertas de rendimiento srv
# Proyecto ASIR - Sara González
# ==========================================

EMAIL="ubuntu@sistema.local"
SCRIPT_PATH=$(readlink -f "$0")

register_cron() {
    local entry="$1"
    local current
    current=$(crontab -l 2>/dev/null || true)

    if ! printf '%s\n' "$current" | grep -Fxq "$entry"; then
        printf '%s\n%s\n' "$current" "$entry" | sed '/^$/d' | crontab -
    fi
}

CRON_LINE="*/5 * * * * $SCRIPT_PATH"

CPU=$(top -bn1 | awk '/Cpu\(s\)/ {print $2 + $4}')
MEM=$(free | awk '/Mem/ {printf("%.0f"), $3/$2 * 100}')
DISK=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

FECHA=$(date)

MENSAJE="ALERTA DE SISTEMA - $FECHA

Uso de recursos:
CPU: $CPU%
Memoria: $MEM%
Disco: $DISK%

Revisar sistema inmediatamente."

CPU_INT=${CPU%.*}

if [ "$CPU_INT" -gt 80 ] || [ "$MEM" -gt 80 ] || [ "$DISK" -gt 85 ]; then
    echo "$MENSAJE" | mail -s "ALERTA SERVIDOR" $EMAIL
fi

# Registrar tarea programada en cron
register_cron "$CRON_LINE"
