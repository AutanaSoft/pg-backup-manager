#!/bin/bash

# Test script for backup functionality
# This script verifies that the basic functions of the backup script work correctly

# Colors for messages
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color
YELLOW="\033[1;33m"

# Test counter
TESTS_TOTAL=0
TESTS_PASSED=0
TEST_NUMBER=0

# Database credentials - use environment variables if set, otherwise use defaults
DB_HOST="${TEST_DB_HOST:-localhost}"
DB_USER="${TEST_DB_USER:-postgres}"
DB_PASS="${TEST_DB_PASS:-postgres}"
DB_PORT="${TEST_DB_PORT:-5432}" # Default PostgreSQL port

# Verbose output for tests - set to true to see command outputs
VERBOSE_TESTS="${VERBOSE_TESTS:-false}"

# Function to check for necessary commands
check_commands() {
    local missing_commands=0
    for cmd in psql createdb dropdb pg_dump; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}Error: Command '$cmd' not found. Please install PostgreSQL client tools.${NC}"
            missing_commands=1
        fi
    done
    if [ "$missing_commands" -eq 1 ]; then
        exit 1
    fi
}

# Function to run a test
run_test() {
    local test_name="$1"
    local command_to_run="$2"
    local expected_exit_code="${3:-0}"
    local print_output_on_success=false # Renamed from capture_output for clarity
    if [ "$#" -gt 3 ]; then
        print_output_on_success=$4 # Use the 4th argument if provided
    fi

    TEST_NUMBER=$((TEST_NUMBER + 1))
    echo -n "Running test $TEST_NUMBER: $test_name... "
    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    local output # To store command output
    local exit_code # To store command exit code

    if [ "$VERBOSE_TESTS" = true ]; then
        # If verbose, print the command being executed
        echo -e "\nExecuting: $command_to_run"
    fi

    # Always capture output (stdout and stderr) from the command
    # shellcheck disable=SC2086
    output=$(eval $command_to_run 2>&1)
    exit_code=$?

    if [ "$VERBOSE_TESTS" = true ]; then
        # If verbose, print the captured output immediately after execution
        # This helps in seeing what happened, regardless of pass/fail status for verbose mode
        echo -e "${YELLOW}Verbose Output:${NC}\n$output"
    fi

    if [ $exit_code -eq "$expected_exit_code" ]; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        if [ "$print_output_on_success" = true ]; then
            # If the test passed and printing output on success was requested, show it
            echo -e "${YELLOW}Output on Success:${NC}\n$output"
        fi
        return 0 # Test passed
    else
        echo -e "${RED}FAILED${NC} (expected exit code: $expected_exit_code, got: $exit_code)"
        # Always print the captured output when a test fails for diagnostics
        echo -e "${YELLOW}Output on Failure:${NC}\n$output"
        return 1 # Test failed
    fi
}

# Configure test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DB="test_db_$(date +%s)"
TEST_DB_RESTORED="${TEST_DB}_restored"
TEST_BACKUP_DIR="$SCRIPT_DIR/test_backups"
TEST_TABLE_NAME="test_data_table"
TEST_DATA_VALUE="Hello, pg-backup-manager!"

# Function to set up the test environment
setup_environment() {
    echo "Setting up test environment..."
    mkdir -p "$TEST_BACKUP_DIR"
    echo "Creating test database: $TEST_DB..."
    if PGPASSWORD=$DB_PASS createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$TEST_DB"; then
        echo "Test database $TEST_DB created."
        echo "Populating test database $TEST_DB from $PROJECT_ROOT/tests/test_db_schema.sql..."
        if PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TEST_DB" -a -f "$PROJECT_ROOT/tests/test_db_schema.sql" &> /dev/null; then
            echo "Test database populated successfully."
            local count
            count=$(PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TEST_DB" -tAc "SELECT COUNT(*) FROM $TEST_TABLE_NAME WHERE message = '$TEST_DATA_VALUE';")
            if [ "$count" -eq 1 ]; then
                echo "Test data verified in $TEST_DB."
            else
                echo -e "${RED}Error: Failed to verify test data in $TEST_DB after populating from SQL file. Count: $count ${NC}"
                cleanup_environment
                exit 1
            fi
        else
            echo -e "${RED}Error: Failed to populate test database $TEST_DB from $PROJECT_ROOT/tests/test_db_schema.sql.${NC}"
            # Attempt to get more detailed error from psql
            echo -e "${YELLOW}psql stderr/stdout from populating attempt:${NC}"
            PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$TEST_DB" -a -f "$PROJECT_ROOT/tests/test_db_schema.sql"
            cleanup_environment
            exit 1
        fi
    else
        echo -e "${RED}Error: Could not create test database $TEST_DB. Please check PostgreSQL connection and permissions.${NC}"
        cleanup_environment
        exit 1
    fi
}

# Function to clean up the test environment
cleanup_environment() {
    echo "Cleaning up test environment..."
    echo "Dropping test databases..."
    PGPASSWORD=$DB_PASS dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" --if-exists "$TEST_DB" &>/dev/null
    PGPASSWORD=$DB_PASS dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" --if-exists "$TEST_DB_RESTORED" &>/dev/null
    echo "Removing test backup directory: $TEST_BACKUP_DIR..."
    rm -rf "$TEST_BACKUP_DIR"
    echo "Cleanup finished."
}

# Trap to ensure cleanup_environment is called on exit
trap cleanup_environment EXIT

# --- Main Test Execution ---
check_commands

echo "=== Starting tests for db_manager.sh ==="
echo "Test directory: $TEST_BACKUP_DIR"
echo "Test database: $TEST_DB"
echo "DB Host: $DB_HOST, User: $DB_USER, Port: $DB_PORT"
echo "Verbose output: $VERBOSE_TESTS"

# Test 1: Verify that the script exists and is executable
run_test "Verify script" "[ -x $PROJECT_ROOT/bin/db_manager.sh ]"

# Test 2: Verify that the help command works
run_test "Help command" "$PROJECT_ROOT/bin/db_manager.sh help"

# Test 3: Verify that the list command works with an empty directory
# Note: The list command returns 0 even when there are no backups
run_test "List command (empty)" "$PROJECT_ROOT/bin/db_manager.sh list -path $TEST_BACKUP_DIR"

# Setup database environment for backup/restore tests
setup_environment

# Test 4: Create a backup
run_test "Create backup" "$PROJECT_ROOT/bin/db_manager.sh backup -db $TEST_DB -path $TEST_BACKUP_DIR -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT"

# Test 5: Verify that the backup was created and is not empty
backup_file_path_pattern="$TEST_BACKUP_DIR/${TEST_DB}_*.sql*"
run_test "Verify backup created and not empty" "find $TEST_BACKUP_DIR -name \"${TEST_DB}_*.sql*\" -size +0c -print | grep -q ."

# Test 6: Restore the backup
# First, get the name of the backup file created
LATEST_BACKUP_FILE=$(find "$TEST_BACKUP_DIR" -name "${TEST_DB}_*.sql*" -type f -print0 | xargs -0 ls -t | head -n 1)
if [ -z "$LATEST_BACKUP_FILE" ]; then
    echo -e "${RED}Critical Error: No backup file found for $TEST_DB to proceed with restore test.${NC}"
    # cleanup_environment is called by trap
    exit 1
fi
echo "Latest backup file for restore test: $LATEST_BACKUP_FILE"

echo "Creating target database for restore: $TEST_DB_RESTORED..."
if PGPASSWORD=$DB_PASS createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$TEST_DB_RESTORED"; then
    echo "Database '$TEST_DB_RESTORED' created successfully."
else
    echo -e "${RED}Critical Error: Failed to create database '$TEST_DB_RESTORED'. Aborting restore tests.${NC}"
    # The trap EXIT will call cleanup_environment.
    exit 1
fi

run_test "Restore backup" "$PROJECT_ROOT/bin/db_manager.sh restore -db $TEST_DB_RESTORED -path $TEST_BACKUP_DIR -host $DB_HOST -user $DB_USER -pass $DB_PASS -port $DB_PORT -file \"$(basename "$LATEST_BACKUP_FILE")\" -y"

# Test 7: Verify data in restored database
run_test "Verify data in restored DB" "PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $TEST_DB_RESTORED -tAc \"SELECT COUNT(*) FROM $TEST_TABLE_NAME WHERE message = '$TEST_DATA_VALUE';\" | grep -q '^1$'"

# Test 8: List command with existing backups
run_test "List command (with backups)" "$PROJECT_ROOT/bin/db_manager.sh list -path $TEST_BACKUP_DIR"

# Show summary (cleanup_environment will be called by trap EXIT)
echo ""
echo "=== Test Summary ==="
echo "Total tests: $TESTS_TOTAL"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_TOTAL - TESTS_PASSED))"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}All tests passed${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi
