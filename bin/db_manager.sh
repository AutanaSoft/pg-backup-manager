#!/bin/bash

# Definir colores para mensajes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Versión del script
VERSION="1.0.0"

# Función para mostrar mensajes
log_message() {
    local type=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    case $type in
        "info")
            echo -e "${GREEN}[INFO]${NC} $timestamp - $message"
            ;;
        "warn")
            echo -e "${YELLOW}[WARN]${NC} $timestamp - $message"
            ;;
        "error")
            echo -e "${RED}[ERROR]${NC} $timestamp - $message"
            ;;
        "title")
            echo -e "\n${BLUE}=== $message ===${NC}\n"
            ;;
        *)
            echo "$timestamp - $message"
            ;;
    esac
}

# Función para mostrar la ayuda general
show_help() {
    echo -e "${BLUE}PostgreSQL Database Manager${NC} v$VERSION"
    echo -e "Herramienta para gestionar backups y restauración de bases de datos PostgreSQL\n"
    echo "Uso: $0 <comando> [opciones]"
    echo ""
    echo "Comandos disponibles:"
    echo "  backup    Crear un backup de una base de datos"
    echo "  restore   Restaurar un backup a una base de datos"
    echo "  list      Listar los backups disponibles"
    echo "  help      Mostrar esta ayuda"
    echo ""
    echo "Para ver las opciones específicas de cada comando, use:"
    echo "  $0 <comando> --help"
    echo ""
    exit 0
}

# Función para mostrar la ayuda del comando backup
show_backup_help() {
    echo -e "${BLUE}PostgreSQL Database Manager - Comando BACKUP${NC}"
    echo -e "Crea un backup de una base de datos PostgreSQL\n"
    echo "Uso: $0 backup [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -db       Nombre de la base de datos a respaldar (opcional si está definido en .env)"
    echo "  -path     Ruta donde se guardarán los backups (por defecto: 'backups')"
    echo "  -host     Host de la base de datos (opcional, por defecto: valor en .env o localhost)"
    echo "  -port     Puerto de la base de datos (opcional, por defecto: valor en .env o 5432)"
    echo "  -user     Usuario de la base de datos (opcional, por defecto: valor en .env o postgres)"
    echo "  -pass     Contraseña de la base de datos (opcional, por defecto: valor en .env o postgres)"
    echo "  -h        Muestra esta ayuda"
    echo ""
    exit 0
}

# Función para mostrar la ayuda del comando restore
show_restore_help() {
    echo -e "${BLUE}PostgreSQL Database Manager - Comando RESTORE${NC}"
    echo -e "Restaura un backup a una base de datos PostgreSQL\n"
    echo "Uso: $0 restore [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -db       Nombre de la base de datos a restaurar (opcional si está definido en .env)"
    echo "  -file     Nombre del archivo de backup a restaurar (si no se especifica, se usará el más reciente)"
    echo "  -path     Ruta donde se encuentran los backups (por defecto: 'backups')"
    echo "  -host     Host de la base de datos (opcional, por defecto: valor en .env o localhost)"
    echo "  -port     Puerto de la base de datos (opcional, por defecto: valor en .env o 5432)"
    echo "  -user     Usuario de la base de datos (opcional, por defecto: valor en .env o postgres)"
    echo "  -pass     Contraseña de la base de datos (opcional, por defecto: valor en .env o postgres)"
    echo "  -h        Muestra esta ayuda"
    echo ""
    exit 0
}

# Función para cargar variables de entorno
load_env() {
    # Obtener el directorio base del proyecto
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    CONFIG_DIR="$PROJECT_ROOT/config"
    
    # Cargar variables de entorno desde config/.env si existe
    if [ -f "$CONFIG_DIR/.env" ]; then
        log_message "info" "Cargando variables de entorno desde archivo $CONFIG_DIR/.env"
        set -a
        . "$CONFIG_DIR/.env"
        set +a
    else
        log_message "warn" "Archivo $CONFIG_DIR/.env no encontrado, usando valores por defecto"
    fi
    
    # Establecer valor por defecto para BACKUP_DIR
    BACKUP_DIR="${BACKUP_DIR:-backups}"
    
    # Si BACKUP_DIR no es una ruta absoluta, hacerla relativa al directorio del proyecto
    if [[ "$BACKUP_DIR" != /* ]]; then
        BACKUP_DIR="$PROJECT_ROOT/$BACKUP_DIR"
    fi
}

# Función para listar los backups disponibles
list_backups() {
    local backup_dir="$1"
    
    log_message "title" "Backups disponibles"
    
    # Verificar si el directorio de backup existe
    if [ ! -d "$backup_dir" ]; then
        log_message "info" "El directorio de backup '$backup_dir' no existe"
        mkdir -p "$backup_dir"
    fi
    
    # Buscar archivos .sql y .sql.gz
    local files=($(find "$backup_dir" -type f \( -name "*.sql" -o -name "*.sql.gz" \) | sort -r))
    
    if [ ${#files[@]} -eq 0 ]; then
        log_message "warn" "No se encontraron archivos de backup"
        return 0
    fi
    
    echo -e "${YELLOW}ID\tFecha\t\tTamaño\t\tBase de datos\tArchivo${NC}"
    
    for i in "${!files[@]}"; do
        local file="${files[$i]}"
        local filename=$(basename "$file")
        local size=$(du -h "$file" | cut -f1)
        local date_created=$(date -r "$file" "+%Y-%m-%d %H:%M:%S")
        local db_name=$(echo "$filename" | sed -E 's/(.+)_[0-9]{14}\.sql(\.gz)?$/\1/')
        
        echo -e "$i\t$date_created\t$size\t$db_name\t$filename"
    done
    
    echo ""
    return 0
}

# Función para crear un backup
do_backup() {
    log_message "title" "Creación de backup"
    
    # Procesar los argumentos
    local db_name=""
    local backup_dir="$BACKUP_DIR"
    local db_host=""
    local db_port=""
    local db_user=""
    local db_password=""
    
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            -h|--help)
            show_backup_help
            ;;
            -db)
            db_name="$2"
            shift
            shift
            ;;
            -path)
            backup_dir="$2"
            shift
            shift
            ;;
            -host)
            db_host="$2"
            shift
            shift
            ;;
            -port)
            db_port="$2"
            shift
            shift
            ;;
            -user)
            db_user="$2"
            shift
            shift
            ;;
            -pass)
            db_password="$2"
            shift
            shift
            ;;
            *)
            log_message "warn" "Opción desconocida: $1"
            shift
            ;;
        esac
    done
    
    # Si DB_NAME no se especificó como argumento, usar el valor de .env
    if [ -z "$db_name" ]; then
        # Verificar si DB_NAME está definido en .env
        if [ -z "${DB_NAME}" ]; then
            log_message "error" "No se ha especificado la base de datos. Usa -db o define DB_NAME en .env"
            mkdir -p "$backup_dir"
        else
            db_name="${DB_NAME}"
            log_message "info" "Usando base de datos definida en .env: $db_name"
        fi
    fi
    
    # Configuración de la base de datos
    # Prioridad: 1. Parámetros de línea de comandos, 2. Variables de entorno, 3. Valores por defecto
    local db_host="${db_host:-${DB_HOST:-localhost}}"
    local db_port="${db_port:-${DB_PORT:-5432}}"
    local db_user="${db_user:-${DB_USER:-postgres}}"
    local db_password="${db_password:-${DB_PASSWORD:-postgres}}"
    
    # Crear directorio de backup si no existe
    if [ ! -d "$backup_dir" ]; then
        log_message "info" "Creando directorio de backup: $backup_dir"
        mkdir -p "$backup_dir"
    fi
    
    # Fecha y hora
    local timestamp=$(date "+%Y%m%d%H%M%S")
    
    # Nombre del archivo de backup
    local backup_file="$backup_dir/${db_name}_$timestamp.sql"
    
    # Verificar si pg_dump está instalado
    if ! command -v pg_dump &> /dev/null; then
        log_message "error" "pg_dump no está instalado. Por favor, instala PostgreSQL client tools."
        mkdir -p "$backup_dir"
    fi
    
    # Mensaje de inicio
    log_message "info" "Realizando backup de la base de datos $db_name en $backup_file"
    
    # Comando para hacer el backup con manejo de errores
    if PGPASSWORD=$db_password pg_dump -h $db_host -p $db_port -U $db_user -F p -b -v -f "$backup_file" "$db_name"; then
        # Verificar tamaño del archivo
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_message "info" "Backup de la base de datos $db_name realizado con éxito (Tamaño: $backup_size)"
        
        # Comprimir el archivo si está habilitado
        local compress_backup=${COMPRESS_BACKUP:-true}
        
        if [ "$compress_backup" = true ]; then
            log_message "info" "Comprimiendo archivo de backup..."
            gzip -f "$backup_file"
            local compressed_size=$(du -h "$backup_file.gz" | cut -f1)
            log_message "info" "Archivo comprimido: $backup_file.gz (Tamaño: $compressed_size)"
            # Actualizar el nombre del archivo para referencias posteriores
            backup_file="$backup_file.gz"
        else
            log_message "info" "Compresión de backup desactivada"
        fi
        
        # Eliminar archivos de backup antiguos (mayores a los días de retención)
        local retention_days=${RETENTION_DAYS:-7}
        log_message "info" "Eliminando archivos de backup antiguos (mayores a $retention_days días)"
        
        # Determinar el patrón de búsqueda según si se comprimió o no
        local search_pattern
        if [ "$compress_backup" = true ]; then
            search_pattern="*.sql.gz"
        else
            search_pattern="*.sql"
        fi
        
        find "$backup_dir" -type f -name "$search_pattern" -mtime +"$retention_days" -exec rm {} \;
        
        # Contar backups restantes
        local backup_count=$(find "$backup_dir" -type f -name "$search_pattern" | wc -l)
        log_message "info" "Backups disponibles: $backup_count"
        
        # Mensaje final
        log_message "info" "Proceso de backup finalizado con éxito"
        return 0
    else
        log_message "error" "Error al realizar el backup de la base de datos $db_name"
        mkdir -p "$backup_dir"
    fi
}

# Función para restaurar un backup
do_restore() {
    log_message "title" "Restauración de backup"
    
    # Procesar los argumentos
    local db_name=""
    local backup_file=""
    local backup_dir="$BACKUP_DIR"
    local db_host=""
    local db_port=""
    local db_user=""
    local db_password=""
    
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            -h|--help)
            show_restore_help
            ;;
            -db)
            db_name="$2"
            shift
            shift
            ;;
            -file)
            backup_file="$2"
            shift
            shift
            ;;
            -path)
            backup_dir="$2"
            shift
            shift
            ;;
            -host)
            db_host="$2"
            shift
            shift
            ;;
            -port)
            db_port="$2"
            shift
            shift
            ;;
            -user)
            db_user="$2"
            shift
            shift
            ;;
            -pass)
            db_password="$2"
            shift
            shift
            ;;
            *)
            log_message "warn" "Opción desconocida: $1"
            shift
            ;;
        esac
    done
    
    # Si DB_NAME no se especificó como argumento, usar el valor de .env
    if [ -z "$db_name" ]; then
        # Verificar si DB_NAME está definido en .env
        if [ -z "${DB_NAME}" ]; then
            log_message "error" "No se ha especificado la base de datos. Usa -db o define DB_NAME en .env"
            mkdir -p "$backup_dir"
        else
            db_name="${DB_NAME}"
            log_message "info" "Usando base de datos definida en .env: $db_name"
        fi
    fi
    
    # Configuración de la base de datos
    # Prioridad: 1. Parámetros de línea de comandos, 2. Variables de entorno, 3. Valores por defecto
    local db_host="${db_host:-${DB_HOST:-localhost}}"
    local db_port="${db_port:-${DB_PORT:-5432}}"
    local db_user="${db_user:-${DB_USER:-postgres}}"
    local db_password="${db_password:-${DB_PASSWORD:-postgres}}"
    
    # Verificar si el directorio de backup existe
    if [ ! -d "$backup_dir" ]; then
        log_message "info" "El directorio de backup '$backup_dir' no existe"
        mkdir -p "$backup_dir"
    fi
    
    # Si no se especificó un archivo de backup, buscar el más reciente para la base de datos
    if [ -z "$backup_file" ]; then
        log_message "info" "Buscando el backup más reciente para la base de datos $db_name"
        
        # Buscar el archivo más reciente (primero .sql.gz, luego .sql)
        backup_file=$(find "$backup_dir" -type f \( -name "${db_name}_*.sql.gz" -o -name "${db_name}_*.sql" \) | sort -r | head -n 1)
        
        if [ -z "$backup_file" ]; then
            log_message "error" "No se encontró ningún backup para la base de datos $db_name"
            mkdir -p "$backup_dir"
        fi
        
        log_message "info" "Se usará el backup más reciente: $(basename "$backup_file")"
    else
        # Si se especificó un archivo, verificar si es una ruta completa o solo el nombre
        if [[ "$backup_file" != /* ]]; then
            backup_file="$backup_dir/$backup_file"
        fi
        
        # Verificar si el archivo existe
        if [ ! -f "$backup_file" ]; then
            log_message "error" "El archivo de backup '$backup_file' no existe"
            mkdir -p "$backup_dir"
        fi
    fi
    
    # Verificar si psql está instalado
    if ! command -v psql &> /dev/null; then
        log_message "error" "psql no está instalado. Por favor, instala PostgreSQL client tools."
        mkdir -p "$backup_dir"
    fi
    
    # Preguntar confirmación antes de restaurar
    log_message "warn" "¡ATENCIÓN! Estás a punto de restaurar la base de datos $db_name con el backup: $(basename "$backup_file")"
    log_message "warn" "Esto sobrescribirá TODOS los datos existentes en la base de datos $db_name"
    read -p "¿Estás seguro de que deseas continuar? (s/N): " confirm
    if [[ ! "$confirm" =~ ^[sS]$ ]]; then
        log_message "info" "Operación cancelada por el usuario"
        return 0
    fi
    
    # Descomprimir el archivo si es necesario
    local temp_file=""
    local restore_file=""
    if [[ "$backup_file" == *.gz ]]; then
        log_message "info" "Descomprimiendo archivo de backup..."
        temp_file="/tmp/$(basename "$backup_file" .gz)"
        gunzip -c "$backup_file" > "$temp_file"
        restore_file="$temp_file"
    else
        restore_file="$backup_file"
    fi
    
    # Mensaje de inicio
    log_message "info" "Iniciando restauración de la base de datos $db_name desde $(basename "$backup_file")"
    
    # Intentar crear la base de datos si no existe
    log_message "info" "Verificando si la base de datos existe..."
    if ! PGPASSWORD=$db_password psql -h $db_host -p $db_port -U $db_user -lqt | cut -d \| -f 1 | grep -qw $db_name; then
        log_message "info" "La base de datos $db_name no existe, creándola..."
        if ! PGPASSWORD=$db_password createdb -h $db_host -p $db_port -U $db_user $db_name; then
            log_message "error" "No se pudo crear la base de datos $db_name"
            # Limpiar archivo temporal si existe
            [ -n "$temp_file" ] && rm -f "$temp_file"
            mkdir -p "$backup_dir"
        fi
    else
        # Si la base de datos existe, verificar si hay conexiones activas
        log_message "info" "Verificando conexiones activas a la base de datos..."
        local active_connections=$(PGPASSWORD=$db_password psql -h $db_host -p $db_port -U $db_user -c "SELECT count(*) FROM pg_stat_activity WHERE datname = '$db_name' AND pid <> pg_backend_pid();" -t | tr -d ' ')
        
        if [ "$active_connections" -gt 0 ]; then
            log_message "warn" "Hay $active_connections conexiones activas a la base de datos. Se recomienda cerrarlas antes de continuar."
            read -p "¿Deseas continuar de todos modos? (s/N): " confirm
            if [[ ! "$confirm" =~ ^[sS]$ ]]; then
                log_message "info" "Operación cancelada por el usuario"
                # Limpiar archivo temporal si existe
                [ -n "$temp_file" ] && rm -f "$temp_file"
                return 0
            fi
        fi
    fi
    
    # Comando para restaurar la base de datos
    log_message "info" "Restaurando la base de datos $db_name..."
    
    if PGPASSWORD=$db_password psql -h $db_host -p $db_port -U $db_user -d $db_name -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" &>/dev/null; then
        log_message "info" "Esquema público reiniciado correctamente"
    else
        log_message "warn" "No se pudo reiniciar el esquema público, intentando restaurar de todos modos"
    fi
    
    # Restaurar la base de datos
    if PGPASSWORD=$db_password psql -h $db_host -p $db_port -U $db_user -d $db_name -f "$restore_file"; then
        log_message "info" "Restauración de la base de datos $db_name completada con éxito"
    else
        log_message "error" "Error al restaurar la base de datos $db_name"
        # Limpiar archivo temporal si existe
        [ -n "$temp_file" ] && rm -f "$temp_file"
        mkdir -p "$backup_dir"
    fi
    
    # Limpiar archivo temporal si existe
    if [ -n "$temp_file" ]; then
        log_message "info" "Eliminando archivo temporal..."
        rm -f "$temp_file"
    fi
    
    log_message "info" "Proceso de restauración finalizado con éxito"
    return 0
}

# Función principal
main() {
    # Si no se proporcionaron argumentos, mostrar la ayuda
    if [ $# -eq 0 ]; then
        show_help
    fi
    
    # Cargar variables de entorno
    load_env
    
    # Procesar el comando principal
    command="$1"
    shift
    
    case $command in
        backup)
            do_backup "$@"
            ;;
        restore)
            do_restore "$@"
            ;;
        list)
            list_backups "$BACKUP_DIR"
            ;;
        help)
            show_help
            ;;
        *)
            log_message "error" "Comando desconocido: $command"
            show_help
            ;;
    esac
    
    exit $?
}

# Ejecutar la función principal
main "$@"
