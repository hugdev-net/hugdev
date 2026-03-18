# FunASR离线文件转写服务GPU版本开发指南

## 镜像启动

```bash
docker pull registry.cn-hangzhou.aliyuncs.com/funasr_repo/funasr:funasr-runtime-sdk-gpu-0.2.1

mkdir -p ~/.cache/funasr/models

docker run --name funasr_gpu --gpus=all -p 10095:10095 -it --privileged=true \
  -v ~/.cache/funasr/models:/workspace/models \
  -v ~/.funasr/data:/workspace/data \
  registry.cn-hangzhou.aliyuncs.com/funasr_repo/funasr:funasr-runtime-sdk-gpu-0.2.1
```

## 服务端启动

```bash
apt install -y ffmpeg
cd FunASR/runtime
nohup bash run_server.sh \
  --certfile 0 \
  --download-model-dir /workspace/models \
  --vad-dir iic/speech_fsmn_vad_zh-cn-16k-common-onnx \
  --model-dir iic/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-pytorch  \
  --punc-dir iic/punc_ct-transformer_cn-en-common-vocab471067-large-onnx \
  --lm-dir iic/speech_ngram_lm_zh-cn-ai-wesp-fst \
  --itn-dir thuduj12/fst_itn_zh \
  --hotword /workspace/models/hotwords.txt > log.txt 2>&1 &

# 服务首次启动时会导出torchscript模型，耗时较长，请耐心等待
# 如果您想关闭ssl，增加参数：--certfile 0
# 默认加载时间戳模型，如果您想使用nn热词模型进行部署，请设置--model-dir为对应模型：
#   iic/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-pytorch（时间戳）
#   iic/speech_paraformer-large-contextual_asr_nat-zh-cn-16k-common-vocab8404（nn热词）
# 如果您想在服务端加载热词，请在宿主机文件./funasr-runtime-resources/models/hotwords.txt配置热词（docker映射地址为/workspace/models/hotwords.txt）:
#   每行一个热词，格式(热词 权重)：阿里巴巴 20（注：热词理论上无限制，但为了兼顾性能和效果，建议热词长度不超过10，个数不超过1k，权重1~100）

```

## 客户端测试与使用

- 下载客户端测试工具目录samples

```bash
wget https://isv-data.oss-cn-hangzhou.aliyuncs.com/ics/MaaS/ASR/sample/funasr_samples.tar.gz
pip install websockets
```

- Python语言客户端为例

```bash
python3 funasr_wss_client.py --host "127.0.0.1" --port 10095 --ssl 0 --mode offline --audio_in "../audio/asr_example.wav"
```

- 常见问题
    - “Exception: sent 1009 (message too big); no close frame received”

```text
      解决方案，修改官方websocket client代码，在websockets.connect加上参数max_size = None
      我推测的原因是，当服务端ASR结束后会将文本一次性通过websocket返回，当音频很长（文本很多）的时候
      （实测在1个半小时不停讲话的情况下，返回的结果文本有1.5MB），
      返回的内容会超过python的websockets库官方给出的单条消息默认限制大小，将这个值改为None就解决了。
```
