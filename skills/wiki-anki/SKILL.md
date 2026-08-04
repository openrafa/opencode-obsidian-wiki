---
name: wiki-anki
description: >
  从 wiki 文档生成 Anki 卡片，支持四类题型：单选、多选、填空、问答题。
  负责知识点提炼、牌组/模型创建（含交互式判分模板）、批量导入与验证。
  Triggers on: "生成卡片", "anki", "抽题", "做成卡片", "anki 集合", "出题", "生成题目", "四类题", "flashcard", "anki 牌组"
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki-anki: 从 Wiki 文档生成 Anki 卡片

## 何时使用

用户要求把 wiki 文档（或任意文本来源）做成 Anki 卡片、抽题、生成题目时。覆盖四类题型：**单选、多选、填空、问答题**。

## 核心出题原则

### 题型分工（避免简单重复）

同一知识点允许多种题型各出一题，但必须**从不同角度考察**，禁止四张卡重复考同一事实：

| 题型 | 考察能力 | 适合内容 | 示例 |
|---|---|---|---|
| 单选 `single` | 事实识别、概念区分 | 「是什么」、唯一答案的选择题 | 滚雷行动是什么行动 |
| 多选 `multi` | 多条件判断、易混点并列 | 「哪些属于/正确」、干扰项半真半假 | 哪些是尼克松的政策 |
| 填空 `fill` | 精确记忆 | 数字、人名、地名、专有名词 | 占领____，答案「西贡」 |
| 问答题 `qa` | 综合理解、因果链 | 「为什么/如何/意义」、影响与评价 | 越南战争如何结束 |

- **相近知识点各一题**：如「17 度线分界」用单选考识别，「西贡陷落日期」用填空考精确记忆，「战争影响」用问答考综合——一个知识点最多出 2 种题型，角度必须不同。
- **问答卡与交互题 1:1 配比**：出题前先把知识点划分为「综合理解类」（因果链、影响意义 → 问答卡）与「事实记忆类」（时间、地点、人物、数字 → 交互题）两组，**两组总量尽量接近 1:1**（如 20 个知识点 → 10 问答 + 10 交互，或 20:20，禁止 2:1 这类失衡）。交互题内部再按单选/多选/填空均衡分配（每类约三分之一），避免单题型扎堆。
- 干扰项设计：单选干扰项必须**同类**（都是行动代号/都是年份/都是人名）；多选干扰项**半真半假**（正确表述+错误表述混杂，如把朝鲜的 38 度线混入越南分界线题）。
- 解析必须写：① 正确答案依据（文档事实）；② 干扰项错在哪（易混点辨析）。

## 两套卡片模型

### 1. 问答题（复用现有模型「问答题」，字段：正面 / 背面）

- 普通问答卡：正面 = 问题，背面 = 答案。不交互，翻面看答案。
- 答案要点分行书写，含关键数字/人名。

### 2. 历史交互题（模型「历史交互题」，字段：题干 / 题型 / 选项 / 答案 / 解析）

- 交互式：点击/输入 → 立即判对错（红绿）→ 点「显示答案」翻面看解析。
- **字段规则**：
  - 题型：`single` | `multi` | `fill`
  - 选项：`||` 分隔（fill 留空）
  - 答案：单选 `"B"`；多选 `"A||B||D"`；填空多个可接受答案 `"300||三百万"`
  - 解析：含错因与干扰项辨析
- **⚠️ 字段顺序必须「题干」在首位**：Anki 重复检测按首字段 hash，若「题型」在前，同题型卡会被误判为重复而跳过（实测踩坑）。

### 模型存在性检查

```json
{"action": "modelNames"}  // xd://mcp__anki_modelnames
```
- 缺失时用下方模板创建（createModel，模型名「历史交互题」，字段顺序 `["题干","题型","选项","答案","解析"]`）
- 存在时直接用，无需重建（模型是模板级共享，删牌组不会删模型）

## 交互模板（最终版，已浏览器实测三轮；勿改动结构）

### Front（卡面）

```html
<div class="vw-card">
  <div class="vw-qtype" id="vwQType"> </div>
  <div class="vw-question" id="vwQ">{{题干}}</div>
  <ul id="vwO-box"></ul>
  <div id="vwF" style="display:none">
    <input id="vw-input" class="vw-fill-input" type="text" placeholder="输入答案后点击提交">
  </div>
  <button id="vw-submit" class="vw-btn" type="button" style="display:none">提交答案</button>
  <div id="vw-feedback" class="vw-feedback" style="display:none"></div>
  <div class="vw-hint" id="vwHint" style="display:none">点击「显示答案」查看解析</div>
</div>
<script type="text/plain" id="vwT">{{题型}}</script>
<script type="text/plain" id="vwO">{{选项}}</script>
<script type="text/plain" id="vwA">{{答案}}</script>
<script>
(function () {
  'use strict';
  function $(id) { return document.getElementById(id); }
  function read(id) { var el = $(id); return el ? el.textContent.trim() : ''; }
  var TYPE = read('vwT');
  var OPTS = read('vwO').split('||').filter(function (s) { return s.trim() !== ''; });
  var ANS = read('vwA').split('||').map(function (s) { return s.trim(); });
  var Q = read('vwQ');
  var LET = ['A', 'B', 'C', 'D', 'E', 'F'];
  var KEY = 'vw-state';
  var state = null;
  try { state = JSON.parse(sessionStorage.getItem(KEY)); } catch (e) { state = null; }
  if (!state || state.q !== Q) { state = { q: Q, done: false, sel: [], input: '', ok: false }; }
  function save() { try { sessionStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {} }

  var qtypeLabel = { single: '单选', multi: '多选', fill: '填空' };
  $('vwQType').textContent = '【' + (qtypeLabel[TYPE] || TYPE) + '】';

  function renderOptions() {
    var box = $('vwO-box');
    box.innerHTML = '';
    OPTS.forEach(function (txt, i) {
      var li = document.createElement('li');
      li.className = 'vw-opt';
      li.textContent = LET[i] + '. ' + txt;
      li.dataset.k = LET[i];
      li.onclick = function () { onOpt(LET[i]); };
      box.appendChild(li);
    });
  }
  function showFill() {
    $('vwF').style.display = 'block';
    $('vw-submit').style.display = 'inline-block';
    $('vw-submit').onclick = submitFill;
  }
  function showMultiSubmit() {
    $('vw-submit').style.display = 'inline-block';
    $('vw-submit').onclick = submitMulti;
  }
  function renderInteractive() {
    renderOptions();
    if (TYPE === 'fill') { showFill(); }
    if (TYPE === 'multi') { showMultiSubmit(); }
  }
  function paintSel() {
    var lis = $('vwO-box').children;
    for (var i = 0; i < lis.length; i++) {
      var k = lis[i].dataset.k;
      lis[i].className = 'vw-opt' + (state.sel.indexOf(k) > -1 ? ' vw-sel' : '');
    }
  }
  function onOpt(k) {
    if (state.done) { return; }
    if (TYPE === 'single') {
      state.sel = [k];
      judge();
    } else if (TYPE === 'multi') {
      var i = state.sel.indexOf(k);
      if (i > -1) { state.sel.splice(i, 1); } else { state.sel.push(k); }
      paintSel();
    }
    save();
  }
  function submitMulti() {
    if (state.done || state.sel.length === 0) { return; }
    judge();
  }
  function submitFill() {
    if (state.done) { return; }
    var v = $('vw-input').value.trim();
    if (!v) { return; }
    state.input = v;
    judge();
  }
  function judge() {
    state.done = true;
    var ok = false;
    if (TYPE === 'fill') {
      ok = ANS.some(function (a) { return a.toLowerCase() === state.input.toLowerCase(); });
    } else {
      var selSet = state.sel.slice().sort().join('');
      var ansSet = ANS.slice().sort().join('');
      ok = selSet === ansSet;
      var lis = $('vwO-box').children;
      for (var i = 0; i < lis.length; i++) {
        var k = lis[i].dataset.k;
        var isC = ANS.indexOf(k) > -1;
        var isS = state.sel.indexOf(k) > -1;
        if (isC) { lis[i].className = 'vw-opt vw-ok'; }
        else if (isS) { lis[i].className = 'vw-opt vw-no'; }
      }
    }
    state.ok = ok;
    paintResult();
    save();
  }
  function paintResult() {
    var fb = $('vw-feedback');
    fb.style.display = 'block';
    if (state.ok) {
      fb.className = 'vw-feedback vw-fb-ok';
      fb.textContent = '✔ 回答正确';
    } else {
      fb.className = 'vw-feedback vw-fb-no';
      fb.textContent = TYPE === 'fill'
        ? '✘ 回答错误，正确答案：' + ANS.join(' / ')
        : '✘ 回答错误，正确答案：' + ANS.join('、');
    }
    if (TYPE === 'fill') {
      var inp = $('vw-input');
      inp.disabled = true;
      inp.className = 'vw-fill-input ' + (state.ok ? 'vw-input-ok' : 'vw-input-no');
    }
    $('vw-submit').style.display = 'none';
    $('vwHint').style.display = 'block';
  }
  function renderResult() {
    renderOptions();
    if (TYPE === 'fill') {
      showFill();
      var inp = $('vw-input');
      inp.value = state.input;
      inp.disabled = true;
      inp.className = 'vw-fill-input ' + (state.ok ? 'vw-input-ok' : 'vw-input-no');
    } else {
      var lis = $('vwO-box').children;
      for (var i = 0; i < lis.length; i++) {
        var k = lis[i].dataset.k;
        var isC = ANS.indexOf(k) > -1;
        var isS = state.sel.indexOf(k) > -1;
        if (isC) { lis[i].className = 'vw-opt vw-ok'; }
        else if (isS) { lis[i].className = 'vw-opt vw-no'; }
      }
    }
    $('vw-submit').style.display = 'none';
    paintResult();
  }

  if (state.done) { renderResult(); } else { renderInteractive(); }
})();
</script>
```

### Back（卡背：翻面显示解析）

```html
{{FrontSide}}<hr id="answer">
<div class="vw-back-explain">
  <div class="vw-explain-title">📖 解析</div>
  <div class="vw-explain-body">{{解析}}</div>
</div>
```

### CSS（模型样式，日/夜双模式）

```css
.card { font-family: -apple-system, 'PingFang SC', 'Microsoft YaHei', sans-serif; }
.vw-card { font-size: 1.05em; line-height: 1.65; margin: 4px; }
.vw-qtype { display: inline-block; padding: 2px 10px; border-radius: 10px; background: #e8eaf6; color: #3949ab; font-size: 0.8em; font-weight: bold; margin-bottom: 10px; }
.vw-question { font-weight: bold; margin-bottom: 12px; }
.vw-opt { list-style: none; padding: 10px 14px; margin: 8px 0; border: 1.5px solid #bdbdbd; border-radius: 8px; cursor: pointer; -webkit-user-select: none; user-select: none; }
.vw-opt:hover { background: #f5f5f5; }
.vw-opt.vw-sel { border-color: #3949ab; background: #e8eaf6; }
.vw-opt.vw-ok { border-color: #2e7d32; background: #e8f5e9; color: #1b5e20; }
.vw-opt.vw-no { border-color: #c62828; background: #ffebee; color: #b71c1c; }
.vw-feedback { padding: 10px 14px; border-radius: 8px; margin-top: 12px; font-weight: bold; }
.vw-fb-ok { background: #e8f5e9; color: #1b5e20; border: 1.5px solid #2e7d32; }
.vw-fb-no { background: #ffebee; color: #b71c1c; border: 1.5px solid #c62828; }
.vw-hint { margin-top: 12px; color: #9e9e9e; font-size: 0.85em; }
.vw-btn { padding: 8px 22px; border-radius: 8px; border: 1.5px solid #3949ab; background: #3949ab; color: #fff; font-size: 1em; cursor: pointer; margin-top: 8px; }
.vw-fill-input { padding: 8px 12px; border-radius: 8px; border: 1.5px solid #bdbdbd; font-size: 1em; width: 55%; }
.vw-input-ok { border-color: #2e7d32; background: #e8f5e9; }
.vw-input-no { border-color: #c62828; background: #ffebee; }
.vw-explain-title { font-weight: bold; color: #3949ab; margin-top: 14px; }
.vw-explain-body { margin-top: 8px; padding: 10px 14px; background: #f5f5f5; border-left: 4px solid #3949ab; border-radius: 4px; }
body.nightMode .vw-opt { border-color: #555; }
body.nightMode .vw-opt:hover { background: #333; }
body.nightMode .vw-opt.vw-sel { background: #26324d; border-color: #8fa8e8; }
body.nightMode .vw-opt.vw-ok { background: #1b3a24; border-color: #66bb6a; color: #a5d6a7; }
body.nightMode .vw-opt.vw-no { background: #3d1f1f; border-color: #ef5350; color: #ef9a9a; }
body.nightMode .vw-fb-ok { background: #1b3a24; border-color: #66bb6a; color: #a5d6a7; }
body.nightMode .vw-fb-no { background: #3d1f1f; border-color: #ef5350; color: #ef9a9a; }
body.nightMode .vw-hint { color: #777; }
body.nightMode .vw-explain-body { background: #333; border-left-color: #8fa8e8; }
body.nightMode .vw-fill-input { background: #222; color: #eee; border-color: #555; }
body.nightMode .vw-input-ok { border-color: #66bb6a; background: #1b3a24; }
body.nightMode .vw-input-no { border-color: #ef5350; background: #3d1f1f; }
```

## 工作流

1. **读源**：读 wiki 文档（或用户给的文本），提炼原子知识点列表（含关键数字、人名、地名、日期、因果链）。
2. **分题型与配比**：先把知识点划分为问答卡（综合理解）与交互题（事实记忆）两组，总量接近 1:1；交互题内部再均衡分配单选/多选/填空。相近知识点避免同角度重复。用户若指定「每类各一题」，则每个知识点从不同角度出 1-4 题。
3. **建牌组**：`createDeck`，命名 `领域::主题`（如 `历史::越南战争`）。**最多 2 级**（`parent::child`），3 级会被拒绝。
4. **确认模型**：`modelNames` 检查；「问答题」/「历史交互题」缺失才创建（用上方模板）。
5. **批量导入**：`addNotes`（同一牌组+模型 ≤100 条/批）。交互题字段：题型/题干/选项/答案/解析；问答字段：正面/背面。共享 tags：`history` + 主题 + `interactive`（交互题）。
6. **验证**：`listDecks`（includeStats）确认卡片数正确；`notesInfo` 抽查 1-2 张字段完整。
7. **收尾**：告知用户可开刷；有新牌组时建议手动同步 AnkiWeb。

## 踩坑清单（实测教训，务必遵守）

1. **首字段即重复检测键**：addNotes 批量添加时，模型首字段相同的卡会被跳过（曾导致 11 张只进 3 张）。交互题首字段必须是「题干」。
2. **提交按钮不可藏在隐藏容器内**：曾把按钮放进 `#vwF`（display:none 的填空容器），多选模式下按钮连带不可见——按钮必须独立、由 JS 按题型控制显隐。
3. **createDeck 限 2 级嵌套**：`历史::冷战::越南战争` 会报错，用 `历史::越南战争`。
4. **Anki 翻面重跑 JS**：`{{FrontSide}}` 会重新执行卡面脚本，交互状态必须存 sessionStorage，并按题干比对（防串卡），刷新后重放红绿。
5. **模板 JS 禁 `{{`**：`{{` 会被 Anki 当字段语法解析，JS 内用字符串拼接，不用模板字符串。
6. **字段数据经 `<script type="text/plain">` 传递**：textContent 读取，避免字段中的引号破坏 JS 字符串/HTML 属性。
7. **sync 报错不影响本地**：Sync status 2 = 本地有未同步的变更（如删牌组），本地操作照常，稍后重试同步即可。
8. **删牌组不会删模型**：重建只需建牌组 + addNotes，模型（含模板）可复用。

## 验证模板（可选，改模板后必做）

将 Front 模板的 `{{题型}}/{{题干}}/{{选项}}/{{答案}}/{{解析}}` 替换为测试数据生成本地 HTML（放 `.scripts/`），用浏览器（xd://browser）模拟点击验证：
- 单选：点选即判，错项红/对项绿
- 多选：勾选 → 「提交答案」按钮**真实可见**（检查 `offsetParent !== null`，勿用 getComputedStyle——隐藏父容器下它仍返回声明值）
- 填空：输入 → 提交 → 红/绿框
- 刷新页面：红绿与横幅状态恢复
- 验证后删除测试文件
