#!/bin/bash
set -e

echo "[frontend] Starting entrypoint..."

mkdir -p /var/log/nginx /var/run/fail2ban

rm -f /var/log/nginx/access.log /var/log/nginx/error.log
touch /var/log/nginx/access.log /var/log/nginx/error.log
touch /var/log/fail2ban.log

rm -f /var/run/fail2ban/fail2ban.sock /var/run/fail2ban/fail2ban.pid

echo "[frontend] Starting nginx..."
nginx -g 'daemon off;' &

sleep 1

echo "[frontend] Starting fail2ban..."
fail2ban-client -x start

echo "[frontend] nginx + fail2ban running."
echo "[frontend] Following fail2ban log (Ctrl+C to stop)..."

exec tail -F /var/log/fail2ban.log