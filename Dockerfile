# ============================================================
# ETAPA 1: Build de Vue.js
# ============================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias (solo las necesarias)
RUN npm ci

# Copiar el resto del proyecto
COPY . .

# Build de producción
RUN npm run build


# ============================================================
# ETAPA 2: Nginx + Fail2Ban
# ============================================================
FROM nginx:1.27-alpine

# Instalar Fail2Ban y dependencias necesarias
RUN apk add --no-cache \
    fail2ban \
    bash \
    iptables \
    iproute2

# Copiar el build de Vue desde la etapa anterior
COPY --from=builder /app/dist /usr/share/nginx/html

# Configuración de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Configuración de Fail2Ban
COPY fail2ban/jail.local /etc/fail2ban/jail.local
COPY fail2ban/filter-http-flood.conf /etc/fail2ban/filter.d/http-flood.conf
COPY fail2ban/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Exponer el puerto 80 (Nginx)
EXPOSE 80

# Entrypoint personalizado (arranca Nginx + Fail2Ban)
ENTRYPOINT ["/entrypoint.sh"]