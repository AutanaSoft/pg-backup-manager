# Gestor de Bases de Datos PostgreSQL

Este script integrado automatiza el proceso de respaldo y restauración de bases de datos PostgreSQL, con una interfaz de subcomandos fácil de usar.

## Características

### Generales
- Interfaz de subcomandos intuitiva (backup, restore, list)
- Configuración flexible a través de variables de entorno o argumentos de línea de comandos
- Mensajes con colores para mejor legibilidad
- Manejo de errores robusto

### Backup
- Realiza backups completos de bases de datos PostgreSQL
- Compresión opcional de archivos de backup (configurable)
- Nombra los archivos con marcas de tiempo para fácil identificación
- Elimina automáticamente backups antiguos (período configurable)

### Restauración
- Restaura backups a la misma base de datos o a una diferente
- Selección automática del backup más reciente
- Manejo de archivos comprimidos y sin comprimir
- Verificación de conexiones activas antes de restaurar

## Requisitos

- PostgreSQL Client (pg_dump, psql, createdb)
- Bash shell
- Utilidades estándar de Unix (find, gzip, gunzip)
- Permisos de lectura/escritura en las bases de datos
- Permisos de escritura en el directorio de destino

## Estructura del Proyecto

```
/
├── bin/                  # Scripts ejecutables
│   └── db_manager.sh     # Script principal
├── config/               # Archivos de configuración
│   ├── .env.example      # Plantilla de variables de entorno
│   └── .env              # Variables de entorno reales (no incluido en git)
├── docs/                 # Documentación adicional
│   └── examples.md       # Ejemplos de uso avanzados
├── tests/                # Pruebas unitarias y de integración
│   └── test_backup.sh    # Pruebas para la funcionalidad de backup
├── .gitignore            # Archivos a ignorar por git
├── CONTRIBUTING.md       # Guía de contribución
├── LICENSE               # Licencia MIT
└── README.md             # Esta documentación
```

## Instalación

1. Clona este repositorio:
   ```bash
   git clone https://github.com/tu-usuario/nombre-del-repo.git
   cd nombre-del-repo
   ```

2. Haz el script ejecutable:
   ```bash
   chmod +x bin/db_manager.sh
   ```

3. Copia el archivo de ejemplo de variables de entorno:
   ```bash
   cp config/.env.example config/.env
   ```

4. Edita el archivo `config/.env` con tus credenciales de base de datos:
   ```bash
   nano config/.env
   ```

## Uso

El script utiliza una interfaz de subcomandos similar a herramientas como git:

```bash
./bin/db_manager.sh <comando> [opciones]
```

Donde `<comando>` puede ser:
- `backup`: Crear un backup de una base de datos
- `restore`: Restaurar un backup a una base de datos
- `list`: Listar los backups disponibles
- `help`: Mostrar ayuda general

### Ayuda

```bash
# Ayuda general
./bin/db_manager.sh help

# Ayuda específica para un comando
./bin/db_manager.sh backup -h
./bin/db_manager.sh restore -h
```

### Crear un backup

```bash
# Backup básico
./bin/db_manager.sh backup -db nombre_base_datos

# Backup con opciones adicionales
./bin/db_manager.sh backup -db nombre_base_datos -path /ruta/backups -host 192.168.1.100 -user admin -pass secreto
```

Opciones disponibles:
- `-db`: Nombre de la base de datos a respaldar (obligatorio si no está en .env)
- `-path`: Ruta donde se guardarán los backups (por defecto: 'backups')
- `-host`: Host de la base de datos
- `-port`: Puerto de la base de datos
- `-user`: Usuario de la base de datos
- `-pass`: Contraseña de la base de datos

### Listar backups disponibles

```bash
./bin/db_manager.sh list
```

### Restaurar un backup

```bash
# Restaurar el backup más reciente
./bin/db_manager.sh restore -db nombre_base_datos

# Restaurar un archivo específico
./bin/db_manager.sh restore -db nombre_base_datos -file nombre_archivo.sql.gz

# Restaurar a un servidor diferente
./bin/db_manager.sh restore -db nueva_db -file backup.sql.gz -host otro_servidor -user otro_usuario -pass otra_clave
```

Opciones disponibles:
- `-db`: Nombre de la base de datos a restaurar (obligatorio si no está en .env)
- `-file`: Archivo de backup a restaurar (si no se especifica, usa el más reciente)
- `-path`: Ruta donde se encuentran los backups (por defecto: 'backups')
- `-host`: Host de la base de datos
- `-port`: Puerto de la base de datos
- `-user`: Usuario de la base de datos
- `-pass`: Contraseña de la base de datos
2. Ejecuta el script con los argumentos requeridos

## Configuración mediante archivo .env

El script puede configurarse mediante un archivo `config/.env` con las siguientes variables:

```
# Configuración de la base de datos
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres

# Base de datos por defecto para hacer backup/restore
DB_NAME=nombre_base_datos

# Días de retención para backups antiguos (opcional, por defecto: 7)
RETENTION_DAYS=7

# Comprimir el archivo de backup (opcional, por defecto: true)
COMPRESS_BACKUP=true

# Directorio para guardar los backups (opcional, por defecto: 'backups')
BACKUP_DIR=backups
```

## Orden de prioridad para configuraciones

El script utiliza el siguiente orden de prioridad para determinar los valores a usar:

1. Parámetros de línea de comandos (máxima prioridad)
2. Variables definidas en el archivo `.env`
3. Valores predeterminados del script (mínima prioridad)

## Seguridad

- El archivo `config/.env` está incluido en `.gitignore` para evitar exponer credenciales
- Se recomienda configurar permisos restrictivos en el archivo `config/.env`: `chmod 600 config/.env`
- Las contraseñas nunca se muestran en los logs del script
- Se solicita confirmación antes de realizar operaciones destructivas (como restaurar una base de datos)

## Ejemplos de uso avanzado

### Backup automático mediante cron

```bash
# Backup diario a las 2 AM
0 2 * * * /ruta/completa/a/bin/db_manager.sh backup -db mi_base_datos > /var/log/db_backup.log 2>&1
```

### Restaurar a una base de datos temporal para pruebas

```bash
./bin/db_manager.sh restore -db db_pruebas -file produccion_20250419123456.sql.gz -host localhost
```

## Pruebas

El proyecto incluye un conjunto de pruebas básicas que puedes ejecutar para verificar que todo funciona correctamente:

```bash
./tests/test_backup.sh
```

Para pruebas más avanzadas, consulta los comentarios en el archivo `tests/test_backup.sh`.

## Documentación Adicional

Para ejemplos más avanzados y casos de uso, consulta la [documentación adicional](docs/examples.md).

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.
