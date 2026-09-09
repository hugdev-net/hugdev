#!/usr/bin/env bash

set -euo pipefail

#https://www.modelscope.cn/
export MODEL_ID="${1:-Qwen/Qwen3.8-27B}"

export MODEL_ROOT_DIR="/data/models"

# pip install -U modelscope-hub

mkdir -p "$MODEL_ROOT_DIR/$MODEL_ID"

ms-hub download "$MODEL_ID" --local-dir "$MODEL_ROOT_DIR/$MODEL_ID"