// ---- Column Maths: column addition and subtraction (Year 3) ----
// Clara taps a space, types a digit, and fills the whole sum in: the answer
// digits AND the carries (addition) or exchanges (subtraction). Nothing is
// worked out for her. "Check" marks each space, and a hint says which column to
// look at without giving the digit. Loaded BEFORE app.js (deep links) and uses
// its helpers (showScreen, chimes, renderFarm) only when called.

// Listed in teaching order. The ids are what is saved (cleared stages, last
// stage), so new stages get new ids rather than renumbering: 8 and 9 are the
// block stages that come before written subtraction, as at school (NCETM 1.21:
// Dienes alongside the column layout first, then the layout alone).
// Clara sees each stage's position in this list, not its id.
const COL_STAGES = [
  { id: 1, op: '+', digits: 3, exchanges: [0],    label: 'Adding, no carrying' },
  { id: 2, op: '+', digits: 3, exchanges: [1],    label: 'Adding, carry once' },
  { id: 3, op: '+', digits: 3, exchanges: [2],    label: 'Adding, carry twice' },
  { id: 8, op: '-', digits: 2, exchanges: [0],    label: 'Subtracting with blocks', blocks: true },
  { id: 9, op: '-', digits: 3, exchanges: [1],    label: 'Swap with blocks: exchanging', blocks: true },
  { id: 4, op: '-', digits: 3, exchanges: [0],    label: 'Subtracting, no exchange' },
  { id: 5, op: '-', digits: 3, exchanges: [1],    label: 'Subtracting, exchange once' },
  { id: 6, op: '-', digits: 3, exchanges: [2],    label: 'Subtracting, exchange twice' },
  { id: 7, op: '+-', digits: 4, exchanges: [0, 1, 2, 3], label: 'Thousands too!' },
];
const colStageIndex = id => Math.max(0, COL_STAGES.findIndex(s => s.id === id));
const colStageDef = id => COL_STAGES[colStageIndex(id)];
const COL_SUMS_PER_SESSION = 5;
const COL_KEY = 'ttg_columns';
const REWARDS_KEY = 'ttg_rewards';       // shared "stars" to spend in the garden
const COL_NAMES = ['ones', 'tens', 'hundreds', 'thousands'];
const COL_HEAD = ['O', 'T', 'H', 'Th'];   // O for ones, as at school

function loadCols() {
  try { return Object.assign({ cleared: [], last: 1 }, JSON.parse(localStorage.getItem(COL_KEY))); }
  catch { return { cleared: [], last: 1 }; }
}
function saveCols(c) { try { localStorage.setItem(COL_KEY, JSON.stringify(c)); } catch {} }
function addStars(n) {
  try {
    const r = JSON.parse(localStorage.getItem(REWARDS_KEY)) || { stars: 0 };
    r.stars = (r.stars || 0) + n;
    localStorage.setItem(REWARDS_KEY, JSON.stringify(r));
  } catch {}
}

// ---- Making a sum ----
const rnd = (a, b) => a + Math.floor(Math.random() * (b - a + 1));

// Digits are stored units-first. Returns null if the sum is unsuitable.
function colAnalyse(op, top, bot) {
  const n = top.length;
  const info = { op, top, bot, n, exch: 0, need: {}, ans: [] };
  if (op === '+') {
    let carry = 0;
    for (let c = 0; c < n; c++) {
      const s = top[c] + bot[c] + carry;
      info.ans[c] = s % 10;
      carry = s >= 10 ? 1 : 0;
      if (carry) {
        if (c + 1 >= n) return null;          // would overflow the columns
        info.need['car' + (c + 1)] = 1;
        info.exch++;
      }
    }
  } else {
    const cur = top.slice();
    for (let c = 0; c < n - 1; c++) {
      if (cur[c] < bot[c]) {
        if (cur[c + 1] === 0) return null;     // no chains through zeros at Year 3
        info.need['ex' + (c + 1)] = top[c + 1] - 1;
        info.need['add' + c] = 1;
        cur[c + 1] -= 1; cur[c] += 10;
        info.exch++;
      }
    }
    for (let c = 0; c < n; c++) {
      if (cur[c] < bot[c]) return null;
      info.ans[c] = cur[c] - bot[c];
    }
  }
  info.need.ans = info.ans;
  return info;
}

function makeColumnSum(stage) {
  const ops = stage.op.split('');
  for (let tries = 0; tries < 4000; tries++) {
    const op = ops[rnd(0, ops.length - 1)];
    const n = stage.digits;
    const t = [], b = [];
    for (let c = 0; c < n; c++) { t.push(rnd(0, 9)); b.push(rnd(0, 9)); }
    // Lead digits are never zero; the bottom number is a little shorter in the thousands stage.
    t[n - 1] = rnd(1, 9);
    b[n - 1] = stage.digits === 4 ? rnd(0, 5) : rnd(1, 9);
    if (op === '-' && t[n - 1] < b[n - 1]) continue;
    const info = colAnalyse(op, t, b);
    if (!info) continue;
    if (!stage.exchanges.includes(info.exch)) continue;
    // Not too close to a trivial 0 in the middle of a simple stage.
    const topVal = +t.slice().reverse().join(''), botVal = +b.slice().reverse().join('');
    if (op === '-' && topVal <= botVal) continue;
    if (stage.digits === 3 && b[n - 1] === 0) continue;
    info.topVal = topVal; info.botVal = botVal;
    info.ansVal = op === '+' ? topVal + botVal : topVal - botVal;
    return info;
  }
  return null;
}

// ---- Game state ----
let colStage = loadCols().last;
let colSumNo = 0, colSolved = 0, colStars = 0, colSum = null;
let colVals = {}, colSel = null, colChecks = 0, colDone = false, colMessy = 0;
let colMat = null;   // the blocks in a block stage: how many in each column, how many subtracted, which columns have swapped

function startColumnsGame() {
  if (actx.state === 'suspended') actx.resume();
  colSumNo = 0; colSolved = 0; colStars = 0; colMessy = 0;
  renderColStages();
  showScreen('screen-columns');
  nextColumnSum();
}

function renderColStages() {
  const row = document.getElementById('columns-stages');
  const cleared = loadCols().cleared;
  row.innerHTML = '';
  COL_STAGES.forEach((s, i) => {
    const b = document.createElement('button');
    b.className = 'stage-btn' + (s.id === colStage ? ' active' : '') + (cleared.includes(s.id) ? ' cleared' : '');
    b.innerHTML = `<span class="stage-num">${i + 1}</span>${cleared.includes(s.id) ? '<span class="tick">✓</span>' : ''}`;
    b.addEventListener('click', () => {
      colStage = s.id;
      const c = loadCols(); c.last = s.id; saveCols(c);
      startColumnsGame();
    });
    row.appendChild(b);
  });
  document.getElementById('columns-stages-caption').textContent =
    `Stage ${colStageIndex(colStage) + 1}: ${colStageDef(colStage).label}`;
}

function nextColumnSum() {
  if (colSumNo >= COL_SUMS_PER_SESSION) return finishColumns();
  const stage = colStageDef(colStage);
  colSum = makeColumnSum(stage);
  colSum.blocks = !!stage.blocks && colSum.op === '-';
  colVals = {}; colSel = null; colChecks = 0; colDone = false;
  colMat = colSum.blocks ? { have: colSum.top.slice(), taken: colSum.top.map(() => 0), swapped: {}, arriving: -1 } : null;
  colSumNo++;
  renderColDots();
  renderColSum();
  setColMsg(colSum.op === '+' ? 'Add the numbers. Start with the ones!'
    : colSum.blocks ? 'The blocks show the top number. Start with the ones: tap the ones blocks to subtract.'
    : 'Subtract. Start with the ones!');
  document.getElementById('columns-next').classList.add('hidden');
  document.getElementById('columns-check').classList.remove('hidden');
  document.getElementById('columns-keys').classList.remove('hidden');
}

function renderColDots() {
  const d = document.getElementById('columns-dots');
  d.innerHTML = '';
  for (let i = 1; i <= COL_SUMS_PER_SESSION; i++) {
    const s = document.createElement('span');
    s.className = 'dot' + (i < colSumNo ? ' done' : i === colSumNo ? ' now' : '');
    d.appendChild(s);
  }
}

function setColMsg(t, kind) {
  const m = document.getElementById('columns-msg');
  m.textContent = t;
  m.className = 'columns-msg' + (kind ? ' ' + kind : '');
}

function cell(key, cls, text) {
  const el = document.createElement('button');
  el.className = 'ccell ' + cls;
  el.dataset.key = key;
  el.textContent = text || '';
  el.addEventListener('click', () => selectCell(key));
  return el;
}

function renderColSum() {
  const s = colSum, n = s.n;
  const box = document.getElementById('columns-sum');
  box.innerHTML = '';
  box.style.gridTemplateColumns = `44px repeat(${n}, 78px)`;
  const off = s.blocks ? 1 : 0;                      // the blocks take the top row in a block stage
  const put = (el, row, col) => { el.style.gridRow = row + off; el.style.gridColumn = col; box.appendChild(el); };
  const colOf = c => n - c + 1;                      // grid column for digit column c (units on the right)
  if (s.blocks) {
    for (let c = n - 1; c >= 0; c--) {
      const m = document.createElement('div'); m.className = 'cmat'; m.id = 'cmat' + c;
      m.style.gridRow = 1; m.style.gridColumn = colOf(c);
      box.appendChild(m);
    }
    renderColMat();
  }
  const rowHead = 1;
  for (let c = n - 1; c >= 0; c--) {
    const h = document.createElement('div'); h.className = 'chead ' + 'h' + c; h.textContent = COL_HEAD[c];
    put(h, rowHead, colOf(c));
  }
  if (s.op === '-') {
    // row 2: exchange cells above the top number; the little "1" sits beside the digit
    for (let c = n - 1; c >= 1; c--) put(cell('ex' + c, 'small'), 2, colOf(c));
    for (let c = 0; c < n; c++) {
      const wrap = document.createElement('div'); wrap.className = 'topwrap';
      wrap.appendChild(cell('add' + c, 'tiny'));
      const d = document.createElement('div'); d.className = 'digit'; d.id = 'topdigit' + c; d.textContent = s.top[c];
      wrap.appendChild(d);
      put(wrap, 3, colOf(c));
    }
  } else {
    for (let c = 0; c < n; c++) {
      const d = document.createElement('div'); d.className = 'digit'; d.textContent = s.top[c];
      put(d, 3, colOf(c));
    }
  }
  const op = document.createElement('div'); op.className = 'opsign'; op.textContent = s.op === '+' ? '+' : '−';
  put(op, 4, 1);
  for (let c = 0; c < n; c++) {
    const d = document.createElement('div'); d.className = 'digit'; d.textContent = s.bot[c] === 0 && c === n - 1 ? '' : s.bot[c];
    put(d, 4, colOf(c));
  }
  const line = document.createElement('div'); line.className = 'cline';
  put(line, 5, '1 / -1');
  for (let c = 0; c < n; c++) put(cell('ans' + c, 'big'), 6, colOf(c));
  if (s.op === '+') {
    const lab = document.createElement('div'); lab.className = 'rowlab'; lab.textContent = 'carry';
    put(lab, 7, 1);
    for (let c = 1; c < n; c++) put(cell('car' + c, 'small'), 7, colOf(c));
  }
  // The top number has the unused leading-zero cell hidden in 3-digit sums.
  refreshCells();
}

function refreshCells(wrong) {
  document.querySelectorAll('.ccell').forEach(el => {
    const k = el.dataset.key;
    el.textContent = colVals[k] !== undefined ? colVals[k] : '';
    el.classList.toggle('sel', k === colSel);
    el.classList.toggle('bad', !!(wrong && wrong.includes(k)));
    el.classList.toggle('good', colDone && el.textContent !== '');
  });
  // Cross out a top digit once an exchange is written above it.
  if (colSum && colSum.op === '-') {
    for (let c = 0; c < colSum.n; c++) {
      const d = document.getElementById('topdigit' + c);
      if (d) d.classList.toggle('struck', colVals['ex' + c] !== undefined);
    }
  }
}

// ---- Blocks (block stages only) ----
// Dienes-style blocks above each column: only the top number is built, as at
// school. Tapping a column subtracts one block; subtracted blocks stay, faded,
// so the bottom number is still visible. "Swap" breaks one block into ten of
// the next column down, and writes the exchange into the sum at the same
// moment, so she sees the crossed-out digit and the little 1 come from the
// swap. It refuses a swap the column next door doesn't need.
const COL_UNIT = ['one', 'ten', 'hundred', 'thousand'];
const BLOCK_KIND = ['one', 'ten', 'hun', 'hun'];
const unitWord = (c, k) => k === 1 ? COL_UNIT[c] : COL_NAMES[c];

function renderColMat() {
  if (!colMat) return;
  const s = colSum;
  for (let c = 0; c < s.n; c++) {
    const m = document.getElementById('cmat' + c);
    if (!m) continue;
    m.innerHTML = '';
    const have = colMat.have[c], taken = colMat.taken[c];
    if (c >= 1 && !colMat.swapped[c] && have - taken >= 1 && !colDone) {
      const sw = document.createElement('button');
      sw.className = 'cswap';
      sw.textContent = 'Swap ➜';
      sw.setAttribute('aria-label', `Swap 1 ${COL_UNIT[c]} for 10 ${COL_NAMES[c - 1]}`);
      sw.addEventListener('click', () => swapBlock(c));
      m.appendChild(sw);
    }
    const pile = document.createElement('button');
    pile.className = 'cpile ' + BLOCK_KIND[c];
    pile.setAttribute('aria-label', `${have - taken} ${unitWord(c, have - taken)} left. Tap to subtract one.`);
    for (let i = 0; i < have; i++) {
      const b = document.createElement('span');
      b.className = 'blk ' + BLOCK_KIND[c] + (i >= have - taken ? ' gone' : '');
      if (colMat.arriving === c && i >= have - 10) { b.classList.add('arrive'); b.style.animationDelay = (i - (have - 10)) * 40 + 'ms'; }
      pile.appendChild(b);
    }
    pile.addEventListener('click', () => takeBlock(c));
    m.appendChild(pile);
  }
  colMat.arriving = -1;
}

function takeBlock(c) {
  if (colDone || !colMat) return;
  const s = colSum, want = s.bot[c], have = colMat.have[c];
  const name = COL_NAMES[c];
  if (colMat.taken[c] >= want) {
    setColMsg(want === 0
      ? `There are no ${name} to subtract in this column. Leave them all!`
      : `You've subtracted ${want} ${unitWord(c, want)} already. How many ${name} are left?`);
    return;
  }
  if (have - colMat.taken[c] <= 0) {
    setColMsg(`There aren't enough ${name} to subtract ${want}. Swap 1 ${COL_UNIT[c + 1]} for 10 ${name}: tap Swap above the ${COL_NAMES[c + 1]}.`, 'warn');
    return;
  }
  colMat.taken[c]++;
  playGentleBlip();
  renderColMat();
  if (colMat.taken[c] === want)
    setColMsg(`${have} ${unitWord(c, have)} minus ${want} ${unitWord(c, want)} is equal to … how many ${name}? Count what's left and write it in the answer.`);
  else
    setColMsg(`Subtracting ${want} ${unitWord(c, want)}: ${colMat.taken[c]} done.`);
}

function swapBlock(c) {
  if (colDone || !colMat) return;
  const s = colSum, lo = c - 1;
  const loName = COL_NAMES[lo];
  if (colMat.have[lo] >= s.bot[lo]) {
    setColMsg(`The ${loName} have enough already: ${colMat.have[lo]} ${unitWord(lo, colMat.have[lo])} minus ${s.bot[lo]} ${unitWord(lo, s.bot[lo])}. No swap needed!`, 'warn');
    return;
  }
  colMat.have[c]--;
  colMat.have[lo] += 10;
  colMat.swapped[c] = true;
  colMat.arriving = lo;
  colVals['ex' + c] = String(s.top[c] - 1);
  colVals['add' + lo] = '1';
  playGentleBlip();
  refreshCells();
  renderColMat();
  setColMsg(`You swapped 1 ${COL_UNIT[c]} for 10 ${loName}. Now there are ${colMat.have[lo]} ${loName}! ` +
    `In the sum, the ${s.top[c]} ${unitWord(c, s.top[c])} became ${s.top[c] - 1}, and the little 1 turns ${s.top[lo]} ${unitWord(lo, s.top[lo])} into ${colMat.have[lo]}.`);
}

function selectCell(key) {
  if (colDone) return;
  colSel = key;
  refreshCells();
  playGentleBlip();
}

function typeDigit(d) {
  if (colDone || !colSel) { if (!colSel) setColMsg('Tap a space first!'); return; }
  colVals[colSel] = String(d);
  refreshCells();
}
function deleteDigit() {
  if (colDone || !colSel) return;
  delete colVals[colSel];
  refreshCells();
}

// The cell keys in the order a teacher would read them: ones first, answer
// then the exchange it produces, then tens, and so on.
function colOrder() {
  const out = [];
  for (let c = 0; c < colSum.n; c++) {
    if (colSum.op === '+') {
      if (colSum.need['car' + c]) out.push('car' + c);
      out.push('ans' + c);
    } else {
      if (colSum.need['add' + c]) out.push('add' + c);
      if (colSum.need['ex' + c]) out.push('ex' + c);
      out.push('ans' + c);
    }
  }
  return out;
}
function requiredValue(key) {
  const s = colSum;
  if (key.startsWith('ans')) return String(s.ans[+key.slice(3)]);
  const v = s.need[key];
  return v === undefined ? undefined : String(v);
}
function allKeys() {
  const s = colSum, out = [];
  for (let c = 0; c < s.n; c++) {
    out.push('ans' + c);
    if (s.op === '+') { if (c >= 1) out.push('car' + c); }
    else { if (c >= 1) out.push('ex' + c); out.push('add' + c); }
  }
  return out;
}

function checkColumnSum() {
  if (colDone) return;
  colChecks++;
  const wrong = [];
  for (const k of allKeys()) {
    const need = requiredValue(k), have = colVals[k];
    if (need === undefined) { if (have !== undefined) wrong.push(k); }       // written but not needed
    else if (have !== need) wrong.push(k);
  }
  if (wrong.length === 0) return columnSolved();
  playGentleBlip();
  // Hint for the first thing wrong, reading ones-first, never the digit itself.
  const first = colOrder().find(k => wrong.includes(k)) || wrong[0];
  const col = +first.replace(/\D/g, '');
  let msg;
  const s = colSum;
  if (first.startsWith('ans')) {
    const t = s.top[col], b = s.bot[col];
    msg = s.op === '+'
      ? `Look at the ${COL_NAMES[col]}: ${t} + ${b}${col > 0 && s.need['car' + col] ? ' + the 1 you carried' : ''}. Is it 10 or more? Only the ones part goes in the answer.`
      : `Look at the ${COL_NAMES[col]}: ${t} ${unitWord(col, t)} minus ${b} ${unitWord(col, b)}. Are there enough ${COL_NAMES[col]}? If not, exchange from the ${COL_NAMES[col + 1] || 'next column'}.`;
  } else if (first.startsWith('car')) {
    msg = `Check the carry into the ${COL_NAMES[col]}. Was the sum in the ${COL_NAMES[col - 1]} column 10 or more? Only carry a 1 if it was.`;
  } else if (first.startsWith('ex')) {
    msg = `Check the ${COL_NAMES[col]}: when you exchange, 1 ${COL_UNIT[col]} moves to the next column. How many are left?`;
  } else {
    msg = `Check the ${COL_NAMES[col]}: an exchange gives that column an extra 10. Only write a 1 where it is needed.`;
  }
  const bad = wrong.length;
  setColMsg(`${bad === 1 ? 'One space needs' : bad + ' spaces need'} another look. ${msg}`, 'warn');
  refreshCells(wrong);
  if (colChecks >= 3) offerHelp(first);
}

function offerHelp(first) {
  const btn = document.getElementById('columns-show');
  btn.classList.remove('hidden');
  btn.onclick = () => {
    const need = requiredValue(first);
    if (need === undefined) delete colVals[first]; else colVals[first] = need;
    colMessy++;
    btn.classList.add('hidden');
    refreshCells();
    setColMsg('Now you have that one. Tap Check again!');
  };
}

function columnSolved() {
  colDone = true;
  const stars = colChecks === 1 ? 3 : colChecks === 2 ? 2 : 1;
  colStars += stars; colSolved++;
  addStars(stars);
  document.getElementById('columns-show').classList.add('hidden');
  refreshCells();
  renderColMat();
  playSuccessChime();
  const s = colSum;
  setColMsg(`Yes! ${s.topVal} ${s.op === '+' ? '+' : '−'} ${s.botVal} = ${s.ansVal}  ${'⭐'.repeat(stars)}`, 'ok');
  document.getElementById('columns-check').classList.add('hidden');
  document.getElementById('columns-keys').classList.add('hidden');
  const nx = document.getElementById('columns-next');
  nx.textContent = colSumNo >= COL_SUMS_PER_SESSION ? 'Finish!' : 'Next sum';
  nx.classList.remove('hidden');
}

function finishColumns() {
  lastCompletedGame = 'columns';
  playCompleteFanfare();
  const cols = loadCols();
  const good = colMessy === 0 ? colSolved >= 4 : colMessy <= 1 && colSolved >= 4;
  document.getElementById('complete-emoji').textContent = '➕➖⭐';
  document.getElementById('complete-title').textContent = `${colSolved} sums done!`;
  document.getElementById('complete-message').textContent =
    `You earned ${colStars} star${colStars === 1 ? '' : 's'} for the garden.` +
    (good && !cols.cleared.includes(colStage) ? ` Stage ${colStageIndex(colStage) + 1} cleared!` : '');
  document.getElementById('new-pig-reveal').classList.add('hidden');
  if (good && !cols.cleared.includes(colStage)) {
    cols.cleared.push(colStage);
    const i = colStageIndex(colStage);
    if (i < COL_STAGES.length - 1) { colStage = COL_STAGES[i + 1].id; cols.last = colStage; }
    saveCols(cols);
  }
  document.getElementById('complete-message').textContent += newWorldMessage();
  showScreen('screen-complete');
}

// ---- Wiring (this file loads before app.js, so wait for the DOM) ----
(function wire() {
  const pad = document.getElementById('columns-keys');
  function keyBtn(t, f, cls) {
    const b = document.createElement('button');
    b.className = 'ckey ' + (cls || ''); b.textContent = t;
    b.addEventListener('click', f);
    return b;
  }
  for (let d = 1; d <= 9; d++) pad.appendChild(keyBtn(String(d), () => typeDigit(d)));
  pad.appendChild(keyBtn('0', () => typeDigit(0)));
  pad.appendChild(keyBtn('⌫', deleteDigit, 'del'));
  document.getElementById('columns-check').addEventListener('click', checkColumnSum);
  document.getElementById('columns-next').addEventListener('click', nextColumnSum);
})();
