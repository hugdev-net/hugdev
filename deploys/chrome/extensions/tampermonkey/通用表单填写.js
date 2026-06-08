// ==UserScript==
// @name         通用表单填写
// @namespace    x-tm-form-autofill
// @version      1.0
// @description  将结构化数据（Json）自动化填写到页面的表单中
// @match        https://xxx.site.com/*
// @grant        none
// ==/UserScript==

(function () {
    'use strict';

    /* ① 字段映射：左边是数据字段名，右边是页面表单元素的选择器。
        用 DevTools 检查后填入，优先用 id / name 最稳定。 */
    const FIELD_MAP = {
        input1: '#input1',
        input2: 'input[name="input2"]'
    };

    /* ② 关键：兼容 React/Vue 的赋值方式 */
    function setNativeValue(el, value) {
        const proto = el.tagName === 'TEXTAREA'
            ? window.HTMLTextAreaElement.prototype
            : window.HTMLInputElement.prototype;
        const setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
        setter.call(el, value);
        el.dispatchEvent(new Event('input', {bubbles: true}));
        el.dispatchEvent(new Event('change', {bubbles: true}));
        el.dispatchEvent(new Event('blur', {bubbles: true}));
    }

    function fillField(selector, value) {
        const el = document.querySelector(selector);
        if (!el) {
            console.warn('未找到元素：', selector);
            return false;
        }
        if (el.tagName === 'SELECT') {
            el.value = value;
            el.dispatchEvent(new Event('change', {bubbles: true}));
        } else {
            el.focus();
            setNativeValue(el, value);
        }
        return true;
    }

    function fillForm(data) {
        if (!data) return;
        try {
            if (data instanceof String) {
                data = JSON.parse(data)
            }
            let ok = 0;
            const miss = [];
            for (const [key, selector] of Object.entries(FIELD_MAP)) {
                if (data[key] == null || data[key] === '') continue;
                fillField(selector, String(data[key])) ? ok++ : miss.push(key);
            }
            status.style.color = miss.length ? '#d97706' : '#16a34a';
            status.textContent = `已填 ${ok} 项` + (miss.length ? `；未找到：${miss.join('、')}` : '');

        } catch (e) {
            status.style.color = '#dc2626';
            status.textContent = '解析失败，请确认是合法 JSON：' + e.message;
        }
    }

    /* ③ 悬浮面板：粘贴数据 → 一键填充 */
    const panel = document.createElement('div');
    Object.assign(panel.style, {
        position: 'fixed', right: '20px', bottom: '20px', zIndex: 99999,
        width: '300px', padding: '12px', background: '#fff',
        border: '1px solid #ddd', borderRadius: '10px',
        boxShadow: '0 4px 16px rgba(0,0,0,.15)', font: '13px/1.5 sans-serif'
    });
    panel.innerHTML = `
    <div style="font-weight:600;margin-bottom:6px">📋 自动录入</div>
    <textarea id="x-tm-form-data" rows="5"
      placeholder='粘贴 JSON，例如：{"invoiceNo":"123","amount":"100.00"}'
      style="width:100%;box-sizing:border-box;resize:vertical"></textarea>
    <button id="x-tm-form-fill" style="margin-top:8px;width:100%;padding:8px;background:#2563eb;
      color:#fff;border:none;border-radius:6px;cursor:pointer">填入表单</button>
    <div id="x-tm-form-status" style="margin-top:6px;min-height:18px;color:#16a34a"></div>`;
    document.body.appendChild(panel);

    const status = panel.querySelector('#x-tm-form-status');
    panel.querySelector('#x-tm-form-fill').addEventListener('click', function () {
        fillForm(panel.querySelector('#x-tm-form-data').value.trim());
    });
})();