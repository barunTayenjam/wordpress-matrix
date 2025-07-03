# Project Improvement Plan

This file outlines the planned improvements to enhance the developer experience of the WordPress development environment.

## High-Impact Features

- [ ] **Integrated Step-Debugging with XDebug**
  - **Goal**: Add and configure XDebug to allow for step-debugging from a code editor like VS Code.
  - **Tasks**:
    - Add the XDebug extension to the WordPress Docker containers.
    - Configure XDebug to connect to an IDE.
    - Update the `README.md` with instructions on how to set up VS Code for debugging.

- [ ] **Built-in Code Quality Tools**
  - **Goal**: Re-integrate `PHPStan` (static analysis) and `PHPCS` (coding standards) to enforce code quality.
  - **Tasks**:
    - Add `phpstan` and `phpcs` services back to the `docker-compose.yml`.
    - Create simple commands in `manage.sh` (e.g., `lint`, `analyse`) to run the tools.

## Medium-Impact Features

- [ ] **Streamlined Dependency Management**
  - **Goal**: Simplify the management of PHP and Node.js dependencies.
  - **Tasks**:
    - Add dedicated `composer` and `node` services to `docker-compose.yml`.
    - Integrate `composer` and `npm`/`yarn` commands into `manage.sh`.

- [ ] **Simplified Database Backups & Restoration**
  - **Goal**: Create a simple, one-command way to back up and restore the database.
  - **Tasks**:
    - Add `backup` and `restore` commands to the `manage.sh` script.
    - Implement the logic to create and restore database snapshots.

## Low-Impact Features & Best Practices

- [ ] **Environment Configuration Template**
  - **Goal**: Make it easier for new developers to configure their environment.
  - **Tasks**:
    - Create an `.env.example` file that documents all the required environment variables.
