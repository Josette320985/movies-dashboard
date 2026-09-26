# Movies Dashboard — LDAP + Keycloak + OAuth 2.0 / OIDC

Sistema completo de autenticación y gestión de películas usando **OpenLDAP**, **Keycloak**, **FastAPI** y **Vue.js**.

Este proyecto implementa un flujo completo de autenticación **OAuth 2.0 / OpenID Connect** donde los usuarios se validan contra un directorio **LDAP**, se emite un **JWT** firmado por Keycloak, y el frontend inyecta ese token en cada request al backend para autorizar las operaciones.

---

## Arquitectura

```
┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│              │        │              │        │              │
│   Vue.js     │───────▶│   Keycloak   │───────▶│   OpenLDAP   │
│   :5173      │  Login │   :8081      │  Bind  │   :389       │
│              │◀───────│              │        │              │
└──────┬───────┘  JWT   └──────────────┘        └──────────────┘
       │
       │ Bearer Token
       │
       ▼
┌──────────────┐
│              │
│  FastAPI     │  Valida JWT con JWKS de Keycloak
│  :8001       │
│              │
└──────────────┘
```

**Flujo:**
1. El usuario ingresa credenciales en el frontend (Vue).
2. El frontend solicita un token a Keycloak (Resource Owner Password Grant).
3. Keycloak valida las credenciales contra OpenLDAP.
4. Keycloak devuelve un **JWT firmado** (RS256).
5. El frontend almacena el JWT en **Pinia** + `localStorage`.
6. Cada request al backend incluye el header `Authorization: Bearer <JWT>`.
7. El backend **FastAPI** valida el JWT contra la clave pública (JWKS) de Keycloak.
8. Si el JWT es válido, permite la operación; si no, devuelve **401**.

---

## Repositorios

Este proyecto está dividido en **3 repositorios**:

| # | Repositorio | Descripción |
|---|---|---|
| 1 | [ldap-keycloak-oauth2-lab](https://github.com/TU_USUARIO/ldap-keycloak-oauth2-lab) | Infraestructura Docker: OpenLDAP, Keycloak, PostgreSQL, phpLDAPadmin |
| 2 | [movies-backend](https://github.com/TU_USUARIO/movies-backend) | API FastAPI que valida JWT y gestiona las películas |
| 3 | [movies-dashboard](https://github.com/TU_USUARIO/movies-dashboard) | Frontend Vue.js con Pinia, Router y Axios |

---

## Tecnologías Utilizadas

### Frontend
- **Vue.js 3** (Composition API con `<script setup>`)
- **Pinia** — Manejo del estado global (JWT, usuario)
- **Vue Router** — Navegación con guards de autenticación
- **Axios** — Cliente HTTP con inyección de Bearer Token
- **Vite** — Bundler y servidor de desarrollo

### Backend
- **FastAPI** — Framework web asíncrono
- **python-jose[cryptography]** — Validación de JWT
- **httpx** — Cliente HTTP asíncrono para obtener JWKS
- **Uvicorn** — Servidor ASGI

### Infraestructura
- **Docker Compose** — Orquestación de servicios
- **OpenLDAP 1.5.0** — Directorio de usuarios
- **Keycloak 26.7.4** — Identity Provider (OIDC/OAuth2)
- **PostgreSQL 16** — Base de datos de Keycloak
- **phpLDAPadmin** — Administración web del LDAP

---

## Instalación y Uso

### Requisitos previos
- Docker Desktop instalado
- Python 3.11+
- Node.js 18+ y npm

### Paso 1: Levantar la infraestructura (LDAP + Keycloak)

```bash
cd ldap-keycloak-oauth2-lab
docker compose up -d --build

# Cargar usuarios LDAP (alice, bob)
# En Linux/Mac:
./load-ldap-users.sh
# En Windows PowerShell:
docker cp ldap/users.ldif openldap:/tmp/users.ldif
docker exec openldap ldapadd -c -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=com" -w adminpassword -f /tmp/users.ldif
```

**Servicios disponibles:**
- Keycloak: http://localhost:8081 (admin / adminpassword)
- phpLDAPadmin: http://localhost:8080
- API de clase (referencia): http://localhost:8000/docs

### Paso 2: Levantar el backend de películas

```bash
cd movies-backend
pip install -r requirements.txt
python main.py
```

Servidor en: http://localhost:8001

### Paso 3: Levantar el frontend Vue

```bash
cd movies-dashboard
npm install
npm install axios
npm run dev
```

Aplicación en: http://localhost:5173

---

##  Credenciales de prueba

| Servicio | Usuario | Contraseña |
|---|---|---|
| Keycloak Admin | `admin` | `adminpassword` |
| LDAP Admin | `cn=admin,dc=example,dc=com` | `adminpassword` |
| Usuario de prueba 1 | `alice` | `alice123` |

---

## Endpoints del Backend

| Método | Endpoint | Descripción | Requiere JWT |
|---|---|---|---|
| GET | `/health` | Verificar estado del servidor | ❌ |
| GET | `/api/movies` | Obtener lista de películas | ✅ |
| POST | `/api/movies` | Agregar una película nueva | ✅ |

**Ejemplo de uso con curl:**

```bash
# 1. Obtener JWT desde Keycloak
TOKEN=$(curl -s -X POST http://localhost:8081/realms/cybersecurity/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=fastapi-api" \
  -d "username=alice" \
  -d "password=alice123" \
  -d "scope=openid" | jq -r '.access_token')

# 2. Usar el JWT para llamar al backend
curl http://localhost:8001/api/movies \
  -H "Authorization: Bearer $TOKEN"
```

## Estructura del Proyecto

```
PracticaFinal/
├── ldap-keycloak-oauth2-lab/      # Infraestructura Docker
│   ├── docker-compose.yml
│   ├── ldap/
│   │   └── users.ldif
│   ├── keycloak/
│   │   └── import/
│   │       └── cybersecurity-realm.json
│   ├── load-ldap-users.sh
│   └── reset.sh
│
├── movies-backend/                # API FastAPI
│   ├── main.py
│   └── requirements.txt
│
└── movies-dashboard/              # Frontend Vue
    ├── src/
    │   ├── router/index.js
    │   ├── stores/auth.js
    │   ├── styles/
    │   │   ├── login.css
    │   │   ├── dashboard.css
    │   │   └── addMovie.css
    │   ├── views/
    │   │   ├── Login.vue
    │   │   ├── Dashboard.vue
    │   │   └── AddMovie.vue
    │   ├── App.vue
    │   └── main.js
    ├── package.json
    └── vite.config.js
```


