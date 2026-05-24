# Ubuntu-Script
 Instalar y configurar Apache, SFTP, Samba, SSH y UFW en un servidor Ubuntu.
 1.- copiar los archivos en el servidor Ubuntu.
 2.- chmod +x *.sh
 3.- sudo ./setup-srv.sh  -> Instala Apache, Samba, Postfix para correo ubuntu@sistema.local y configura UFW.
 4.- sudo ./usuarios_samba.sh  -> Crear usuarios y salir al terminar.
 5.- sudo ./backup.sh -> Hace un backup de los archivos y se añade al cron como tarea diaria.
 6.- sudo ./monitor.sh -> Envia a ubuntu@sistema.local un mail de alerta de rendimiento sel servidor.

 Si se instala en un servidor en AWS es necesario abrir los puertos 22, 139, 445 para la ip local y los puertos 80 y 443 para todas las direcciones.

 Comprobaciones posibles:
 1.- sudo crontab -l -> ver tareas cron programadas.
 2.- Desde nemo o navegador de Windows: smb://IPservidor -> ver carpetas en samba.
 3.- sudo apt install stress
     stress --cpu 8 --timeout 90  -> Estresar el servidor para que envie el mail de alerta.
 4.- mail -> ver el mail del usuario local.
 5.- sudo ls -lh /backups  -> Ver backups creados.
 6.- sudo cat /var/log -> Ver logs de creación de usuarios.
