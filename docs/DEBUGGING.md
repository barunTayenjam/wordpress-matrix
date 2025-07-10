# Debugging with XDebug and VS Code

This guide explains how to set up XDebug for step-debugging your WordPress environment using VS Code.

## Prerequisites

*   **VS Code**: Make sure you have Visual Studio Code installed.
*   **PHP Debug Extension**: Install the "PHP Debug" extension by Xdebug in VS Code.

## VS Code Configuration

1.  Open your project in VS Code.
2.  Go to the Run and Debug view (Ctrl+Shift+D or Cmd+Shift+D).
3.  Click on "create a launch.json file" (if you don't have one). Select "PHP".
4.  Your `launch.json` file should look something like this:

    ```json
    {
        "version": "0.2.0",
        "configurations": [
            {
                "name": "Listen for XDebug",
                "type": "php",
                "request": "launch",
                "port": 9003
            },
            {
                "name": "Launch currently open script",
                "type": "php",
                "request": "launch",
                "program": "${file}",
                "cwd": "${workspaceRoot}",
                "port": 9003
            }
        ]
    }
    ```

    Ensure the `port` is set to `9003`, which matches the `xdebug.client_port` in `config/php/php.ini`.

## How to Debug

1.  Start your Docker environment: `./scripts/manage.sh start`
2.  In VS Code, go to the Run and Debug view.
3.  Select the "Listen for XDebug" configuration from the dropdown.
4.  Click the green play button to start listening for incoming XDebug connections.
5.  Set breakpoints in your PHP code.
6.  Access your WordPress site in your web browser. XDebug should connect, and execution will pause at your breakpoints.

## Troubleshooting

*   **XDebug not connecting**:
    *   Ensure your Docker containers are running.
    *   Verify that `xdebug.client_host` is `host.docker.internal` in `config/php/php.ini`.
    *   Check that the port in `launch.json` (9003) matches `xdebug.client_port` in `php.ini`.
    *   Look at the XDebug log file: `/var/log/php/xdebug.log` inside the WordPress container. You can access it using `docker-compose exec xandar tail -f /var/log/php/xdebug.log`.
*   **Performance issues**: XDebug can impact performance. Remember to disable it when not actively debugging by commenting out or removing the `xdebug.mode` line in `config/php/php.ini` and restarting your containers.
