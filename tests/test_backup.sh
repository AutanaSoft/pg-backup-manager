#!/bin/bash

# Script de prueba para la funcionalidad de backup
# Este script verifica que las funciones básicas del script de backup funcionen correctamente

# Colores para mensajes
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Contador de pruebas
TESTS_TOTAL=0
TESTS_PASSED=0

# Función para ejecutar una prueba
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    
    echo -n "Ejecutando prueba: $test_name... "
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # Ejecutar el comando y capturar su código de salida
    eval "$command"
    local exit_code=$?
    
    if [ $exit_code -eq $expected_exit_code ]; then
        echo -e "${GREEN}PASÓ${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FALLÓ${NC} (código de salida esperado: $expected_exit_code, obtenido: $exit_code)"
        return 1
    fi
}

# Configurar entorno de prueba
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DB="test_db_$(date +%s)"
TEST_BACKUP_DIR="$SCRIPT_DIR/test_backups"

# Crear directorio para backups de prueba
mkdir -p "$TEST_BACKUP_DIR"

echo "=== Iniciando pruebas para db_manager.sh ==="
echo "Directorio de pruebas: $TEST_BACKUP_DIR"
echo "Base de datos de prueba: $TEST_DB"

# Prueba 1: Verificar que el script existe y es ejecutable
run_test "Verificar script" "[ -x $PROJECT_ROOT/bin/db_manager.sh ]"

# Prueba 2: Verificar que el comando help funciona
run_test "Comando help" "$PROJECT_ROOT/bin/db_manager.sh help > /dev/null"

# Prueba 3: Verificar que el comando list funciona con un directorio vacío
# Nota: El comando list devuelve 0 incluso cuando no hay backups
run_test "Comando list" "$PROJECT_ROOT/bin/db_manager.sh list -path $TEST_BACKUP_DIR > /dev/null"

# NOTA: Las siguientes pruebas requieren una base de datos PostgreSQL real
# Descomenta y adapta según tu entorno

# # Prueba 4: Crear un backup
# run_test "Crear backup" "$PROJECT_ROOT/bin/db_manager.sh backup -db $TEST_DB -path $TEST_BACKUP_DIR -host localhost -user postgres -password postgres > /dev/null"

# # Prueba 5: Verificar que el backup se creó
# run_test "Verificar backup creado" "find $TEST_BACKUP_DIR -name \"${TEST_DB}_*.sql*\" | grep -q ."

# # Prueba 6: Restaurar el backup
# run_test "Restaurar backup" "$PROJECT_ROOT/bin/db_manager.sh restore -db ${TEST_DB}_restored -path $TEST_BACKUP_DIR -host localhost -user postgres -password postgres -file \$(find $TEST_BACKUP_DIR -name \"${TEST_DB}_*.sql*\" | sort -r | head -n 1) > /dev/null" 1

# Limpiar entorno de prueba
# Descomenta si ejecutaste las pruebas 4-6
# echo "Limpiando entorno de prueba..."
# PGPASSWORD=postgres dropdb -h localhost -U postgres $TEST_DB 2>/dev/null
# PGPASSWORD=postgres dropdb -h localhost -U postgres ${TEST_DB}_restored 2>/dev/null
# rm -rf "$TEST_BACKUP_DIR"

# Mostrar resumen
echo "=== Resumen de pruebas ==="
echo "Total de pruebas: $TESTS_TOTAL"
echo "Pruebas pasadas: $TESTS_PASSED"
echo "Pruebas fallidas: $((TESTS_TOTAL - TESTS_PASSED))"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}Todas las pruebas pasaron${NC}"
    exit 0
else
    echo -e "${RED}Algunas pruebas fallaron${NC}"
    exit 1
fi
