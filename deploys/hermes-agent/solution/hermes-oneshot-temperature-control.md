# Hermes oneshot 模式 temperature 控制结论

日期：2026-07-30

## 结论

当前版本中，`hermes --oneshot`（简写 `hermes -z`）没有公开的 `--temperature` 参数，也没有可供主 Agent 使用的标准 `config.yaml` temperature 配置项。

因此，在不做二次开发的情况下，无法为一次 oneshot 调用显式指定 temperature。若业务必须控制该值，需要修改代码，或者绕过 oneshot CLI，直接通过 Python 创建 `AIAgent` 并传入请求覆盖参数。

下面的命令当前不受支持：

```powershell
hermes --oneshot "你好" --temperature 0.2
```

## 代码依据

### 1. oneshot 没有 temperature 命令行参数

`hermes_cli/_parser.py` 为 oneshot 暴露了以下主要参数：

- `-z` / `--oneshot`
- `-m` / `--model`
- `--provider`
- `-t` / `--toolsets`

其中没有 `--temperature`。

### 2. oneshot 创建 Agent 时没有传递 temperature

`hermes_cli/oneshot.py` 中的调用链是：

```text
run_oneshot()
  -> _run_agent()
  -> AIAgent(...)
  -> agent.chat(prompt)
```

`_run_agent()` 创建 `AIAgent` 时传递了模型、provider、toolsets、fallback model 等参数，但没有传递 temperature，也没有传递包含 temperature 的 `request_overrides`。

### 3. 底层具备传递 temperature 的能力

`AIAgent` 构造函数支持：

```python
request_overrides: Dict[str, Any] = None
```

`agent/transports/chat_completions.py` 在构造模型请求时会读取调用方提供的 temperature，并且会把 `request_overrides` 合并到最终 API 请求参数中。

所以限制不在模型传输层，而在 oneshot CLI 没有暴露和传递该设置。

## 可行方案

### 方案一：为 oneshot 增加参数

推荐增加以下调用方式：

```powershell
hermes --oneshot "你好" --temperature 0.2
```

下面给出与当前源码结构对应的最小修改示例。

#### 第一步：增加 CLI 参数

修改 `hermes_cli/_parser.py`，在 `--provider`、`--toolsets` 等 oneshot
顶层参数附近增加：

```python
parser.add_argument(
    "--temperature",
    type=float,
    default=None,
    help=(
        "Sampling temperature for this invocation. "
        "Applies to -z/--oneshot."
    ),
)
```

这里必须使用 `default=None`，以便区分：

- 用户没有指定：不向模型请求添加 temperature，继续使用 provider 默认值。
- 用户明确指定 `0`：传递 `temperature=0.0`。

不要使用 `if temperature:` 判断，因为 `0.0` 是合法值，但在 Python 中
会被判断为 false。

#### 第二步：从 main.py 传入 run_oneshot()

`hermes_cli/main.py` 当前有两处 oneshot 分发路径，两处都要修改：

```python
sys.exit(
    run_oneshot(
        args.oneshot,
        model=getattr(args, "model", None),
        provider=getattr(args, "provider", None),
        toolsets=getattr(args, "toolsets", None),
        temperature=getattr(args, "temperature", None),
    )
)
```

两处位置分别是：

- oneshot/chat 快速启动路径。
- 完整 CLI 分发路径。

如果只改其中一处，不同启动参数组合可能出现行为不一致。

#### 第三步：修改 run_oneshot()

修改 `hermes_cli/oneshot.py`：

```python
def run_oneshot(
    prompt: str,
    model: Optional[str] = None,
    provider: Optional[str] = None,
    toolsets: object = None,
    temperature: Optional[float] = None,
) -> int:
```

在调用 `_run_agent()` 时继续传递：

```python
response = _run_agent(
    prompt,
    model=model,
    provider=provider,
    toolsets=explicit_toolsets,
    use_config_toolsets=use_config_toolsets,
    temperature=temperature,
)
```

#### 第四步：修改 _run_agent()

同样在 `hermes_cli/oneshot.py` 中修改：

```python
def _run_agent(
    prompt: str,
    model: Optional[str] = None,
    provider: Optional[str] = None,
    toolsets: object = None,
    use_config_toolsets: bool = True,
    temperature: Optional[float] = None,
) -> str:
```

创建 `AIAgent` 前构造请求覆盖参数：

```python
request_overrides = None
if temperature is not None:
    request_overrides = {"temperature": temperature}
```

然后传给 `AIAgent`：

```python
agent = AIAgent(
    api_key=runtime.get("api_key"),
    base_url=runtime.get("base_url"),
    provider=runtime.get("provider"),
    api_mode=runtime.get("api_mode"),
    model=effective_model,
    enabled_toolsets=toolsets_list,
    quiet_mode=True,
    platform="cli",
    session_db=session_db,
    credential_pool=runtime.get("credential_pool"),
    fallback_model=_fb or None,
    request_overrides=request_overrides,
    clarify_callback=_oneshot_clarify_callback,
)
```

示例只展示新增部分与必要上下文；原有参数应保留。

#### 第五步：同步顶层参数识别

`hermes_cli/main.py` 的 `_TOP_LEVEL_VALUE_FLAGS` 用于快速识别带值的顶层参数。
应加入：

```python
_TOP_LEVEL_VALUE_FLAGS = frozenset(
    {
        # 原有参数……
        "--temperature",
    }
)
```

实际代码中不要重新定义该常量，只在现有集合中追加
`"--temperature"`。否则类似下面的调用可能在快速分发阶段错误地把
`0.2` 当成位置参数：

```powershell
hermes --temperature 0.2 --oneshot "你好"
```

#### 第六步：增加测试

可以在 `tests/hermes_cli/test_tui_resume_flow.py` 中扩展现有
`test_main_top_level_oneshot_accepts_toolsets`，验证 CLI 参数被正确传递：

```python
monkeypatch.setattr(
    sys,
    "argv",
    [
        "hermes",
        "-z",
        "hello",
        "--toolsets",
        "web,terminal",
        "--temperature",
        "0.2",
    ],
)

# 其余 mock 沿用现有测试

assert captured == {
    "prompt": "hello",
    "model": None,
    "provider": None,
    "toolsets": "web,terminal",
    "temperature": 0.2,
}
```

再增加一个 `_run_agent()` 层测试，确认最终传入 `AIAgent`：

```python
def test_oneshot_passes_temperature_to_agent(monkeypatch):
    # 可复用 test_oneshot_wires_session_db_for_recall 中的 FakeAgent
    # 以及 provider/config 模块 mock。
    captured = {}

    class FakeAgent:
        def __init__(self, **kwargs):
            captured.update(kwargs)
            self.suppress_status_output = False
            self.stream_delta_callback = object()
            self.tool_gen_callback = object()

        def chat(self, prompt):
            return "ok"

    # 安装与现有 oneshot 测试相同的模块 mock 后：
    assert _run_agent("hello", temperature=0.0) == "ok"
    assert captured["request_overrides"] == {"temperature": 0.0}
```

这个测试特意使用 `0.0`，可以防止后续代码错误地用 truthy 判断而丢失零值。

#### 可选：增加参数范围校验

不同 provider 对 temperature 的接受范围并不完全一致。若只支持项目当前
常见的 OpenAI-compatible 语义，可以在 `run_oneshot()` 开始处加入：

```python
import math

if temperature is not None and (
    not math.isfinite(temperature) or not 0.0 <= temperature <= 2.0
):
    sys.stderr.write(
        "hermes -z: --temperature must be a finite number between 0 and 2.\n"
    )
    return 2
```

如果需要兼容范围不同的 provider，则只检查 `math.isfinite()`，具体范围交给
provider 返回错误，不要在 Hermes 中写死统一范围。

#### 修改后的使用示例

```powershell
# 更稳定、确定的输出
hermes --oneshot "提取下面文本中的订单号" --temperature 0

# 保留一定随机性
hermes --oneshot "给出三个标题方案" --temperature 0.7

# 不传参数时继续使用模型服务默认值
hermes --oneshot "总结这段内容"
```

## 更稳妥的实现注意

上面的 `request_overrides` 方案改动最小，但它属于“最终请求字段覆盖”：
`agent/transports/chat_completions.py` 会在 provider profile 的 temperature
处理之后合并它。因此，它可能覆盖某些 provider/model 原本要求固定或省略
temperature 的规则。

若准备把功能贡献回上游，建议不要把 `request_overrides` 当作最终设计，
而是给 `AIAgent` 增加一个正式的 `temperature: Optional[float]` 参数，并沿
主模型请求构造链传递。最终由 transport 按以下优先级处理：

```text
模型要求完全省略 temperature
    > 模型固定 temperature
    > 用户显式 temperature
    > provider 默认值
```

这样可以保持 Kimi/Moonshot、Claude thinking 等现有兼容规则不被 CLI
参数绕过。最小补丁适合内部快速使用；正式上游实现应优先采用这一语义。

### 方案二：直接使用 Python API

如果不要求使用 `hermes --oneshot` 命令，可以直接创建 Agent：

```python
from run_agent import AIAgent

agent = AIAgent(
    model="your-model",
    provider="your-provider",
    request_overrides={"temperature": 0.2},
)

print(agent.chat("你好"))
```

这仍属于代码调用，不是现有 oneshot CLI 的配置能力。

## 注意事项

- `auxiliary.*.extra_body` 控制的是压缩、视觉、网页提取等辅助模型调用，不是 oneshot 主 Agent 的 temperature。
- 不建议自行增加新的 `HERMES_*` 环境变量。按照项目约定，非密钥行为配置应放入 `config.yaml`；如果需要长期配置，应设计正式的配置项并由 CLI 读取。
- 部分模型不允许客户端自由设置 temperature。例如 Kimi/Moonshot 的部分模型由服务端管理该值，某些 Claude thinking 模型也有固定或受限的采样参数。即使增加 CLI 参数，也应保留现有 provider/model 兼容处理。

## 最终判断

```text
现有 hermes --oneshot
    └─ 无 --temperature 参数
    └─ 无主模型 temperature 配置项
    └─ 无法在不改代码的情况下显式控制

需要显式控制
    ├─ 修改 oneshot CLI，将值传入 AIAgent.request_overrides
    └─ 或直接使用 Python API 创建 AIAgent
```
