// ---- Stage definitions ----
// Cumulative: each stage adds one new table to the pool built up so far,
// per the requested teaching order (1,2,5,10 are the easy "main focus"
// starting point, then one harder table introduced per stage).
const STAGES = [
  { id: 1, tables: [1, 2, 5, 10], label: '1, 2, 5 & 10' },
  { id: 2, tables: [1, 2, 5, 10, 3], label: '+ the 3 times table' },
  { id: 3, tables: [1, 2, 5, 10, 3, 4], label: '+ the 4 times table' },
  { id: 4, tables: [1, 2, 5, 10, 3, 4, 9], label: '+ the 9 times table' },
  { id: 5, tables: [1, 2, 5, 10, 3, 4, 9, 8], label: '+ the 8 times table' },
  { id: 6, tables: [1, 2, 5, 10, 3, 4, 9, 8, 6], label: '+ the 6 times table' },
  { id: 7, tables: [1, 2, 5, 10, 3, 4, 9, 8, 6, 7], label: '+ the 7 times table - all done!' },
];
const MAX_MULTIPLIER = 12;
const ROUNDS_PER_SESSION = 8;
// A stage counts as "cleared" (and unlocks its guinea pig) once this many
// correct answers land in a single session - matches the "8 in a row"
// completion convention used across the sibling Nuggets/Phonics apps.
const ROUNDS_TO_CLEAR_STAGE = 8;

// ---- Guinea pig farm - 7 collectible pigs, one per stage ----
const FARM_PIGS = [
  { id: 1, name: 'Butterscotch', body: '#d99a4e', accent: '#fdf1de', patch: null },
  { id: 2, name: 'Domino', body: '#ffffff', accent: '#f2ede0', patch: '#8a5a34' },
  { id: 3, name: 'Smokey', body: '#9a9a9e', accent: '#e8e8ea', patch: null },
  { id: 4, name: 'Panda', body: '#2b2b2e', accent: '#efefef', patch: '#ffffff' },
  { id: 5, name: 'Marmalade', body: '#e2783a', accent: '#fde3d0', patch: null },
  { id: 6, name: 'Marshmallow', body: '#f7f0e3', accent: '#ffffff', patch: null },
  { id: 7, name: 'Biscuit', body: '#c98a52', accent: '#fbeedb', patch: '#5c3a22' },
];

// ---- Guinea pig SVG (simple flat shape, matches the reward-animal style) ----
function guineaPigSvg(pig, opts = {}) {
  const { happy = false } = opts;
  const patch = pig.patch
    ? `<ellipse cx="62" cy="55" rx="16" ry="14" fill="${pig.patch}" />`
    : '';
  const mouth = happy
    ? `<path d="M42 66 Q50 72 58 66" stroke="#3a2a1c" stroke-width="2.5" fill="none" stroke-linecap="round" />`
    : `<line x1="46" y1="66" x2="54" y2="66" stroke="#3a2a1c" stroke-width="2.5" stroke-linecap="round" />`;
  return `<svg viewBox="0 0 100 80" class="pig-svg">
    <ellipse cx="50" cy="50" rx="38" ry="26" fill="${pig.body}" />
    ${patch}
    <ellipse cx="50" cy="56" rx="20" ry="12" fill="${pig.accent}" />
    <ellipse cx="24" cy="52" rx="7" ry="5" fill="${pig.body}" />
    <ellipse cx="76" cy="52" rx="7" ry="5" fill="${pig.body}" />
    <ellipse cx="22" cy="24" rx="7" ry="6" fill="${pig.body}" />
    <ellipse cx="22" cy="24" rx="3.5" ry="3" fill="${pig.accent}" />
    <ellipse cx="42" cy="22" rx="7" ry="6" fill="${pig.body}" />
    <ellipse cx="42" cy="22" rx="3.5" ry="3" fill="${pig.accent}" />
    <circle cx="20" cy="34" r="4" fill="#1a1a1a" />
    <circle cx="21" cy="33" r="1.3" fill="#fff" />
    <circle cx="44" cy="34" r="4" fill="#1a1a1a" />
    <circle cx="45" cy="33" r="1.3" fill="#fff" />
    <ellipse cx="32" cy="42" rx="4" ry="3" fill="#3a2a1c" />
    ${mouth}
  </svg>`;
}

// ---- Progress persistence ----
const STORAGE_KEY = 'ttg_progress';
function loadProgress() {
  try { return JSON.parse(localStorage.getItem(STORAGE_KEY)) || { clearedStages: [] }; }
  catch { return { clearedStages: [] }; }
}
function saveProgress(p) { localStorage.setItem(STORAGE_KEY, JSON.stringify(p)); }

function renderFarm() {
  const progress = loadProgress();
  const grid = document.getElementById('farm-grid');
  grid.innerHTML = '';
  FARM_PIGS.forEach(pig => {
    const unlocked = progress.clearedStages.includes(pig.id);
    const slot = document.createElement('div');
    slot.className = 'farm-slot' + (unlocked ? '' : ' locked');
    slot.innerHTML = unlocked ? guineaPigSvg(pig, { happy: true }) : '<span class="lock-icon">🔒</span>';
    const label = document.createElement('div');
    label.className = 'farm-slot-label';
    label.textContent = unlocked ? pig.name : `Stage ${pig.id}`;
    const wrap = document.createElement('div');
    wrap.className = 'farm-slot-wrap';
    wrap.appendChild(slot);
    wrap.appendChild(label);
    grid.appendChild(wrap);
  });
}

// ---- Chime sounds (synthesized, no assets needed) ----
const actx = new (window.AudioContext || window.webkitAudioContext)();
function playTone(freq, startTime, duration, gainPeak = 0.2) {
  const osc = actx.createOscillator();
  const gain = actx.createGain();
  osc.type = 'sine';
  osc.frequency.value = freq;
  osc.connect(gain);
  gain.connect(actx.destination);
  gain.gain.setValueAtTime(0, startTime);
  gain.gain.linearRampToValueAtTime(gainPeak, startTime + 0.02);
  gain.gain.exponentialRampToValueAtTime(0.001, startTime + duration);
  osc.start(startTime);
  osc.stop(startTime + duration);
}
function playSuccessChime() {
  const now = actx.currentTime;
  playTone(523.25, now, 0.18);
  playTone(659.25, now + 0.1, 0.22);
  playTone(783.99, now + 0.2, 0.3);
}
function playCompleteFanfare() {
  const now = actx.currentTime;
  [523.25, 587.33, 659.25, 783.99, 1046.5].forEach((f, i) => playTone(f, now + i * 0.12, 0.3, 0.18));
}
function playGentleBlip() {
  const now = actx.currentTime;
  playTone(300, now, 0.15, 0.12);
}

// ---- Navigation ----
function showScreen(id) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  document.getElementById(id).classList.add('active');
}
document.querySelectorAll('.game-tile').forEach(btn => {
  btn.addEventListener('click', () => {
    if (actx.state === 'suspended') actx.resume();
    const game = btn.dataset.game;
    if (game === 'feed') startFeedGame();
    if (game === 'jigsaw') startJigsawGame();
  });
});
document.querySelectorAll('[data-back]').forEach(btn => {
  btn.addEventListener('click', () => { renderFarm(); showScreen('screen-home'); });
});
document.getElementById('home-btn').addEventListener('click', () => { renderFarm(); showScreen('screen-home'); });

let lastCompletedGame = null;
document.getElementById('play-again-btn').addEventListener('click', () => {
  if (lastCompletedGame === 'feed') startFeedGame();
  else startJigsawGame();
});

// ---- Question generation ----
function generateQuestion(tables) {
  const table = tables[Math.floor(Math.random() * tables.length)];
  const multiplier = 1 + Math.floor(Math.random() * MAX_MULTIPLIER);
  const product = table * multiplier;

  const distractors = new Set();
  const candidates = [
    table * (multiplier + 1),
    table * (multiplier - 1),
    (table + 1) * multiplier,
    (table - 1) * multiplier,
    product + table,
    product - table,
  ].filter(n => n > 0 && n !== product);
  shuffle(candidates);
  for (const c of candidates) {
    if (distractors.size >= 2) break;
    distractors.add(c);
  }
  while (distractors.size < 2) {
    const fallback = product + (Math.floor(Math.random() * 10) + 1) * (Math.random() < 0.5 ? 1 : -1);
    if (fallback > 0 && fallback !== product) distractors.add(fallback);
  }

  const options = shuffle([product, ...distractors]);
  return { table, multiplier, product, options };
}

function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ---- Stage selector (shared row builder for both games) ----
let feedStage = 1;
let jigsawStage = 1;

function renderStageRow(containerId, activeStage, onSelect) {
  const wrap = document.getElementById(containerId);
  wrap.innerHTML = '';
  STAGES.forEach(s => {
    const btn = document.createElement('button');
    btn.className = 'stage-btn' + (s.id === activeStage ? ' active' : '');
    btn.textContent = s.id;
    btn.title = s.label;
    btn.addEventListener('click', () => onSelect(s.id));
    wrap.appendChild(btn);
  });
}

// ---- Feed Pip ----
let feedRound = 0;
let feedCorrectStreak = 0;
let feedQuestion = null;

function startFeedGame() {
  feedRound = 0;
  feedCorrectStreak = 0;
  renderStageRow('feed-stages', feedStage, (id) => { feedStage = id; startFeedGame(); });
  renderFeedDots();
  showScreen('screen-feed');
  nextFeedRound();
}

function renderFeedDots() {
  const wrap = document.getElementById('feed-dots');
  wrap.innerHTML = '';
  for (let i = 0; i < ROUNDS_PER_SESSION; i++) {
    const dot = document.createElement('div');
    dot.className = 'dot';
    wrap.appendChild(dot);
  }
}

function nextFeedRound() {
  if (feedRound >= ROUNDS_PER_SESSION) {
    finishSession('feed');
    return;
  }
  const stage = STAGES.find(s => s.id === feedStage);
  feedQuestion = generateQuestion(stage.tables);

  document.getElementById('feed-question').textContent = `${feedQuestion.table} × ${feedQuestion.multiplier} = ?`;
  const choicesWrap = document.getElementById('feed-choices');
  choicesWrap.innerHTML = '';
  feedQuestion.options.forEach(n => {
    const btn = document.createElement('button');
    btn.className = 'choice-btn';
    btn.textContent = n;
    btn.addEventListener('click', () => handleFeedAnswer(n, btn));
    choicesWrap.appendChild(btn);
  });
  document.getElementById('feed-pip').innerHTML = guineaPigSvg(FARM_PIGS[0], { happy: false });
}

function handleFeedAnswer(n, btn) {
  const pip = document.getElementById('feed-pip');
  if (n === feedQuestion.product) {
    btn.classList.add('correct-flash');
    pip.innerHTML = guineaPigSvg(FARM_PIGS[0], { happy: true });
    pip.classList.add('munch');
    playSuccessChime();
    document.querySelectorAll('#feed-dots .dot')[feedRound].classList.add('done');
    feedRound++;
    feedCorrectStreak++;
    setTimeout(() => {
      pip.classList.remove('munch');
      nextFeedRound();
    }, 700);
  } else {
    btn.classList.add('wrong-flash');
    feedCorrectStreak = 0;
    playGentleBlip();
    setTimeout(() => btn.classList.remove('wrong-flash'), 400);
  }
}

// ---- Guinea Pig Jigsaw ----
// Real photos, not drawn SVGs - one dedicated picture per stage, so each
// stage has its own distinct picture to reveal rather than a random draw.
// To swap or add pictures: drop the file in images/ and update the entry
// for that stage number below.
const JIGSAW_IMAGES = {
  1: { file: 'images/images.jpg', name: 'a guinea pig in the straw' },
  2: { file: 'images/images-2.jpg', name: 'a white guinea pig' },
  3: { file: 'images/images-1.jpg', name: 'a guinea pig in the grass' },
  4: { file: 'images/images-4.jpg', name: 'a fluffy long-haired guinea pig' },
  5: { file: 'images/gpig8.webp', name: 'two guinea pigs together' },
  6: { file: 'images/images-5.jpg', name: 'a guinea pig having a snack' },
  7: { file: 'images/images-3.jpg', name: 'three guinea pigs having a feast' },
};
let jigsawRound = 0;
let jigsawQuestion = null;
let jigsawTilesLeft = [];
let currentJigsawImage = null;

function startJigsawGame() {
  jigsawRound = 0;
  currentJigsawImage = JIGSAW_IMAGES[jigsawStage];

  document.getElementById('jigsaw-pic').innerHTML = `<img src="${currentJigsawImage.file}" alt="${currentJigsawImage.name}">`;
  renderStageRow('jigsaw-stages', jigsawStage, (id) => { jigsawStage = id; startJigsawGame(); });
  renderJigsawGrid();
  showScreen('screen-jigsaw');
  nextJigsawRound();
}

function renderJigsawGrid() {
  const grid = document.getElementById('jigsaw-grid');
  grid.innerHTML = '';
  jigsawTilesLeft = [];
  for (let i = 0; i < 6; i++) {
    const tile = document.createElement('div');
    tile.className = 'jigsaw-tile';
    tile.textContent = '?';
    grid.appendChild(tile);
    jigsawTilesLeft.push(tile);
  }
}

function nextJigsawRound() {
  // Only ever called when there's at least one tile left to reveal - the
  // picture being fully uncovered is what ends the session, not a fixed
  // round count (see handleJigsawAnswer).
  const stage = STAGES.find(s => s.id === jigsawStage);
  jigsawQuestion = generateQuestion(stage.tables);

  document.getElementById('jigsaw-question').textContent = `${jigsawQuestion.table} × ${jigsawQuestion.multiplier} = ?`;
  const choicesWrap = document.getElementById('jigsaw-choices');
  choicesWrap.innerHTML = '';
  jigsawQuestion.options.forEach(n => {
    const btn = document.createElement('button');
    btn.className = 'choice-btn';
    btn.textContent = n;
    btn.addEventListener('click', () => handleJigsawAnswer(n, btn));
    choicesWrap.appendChild(btn);
  });
}

function handleJigsawAnswer(n, btn) {
  if (n === jigsawQuestion.product) {
    btn.classList.add('correct-flash');
    playSuccessChime();
    const tile = jigsawTilesLeft.splice(Math.floor(Math.random() * jigsawTilesLeft.length), 1)[0];
    tile.classList.add('revealed');
    jigsawRound++;
    if (jigsawTilesLeft.length === 0) {
      // Picture fully revealed - that's the achievement, session ends here.
      setTimeout(() => finishSession('jigsaw'), 700);
    } else {
      setTimeout(nextJigsawRound, 700);
    }
  } else {
    btn.classList.add('wrong-flash');
    playGentleBlip();
    setTimeout(() => btn.classList.remove('wrong-flash'), 400);
  }
}

// ---- Completion ----
function finishSession(game) {
  lastCompletedGame = game;
  playCompleteFanfare();
  const title = document.getElementById('complete-title');
  const message = document.getElementById('complete-message');
  const reveal = document.getElementById('new-pig-reveal');
  reveal.classList.add('hidden');

  const stage = game === 'feed' ? feedStage : jigsawStage;
  // Feed Pip has no natural end point, so clearing the stage there still
  // needs a streak threshold. The jigsaw's own picture being fully
  // revealed already IS the achievement - no separate threshold needed.
  const stageCleared = game === 'feed'
    ? feedCorrectStreak >= ROUNDS_TO_CLEAR_STAGE
    : true;

  if (game === 'feed') {
    title.textContent = 'Pip is full!';
    message.textContent = 'Great counting - every carrot earned!';
  } else {
    title.textContent = 'Picture complete!';
    message.textContent = `You matched every answer to reveal ${currentJigsawImage.name}!`;
  }

  if (stageCleared) {
    const progress = loadProgress();
    if (!progress.clearedStages.includes(stage)) {
      progress.clearedStages.push(stage);
      saveProgress(progress);
      const pig = FARM_PIGS.find(p => p.id === stage);
      document.getElementById('new-pig-avatar').innerHTML = guineaPigSvg(pig, { happy: true });
      document.getElementById('new-pig-name').textContent = pig.name;
      reveal.classList.remove('hidden');
    }
    // Move on to the next stage automatically, same as the auto-advance
    // pattern used across the sibling Nuggets/Phonics apps.
    if (game === 'jigsaw' && jigsawStage < STAGES.length) {
      jigsawStage++;
    }
  }

  showScreen('screen-complete');
}

// ---- Init ----
renderFarm();
