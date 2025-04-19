# Ejemplos de Uso Avanzados

Este documento proporciona ejemplos avanzados de uso para el Gestor de Bases de Datos PostgreSQL.

## Escenarios de Backup

### Backup de múltiples bases de datos

Para hacer backup de varias bases de datos en secuencia:

```bash
#!/bin/bash
# Script para hacer backup de múltiples bases de datos

DATABASES=("db1" "db2" "db3")
for db in "${DATABASES[@]}"; do
  ../bin/db_manager.sh backup -db "$db"
done
```

### Backup con rotación personalizada

Para implementar una estrategia de rotación personalizada:

```bash
#!/bin/bash
# Mantener backups diarios durante una semana, semanales durante un mes y mensuales durante un año

# Backup diario
../bin/db_manager.sh backup -db mi_base_datos

# Backup semanal (cada domingo)
if [ "$(date +%u)" = "7" ]; then
  ../bin/db_manager.sh backup -db mi_base_datos -path backups/weekly
fi

# Backup mensual (primer día del mes)
if [ "$(date +%d)" = "01" ]; then
  ../bin/db_manager.sh backup -db mi_base_datos -path backups/monthly
fi
```

## Escenarios de Restauración

### Restauración a un servidor de desarrollo

Para restaurar un backup de producción a un entorno de desarrollo:

```bash
../bin/db_manager.sh restore -db dev_database \
  -file production_20250419123456.sql.gz \
  -host dev-server \
  -user dev_user \
  -password dev_password
```

### Restauración con transformación de datos

Para restaurar y luego anonimizar datos sensibles:

```bash
#!/bin/bash
# Restaurar y luego anonimizar datos para entorno de pruebas

# Primero restauramos el backup
../bin/db_manager.sh restore -db test_db -file production_backup.sql.gz

# Luego ejecutamos script de anonimización
PGPASSWORD=password psql -h localhost -U postgres -d test_db -f anonymize_data.sql
```

## Integración con Otras Herramientas

### Notificaciones por correo electrónico

Para enviar notificaciones por correo después de un backup:

```bash
#!/bin/bash
# Backup con notificación por correo

LOG_FILE="/tmp/backup_log.txt"

# Ejecutar backup y guardar salida en archivo de log
../bin/db_manager.sh backup -db mi_base_datos > "$LOG_FILE" 2>&1
BACKUP_STATUS=$?

# Enviar correo con el resultado
if [ $BACKUP_STATUS -eq 0 ]; then
  mail -s "Backup completado con éxito" admin@example.com < "$LOG_FILE"
else
  mail -s "ERROR en backup" admin@example.com < "$LOG_FILE"
fi
```

### Integración con monitoreo

Para integrar con sistemas de monitoreo:

```bash
#!/bin/bash
# Integración con sistema de monitoreo

START_TIME=$(date +%s)
../bin/db_manager.sh backup -db mi_base_datos
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Enviar métrica a sistema de monitoreo
echo "backup.duration $DURATION $(date +%s)" | nc -w 1 metrics-server 2003
```
