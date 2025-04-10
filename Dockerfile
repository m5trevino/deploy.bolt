# START ### BASE IMAGE ###
# Use a CUDA 12.x devel image compatible with your host driver
FROM nvidia/cuda:12.3.2-devel-ubuntu22.04
# FINISH ### BASE IMAGE ###

# START ### ENV VARS ###
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
ENV APP_HOME=/app
# Set HOME for consistency if scripts use Path.home()
ENV HOME=/home/flintx
WORKDIR $APP_HOME
# FINISH ### ENV VARS ###

# START ### SYSTEM DEPENDENCIES ###
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    cmake \
    supervisor \
    && useradd -m -d /home/flintx -s /bin/bash flintx \
    && rm -rf /var/lib/apt/lists/*
# FINISH ### SYSTEM DEPENDENCIES ###

# START ### PYTHON DEPENDENCIES ###
COPY requirements.docker.txt .

# Install Python packages, including compiling llama-cpp-python with CUDA
# Ensure llama-cpp-python is listed in requirements.docker.txt
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir -r requirements.docker.txt && \
    CMAKE_ARGS="-DLLAMA_CUBLAS=on" pip3 install --no-cache-dir --force-reinstall --upgrade --no-binary llama-cpp-python llama-cpp-python && \
    # Clean pip cache again potentially
    rm -rf /root/.cache/pip
# FINISH ### PYTHON DEPENDENCIES ###

# START ### APP CODE ###
COPY . $APP_HOME

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/bolt.conf

# Ensure scripts are executable (run_server.sh will be created by huggingface.py)
RUN chmod +x scripts/*.py manage.sh launch_hf.sh || true # Allow failure if scripts don't exist yet
# Fix permissions for mounted volumes potentially accessed by non-root user later
# RUN chown -R flintx:flintx /home/flintx /app/logs /app/config
# FINISH ### APP CODE ###

# START ### RUN COMMAND ###
# Expose ports used by services
EXPOSE 8080 # llama_cpp.server API
EXPOSE 7860 # Maybe bolt_app UI?
EXPOSE 4040 # Ngrok UI

# Run supervisord
# The -n flag runs it in the foreground, which is required for Docker containers
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
# FINISH ### RUN COMMAND ###
