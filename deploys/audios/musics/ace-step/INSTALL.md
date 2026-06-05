# 安装

## 快速开始（全平台）

```bash
git clone https://github.com/ACE-Step/ACE-Step-1.5.git
cd ACE-Step-1.5
git checkout df14e88 
uv sync

# 启动 Gradio 网页界面
uv run acestep --port 7861 --language zh  --device cuda --lm_model_path acestep-5Hz-lm-0.6B --download-source modelscope --enable-api --init_service true --batch_size 1 --init_llm false

# 启动 REST API 服务器
uv run acestep-api --port 8001 --download-source modelscope --init-llm false

# 启动 Gradio 网页界面
# ./start_gradio_ui.sh

# 启动 REST API 服务器
# ./start_api_server.sh
```

首次运行时模型会自动下载。打开 http://localhost:7860（Gradio）或 http://localhost:8001（API）。

## 参考

https://github.com/ace-step/ACE-Step-1.5/blob/main/docs/zh/INSTALL.md

## 常见问题

- 报错：“bitsandbytes not installed. Using standard AdamW.”

```bash
uv add bitsandbytes
```

- 报错：“ValueError: Unknown scheme for proxy URL URL('socks://127.0.0.1:1080/')”

```bash
unset no_proxy
unset http_proxy
unset https_proxy
unset all_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
unset ALL_PROXY

./start_gradio_ui.sh
```

- 加速模型下载

```bash
export HF_ENDPOINT="https://hf-mirror.com"
```

- torchcodec 0.11.1 版本冲突问题， 需要降级为 0.11.*

```bash
uv pip list | grep torchcodec
uv pip uninstall --python .venv/bin/python torchcodec
vi pyproject.toml
#原先：  "torchcodec>=0.9.1; platform_machine != 'aarch64'",
#改为：  "torchcodec>=0.9.1,<0.11.0; platform_machine != 'aarch64'",
uv sync
uv pip list | grep torchcodec
```

- ffmpeg 动态库找不到问题
```bash
wget https://ffmpeg.org/releases/ffmpeg-8.0.tar.xz 
tar xf ffmpeg-8.0.tar.xz
cd ffmpeg-8.0
./configure --prefix="/usr/local/ffmpeg8" --enable-shared --disable-static --disable-doc --disable-programs
make -j 64
sudo make install

export LD_LIBRARY_PATH="/usr/local/ffmpeg8/lib:$LD_LIBRARY_PATH"
uv run acestep 
```