from __future__ import annotations

from datetime import datetime
from threading import Lock
from time import perf_counter
import unicodedata

from PIL import ImageGrab
from PySide6.QtCore import QObject, QThread, Qt, QTimer, Signal
from PySide6.QtGui import QCursor, QFont, QImage, QPixmap
from PySide6.QtWidgets import (
    QApplication,
    QCheckBox,
    QFormLayout,
    QFrame,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QSizePolicy,
    QSpinBox,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)
from rapidocr_onnxruntime import RapidOCR


class OcrWorker(QObject):
    finished = Signal()
    error = Signal(str)
    log = Signal(str)
    image_ready = Signal(QImage)
    text_ready = Signal(str)

    _engine_lock = Lock()
    _ocr_engine: RapidOCR | None = None

    def __init__(self, region: tuple[int, int, int, int], single_line_fast_mode: bool) -> None:
        super().__init__()
        self.region = region
        self.single_line_fast_mode = single_line_fast_mode
        self._cancel_requested = False

    def request_cancel(self) -> None:
        self._cancel_requested = True
        self.log.emit("已收到停止请求，将在当前步骤结束后中断流程。")

    def run(self) -> None:
        started_at = perf_counter()
        try:
            capture_started_at = perf_counter()
            self.log.emit(
                f"开始截图，区域 left={self.region[0]}, top={self.region[1]}, right={self.region[2]}, bottom={self.region[3]}"
            )
            image = ImageGrab.grab(bbox=self.region, all_screens=True)
            self.log.emit(f"截图完成，尺寸 {image.width}x{image.height}")
            self.log.emit(f"截图耗时 {(perf_counter() - capture_started_at) * 1000:.1f} ms")

            if self._cancel_requested:
                self.log.emit("流程已在截图后中断。")
                return

            qimage = self._pil_to_qimage(image)
            self.image_ready.emit(qimage)
            self.log.emit("截图已更新到预览区")

            if self._cancel_requested:
                self.log.emit("流程已在 OCR 前中断。")
                return

            self.log.emit(
                "开始执行本地 OCR 识别（单行极速模式）"
                if self.single_line_fast_mode
                else "开始执行本地 OCR 识别（标准模式）"
            )
            ocr_started_at = perf_counter()
            result, _ = self._get_ocr_engine()(
                image,
                use_det=not self.single_line_fast_mode,
                use_cls=False,
                use_rec=True,
            )
            self.log.emit(f"OCR 推理耗时 {(perf_counter() - ocr_started_at) * 1000:.1f} ms")

            if self._cancel_requested:
                self.log.emit("流程已在 OCR 后处理中断。")
                return

            text = self._extract_text(result)
            self.log.emit(
                f"OCR 识别完成，得到 {len(text)} 个字符"
                if text
                else "OCR 识别完成，但未识别出文字"
            )
            self.text_ready.emit(text)
        except Exception as exc:  # pragma: no cover - GUI runtime path
            self.error.emit(str(exc))
        finally:
            self.log.emit(f"本次流程总耗时 {(perf_counter() - started_at) * 1000:.1f} ms")
            self.finished.emit()

    @classmethod
    def _get_ocr_engine(cls) -> RapidOCR:
        if cls._ocr_engine is not None:
            return cls._ocr_engine

        with cls._engine_lock:
            if cls._ocr_engine is None:
                cls._ocr_engine = RapidOCR(use_cls=False)
        return cls._ocr_engine

    def _pil_to_qimage(self, image) -> QImage:
        rgba_image = image.convert("RGBA")
        data = rgba_image.tobytes("raw", "RGBA")
        return QImage(
            data,
            rgba_image.width,
            rgba_image.height,
            rgba_image.width * 4,
            QImage.Format.Format_RGBA8888,
        ).copy()

    def _extract_text(self, result) -> str:
        if not result:
            return ""

        lines: list[str] = []
        for item in result:
            if not item:
                continue

            candidate = ""
            if len(item) >= 2 and isinstance(item[0], str):
                candidate = str(item[0]).strip()
            elif len(item) >= 2 and item[1]:
                candidate = str(item[1]).strip()

            if candidate:
                lines.append(candidate)
        return " ".join(lines).strip()


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("区域截图 OCR 工具")
        self.resize(980, 760)

        self._is_running = False
        self._worker_thread: QThread | None = None
        self._worker: OcrWorker | None = None
        self._current_preview: QPixmap | None = None
        self._cursor_timer = QTimer(self)
        self._cursor_timer.setInterval(80)
        self._cursor_timer.timeout.connect(self._update_cursor_position)

        self._build_ui()
        self._set_running(False)
        self._append_log("应用已初始化，等待启动。")
        self._cursor_timer.start()
        self._update_cursor_position()

    def _build_ui(self) -> None:
        central = QWidget(self)
        self.setCentralWidget(central)

        root = QVBoxLayout(central)
        root.setContentsMargins(16, 16, 16, 16)
        root.setSpacing(12)

        root.addWidget(self._build_action_group())
        root.addWidget(self._build_region_group())
        root.addWidget(self._build_display_group(), stretch=1)

    def _build_action_group(self) -> QGroupBox:
        group = QGroupBox("按钮区", self)
        layout = QHBoxLayout(group)
        layout.setContentsMargins(12, 12, 12, 12)
        layout.setSpacing(10)

        self.start_button = QPushButton("启动", group)
        self.stop_button = QPushButton("停止", group)
        self.start_button.setMinimumHeight(36)
        self.stop_button.setMinimumHeight(36)

        self.start_button.clicked.connect(self._start_task)
        self.stop_button.clicked.connect(self._stop_task)

        self.single_line_fast_checkbox = QCheckBox("单行极速模式", group)
        self.single_line_fast_checkbox.setChecked(True)
        self.single_line_fast_checkbox.setToolTip(
            "截图区域已紧贴单行文本时启用，可跳过文本检测并显著降低延迟。"
        )

        layout.addWidget(self.start_button)
        layout.addWidget(self.stop_button)
        layout.addWidget(self.single_line_fast_checkbox)
        layout.addStretch(1)

        return group

    def _build_region_group(self) -> QGroupBox:
        group = QGroupBox("表单参数区", self)
        layout = QHBoxLayout(group)
        layout.setContentsMargins(12, 12, 12, 12)
        layout.setSpacing(10)

        self.left_input = self._create_spin_box(800)
        self.top_input = self._create_spin_box(500)
        self.right_input = self._create_spin_box(1200)
        self.bottom_input = self._create_spin_box(700)

        fields = [
            ("左", self.left_input),
            ("上", self.top_input),
            ("右", self.right_input),
            ("下", self.bottom_input),
        ]

        for label_text, widget in fields:
            field_layout = QFormLayout()
            field_layout.setContentsMargins(0, 0, 0, 0)
            field_layout.setLabelAlignment(Qt.AlignmentFlag.AlignRight)
            field_layout.addRow(label_text, widget)
            layout.addLayout(field_layout)

        hint = QLabel("四个整数像素值共同定义屏幕区域：左上右下", group)
        hint.setStyleSheet("color: #666666;")

        self.cursor_position_label = QLabel("鼠标: X=0, Y=0", group)
        self.cursor_position_label.setStyleSheet("color: #1f4e79; font-weight: 600;")

        layout.addSpacing(12)
        layout.addWidget(hint)
        layout.addSpacing(16)
        layout.addWidget(self.cursor_position_label)
        layout.addStretch(1)

        return group

    def _build_display_group(self) -> QGroupBox:
        group = QGroupBox("显示区", self)
        layout = QVBoxLayout(group)
        layout.setContentsMargins(12, 12, 12, 12)
        layout.setSpacing(10)

        self.image_label = QLabel("等待截图", group)
        self.image_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.image_label.setMinimumHeight(300)
        self.image_label.setSizePolicy(
            QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding
        )
        self.image_label.setFrameShape(QFrame.Shape.StyledPanel)
        self.image_label.setStyleSheet(
            "background-color: #f3f6fa; border: 1px solid #c7d0d9; color: #4c5968;"
        )

        self.result_input = QLineEdit(group)
        self.result_input.setReadOnly(True)
        self.result_input.setPlaceholderText("OCR 识别结果会显示在这里，并自动写入剪贴板")

        self.log_output = QTextEdit(group)
        self.log_output.setReadOnly(True)
        self.log_output.setLineWrapMode(QTextEdit.LineWrapMode.NoWrap)
        self.log_output.setFont(QFont("Consolas", 10))
        self.log_output.setPlaceholderText("调试日志输出区")

        layout.addWidget(self.image_label, stretch=3)
        layout.addWidget(self.result_input)
        layout.addWidget(self.log_output, stretch=2)

        return group

    def _create_spin_box(self, value: int = 0) -> QSpinBox:
        widget = QSpinBox(self)
        widget.setRange(0, 99999)
        widget.setValue(value)
        widget.setButtonSymbols(QSpinBox.ButtonSymbols.NoButtons)
        widget.setFixedWidth(88)
        widget.setAlignment(Qt.AlignmentFlag.AlignCenter)
        return widget

    def _start_task(self) -> None:
        if self._is_running:
            self._append_log("启动请求已忽略，当前任务仍在执行。")
            return

        region = self._get_region()
        if region is None:
            return

        self.result_input.clear()
        self._append_log("收到启动请求，准备执行截图与 OCR 流程。")
        self._append_log(
            "当前模式: 单行极速模式（跳过检测）"
            if self.single_line_fast_checkbox.isChecked()
            else "当前模式: 标准模式（检测 + 识别）"
        )
        self._set_running(True)
        self._launch_worker(region)

    def _stop_task(self) -> None:
        if not self._is_running:
            self._append_log("停止请求已忽略，当前未在运行。")
            return

        if self._worker is not None:
            self._worker.request_cancel()
        self.stop_button.setEnabled(False)

    def _launch_worker(self, region: tuple[int, int, int, int]) -> None:
        self._worker_thread = QThread(self)
        self._worker = OcrWorker(region, self.single_line_fast_checkbox.isChecked())
        self._worker.moveToThread(self._worker_thread)

        self._worker_thread.started.connect(self._worker.run)
        self._worker.log.connect(self._append_log)
        self._worker.image_ready.connect(self._show_captured_image)
        self._worker.text_ready.connect(self._handle_ocr_text)
        self._worker.error.connect(self._handle_worker_error)
        self._worker.finished.connect(self._worker_thread.quit)
        self._worker.finished.connect(self._worker.deleteLater)
        self._worker_thread.finished.connect(self._worker_thread.deleteLater)
        self._worker_thread.finished.connect(self._on_worker_finished)

        self._worker_thread.start()

    def _get_region(self) -> tuple[int, int, int, int] | None:
        left = self.left_input.value()
        top = self.top_input.value()
        right = self.right_input.value()
        bottom = self.bottom_input.value()

        if left >= right or top >= bottom:
            QMessageBox.warning(self, "参数错误", "区域参数无效，必须满足 左 < 右 且 上 < 下。")
            self._append_log("区域参数校验失败。")
            return None

        return left, top, right, bottom

    def _set_running(self, running: bool) -> None:
        self._is_running = running
        self.start_button.setEnabled(not running)
        self.stop_button.setEnabled(running)

    def _show_captured_image(self, image: QImage) -> None:
        self._current_preview = QPixmap.fromImage(image)
        self._refresh_preview()

    def _handle_ocr_text(self, text: str) -> None:
        normalized_text = self._normalize_ocr_text(text)
        self.result_input.setText(normalized_text)

        clipboard = QApplication.clipboard()
        clipboard.setText(normalized_text)

        self._append_log(
            f"OCR 文本清洗完成: 原始长度 {len(text)} -> 清洗后长度 {len(normalized_text)}"
        )
        if normalized_text:
            self._append_log("识别文本已显示到文本框，并写入系统剪贴板。")
        else:
            self._append_log("清洗后无可用文本，已将空字符串写入系统剪贴板。")

    def _normalize_ocr_text(self, text: str) -> str:
        chars_to_remove = set("当前邀请码10000个限量领取说明")
        cleaned = "".join(char for char in text if char not in chars_to_remove)
        cleaned = cleaned.replace(":", "").replace("：", "")
        cleaned = "".join(
            char for char in cleaned if not unicodedata.category(char).startswith("P")
        )
        return cleaned.strip()

    def _handle_worker_error(self, message: str) -> None:
        self._append_log(f"执行失败: {message}")
        QMessageBox.critical(self, "执行失败", message)

    def _on_worker_finished(self) -> None:
        self._worker = None
        self._worker_thread = None
        self._set_running(False)
        self._append_log("当前流程结束，界面已恢复可再次启动。")

    def _refresh_preview(self) -> None:
        if self._current_preview is None:
            return

        self.image_label.setPixmap(
            self._current_preview.scaled(
                self.image_label.size(),
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation,
            )
        )

    def _append_log(self, message: str) -> None:
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.log_output.append(f"[{timestamp}] {message}")

    def _update_cursor_position(self) -> None:
        pos = QCursor.pos()
        self.cursor_position_label.setText(f"鼠标: X={pos.x()}, Y={pos.y()}")

    def resizeEvent(self, event) -> None:  # type: ignore[override]
        super().resizeEvent(event)
        self._refresh_preview()
