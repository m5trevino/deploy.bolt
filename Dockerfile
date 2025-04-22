# Use the official NVIDIA CUDA development image matching the toolkit version
FROM nvidia/cuda:12.2.2-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC LANG=C.UTF-8 PYTHONUNBUFFERED=1

# Install dependencies + compat package + CUDA DEV LIBRARIES
RUN apt-get update && apt-get install -y --no-install-recommends \
    git cmake build-essential python3.10 python3-pip python3-venv sudo terminator \
    cuda-compat-12-2 \
    cuda-libraries-dev-12-2 \
    libcublas-dev-12-2 \
    libcufft-dev-12-2 \
    libcurand-dev-12-2 \
    libcusolver-dev-12-2 \
    libcusparse-dev-12-2 \
    # Add findutils to get the 'find' command
    findutils \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig

# Verify nvcc
RUN nvcc --version

# Set CUDA Env Vars (including stubs path)
ENV CUDA_HOME=/usr/local/cuda-12.2
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${CUDA_HOME}/lib64/stubs:${LD_LIBRARY_PATH}

# Keep LDFLAGS pointing to the specific toolkit version's stubs/libs
ENV LDFLAGS="-L${CUDA_HOME}/lib64/stubs -L${CUDA_HOME}/lib64 -Wl,-rpath,${CUDA_HOME}/lib64/stubs -Wl,-rpath,${CUDA_HOME}/lib64"

# --- HACK: Find and copy libcuda.so.1 to a standard linker path ---
# This assumes the nvidia container runtime makes the driver libs available *somewhere* during build
# It might be in /usr/lib/x86_64-linux-gnu or elsewhere depending on driver install method on host/runtime setup
RUN find / -name 'libcuda.so.1' -exec cp {} /usr/local/lib/ \; || echo "Warning: libcuda.so.1 not found during build, linking might still fail."
# Re-run ldconfig AFTER potentially copying the library
RUN ldconfig
# --- End Hack ---

# Upgrade pip tools
RUN python3 -m pip install --upgrade pip setuptools wheel packaging

# Set CMAKE_ARGS (Keep all flags)
ENV CMAKE_ARGS="-DGGML_CUDA=on -DLLAMA_MLIR=on -DLLAMA_BUILD_EXAMPLES=OFF"
ENV FORCE_CMAKE=1

# Create user flintx
RUN useradd -m -s /bin/bash flintx && \
    echo "flintx ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/flintx && \
    chmod 0440 /etc/sudoers.d/flintx

# Add local bin path
ENV PATH="/home/flintx/.local/bin:${PATH}"

# Switch user
USER flintx
WORKDIR /home/flintx

# Copy requirements
COPY --chown=flintx:flintx requirements.docker.txt .

# Install Python requirements (Build llama-cpp-python here)
RUN pip3 install --user --no-cache-dir -r requirements.docker.txt

# Copy app code
COPY --chown=flintx:flintx . .

# Keep container running indefinitely (useful for exec)
CMD ["tail", "-f", "/dev/null"]