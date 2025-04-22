# ⚡️ deploy.bolt

**Custom LLM Deployment System - Prepare and Run Your AI Models**

This project provides a framework for easily setting up and running a local LLM server (using llama.cpp) integrated with a Bolt.diy web application interface. It supports a dual-mode approach: an interactive setup on your host machine to prepare necessary files and dependencies, and a headless Docker service for running the final application stack in an isolated environment.

---

## 🗺️ Operational Modes

This system operates in two distinct modes designed to work together:

### Mode 1: Interactive Host Setup (The Launcher)

This mode is focused on the user-friendly installation and initial configuration process. You run scripts directly on your Linux desktop environment.

*   **Purpose:** To guide the user through installing host-level dependencies (like Node.js, pnpm, Ngrok if needed), collecting necessary API keys/tokens, selecting and downloading the LLM model, and patching the Bolt.diy codebase to work with the local setup.
*   **Key Scripts:** `run.py` (main menu launcher), `scratch/install_bolt_and_ngrok.sh` (installs host deps), `tokens.py` (interactive token collection), `huggingface.py` (interactive/env-driven model setup, generates server script), `scripts/final_validation.py` (patches Bolt.diy config files).
*   **Environment:** Requires a graphical Linux desktop (like XFce) with a terminal emulator (xfce4-terminal, Terminator), Python 3+, Git, Sudo access, Node.js, npm, pnpm, Ngrok executable (if not using a Dockerized Ngrok), and necessary Python libraries (`requirements.txt`).
*   **Outcome:** Prepares all application files (downloaded model, generated configs, patched Bolt.diy code, token files, `.env`) on your host machine in specific directories (`/home/flintx/models`, `~/deploy.bolt`, `~/.local/share`).

### Mode 2: Headless Docker Service (The Runner)

This mode is focused on running the final configured application stack (LLM server, Bolt.diy app process, Ngrok tunnel, Monitor) as persistent background services in an isolated Docker container.

*   **Purpose:** To provide a consistent, portable environment for the application services, isolating their runtime dependencies from the host system and managing their lifecycle automatically.
*   **Key Components:** `docker-compose.yml`, `Dockerfile`, `entrypoint.sh`, `supervisord.conf`, and the service launch scripts (`scripts/run_server.sh`, `scripts/run_bolt.py`, `scripts/run_ngrok.py`, `scripts/run_monitor.py`).
*   **Environment:** Requires Docker Engine, Docker Compose (V2+), and the NVIDIA Container Toolkit/Driver installed on the host machine. Does NOT require Node.js, pnpm, graphical terminals, or Python libraries installed directly on the host (beyond Docker/NVIDIA drivers).
*   **Outcome:** Builds a Docker image with all runtime dependencies (CUDA, llama-cpp-python, supervisor) and copies the prepared files from Mode 1. Runs a container where `supervisord` launches and manages the application services using the prepared files and mounted volumes for models/data. Services run headless, with output going to logs.

---

## 🚀 Quick Start

Deploying the full stack involves completing the Interactive Host Setup (Mode 1) once to prepare the necessary files, then using the Headless Docker Service (Mode 2) to build and run the containerized application.

### Step 1: Interactive Host Setup (Prepare Files)

Run these steps on your Linux desktop machine.

1.  **Navigate to the project directory:**
    ```bash
    cd ~/deploy.bolt
    ```
2.  **Run the main launcher script:**
    ```bash
    python3 run.py
    ```
3.  **Select Option 1: "Fresh Install"** and follow the prompts. This will:
    *   Launch installation scripts (`scratch/install_bolt_and_ngrok.sh`, etc.) in new terminal windows to install necessary host dependencies (Node.js, pnpm, Ngrok - ensure you grant sudo when prompted).
    *   Launch `tokens.py` in a new terminal to collect your Ngrok and Hugging Face API tokens interactively.
    *   Launch `huggingface.py` in a new terminal to guide you through selecting/downloading an LLM model (based on env vars in `.env` or prompts) and generating the server launch script (`scripts/run_server.sh`).
    *   Launch `scripts/final_validation.py` (or similar) in a new terminal to patch the Bolt.diy code (`bolt.diy` subdirectory) with the local provider definition and update configs.

    *Note: Keep an eye on each terminal window launched by `run.py` to follow progress and respond to prompts.*

4.  **Verify Prepared Files:** After the setup flow completes, confirm key files/directories exist on your host:
    *   Model file: `/home/flintx/models/<your_model>/<quant>/<model_file>.gguf`
    *   Server script: `~/deploy.bolt/scripts/run_server.sh`
    *   Supervisor config: `~/deploy.bolt/supervisord.conf` (should define programs)
    *   Bolt.diy code: `~/deploy.bolt/bolt.diy/` (should be cloned and patched)
    *   Token files: `~/deploy.bolt/tokens/` and `~/deploy.bolt/.env` (should contain tokens/config)

### Step 2: Launch Headless Docker Services (Run Application)

Once the setup (Step 1) is complete and necessary files are prepared on your host, you can build and run the containerized application stack.

1.  **Navigate back to the project directory:**
    ```bash
    cd ~/deploy.bolt
    ```
2.  **Build the Docker image and launch services:** Use Docker Compose with explicit path/file flags for reliability. The `--build` flag ensures the image is up-to-date with your local files, and `--force-recreate` ensures a fresh container start.
    ```bash
    docker compose --project-directory . -f docker-compose.yml up --build --force-recreate
    ```
3.  **Monitor Startup:** Watch the output in your terminal. You should see Docker build the image (likely fast if layers are cached), create the container, and then see logs from the `entrypoint.sh` script running its checks, followed by `supervisord` starting the defined programs (llama_server, bolt_app, ngrok, monitor).
4.  **Access Application:** Once services are running (check logs for server/app startup messages), you should be able to access:
    *   LLM Server API: `http://localhost:8080`
    *   Bolt.diy Web UI: `http://localhost:7860`
    *   Ngrok UI: `http://localhost:4040`
    *   Ngrok Public URL: Check the ngrok logs for the public `*.ngrok-free.app` URL.

5.  **Stopping Services:** To stop the running containers:
    ```bash
    docker compose --project-directory . -f docker-compose.yml down
    ```

---

## 📁 Structure

    

IGNORE_WHEN_COPYING_START
Use code with caution. Bash
IGNORE_WHEN_COPYING_END

.
├── ascii/ # ASCII art used by interactive scripts
├── config/ # Configuration files (generated/templates)
├── core.py # Core utility functions?
├── create_tag_database.sh # Script for tag database?
├── cuda_tags_database.json # Data file
├── docker-compose.yml # Docker Compose definition for services
├── Dockerfile # Docker build recipe for the main container
├── Dockerfile.dev # Development Dockerfile variant?
├── .env # Environment variables for Docker Compose/scripts (DO NOT COMMIT)
├── entrypoint.sh # Container startup script for Docker
├── huggingface.py # Interactive/Env-driven LLM setup & script generator
├── launch_hf.sh # Script generated by tokens.py to launch huggingface.py
├── launch.py # Part of interactive launcher flow?
├── manage.sh # Management script?
├── model_config.json # Model configuration template/default
├── new_handler.py # New handler logic?
├── README.md # This file
├── requirements.docker.txt # Python dependencies for the Docker image
├── requirements.txt # Python dependencies for host scripts?
├── run_bolt.py # Script to launch Bolt.diy application service
├── run.py # Main interactive desktop launcher script
├── scratch/ # Scripts for initial setup (Host Mode 1)
│   └── install_bolt_and_ngrok.sh # Installs Bolt.diy and Ngrok on host
├── scratch.py # Setup script part?
├── scripts/ # Service launch and validation scripts
│   ├── final_validation.py # Patches Bolt.diy config after setup
│   ├── run_bolt.py # Launches Bolt.diy app service
│   ├── run_monitor.py # Launches Monitor service
│   ├── run_ngrok.py # Launches Ngrok service
│   ├── run_server.sh # Launches LLM FastAPI server service (Generated by huggingface.py)
│   └── validate.py # Validation script?
├── supervisord.conf # Config for supervisord process manager in Docker
├── terminator_config/ # Terminator terminal profile configs (User specific, can be ignored)
├── tokens/ # Stores API tokens (DO NOT COMMIT)
└── tokens.py # Interactive script for collecting tokens

      
---

## 🔥 Features

*   Dual-mode deployment: Interactive setup on desktop host, automated runner in Docker.
*   Isolated runtime environment for services using Docker.
*   Automated LLM server setup and configuration based on environment variables/defaults.
*   Integration with Bolt.diy web application interface.
*   Process management for services using Supervisord.
*   Ngrok tunneling support.
*   System resource monitoring (via run_monitor.py).
*   Support for GGUF format models.
*   Optimized configuration parameters for Quadro P2000 GPUs (default).

---

## 💾 Model Storage

LLM model files (`.gguf`, etc.) are downloaded during the Interactive Host Setup (Mode 1) to `/home/flintx/models` on your host machine. This directory is mounted as a volume into the Docker container (`/home/flintx/models`) so the LLM server running inside the container can access the large model files without storing them within the image itself.

---

## 🔧 Configuration

*   Environment variables for the Docker services are loaded from the `.env` file in the project root (`~/deploy.bolt/.env`). This is where you configure Hugging Face tokens, Ngrok tokens, default model name, etc. (Refer to `env.example` if present).
*   The `huggingface.py` script generates the `scripts/run_server.sh` file based on detected/configured parameters, which contains the exact command used to launch the llama_cpp.server process.
*   The `scripts/final_validation.py` script patches specific files within the `bolt.diy` subdirectory (`app/lib/modules/llm/providers/mixtral-local.ts`, `app/lib/modules/llm/registry.ts`, `vite.config.ts`, `.env.local`) to integrate the local LLM server into the Bolt.diy web UI.
*   Service management and logging are configured in `supervisord.conf`.

---

## 🛠️ Requirements

**For Interactive Host Setup (Mode 1):**

*   A Linux desktop environment (like MX Linux with XFce)
*   Terminal emulator (xfce4-terminal, Terminator)
*   Python 3.8+ and libraries from `requirements.txt`
*   Git
*   Sudo access
*   Node.js and npm
*   pnpm (`curl -fsSL https://get.pnpm.io/install.sh | sh -`)
*   Ngrok executable (if not using a Dockerized version later)

**For Headless Docker Service (Mode 2):**

*   Docker Engine installed and running
*   Docker Compose (V2+)
*   NVIDIA Driver for your GPUs
*   NVIDIA Container Toolkit (`sudo apt-get install -y nvidia-container-toolkit`)

---

## 🤝 Contributing

If you want to contribute, fork the repo and submit a pull request. Check the issues for needed features or report bugs.

---

## 📜 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## 🙏 Credits

Built with 🔥 for the streets, powered by:

*   bolt.diy
*   llama.cpp / llama-cpp-python
*   huggingface_hub
*   Ngrok
*   Docker
*   NVIDIA CUDA
*   Rich library

Built with 🔥 by @m5trevino

