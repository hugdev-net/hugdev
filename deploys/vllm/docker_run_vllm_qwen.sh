#!/usr/bin/env bash

set -x
set -euo pipefail

export MODEL_ID="${1:-Qwen/Qwen3.8-27B}"
export MODEL_ROOT_DIR="/data/models"
export RUN_NAME="${2:-vllm-qwen38-27b}"

docker run --name $RUN_NAME --gpus all \
  -p 18081:8000 \
  -v ${MODEL_ROOT_DIR}/${MODEL_ID}:/model \
  vllm/vllm-openai:latest \
  --model /model \
  --tensor-parallel-size 4 \
  --max-model-len 262144 \
  --served-model-name "`basename $MODEL_ID`" \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder \
  --reasoning-parser qwen3