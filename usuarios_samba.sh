#!/bin/bash
set -euo pipefail

# =====================================================
# usuarios_samba.sh
# Gestión de usuarios + Samba
# Proyecto ASIR - Sara González
# =====================================================

LOG_FILE="/var/log/user_samba_asir.log"

# ---------------- ROOT ----------------
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Este script debe ejecutarse como root."
    exit 1
fi

# ---------------- LOG ----------------
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# ---------------- ENTRADA ----------------
pedir_datos() {
    read -p "Usuario: " USUARIO
    read -p "Grupo: " GRUPO
}

# ---------------- VALIDACIONES ----------------
usuario_existe() {
    id "$1" &>/dev/null
}

validar_usuario() {
    [[ "$1" =~ ^[a-zA-Z0-9._-]+$ ]]
}

validar_password() {
    PASS="$1"

    if [ ${#PASS} -lt 8 ]; then
        echo "La contraseña debe tener al menos 8 caracteres."
        return 1
    fi

    if ! [[ "$PASS" =~ [0-9] ]]; then
        echo "La contraseña debe incluir al menos un número."
        return 1
    fi

    return 0
}

# ---------------- MENÚ ----------------
menu() {
    echo ""
    echo "========== PANEL ASIR =========="
    echo "1) Crear usuario"
    echo "2) Salir"
    echo "================================"
    read -p "Opción: " OPCION
}

# ---------------- CARPETA GRUPO ----------------
crear_carpeta_grupo() {

    GRUPO=$1
    RUTA="/srv/samba/$GRUPO"

    if [ ! -d "$RUTA" ]; then
        mkdir -p "$RUTA"
        log "Carpeta creada: $RUTA"
    fi

    chown root:"$GRUPO" "$RUTA"
    chmod 770 "$RUTA"
    log "Permisos asignados: $RUTA (grupo $GRUPO)"
}

# ---------------- SAMBA CONF ----------------
actualizar_smb_conf() {

    GRUPO=$1
    RUTA="/srv/samba/$GRUPO"
    CONF="/etc/samba/smb.conf"

    # Evitar duplicados
    if grep -q "^\[$GRUPO\]" "$CONF"; then
        log "Share ya existe: $GRUPO"
        return
    fi

    cat >> "$CONF" <<EOF

[$GRUPO]
   path = $RUTA
   browseable = yes
   writable = yes
   valid users = @$GRUPO
EOF

    log "Share añadido en smb.conf: $GRUPO"
}

# ---------------- USUARIO ----------------
crear_usuario() {

    USUARIO=$1
    GRUPO=$2

    # Validación usuario
    if ! validar_usuario "$USUARIO"; then
        echo "Usuario no válido"
        log "ERROR usuario inválido: $USUARIO"
        return
    fi

    # Usuario duplicado
    if usuario_existe "$USUARIO"; then
        echo "El usuario ya existe"
        log "ERROR duplicado: $USUARIO"
        return
    fi

    # Grupo
    if ! getent group "$GRUPO" > /dev/null; then
        groupadd "$GRUPO"
        log "Grupo creado: $GRUPO"
    fi

    crear_carpeta_grupo "$GRUPO"
    actualizar_smb_conf "$GRUPO"

    # Usuario Linux
    useradd -m -g "$GRUPO" "$USUARIO"
    log "Usuario creado: $USUARIO -> $GRUPO"

    # Password
    while true; do
        read -s -p "Contraseña: " PASS
        echo
        read -s -p "Confirmar: " PASS2
        echo

        [ "$PASS" = "$PASS2" ] || { echo "No coinciden"; continue; }

        validar_password "$PASS" && break
    done

    echo "$USUARIO:$PASS" | chpasswd

    # Samba usuario
    (echo "$PASS"; echo "$PASS") | smbpasswd -a "$USUARIO"
    smbpasswd -e "$USUARIO"

    log "Samba configurado: $USUARIO"

    echo "Usuario creado correctamente"
}

# ---------------- MAIN ----------------

mkdir -p /var/log
touch "$LOG_FILE"
chmod 640 "$LOG_FILE"
chown root:root "$LOG_FILE"

while true; do

    menu

    case "$OPCION" in
        1)
            pedir_datos
            crear_usuario "$USUARIO" "$GRUPO"
        ;;
        2)
            echo "Saliendo..."
            exit 0
        ;;
        *)
            echo "Opción no válida"
        ;;
    esac

done