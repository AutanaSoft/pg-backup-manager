#!/bin/bash

# Define colors for messages
GREEN="\\033[0;32m"
YELLOW="\\033[1;33m"
RED="\\033[0;31m"
BLUE="\\033[0;34m"
NC="\\033[0m" # No Color

# Script version
VERSION="1.0.0"

# Function to display messages
log_message() {
    local type="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    case "$type" in
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
            echo -e "\\n${BLUE}=== $message ===${NC}\\n"
            ;;
        *)
            echo "$timestamp - $message"
            ;;
    esac
}

# Function to display general help
show_help() {
    echo -e "${BLUE}PostgreSQL Database Manager${NC} v$VERSION"
    echo -e "Tool to manage backups and restoration of PostgreSQL databases\\n"
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Available commands:"
    echo "  backup    Create a backup of a database"
    echo "  restore   Restore a backup to a database"
    echo "  list      List available backups"
    echo "  help      Show this help"
    echo ""
    echo "To see specific options for each command, use:"
    echo "  $0 <command> --help"
    echo ""
    exit 0
}

# Function to display backup command help
show_backup_help() {
    echo -e "${BLUE}PostgreSQL Database Manager - BACKUP Command${NC}"
    echo -e "Creates a backup of a PostgreSQL database\\n"
    echo "Usage: $0 backup [options]"
    echo ""
    echo "Options:"
    echo "  -db       Name of the database to back up (optional if defined in .env)"
    echo "  -path     Path where backups will be saved (default: 'backups')"
    echo "  -host     Database host (optional, default: value in .env or localhost)"
    echo "  -port     Database port (optional, default: value in .env or 5432)"
    echo "  -user     Database user (optional, default: value in .env or postgres)"
    echo "  -pass     Database password (optional, default: value in .env or postgres)"
    echo "  -h        Show this help"
    echo ""
    exit 0
}

# Function to display restore command help
show_restore_help() {
    echo -e "${BLUE}PostgreSQL Database Manager - RESTORE Command${NC}"
    echo -e "Restores a backup to a PostgreSQL database\\n"
    echo "Usage: $0 restore [options]"
    echo ""
    echo "Options:"
    echo "  -db       Name of the database to restore (optional if defined in .env)"
    echo "  -file     Name of the backup file to restore (if not specified, the most recent will be used)"
    echo "  -path     Path where backups are located (default: 'backups')"
    echo "  -host     Database host (optional, default: value in .env or localhost)"
    echo "  -port     Database port (optional, default: value in .env or 5432)"
    echo "  -user     Database user (optional, default: value in .env or postgres)"
    echo "  -pass     Database password (optional, default: value in .env or postgres)"
    echo "  -h        Show this help"
    echo ""
    exit 0
}

# Function to load environment variables
load_env() {
    # Get the project's base directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    CONFIG_DIR="$PROJECT_ROOT/config"
    
    # Load environment variables from config/.env if it exists
    if [ -f "$CONFIG_DIR/.env" ]; then
        log_message "info" "Loading environment variables from file $CONFIG_DIR/.env"
        set -a
        # shellcheck source=/dev/null
        . "$CONFIG_DIR/.env"
        set +a
    else
        log_message "warn" "File $CONFIG_DIR/.env not found, using default values"
    fi
    
    # Set default value for BACKUP_DIR
    BACKUP_DIR="${BACKUP_DIR:-backups}"
    
    # If BACKUP_DIR is not an absolute path, make it relative to the project directory
    if [[ "$BACKUP_DIR" != /* ]]; then
        BACKUP_DIR="$PROJECT_ROOT/$BACKUP_DIR"
    fi
}

# Function to list available backups
list_backups() {
    local backup_dir="$1"
    
    log_message "title" "Available backups"
    
    # Check if the backup directory exists
    if [ ! -d "$backup_dir" ]; then
        log_message "info" "Backup directory '$backup_dir' does not exist"
        mkdir -p "$backup_dir"
    fi
    
    # Search for .sql and .sql.gz files
    local files=()
    mapfile -t files < <(find "$backup_dir" -type f \( -name "*.sql" -o -name "*.sql.gz" \) -print0 | sort -rz | { while IFS= read -r -d $'\\0' file; do echo "$file"; done })

    if [ ${#files[@]} -eq 0 ]; then
        log_message "warn" "No backup files found"
        return 0
    fi
    
    echo -e "${YELLOW}ID\\tDate\\t\\tSize\\t\\tDatabase\\tFile${NC}"
    
    for i in "${!files[@]}"; do
        local file="${files[$i]}"
        local filename
        filename=$(basename "$file")
        local size
        size=$(du -h "$file" | cut -f1)
        local date_created
        date_created=$(date -r "$file" "+%Y-%m-%d %H:%M:%S")
        local db_name
        db_name=$(echo "$filename" | sed -E 's/(.+)_[0-9]{14}\\.sql(\\.gz)?$/\\1/')
        
        echo -e "$i\\t$date_created\\t$size\\t$db_name\\t$filename"
    done
    
    echo ""
    return 0
}

# Function to create a backup
do_backup() {
    log_message "title" "Backup creation"
    
    # Process arguments
    local db_name=""
    local backup_dir="$BACKUP_DIR"
    local db_host=""
    local db_port=""
    local db_user=""
    local db_password=""
    
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case "$key" in
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
            log_message "warn" "Unknown option: $1"
            shift
            ;;
        esac
    done
    
    # If DB_NAME was not specified as an argument, use the value from .env
    if [ -z "$db_name" ]; then
        # Check if DB_NAME is defined in .env
        if [ -z "${DB_NAME}" ]; then
            log_message "error" "Database not specified. Use -db or define DB_NAME in .env"
            mkdir -p "$backup_dir" # Ensure backup_dir is created before exiting or returning
            return 1 # Indicate failure
        else
            db_name="${DB_NAME}"
            log_message "info" "Using database defined in .env: $db_name"
        fi
    fi
    
    # Database configuration
    # Priority: 1. Command line parameters, 2. Environment variables, 3. Default values
    db_host="${db_host:-${DB_HOST:-localhost}}"
    db_port="${db_port:-${DB_PORT:-5432}}"
    db_user="${db_user:-${DB_USER:-postgres}}"
    db_password="${db_password:-${DB_PASSWORD:-postgres}}"
    
    # Create backup directory if it doesn't exist
    if [ ! -d "$backup_dir" ]; then
        log_message "info" "Creating backup directory: $backup_dir"
        mkdir -p "$backup_dir"
    fi
    
    # Date and time
    local timestamp
    timestamp=$(date "+%Y%m%d%H%M%S")
    
    # Backup file name
    local backup_file="$backup_dir/${db_name}_$timestamp.sql"
    
    # Check if pg_dump is installed
    if ! command -v pg_dump &> /dev/null; then
        log_message "error" "pg_dump is not installed. Please install PostgreSQL client tools."
        mkdir -p "$backup_dir" # Ensure backup_dir is created before exiting or returning
        return 1 # Indicate failure
    fi
    
    # Start message
    log_message "info" "Performing backup of database $db_name to $backup_file"
    
    # Command to perform the backup with error handling
    if PGPASSWORD="$db_password" pg_dump -h "$db_host" -p "$db_port" -U "$db_user" -F p -b -v -f "$backup_file" "$db_name"; then
        # Check file size
        local backup_size
        backup_size=$(du -h "$backup_file" | cut -f1)
        log_message "info" "Database backup $db_name completed successfully (Size: $backup_size)"
        
        # Compress the file if enabled
        local compress_backup="${COMPRESS_BACKUP:-true}"
        
        if [ "$compress_backup" = true ]; then
            log_message "info" "Compressing backup file..."
            gzip -f "$backup_file"
            local compressed_size
            compressed_size=$(du -h "$backup_file.gz" | cut -f1)
            log_message "info" "Compressed file: $backup_file.gz (Size: $compressed_size)"
            # Update file name for later references
            backup_file="$backup_file.gz"
        else
            log_message "info" "Backup compression disabled"
        fi
        
        # Delete old backup files (older than retention days)
        local retention_days="${RETENTION_DAYS:-7}"
        log_message "info" "Deleting old backup files (older than $retention_days days)"
        
        # Determine search pattern based on whether compression was used
        local search_pattern
        if [ "$compress_backup" = true ]; then
            search_pattern="*.sql.gz"
        else
            search_pattern="*.sql"
        fi
        
        find "$backup_dir" -type f -name "$search_pattern" -mtime "+$retention_days" -exec rm {} \;
        
        # Count remaining backups
        local backup_count
        backup_count=$(find "$backup_dir" -type f -name "$search_pattern" | wc -l)
        log_message "info" "Available backups: $backup_count"
        
        # Final message
        log_message "info" "Backup process finished successfully"
        return 0
    else
        log_message "error" "Error performing backup of database $db_name"
        mkdir -p "$backup_dir" # Ensure backup_dir is created before exiting or returning
        return 1 # Indicate failure
    fi
}

# Function to restore a backup
do_restore() {
    log_message "title" "Backup restoration"
    
    # Process arguments
    local db_name=""
    local backup_file_arg="" # Renamed to avoid conflict with backup_file variable used later
    local backup_dir="$BACKUP_DIR"
    local db_host=""
    local db_port=""
    local db_user=""
    local db_password=""
    
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case "$key" in
            -h|--help)
            show_restore_help
            ;;
            -db)
            db_name="$2"
            shift
            shift
            ;;
            -file)
            backup_file_arg="$2"
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
            log_message "warn" "Unknown option: $1"
            shift
            ;;
        esac
    done
    
    # If DB_NAME was not specified as an argument, use the value from .env
    if [ -z "$db_name" ]; then
        # Check if DB_NAME is defined in .env
        if [ -z "${DB_NAME}" ]; then
            log_message "error" "Database not specified. Use -db or define DB_NAME in .env"
            mkdir -p "$backup_dir" # Ensure backup_dir is created before exiting or returning
            return 1 # Indicate failure
        else
            db_name="${DB_NAME}"
            log_message "info" "Using database defined in .env: $db_name"
        fi
    fi
    
    # Database configuration
    # Priority: 1. Command line parameters, 2. Environment variables, 3. Default values
    db_host="${db_host:-${DB_HOST:-localhost}}"
    db_port="${db_port:-${DB_PORT:-5432}}"
    db_user="${db_user:-${DB_USER:-postgres}}"
    db_password="${db_password:-${DB_PASSWORD:-postgres}}"
    
    # Check if the backup directory exists
    if [ ! -d "$backup_dir" ]; then
        log_message "info" "Backup directory '$backup_dir' does not exist"
        mkdir -p "$backup_dir" # Ensure backup_dir is created before exiting or returning
    fi
    
    local current_backup_file # Declare variable to store the determined backup file path
    # If no backup file was specified, search for the most recent one for the database
    if [ -z "$backup_file_arg" ]; then
        log_message "info" "Searching for the most recent backup for database $db_name"
        
        # Search for the most recent file (first .sql.gz, then .sql)
        current_backup_file=$(find "$backup_dir" -type f \( -name "${db_name}_*.sql.gz" -o -name "${db_name}_*.sql" \) -print0 | sort -rz | { IFS= read -r -d $'\\0' file; echo "$file"; } )

        if [ -z "$current_backup_file" ]; then
            log_message "error" "No backup found for database $db_name"
            mkdir -p "$backup_dir" # Ensure backup_dir is created before exiting or returning
            return 1
        fi
        
        log_message "info" "Using the most recent backup: $(basename "$current_backup_file")"
    else
        # If a file was specified, check if it's an absolute path, relative, or just the name
        if [[ "$backup_file_arg" == /* ]]; then
            # It's an absolute path, use it as is
            current_backup_file="$backup_file_arg"
        elif [[ "$backup_file_arg" == ./* ]] || [[ "$backup_file_arg" == ../* ]]; then
            # It's a relative path, convert it to absolute from the current directory
            current_backup_file="$(cd "$(dirname "$backup_file_arg")" && pwd)/$(basename "$backup_file_arg")"
        else
            # It's just a file name, add the backup directory path
            current_backup_file="$backup_dir/$backup_file_arg"
        fi
        
        # Check if the file exists
        if [ ! -f "$current_backup_file" ]; then
            log_message "error" "Backup file '$current_backup_file' does not exist"
            mkdir -p "$backup_dir" # Ensure backup_dir is created before exiting or returning
            return 1
        fi
    fi
    
    # Check if psql is installed
    if ! command -v psql &> /dev/null; then
        log_message "error" "psql is not installed. Please install PostgreSQL client tools."
        mkdir -p "$backup_dir" # Ensure backup_dir is created before exiting or returning
        return 1 # Indicate failure
    fi
    
    # Ask for confirmation before restoring
    log_message "warn" "ATTENTION! You are about to restore database $db_name with backup: $(basename "$current_backup_file")"
    log_message "warn" "This will overwrite ALL existing data in database $db_name"
    local confirm
    read -r -p "Are you sure you want to continue? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        log_message "info" "Operation cancelled by the user"
        return 0
    fi
    
    # Decompress the file if necessary
    local temp_file=""
    local restore_file=""
    if [[ "$current_backup_file" == *.gz ]]; then
        log_message "info" "Decompressing backup file..."
        temp_file="/tmp/$(basename "$current_backup_file" .gz)"
        gunzip -c "$current_backup_file" > "$temp_file"
        restore_file="$temp_file"
    else
        restore_file="$current_backup_file"
    fi
    
    # Start message
    log_message "info" "Starting restoration of database $db_name from $(basename "$current_backup_file")"
    
    # Try to create the database if it doesn't exist
    log_message "info" "Checking if the database exists..."
    if ! PGPASSWORD="$db_password" psql -h "$db_host" -p "$db_port" -U "$db_user" -lqt | cut -d '|' -f 1 | grep -qw "$db_name"; then
        log_message "info" "Database $db_name does not exist, creating it..."
        if ! PGPASSWORD="$db_password" createdb -h "$db_host" -p "$db_port" -U "$db_user" "$db_name"; then
            log_message "error" "Could not create database $db_name"
            # Clean up temporary file if it exists
            [ -n "$temp_file" ] && rm -f "$temp_file"
            mkdir -p "$backup_dir" # Ensure backup_dir is created before exiting or returning
            return 1 # Indicate failure
        fi
    else
        # If the database exists, check for active connections
        log_message "info" "Checking for active connections to the database..."
        local active_connections
        active_connections=$(PGPASSWORD="$db_password" psql -h "$db_host" -p "$db_port" -U "$db_user" -c "SELECT count(*) FROM pg_stat_activity WHERE datname = '$db_name' AND pid <> pg_backend_pid();" -tA)
        
        if [ "$active_connections" -gt 0 ]; then
            log_message "warn" "There are $active_connections active connections to the database. It is recommended to close them before continuing."
            read -r -p "Do you want to continue anyway? (y/N): " confirm
            if [[ ! "$confirm" =~ ^[yY]$ ]]; then
                log_message "info" "Operation cancelled by the user"
                # Clean up temporary file if it exists
                [ -n "$temp_file" ] && rm -f "$temp_file"
                return 0
            fi
        fi
    fi
    
    # Command to restore the database
    log_message "info" "Restoring database $db_name..."
    
    if PGPASSWORD="$db_password" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" &>/dev/null; then
        log_message "info" "Public schema reset successfully"
    else
        log_message "warn" "Could not reset public schema, attempting to restore anyway"
    fi
    
    # Restore the database
    if PGPASSWORD="$db_password" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -f "$restore_file"; then
        log_message "info" "Database restoration $db_name completed successfully"
    else
        log_message "error" "Error restoring database $db_name"
        # Clean up temporary file if it exists
        [ -n "$temp_file" ] && rm -f "$temp_file"
        mkdir -p "$backup_dir" # Ensure backup_dir is created before exiting or returning
        return 1 # Indicate failure
    fi
    
    # Clean up temporary file if it exists
    [ -n "$temp_file" ] && rm -f "$temp_file"
    
    log_message "info" "Restore process finished successfully"
    return 0
}

# Main function
main() {
    # Load environment variables
    load_env
    
    # Check if no arguments were provided
    if [ $# -eq 0 ]; then
        show_help
    fi
    
    # Main command
    COMMAND=$1
    shift # Remove the command from the arguments
    
    case "$COMMAND" in
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
            log_message "error" "Unknown command: $COMMAND"
            show_help
            ;;
    esac
    
    exit $?
}

# Execute main function
main "$@"
