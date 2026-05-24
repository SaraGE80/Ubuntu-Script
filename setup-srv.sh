#!/bin/bash
set -euo pipefail

# ==========================================
# setup_server.sh
# Automatización básica del servidor AWS
# Proyecto ASIR - Sara González
# ==========================================

echo "=========================================="
echo " INICIANDO CONFIGURACIÓN DEL SERVIDOR "
echo "=========================================="

# Comprobar permisos root
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Ejecuta este script como root o con sudo."
    exit 1
fi

EMAIL="ubuntu@sistema.local"

# Actualizar sistema
echo "[INFO] Actualizando sistema..."
apt update && apt upgrade -y

# Instalar servicios necesarios
echo "[INFO] Instalando Apache, Samba y UFW..."
apt install apache2 samba ufw -y

# Instalar servicio de mail
echo "[INFO] Instalando sistema de correo..."
DEBIAN_FRONTEND=noninteractive apt install -y mailutils postfix
if ! grep -qxF "root: $EMAIL" /etc/aliases; then
    echo "root: $EMAIL" >> /etc/aliases
fi
newaliases

# Asegurar que Postfix trata 'sistema.local' como destino local
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, sistema.local"

# Preparar spool de correo local
mkdir -p /var/mail
chown root:mail /var/mail
chmod 2775 /var/mail
if [ -n "${EMAIL##*@}" ] && [ "${EMAIL##*@}" = "sistema.local" ]; then
    touch /var/mail/${EMAIL%%@*}
    chown ${EMAIL%%@*}:mail /var/mail/${EMAIL%%@*}
    chmod 660 /var/mail/${EMAIL%%@*}
fi

systemctl enable postfix
systemctl restart postfix

echo "[INFO] Probando sistema de correo..."
echo "Servidor configurado correctamente" | mail -s "TEST CONFIGURACION SERVIDOR" "$EMAIL"

# Crear directorio backup
mkdir -p /backups
chmod 700 /backups

# Crear directorio base Samba
echo "[INFO] Creando estructura base de Samba..."
mkdir -p /srv/samba
chmod 755 /srv/samba

# Backup configuración Samba original
echo "[INFO] Realizando copia de seguridad de smb.conf..."
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Configuración básica Samba (solo global)
echo "[INFO] Configurando Samba (global)..."

cat > /etc/samba/smb.conf <<EOF
[global]
   workgroup = WORKGROUP
   server string = Servidor Samba AWS
   security = user
   map to guest = never
   server min protocol = SMB2
   server max protocol = SMB3
   encrypt passwords = yes
   ntlm auth = yes
EOF

# Configuración Firewall UFW
echo "[INFO] Configurando UFW..."

ufw allow OpenSSH
ufw allow 'Apache Full'
ufw allow Samba

ufw --force enable

# Habilitar servicios
echo "[INFO] Habilitando servicios..."

systemctl enable apache2
systemctl enable smbd
systemctl enable postfix

systemctl restart apache2
systemctl restart smbd
systemctl restart postfix

# Estado de servicios
echo "[INFO] Estado de servicios:"
systemctl status apache2 --no-pager
systemctl status smbd --no-pager

# Mensaje final
echo ""
echo "=========================================="
echo " CONFIGURACIÓN FINALIZADA "
echo "=========================================="
echo ""
echo "PASOS MANUALES PENDIENTES:"
echo "1. Configurar certificados SSL si aplica:"
echo "   sudo apt install certbot
echo "   sudo certbot --apache"
echo ""
echo "2. Ejecutar script usuarios_samba.sh"
echo ""
echo "3. Ejecutar script backup.sh"
echo ""
echo "4. Ejecutar script monitor.sh"
echo ""
echo "5. Revisar y completar configuración de Samba según grupos/usuarios"
echo ""
echo "Servidor listo para continuar configuración."
echo "=========================================="
