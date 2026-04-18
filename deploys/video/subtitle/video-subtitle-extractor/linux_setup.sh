#!/usr/bin/env bash

sudo apt install ccache

git clone https://github.com/YaoFANGUK/video-subtitle-extractor
cd video-subtitle-extractor || exit 1

uv venv --python 3.12
source .venv/bin/activate
which python
python -m pip install --upgrade --force-reinstall pip
which pip

uv pip install paddlepaddle-gpu==3.3.1 paddle2onnx==1.3.1 -i https://www.paddlepaddle.org.cn/packages/stable/cu129/
uv pip install onnxruntime-gpu==1.24.4 -i https://mirrors.aliyun.com/pypi/simple/
uv pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/

# 运行图形化界面版本（GUI）
# python gui.py

# 运行命令行版本（CLI）
# python ./backend/main.py