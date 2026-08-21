---
name: wiki-anki
description: >
  Generate Anki cards from wiki documents, supporting four question types:
  single-choice, multi-choice, fill-in-blank, and free-response QA cards.
  Handles knowledge extraction, deck/model creation (including an interactive
  grading template), batch import, and verification.
  Triggers on: "生成卡片", "anki", "抽题", "做成卡片", "anki 集合", "出题", "生成题目", "四类题", "flashcard", "anki 牌组"
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki-anki: Generate Anki Cards from Wiki Documents

## When to Use

When the user asks to turn a wiki document (or any text source) into Anki cards, extract quiz questions, or generate exercises. Four question types are covered: **single-choice, multi-choice, fill-in-blank, free-response QA**.

## Core Question-Design Principles

### Type Division of Labor (avoid simple duplication)

The same knowledge point may appear in multiple question types, but each must **test a different angle** — never generate four cards that re-test the same fact:

| Type | Skill tested | Best for | Example |
|---|---|---|---|
| Single-choice `single` | Fact recognition, concept discrimination | "What is X", unique-answer identification | What was Rolling Thunder |
| Multi-choice `multi` | Multi-condition judgment, confusable items | "Which of these", half-true distractors | Which policies were Nixon's |
| Fill-in-blank `fill` | Precise recall | Numbers, names, places, proper nouns | Captured ____, answer "Saigon" |
| QA `qa` | Comprehension, causal chains | "Why / how / significance", impacts | How did the war end |

- **One question per related knowledge point**: e.g., "the 17th parallel" tested by single-choice for recognition, "fall of Saigon date" by fill-in-blank for precise recall, "war impact" by QA for synthesis — at most 2 types per knowledge point, angles must differ.
- **Distractor design**: single-choice distractors must be **same-class** (all operation names / all years / all names); multi-choice distractors **half-true** (mix correct and incorrect statements, e.g., sneak Korea's 38th parallel into a Vietnam partition question).
- **Explanation field must contain**: ① basis for the correct answer (facts from the document); ② why each distractor is wrong (confusion-point analysis).

### Card-Type Ratio (hard rule)

- **QA cards vs interactive cards ≈ 1:1**: before writing questions, split knowledge points into "comprehension" (causal chains, impacts → QA cards) and "fact recall" (dates, places, people, numbers → interactive cards) groups. **The two groups must be close to equal in size** (e.g., 20 knowledge points → 10 QA + 10 interactive, or 20:20; a 2:1 imbalance is not acceptable). Within the interactive group, distribute single/multi/fill evenly (about one third each) — no single-type crowding.

## The Two Card Models

### 1. QA Cards (reuse existing model "问答题", fields: 正面 / 背面)

- Plain Q&A cards: Front = question, Back = answer. No interaction; flip to reveal the answer.
- Write answer points on separate lines; include key numbers/names.

### 2. Interactive Cards (model "交互题", fields: 题干 / 题型 / 选项 / 答案 / 解析)

- Interactive: click/type → immediate red/green grading → press "Show Answer" to flip and read the explanation.
- **Field rules**:
  - 题型 (Type): `single` | `multi` | `fill`
  - 选项 (Options): `||`-separated (empty for fill)
  - 答案 (Answer): single `"B"`; multi `"A||B||D"`; fill accepts multiple answers `"300||三百万"`
  - 解析 (Explanation): correct-answer basis + distractor analysis
- **⚠️ Field order: "题干" (Question) MUST be first**: Anki's duplicate check hashes the first field; if "题型" came first, same-type cards were wrongly skipped as duplicates (real bug hit in production).

### Model Existence Check

```json
{"action": "modelNames"}
```
Call this through your Anki MCP server or AnkiConnect HTTP API (`localhost:8765`). Do not hardcode a vendor tool URI.
- If missing, create with the template below (model name `交互题`, field order `["题干","题型","选项","答案","解析"]`). If you already created a model with the same fields under another name, reuse it.
- If present, reuse as-is (models are shared at template level; deleting a deck does not delete the model)

## Interactive Template (final version, browser-tested 3 rounds; do not change the structure)

### Front

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

### Back (flip side: explanation)

```html
{{FrontSide}}<hr id="answer">
<div class="vw-back-explain">
  <div class="vw-explain-title">📖 解析</div>
  <div class="vw-explain-body">{{解析}}</div>
</div>
```

### CSS (model styling, light/dark dual mode)

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

## Workflow

1. **Read source**: read the wiki document (or user-provided text); extract an atomic knowledge-point list (key numbers, names, places, dates, causal chains).
2. **Assign types & balance ratio**: split knowledge points into QA (comprehension) and interactive (fact recall) groups, **totals close to 1:1**; within the interactive group, distribute single/multi/fill evenly. Avoid same-angle duplication across nearby points. If the user asks for "one of each type per point", produce 1-4 cards per point from different angles.
3. **Create deck**: `createDeck`, name as `Domain::Topic` (e.g. `历史::越南战争`). **Max 2 levels** (`parent::child`); 3 levels are rejected.
4. **Check models**: `modelNames`; create `问答题`/`交互题` only if missing (use templates above).
5. **Batch import**: `addNotes` (≤100 notes per batch per deck+model). Interactive fields: 题型/题干/选项/答案/解析; QA fields: 正面/背面. Shared tags: `history` + topic + `interactive` (for interactive cards).
6. **Verify**: `listDecks` (includeStats) confirms card counts; `notesInfo` spot-checks 1-2 notes for complete fields.
7. **Wrap up**: tell the user the deck is ready to study; suggest a manual AnkiWeb sync when new decks were added.

## Pitfalls (all hit in production — obey these)

1. **First field is the duplicate key**: in batch `addNotes`, cards sharing the same first-field value are skipped as duplicates (caused 8 of 11 cards to be dropped once). The interactive model's first field MUST be 题干.
2. **Never hide the submit button inside a hidden container**: the button was once placed inside `#vwF` (a `display:none` fill container), making it invisible in multi-choice mode. The button must be a standalone element whose visibility is controlled by JS per type.
3. **createDeck is limited to 2 levels**: `历史::冷战::越南战争` errors; use `历史::越南战争`.
4. **Anki re-runs JS on flip**: `{{FrontSide}}` re-executes the front script; interaction state must persist via sessionStorage keyed by the question text (prevents cross-card leakage) and be replayed on re-render.
5. **No `{{` in template JS**: `{{` is parsed as an Anki field; use string concatenation, never template literals.
6. **Pass field data via `<script type="text/plain">`**: read with `textContent` to avoid quotes in field values breaking JS strings or HTML attributes.
7. **Sync errors do not block local work**: Sync status 2 = pending local changes (e.g. deleted decks); local operations are fine, retry sync later.
8. **Deleting a deck does not delete the model**: rebuild = create deck + addNotes; the model (with templates) is reusable.

## Template Verification (mandatory after any template change)

Replace `{{题型}}/{{题干}}/{{选项}}/{{答案}}/{{解析}}` in the Front template with test data, write a local HTML file (under `.scripts/`), and open it in a browser to click through:
- Single: click-to-grade; wrong option red / correct green
- Multi: toggle options → "提交答案" button **really visible** (check `offsetParent !== null`, NOT getComputedStyle — it returns the declared value even under a hidden parent)
- Fill: input → submit → red/green input frame
- Reload page: red/green state and banner restored
- Delete test files afterwards
