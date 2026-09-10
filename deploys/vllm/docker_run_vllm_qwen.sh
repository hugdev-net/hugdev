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
  --tensor-parallel-size 1 \
  --max-model-len 65536 \
  --gpu-memory-utilization 0.98 \
  --cpu-offload-gb 4 \
  --enforce-eager \
  --kv-cache-dtype fp8 \
  --max-num-seqs 8 \
  --served-model-name "`basename $MODEL_ID`" \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder \
  --reasoning-parser qwen3

###############################################################################
# 模型目录或模型名称；这里指向容器内挂载的 /model                     --model /model
# Tensor Parallel 并行度；1 表示单 GPU，2 表示两张 GPU 分摊模型     --tensor-parallel-size 1
# 最大上下文长度（token 数）；越大 KV Cache 占用越高                 --max-model-len 65536
# vLLM 可使用的 GPU 显存比例；0.98 表示最多使用约 98% 显存           --gpu-memory-utilization 0.98
# 每张 GPU 最多向 CPU 内存卸载 4GiB 模型权重，用于缓解显存不足         --cpu-offload-gb 4
# 强制使用 Eager 模式，禁用 CUDA Graph；更省部分显存但性能可能略降      --enforce-eager
# KV Cache 使用 FP8，降低 KV Cache 显存占用，适合长上下文            --kv-cache-dtype fp8
# 单次调度最大并发请求/序列数；越大吞吐更高，但显存占用也更高             --max-num-seqs 8
# API 对外暴露的模型名称，取 MODEL_ID 路径最后一级名称                --served-model-name "`basename $MODEL_ID`"
# 开启模型自动判断是否需要调用 Tool/Function                        --enable-auto-tool-choice
# 使用 Qwen3 Coder 格式解析模型输出的 Tool Call                    --tool-call-parser qwen3_coder
# 使用 Qwen3 格式解析 reasoning/thinking 内容                     --reasoning-parser qwen3

###############################################################################
# 其中维护时最需要警惕的是这 5 个参数：

# tensor-parallel-size       ← 跟 GPU 数量直接相关
# max-model-len              ← 对 KV Cache 显存影响很大
# gpu-memory-utilization     ← 太高容易因为额外显存开销 OOM
# cpu-offload-gb             ← 越大越省显存，但 CPU ↔ GPU 传输越多、速度越慢
# max-num-seqs               ← 越大并发越高，同时 KV Cache/显存压力越大

###############################################################################
# 调优关系：

# 显存不够：
#   max-model-len ↓
#   max-num-seqs ↓
#   cpu-offload-gb ↑
#   gpu-memory-utilization ↑（只能小幅提高）
#
# 性能太慢：
#   cpu-offload-gb ↓
#   enforce-eager 去掉
#   max-num-seqs ↑（吞吐场景）