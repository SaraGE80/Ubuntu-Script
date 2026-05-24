#!/bin/bash

# ==========================================
# backup.sh
# Copia de seguridad del basica srv
# Proyecto ASIR - Sara González
# ==========================================

# Fecha para nombrar el backup
FECHA=$(date +%Y-%m-%d)

# Email de alerta
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

CRON_LINE="0 2 * * * $SCRIPT_PATH"

# Directorio destino
DESTINO="/backups"

# Crear directorio destino si no existe
mkdir -p "$DESTINO"

# Crear backup comprimido
tar -czvf "$DESTINO/backup-$FECHA.tar.gz" \
/etc \
/home \
/srv
STATUS=$?

if [ $STATUS -ne 0 ]; then
    MENSAJE="ERROR DE BACKUP - $FECHA

El proceso de copia de seguridad ha fallado.
Revisar el sistema y los permisos de destino: $DESTINO"
    echo "$MENSAJE" | mail -s "ERROR BACKUP SERVIDOR" "$EMAIL"
    exit $STATUS
fi

# Eliminar backups de más de 7 días
find "$DESTINO" -type f -name "*.tar.gz" -mtime +7 -delete

# Registrar tarea programada en cron
register_cron "$CRON_LINE"
