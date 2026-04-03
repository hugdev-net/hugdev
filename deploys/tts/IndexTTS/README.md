# 安装部署 IndexTTS2

- 参考 https://github.com/index-tts/index-tts/blob/main/docs/README_zh.md

## 基础环境

- 安装 lfs

```bash
git lfs install
```

- 安装 uv

```bash
pip install -U uv 
```

## 部署

```bash
#克隆项目
git clone https://github.com/index-tts/index-tts.git && cd index-tts
git lfs pull  # download large repository files

# 安装依赖
uv sync --all-extras
# uv sync --all-extras --default-index "https://mirrors.aliyun.com/pypi/simple"
# uv sync --all-extras --default-index "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"

# 下载模型
uv tool install "modelscope"
modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints

# 检测 GPU
uv run tools/gpu_check.py
```

- 注意
    - Windows注意： DeepSpeed在部分Windows环境较难安装，可去除--all-extras。
    - Linux/Windows注意： 如遇CUDA相关报错，请确保已安装NVIDIA CUDA Toolkit 12.8及以上。

## 启动

```bash
export HF_ENDPOINT="https://hf-mirror.com"
uv run webui.py
```
- 浏览器访问 http://127.0.0.1:7860 查看演示。

