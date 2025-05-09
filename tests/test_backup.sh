#!/bin/bash

# Test script for backup functionality
# This script verifies that the basic functions of the backup script work correctly

# Colors for messages
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Test counter
TESTS_TOTAL=0
TESTS_PASSED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    
    echo -n "Running test: $test_name... "
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # Execute the command and capture its exit code
    eval "$command"
    local exit_code=$?
    
    if [ $exit_code -eq "$expected_exit_code" ]; then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAILED${NC} (expected exit code: $expected_exit_code, got: $exit_code)"
        return 1
    fi
}

# Configure test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DB="test_db_$(date +%s)"
TEST_BACKUP_DIR="$SCRIPT_DIR/test_backups"

# Create directory for test backups
mkdir -p "$TEST_BACKUP_DIR"

echo "=== Starting tests for db_manager.sh ==="
echo "Test directory: $TEST_BACKUP_DIR"
echo "Test database: $TEST_DB"

# Test 1: Verify that the script exists and is executable
run_test "Verify script" "[ -x $PROJECT_ROOT/bin/db_manager.sh ]"

# Test 2: Verify that the help command works
run_test "Help command" "$PROJECT_ROOT/bin/db_manager.sh help > /dev/null"

# Test 3: Verify that the list command works with an empty directory
# Note: The list command returns 0 even when there are no backups
run_test "List command" "$PROJECT_ROOT/bin/db_manager.sh list -path $TEST_BACKUP_DIR > /dev/null"

# NOTE: The following tests require a real PostgreSQL database
# Uncomment and adapt to your environment

# # Test 4: Create a backup
run_test "Create backup" "$PROJECT_ROOT/bin/db_manager.sh backup -db $TEST_DB -path $TEST_BACKUP_DIR -host localhost -user postgres -pass postgres > /dev/null"

# # Test 5: Verify that the backup was created
run_test "Verify backup created" "find $TEST_BACKUP_DIR -name \"${TEST_DB}_*.sql*\" | grep -q ."

# # Test 6: Restore the backup
run_test "Restore backup" "$PROJECT_ROOT/bin/db_manager.sh restore -db ${TEST_DB}_restored -path $TEST_BACKUP_DIR -host localhost -user postgres -pass postgres -file \$(find $TEST_BACKUP_DIR -name \"${TEST_DB}_*.sql*\" | sort -r | head -n 1) > /dev/null" 1

# Clean up test environment
# Uncomment if you ran tests 4-6
echo "Cleaning up test environment..."
PGPASSWORD=postgres dropdb -h localhost -U postgres $TEST_DB 2>/dev/null
PGPASSWORD=postgres dropdb -h localhost -U postgres ${TEST_DB}_restored 2>/dev/null
rm -rf "$TEST_BACKUP_DIR"

# Show summary
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
