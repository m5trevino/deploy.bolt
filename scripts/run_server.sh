#!/bin/bash
echo -e "[36m[+] Starting Mixtral Server with GPU Acceleration...[0m"
echo -e "[32m[+] Model: /home/flintx/models/Mixtral-8x7B-v0.1-GGUF/Q4_K_M/mixtral-8x7b-v0.1.Q4_K_M.gguf[0m"
echo -e "[32m[+] Context Window: 2048[0m"
echo -e "[32m[+] CPU Threads: 6[0m"
echo -e "[32m[+] GPU Layers: 8[0m"
echo -e "[32m[+] Server will run on 0.0.0.0:8080[0m"
echo ""

export CUDA_VISIBLE_DEVICES=0,1

python3 -m llama_cpp.server \
    --model /home/flintx/models/Mixtral-8x7B-v0.1-GGUF/Q4_K_M/mixtral-8x7b-v0.1.Q4_K_M.gguf \
    --host 0.0.0.0 \
    --port 8080 \
    --n_ctx 2048 \
    --n_threads 6 \
    --n_gpu_layers 8 \
    --use_mlock true \
    --numa false \
    --n_batch 64 \
    --tensor_split 0.35 0.35 \
    --model_alias mixtral \
    --rope_freq_base 10000 \
    --rope_freq_scale 1.0 \
    --mul_mat_q true