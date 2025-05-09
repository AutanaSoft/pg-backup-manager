# Contribution Guide

Thank you for your interest in contributing to this project! We welcome all contributions that help improve this tool. Here are some guidelines to help you get started.

## Code of Conduct

All contributors are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before contributing.

## Contribution Process

1.  **Fork the Repository**: Start by forking the main repository ([`AutanaSoft/pg-backup-manager`](https://github.com/AutanaSoft/pg-backup-manager.git)) on GitHub to your personal account.
2.  **Create a Feature Branch**: For new features or bug fixes, create a descriptive branch from `main`.
    ```bash
    git checkout -b feature/your-amazing-feature
    # or for a bug fix
    git checkout -b fix/issue-description
    ```
3.  **Make Your Changes**: Implement your feature or fix.
    *   Ensure your code adheres to the [Code Standards](#code-standards).
4.  **Test Your Changes**:
    *   Run `shellcheck` on `bin/db_manager.sh` to catch common shell errors.
    *   Perform local testing. See the [Testing](#testing) section for more details.
5.  **Commit Your Changes**: Write clear and concise commit messages. We encourage following [Conventional Commits](https://www.conventionalcommits.org/) for commit message formatting.
    ```bash
    git commit -m "feat: Add support for X feature"
    # or
    git commit -m "fix: Resolve Y bug in Z module"
    ```
6.  **Push to Your Branch**:
    ```bash
    git push origin feature/your-amazing-feature
    ```
7.  **Open a Pull Request (PR)**:
    *   Submit a PR against the `main` branch of the original repository.
    *   Provide a clear title and description for your PR. Explain the "what" and "why" of your changes.
    *   Link to any relevant issues (e.g., "Closes #123").
    *   Ensure your PR passes all automated checks.

## After Submitting a Pull Request

*   **Respond to Feedback**: Project maintainers may ask questions or request changes. Please be responsive to feedback.
*   **Address CI Failures**: If Continuous Integration (CI) checks fail, please investigate and push fixes to your branch.
*   **Patience**: Reviewing PRs takes time. We appreciate your patience.

## Code Standards

*   Follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).
*   Use `shellcheck` (available at [www.shellcheck.net](https://www.shellcheck.net/)) to lint your shell scripts.
*   Write clear and explanatory comments for complex logic or non-obvious functionalities.
*   Strive for compatibility with `bash` (version 4.0+) and common POSIX `sh` features where feasible, but `bash` is the primary target.
*   **New features or bug fixes must include corresponding tests** or updates to existing tests.

## Testing

Thorough testing is crucial. Please ensure your changes are well-tested:

*   **Local Testing**:
    *   Test your changes in different environments if possible (e.g., different Linux distributions, macOS).
    *   Verify functionality with different versions of PostgreSQL (e.g., 12, 13, 14, 15, 16).
    *   Test with various `.env` file configurations (e.g., all variables set, some variables set, no `.env` file).
    *   Familiarize yourself with and utilize the `tests/test_backup.sh` script for automated checks of core backup and restore functionalities. Modify or extend it as needed for your changes.
*   **ShellCheck**: Always run `shellcheck bin/db_manager.sh` after making changes to the script.

## Documentation

Good documentation is as important as good code.

*   **README.md**: Update `README.md` if you add or change functionalities, command-line options, or environment variables.
*   **Examples**: Add or update usage examples in `docs/examples.md` for new features or significant changes.
*   **Script Help**: If you modify command-line options, ensure the help messages within `bin/db_manager.sh` (e.g., `display_help()` function) are updated accordingly.

## Reporting Issues

If you encounter a bug or have a feature request:

1.  **Search Existing Issues**: Before submitting a new issue, please check if a similar one already exists.
2.  **Use Issue Templates**: If available, use the provided issue templates (bug report, feature request).
3.  **Provide Details**: For bug reports, include:
    *   Clear steps to reproduce the issue.
    *   Expected behavior and actual behavior.
    *   Your environment: Operating System, `bash` version, PostgreSQL version, `db_manager.sh` script version (if applicable).
    *   Any relevant error messages or logs.

## Areas for Contribution (Wishlist)

Looking for ways to contribute? Here are some ideas:

*   **Enhanced Cloud Provider Support**: Add backup/restore capabilities for more cloud storage services (e.g., Azure Blob Storage, Google Cloud Storage).
*   **Improved Logging**: More granular logging options or structured logging (e.g., JSON).
*   **More Test Cases**: Expand `tests/test_backup.sh` with more scenarios.
*   **Performance Optimizations**: For large database backups or restores.
*   **Documentation Improvements**: Clarifications, more examples, translations.
*   **Support for other DBs**: Add support for other databases like MySQL, MariaDB, etc. (This would be a major undertaking).

Thank you for contributing! Your efforts help make this project better for everyone.
