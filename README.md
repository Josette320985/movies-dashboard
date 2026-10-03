# Movies Dashboard — Vue.js + Nginx + Fail2Ban

Frontend del proyecto **CineLog** — dashboard de películas con autenticación **OAuth 2.0 / OIDC** contra **Keycloak + LDAP**, protegido con **Fail2Ban**.

![Vue.js](https://img.shields.io/badge/Vue.js-3-4FC08D?logo=vuedotjs&logoColor=white)
![Pinia](https://img.shields.io/badge/Pinia-2-FFD859?logo=pinia&logoColor=black)
![Nginx](https://img.shields.io/badge/Nginx-1.27-009639?logo=nginx&logoColor=white)
![Fail2Ban](https://img.shields.io/badge/Fail2Ban-1.0-EE0000?logo=linux&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Alpine-2496ED?logo=docker&logoColor=white)

---

##  Description

Vue.js 3 SPA (Composition API + `<script setup>`) que:

- ✅ Autentica contra **Keycloak** (OAuth 2.0 / OIDC)
- ✅ Almacena el **JWT** con **Pinia** + `localStorage`
- ✅ Inyecta el token en cada request al backend con **Axios**
- ✅ Protege rutas con **Vue Router** guards
- ✅ Se sirve con **Nginx** y **Fail2Ban** en producción
- ✅ Se despliega como imagen **Docker** multi-stage

---

##  Repositorios Relacionados

| # | Repositorio | Descripción |
|---|---|---|
| 1 | [ldap-keycloak-oauth2-lab](https://github.com/Josette320985/ldap-keycloak-oauth2-lab) | Infraestructura Docker (OpenLDAP + Keycloak + PostgreSQL) |
| 2 | [movies-backend](https://github.com/Josette320985/movies-backend) | API FastAPI con validación JWT |
| 3 | **movies-dashboard** (este repo) | Frontend Vue.js |
| 4 | [ddos-script](https://github.com/Josette320985/ddos-script) | Script de load test |

---

##  Cómo levantar el contenedor

### Requisitos previos

- **Docker Desktop** instalado y corriendo.
- Los otros servicios del proyecto **deben estar levantados primero**:
  - `ldap-keycloak-oauth2-lab` (en `http://localhost:8081`)
  - `movies-backend` (en `http://localhost:8001`)

### Paso 1: Levantar la infraestructura y el backend

```bash
# Terminal 1: Infraestructura (LDAP + Keycloak)
cd ldap-keycloak-oauth2-lab
docker compose up -d

# Terminal 2: Backend
cd movies-backend
docker compose up -d --build
```

### Paso 2: Levantar el frontend

```bash
# Terminal 3: Frontend
cd movies-dashboard
docker compose up -d --build
```

**Tiempo esperado:** 1-2 minutos (multi-stage build).

**Salida esperada:**
```
[+] Building XXs (XX/XX) FINISHED
 => naming to docker.io/library/movies-dashboard-frontend
[+] Running 2/2
 ✔ Network movies-dashboard_labnet  Created
 ✔ Container movies-frontend         Started
```

### Paso 3: Abrir en el navegador

| URL | Descripción |
|---|---|
| **http://localhost:5173** | Aplicación (login + dashboard) |
| http://localhost:8081 | Keycloak Admin Console |
| http://localhost:8001/docs | Backend Swagger |
| http://localhost:8080 | phpLDAPadmin |

**Credenciales de prueba:** `alice` / `alice123`

### Paso 4: Verificar que Fail2Ban está activo

```bash
docker exec movies-frontend fail2ban-client status
docker exec movies-frontend fail2ban-client status http-flood
```

**Esperado:**
```
Status for the jail: http-flood
|- Filter
|  |- Currently failed: 0
|  `- File list:        /var/log/nginx/access.log
`- Actions
   |- Currently banned: 0
   `- Banned IP list:
```

---

##  Cómo detener el contenedor

```bash
cd movies-dashboard
docker compose down
```

**Para detener TODOS los servicios del proyecto:**

```bash
# Detener frontend
cd movies-dashboard && docker compose down

# Detener backend
cd movies-backend && docker compose down

# Detener infraestructura
cd ldap-keycloak-oauth2-lab && docker compose down
```

> ⚠️ **NO uses `-v`** a menos que quieras borrar volúmenes (LDAP users, Keycloak DB).

---

##  Estructura del Proyecto

```
movies-dashboard/
├── src/
│   ├── router/index.js            # Rutas + guards
│   ├── stores/auth.js             # Pinia store (JWT)
│   ├── styles/                    # CSS separado
│   │   ├── login.css
│   │   ├── dashboard.css
│   │   └── addMovie.css
│   ├── views/
│   │   ├── Login.vue
│   │   ├── Dashboard.vue
│   │   └── AddMovie.vue
│   ├── App.vue
│   └── main.js
├── fail2ban/
│   ├── jail.local                 # Jail http-flood
│   ├── filter-http-flood.conf
│   └── entrypoint.sh
├── Dockerfile                     # Multi-stage: Vue → Nginx + Fail2Ban
├── nginx.conf
├── docker-compose.yml
├── .dockerignore
├── package.json
└── README.md
```

---

##  Fail2Ban Configuration

**Jail `http-flood`:** banea IPs que envían **+60 requests en 10 segundos**.

**`fail2ban/jail.local`:**
```ini
[DEFAULT]
banaction = iptables-allports
ignoreip = 127.0.0.1/8
usedns = no
backend = polling
bantime = 10m
bantime.increment = true
bantime.factor = 2
bantime.maxtime = 1d

[http-flood]
enabled = true
port = http,https
filter = http-flood
logpath = /var/log/nginx/access.log
maxretry = 60
findtime = 10s
```

**Filtro `fail2ban/filter-http-flood.conf`:**
```ini
[Definition]
failregex = ^<HOST> -.*"(?:GET|POST|HEAD|PUT|DELETE|PATCH|OPTIONS|CONNECT|TRACE) [^"]*" [0-9]{3}
ignoreregex =
```

---

##  Load Test Results

**RPS máximo seguro desde una IP:** **5 RPS**

| RPS | Total | OK | Failed | % Failed | ¿Baneó? |
|---|---|---|---|---|---|
| **5** | 98 | 98 | 0 | **0%** | ❌ NO |
| 6 | 117 | 61 | 56 | 47% | ✅ SÍ |
| 50 | 660 | 76 | 584 | 88% | ✅ SÍ |

Ver detalles completos en el [repo ddos-script](https://github.com/TU_USUARIO/ddos-script).

---

##  Probar Fail2Ban manualmente

```bash
# Enviar 200 requests rápidos desde PowerShell
1..200 | ForEach-Object {
    try { Invoke-WebRequest -Uri http://localhost:5173 -UseBasicParsing | Out-Null } catch { }
}

# Ver si tu IP fue baneada
docker exec movies-frontend fail2ban-client status http-flood

# Desbanear
docker exec movies-frontend fail2ban-client set http-flood unbanip <IP>
```

---

##  JWT Handling

- Almacenado en **Pinia** + `localStorage`.
- Inyectado en cada request al backend: `Authorization: Bearer <JWT>`.
- **NO se imprime en consola** (removido del código).
- Al recibir **401**, se limpia y redirige al login.

**Endpoints consumidos:**
| Método | Endpoint | Requiere JWT |
|---|---|---|
| GET | `http://localhost:8001/health` | ❌ |
| GET | `http://localhost:8001/api/movies` | ✅ |
| POST | `http://localhost:8001/api/movies` | ✅ |

---

##  Troubleshooting

| Problema | Solución |
|---|---|
| Error 401 en `/api/movies` | Verifica que el backend (`:8001`) y Keycloak (`:8081`) estén corriendo |
| Fail2Ban banea mi IP | `docker exec movies-frontend fail2ban-client set http-flood unbanip <IP>` |
| El contenedor no arranca | `docker logs movies-frontend` |
| Error de CORS | Verifica la configuración de `webOrigins` en Keycloak para el cliente `fastapi-api` |

---




