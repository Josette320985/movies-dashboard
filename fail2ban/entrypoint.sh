#!/bin/bash
set -e

echo "[frontend] Starting entrypoint..."

# ============================================================
# Preparar directorios y archivos de log
# ============================================================
mkdir -p /var/log/nginx /var/run/fail2ban

# Nginx: reemplazar symlinks (apuntan a stdout) con archivos reales
# Fail2Ban necesita un archivo real que pueda leer
rm -f /var/log/nginx/access.log /var/log/nginx/error.log
touch /var/log/nginx/access.log /var/log/nginx/error.log

# Log de Fail2Ban
touch /var/log/fail2ban.log

# Limpiar sockets/pids de ejecuciones previas
rm -f /var/run/fail2ban/fail2ban.sock /var/run/fail2ban/fail2ban.pid

# ============================================================
# Arrancar Nginx en background
# ============================================================
echo "[frontend] Starting nginx..."
nginx -g 'daemon off;' &

# Esperar a que Nginx esté listo
sleep 1

# ============================================================
# Arrancar Fail2Ban
# ============================================================
echo "[frontend] Starting fail2ban..."
fail2ban-client -x start

echo "[frontend] nginx + fail2ban running."
echo "[frontend] Following fail2ban log (Ctrl+C to stop)..."

# Mantener el contenedor vivo siguiendo el log de Fail2Ban
exec tail -F /var/log/fail2ban.log