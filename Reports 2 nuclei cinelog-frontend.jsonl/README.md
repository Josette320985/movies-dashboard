# Reporte de Correcciones de Seguridad — CineLog

Este documento recopila las correcciones aplicadas y los hallazgos restantes en los tres servicios de CineLog: Frontend, Backend y Keycloak Proxy.

---

## 1. Frontend — movies-dashboard

###  Resumen

| Métrica | Antes | Después |
|---|---:|---:|
| Hallazgos totales | 15 | 3 |
| Reducción | — | **80 %** |

###  Correcciones aplicadas

#### 1. Headers de seguridad en `nginx.conf`

Se configuraron los siguientes encabezados de seguridad en Nginx para reducir los riesgos relacionados con la exposición de información, la carga de contenido externo y los ataques del lado del cliente.

```nginx
server_tokens off;

add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
add_header Cross-Origin-Opener-Policy "same-origin" always;
add_header Cross-Origin-Embedder-Policy "require-corp" always;
add_header Cross-Origin-Resource-Policy "same-origin" always;
add_header X-Permitted-Cross-Domain-Policies "none" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self' http://localhost:8001 http://localhost:8081" always;
```

Las principales modificaciones fueron las siguientes:

- Se eliminó el encabezado `X-XSS-Protection`, debido a que es obsoleto y no se recomienda como mecanismo de protección moderno.
- Se eliminó `'unsafe-inline'` de la directiva `script-src` de la política de seguridad de contenido (CSP), después de verificar que el HTML generado no contiene scripts en línea.
- Se configuró `server_tokens off` para ocultar la versión de Nginx.
- Se agregaron encabezados para controlar la carga de recursos, restringir permisos del navegador y reducir los riesgos de ataques mediante iframes.
- Se incorporó HSTS para indicar a los navegadores que deben utilizar HTTPS durante el periodo especificado.

#### 2. Aplicación de HSTS

Se utilizó el siguiente comando de PowerShell para agregar el encabezado HSTS a `nginx.conf`, únicamente si todavía no estaba configurado.

```powershell
cd C:\Users\naher\Documents\PracticaFinal\movies-dashboard

$content = Get-Content nginx.conf -Raw

if ($content -notmatch "Strict-Transport-Security") {
    $content = $content -replace '(add_header X-Permitted-Cross-Domain-Policies "none" always;)', '$1' + "`n    add_header Strict-Transport-Security `"max-age=31536000; includeSubDomains`" always;"

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText(
        "$PWD\nginx.conf",
        $content,
        $utf8NoBom
    )

    Write-Host "HSTS añadido al frontend"
} else {
    Write-Host "HSTS ya existe en frontend"
}

Get-Content nginx.conf | Select-String "Strict-Transport-Security"
```

La configuración aplicada establece una duración de un año (`max-age=31536000`) e incluye los subdominios mediante `includeSubDomains`. Su efectividad depende de que el servicio se encuentre accesible mediante HTTPS y de que la política sea adecuada para los subdominios correspondientes.

#### 3. Reconstrucción y verificación

Después de modificar la configuración, se reconstruyó y levantó el servicio mediante el siguiente comando:

```powershell
docker compose up -d --build
```

Se realizaron las siguientes verificaciones:

- El inicio de sesión con el usuario de prueba `alice` y la contraseña `alice123` funciona correctamente.
- Los encabezados de seguridad están presentes en las respuestas verificadas, incluido HSTS.
- El servicio frontend permanece operativo después de la reconstrucción.

###  Hallazgos restantes

Se reportaron tres hallazgos restantes, todos clasificados como informativos (`info`).

| # | Hallazgo | Justificación |
|---:|---|---|
| 1 | `waf-detect:nginxgeneric` | El WAF basado en Nginx bloquea las peticiones identificadas como maliciosas y responde con `405 Not Allowed`. Este comportamiento es consistente con un mecanismo de filtrado funcionando y no constituye, por sí mismo, una vulnerabilidad. |
| 2 | `tech-detect:nginx` | Se identificó el uso de Nginx mediante los encabezados HTTP. La directiva `server_tokens off` oculta la versión exacta, pero no necesariamente elimina el encabezado `Server`. Se intentó utilizar el módulo `headers-more` para retirarlo; sin embargo, se presentaron incompatibilidades binarias con Nginx 1.27 en Alpine. Por ello, el hallazgo se mantiene como informativo. |
| 3 | `favicon-detect:Vue` | Se detectó el framework Vue mediante el hash del favicon. Esta detección tecnológica no representa, por sí misma, un riesgo de seguridad. |

### Conclusión

El frontend `movies-dashboard` pasó de 15 a 3 hallazgos, lo que representa una reducción del **80 %**. Los hallazgos restantes están clasificados como informativos y corresponden a la detección de tecnologías o a mecanismos de seguridad identificados durante el análisis.

Con base en las verificaciones realizadas, no se identificaron vulnerabilidades explotables entre los hallazgos restantes del frontend. Sin embargo, esta conclusión se limita al alcance y a los resultados de las pruebas efectuadas, por lo que no implica que el servicio esté completamente libre de vulnerabilidades.





