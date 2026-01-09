系统依赖

```bash
sudo apt update
sudo apt install -y \
  pkg-config \
  git ffmpeg sox unzip \
  libavcodec-dev \
  libavformat-dev \
  libavdevice-dev \
  libavutil-dev \
  libavfilter-dev \
  libswscale-dev \
  libswresample-dev
```

1️⃣ 确认 uv 已安装（如果没装）

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
uv --version
```

2️⃣ 用 uv 安装 Python 3.10; 创建并生效 venv

```bash
uv python install 3.10

source .venv/bin/activate
python --version
```

3️⃣ 在 venv 中安装相关常用包 包括： Cython < 3（关键）

```bash
uv pip install "Cython<3"
uv pip install setuptools wheel huggingface_hub
```

验证（这次一定要能 import）：

```bash
uv run python - <<'PY'
import Cython
print("Cython version:", Cython.__version__)
PY
```

你应该看到类似：
Cython version: 0.29.36
✅ 这是正确状态

4️⃣ 安装 PyTorch（关键：选 cu121）

```bash
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

验证 GPU：

```bash
uv run python - <<'PY'
import torch
print("torch:", torch.__version__)
print("cuda available:", torch.cuda.is_available())
print("gpu:", torch.cuda.get_device_name(0))
print("compiled cuda:", torch.version.cuda)
PY
```

5️⃣ 安装 OpenVoice（uv 方式）

```bash
cd /opt/openvoice
git clone https://github.com/myshell-ai/OpenVoice.git
cd OpenVoice
uv pip install -e . --no-build-isolation
```

6️⃣ 安装 必需组件（非常重要）

```bash
uv pip install git+https://github.com/myshell-ai/MeloTTS.git
uv run python -m unidic download
```

7️⃣ 下载 OpenVoice checkpoints

```bash
cd /opt/openvoice/OpenVoice
mkdir -p checkpoints

huggingface-cli download myshell-ai/OpenVoice --include "checkpoints/base_speakers/**" --local-dir .
huggingface-cli download myshell-ai/OpenVoice --include "checkpoints/converter/**" --local-dir .
```

8️⃣ 启动你的 TTS API（FastAPI 示例）

```bash
uv pip install fastapi uvicorn soundfile pydantic
uv run uvicorn server.app:app --host 0.0.0.0 --port 25123
```


🧪 验证
```bash
uv run python - <<'PY'
import av
print("PyAV:", av.__version__)
from openvoice.api import BaseSpeakerTTS, ToneColorConverter
print("OpenVoice OK")
PY
```

显示：
PyAV: 10.0.0
OpenVoice OK
✅ 说明 openvoice V1包安装 已经完成


```bash
uv run python - <<'PY'
from server.engine import OpenVoiceEngine
engine = OpenVoiceEngine()
print("V1 engine init OK")
PY
```

显示：
V1 engine init OK
✅ 说明 openvoice V1 模型加载已经完成


测试

```bash 
curl -X POST http://localhost:25123/speaker/register -F "file=@narrator.mp3"


curl -X POST http://localhost:25123/tts -H "Content-Type: application/json" \
  -d '{
    "text": "他跪拜再三，记下“此后多行善事，不可作恶”的嘱托，最终孤身坐下。带着七十二变和筋斗云下山的，不只是本领，还有一种被世界推开的孤独——那将驱动他去问，何为真正的自由。",
    "speaker_id": "spk_22aaa5a1"
  }' \
  --output out.wav
  
```
