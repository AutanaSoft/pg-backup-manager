# Advanced Usage Examples

This document provides advanced usage examples for the PostgreSQL Database Manager.

## Backup Scenarios

### Backup of multiple databases

To back up multiple databases in sequence:

```bash
#!/bin/bash
# Script to back up multiple databases

DATABASES=("db1" "db2" "db3")
for db in "${DATABASES[@]}"; do
  ../bin/db_manager.sh backup -db "$db"
done
```

### Backup with custom rotation

To implement a custom rotation strategy:

```bash
#!/bin/bash
# Keep daily backups for a week, weekly for a month, and monthly for a year

# Daily backup
# This backup will go to the default path (e.g., 'backups/' or as configured in .env)
../bin/db_manager.sh backup -db my_database

# Weekly backup (every Sunday)
if [ "$(date +%u)" = "7" ]; then
  ../bin/db_manager.sh backup -db my_database -path backups/weekly
fi

# Monthly backup (first day of the month)
if [ "$(date +%d)" = "01"; then
  ../bin/db_manager.sh backup -db my_database -path backups/monthly
fi
```
Note: For the daily backup, if you want it in a specific subdirectory like `backups/daily`, add the `-path backups/daily` option to the command.

### Backup relying on .env configuration

If you have configured your `DB_NAME` and connection parameters (host, user, port, password) in the `config/.env` file, you can run a backup with a very simple command:

```bash
# Assumes DB_NAME, DB_HOST, DB_USER, DB_PASSWORD, DB_PORT are set in config/.env
# Also uses default BACKUP_DIR or the one set in .env
../bin/db_manager.sh backup
```
This will back up the database specified by `DB_NAME` in your `.env` file to the configured backup path.

## Restore Scenarios

### Restore to a development server

To restore a production backup to a development environment:

```bash
../bin/db_manager.sh restore -db dev_database \
  -file production_20250419123456.sql.gz \
  -host dev-server \
  -port 5433 \
  -user dev_user \
  -pass dev_password
```

### Restore with data transformation

To restore and then anonymize sensitive data:

```bash
#!/bin/bash
# Restore and then anonymize data for testing environment

# First, restore the backup
../bin/db_manager.sh restore -db test_db -file production_backup.sql.gz

# Then, run the anonymization script
PGPASSWORD=password psql -h localhost -U postgres -d test_db -f anonymize_data.sql
```

## Integration with Other Tools

### Email notifications

To send email notifications after a backup:

```bash
#!/bin/bash
# Backup with email notification

LOG_FILE="/tmp/backup_log.txt"

# Execute backup and save output to log file
../bin/db_manager.sh backup -db my_database > "$LOG_FILE" 2>&1
BACKUP_STATUS=$?

# Send email with the result
if [ $BACKUP_STATUS -eq 0 ]; then
  mail -s "Backup completed successfully" admin@example.com < "$LOG_FILE"
else
  mail -s "ERROR in backup" admin@example.com < "$LOG_FILE"
fi
```

### Integration with monitoring

To integrate with monitoring systems:

```bash
#!/bin/bash
# Integration with monitoring system

START_TIME=$(date +%s)
../bin/db_manager.sh backup -db my_database
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Send metric to monitoring system
echo "backup.duration $DURATION $(date +%s)" | nc -w 1 metrics-server 2003
```
