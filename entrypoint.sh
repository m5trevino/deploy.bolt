#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "[Entrypoint] Running pre-flight checks and setup via huggingface.py..."
# Run the setup script - it will download model if needed & create run_server.sh
python3 /app/huggingface.py

# Check if run_server.sh was created successfully
if [ ! -f "/app/scripts/run_server.sh" ]; then
    echo "[Entrypoint] Error: /app/scripts/run_server.sh not found after running setup!"
    exit 1
fi

# Ensure run_server.sh is executable (huggingface.py should do this, but double-check)
chmod +x /app/scripts/run_server.sh

echo "[Entrypoint] Setup complete. Handing over to Supervisor..."
# Execute supervisord using the configuration file
# The '-n' flag runs it in the foreground, which is required for Docker CMD/ENTRYPOINT
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

