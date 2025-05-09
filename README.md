# PostgreSQL Database Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ShellCheck](https://img.shields.io/badge/shellcheck-passing-brightgreen.svg)](https://www.shellcheck.net/)

This integrated script automates the process of backing up and restoring PostgreSQL databases, with an easy-to-use subcommand interface.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Usage](#usage)
  - [Help](#help)
  - [Create a backup](#create-a-backup)
  - [List available backups](#list-available-backups)
  - [Restore a backup](#restore-a-backup)
- [Advanced Usage](#advanced-usage)
- [Configuration via .env file](#configuration-via-env-file)
- [Configuration priority order](#configuration-priority-order)
- [Security](#security)
- [Tests](#tests)
- [Contributing](#contributing)
- [License](#license)

## Features

### General
- Intuitive subcommand interface (backup, restore, list)
- Flexible configuration through environment variables or command-line arguments
- Color-coded messages for better readability
- Robust error handling

### Backup
- Performs full backups of PostgreSQL databases
- Optional compression of backup files (configurable)
- Names files with timestamps for easy identification
- Automatically deletes old backups (configurable period)

### Restore
- Restores backups to the same or a different database
- Automatic selection of the most recent backup
- Handles compressed and uncompressed files
- Checks for active connections before restoring

## Requirements

- PostgreSQL Client (pg_dump, psql, createdb)
- Bash shell
- Standard Unix utilities (find, gzip, gunzip)
- Read/write permissions on the databases
- Write permissions in the destination directory

## Project Structure

```
/
├── bin/                  # Executable scripts
│   └── db_manager.sh     # Main script
├── config/               # Configuration files
│   ├── .env.example      # Environment variable template
│   └── .env              # Actual environment variables (not included in git)
├── docs/                 # Additional documentation
│   └── examples.md       # Advanced usage examples
├── tests/                # Unit and integration tests
│   └── test_backup.sh    # Tests for backup functionality
├── .gitignore            # Files to ignore by git
├── CONTRIBUTING.md       # Contribution guide
├── LICENSE               # MIT License
└── README.md             # This documentation
```

## Installation

**Prerequisites:**
- `git` (for cloning the repository)

1. Clone this repository (replace `<your-repository-url>` with the actual URL or use the one for this project):
   ```bash
   git clone git@github.com:AutanaSoft/pg-backup-manager.git
   cd pg-backup-manager
   ```

2. Make the script executable:
   ```bash
   chmod +x bin/db_manager.sh
   ```

3. Copy the example environment variables file:
   ```bash
   cp config/.env.example config/.env
   ```

4. Edit the `config/.env` file with your database credentials:
   ```bash
   nano config/.env
   ```

## Usage

The script uses a subcommand interface similar to tools like git:

```bash
./bin/db_manager.sh <command> [options]
```

For more complex scenarios and advanced examples, please refer to the [Advanced Usage Examples](docs/examples.md) document.

Where `<command>` can be:
- `backup`: Create a database backup
- `restore`: Restore a backup to a database
- `list`: List available backups
- `help`: Show general help

### Help

```bash
# General help
./bin/db_manager.sh help

# Specific help for a command
./bin/db_manager.sh backup -h
./bin/db_manager.sh restore -h
```

### Create a backup

```bash
# Basic backup specifying the database name
./bin/db_manager.sh backup -db database_name

# Backup relying on DB_NAME from config/.env file
# (Assumes DB_NAME is set in config/.env)
./bin/db_manager.sh backup

# Backup with additional options (overrides .env values for these options)
./bin/db_manager.sh backup -db database_name -path /path/to/backups -host 192.168.1.100 -user admin -pass secret
```

Available options:
- `-db`: Name of the database to back up. If `DB_NAME` is set in `config/.env`, this option is not strictly mandatory; if omitted, the `.env` value will be used. If provided, it overrides the `.env` value for this specific command.
- `-path`: Path where backups will be saved (default: 'backups')
- `-host`: Database host
- `-port`: Database port
- `-user`: Database user
- `-pass`: Database password

### List available backups

```bash
./bin/db_manager.sh list
```

This command will output a list of available backup files found in the configured backup directory. Example output:

```
[INFO] 2025-05-09 10:00:00 - Loading environment variables from file /home/user/projects/pg-backup-manager/config/.env

=== Available backups ===

ID      Date                    Size            Database        File
0       2025-05-09 07:16:06     1.2M            app_pro         app_pro_20250509071606.sql.gz
1       2025-05-09 07:15:36     850K            app_dev         app_dev_20250509071536.sql.gz
2       2025-05-09 07:00:47     849K            app_dev         app_dev_20250509070047.sql.gz
3       2025-05-09 06:59:56     1.1M            app_pro         app_pro_20250509065956.sql.gz

```

### Restore a backup

```bash
# Restore the most recent backup
./bin/db_manager.sh restore -db database_name

# Restore a specific file
./bin/db_manager.sh restore -db database_name -file file_name.sql.gz

# Restore to a different server
./bin/db_manager.sh restore -db new_db -file backup.sql.gz -host other_server -user other_user -pass other_key
```

Available options:
- `-db`: Name of the database to restore. If `DB_NAME` is set in `config/.env`, this option is not strictly mandatory for restoring to that default database; if omitted, the `.env` value will be used. If provided, it overrides the `.env` value for this specific command.
- `-file`: Backup file to restore (if not specified, uses the most recent for the given database name)
- `-path`: Path where backups are located (default: 'backups')
- `-host`: Database host
- `-port`: Database port
- `-user`: Database user
- `-pass`: Database password

## Advanced Usage

For more advanced usage examples, such as cron job automation, restoring to different environments, and integration with other tools, please see the [Advanced Usage Examples document](docs/examples.md).

## Configuration via .env file

The script can be configured using a `config/.env` file located in the `config/` directory. The following variables can be set:

```
# Database configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres

# Default database for backup/restore
DB_NAME=database_name

# Retention days for old backups (optional, default: 7)
RETENTION_DAYS=7

# Compress the backup file (optional, default: true)
COMPRESS_BACKUP=true

# Directory to save backups (optional, default: 'backups')
# If a relative path is used, it's relative to the project's root directory.
BACKUP_DIR=backups
```

## Configuration priority order

The script uses the following priority order to determine the values to use:

1. Command-line parameters (highest priority)
2. Variables defined in the `.env` file
3. Script default values (lowest priority)

## Security

- The `config/.env` file, which may contain sensitive credentials, is included in `.gitignore` by default to prevent accidental commits.
- It is highly recommended to set restrictive permissions on the `config/.env` file: `chmod 600 config/.env`
- Passwords are never displayed in the script logs
- Confirmation is requested before performing destructive operations (like restoring a database)

## Tests

The project includes a basic test script `tests/test_backup.sh` to verify core backup and restore functionalities. 

To run the tests:
1. Ensure you have a test database configured or are prepared for the script to attempt to create one based on your `.env` settings (or defaults).
2. Execute the script:
```bash
./tests/test_backup.sh
```
Review the output of the script to ensure all tests pass as expected. The test script itself contains comments and can be modified to suit more specific testing scenarios.

## Additional Documentation

For more advanced examples and use cases, refer to the [Advanced Usage Examples document](docs/examples.md).

## Contributing

Contributions are welcome! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
