# movies-dashboard

## Preparación del servicio

```powershell
cd C:\Users\naher\Documents\PracticaFinal\movies-dashboard
docker compose up -d
```

## Verificación de red del contenedor

```powershell
docker inspect movies-frontend --format '{{range $k, $v := .NetworkSettings.Networks}}{{println $k}}{{end}}'
```

Red detectada:

```text
movies-dashboard_labnet
```

## Ajuste de Fail2Ban para permitir el escaneo

```powershell
docker exec movies-frontend fail2ban-client set http-flood maxretry 500
```

## Primer escaneo con Nuclei

```powershell
docker run --rm --network movies-dashboard_labnet -v "${PWD}\reports:/reports" -v "nuclei-templates-cache:/root/nuclei-templates" projectdiscovery/nuclei:latest -target http://movies-frontend:80 -severity info,low,medium -rate-limit 30 -timeout 10 -jsonl-export /reports/nuclei-cinelog-frontend.jsonl
```

## Resultados del primer escaneo

- Servicio: **movies-frontend**
- Hallazgos: **15**
- Problemas principales:
  - Headers de seguridad