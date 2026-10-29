// ---- Colour Mixing: paint and light with the guinea pigs ----
// Clara (and Felix) mix paint in a bowl to match a colour card, then paint the
// guinea pigs' things with it: a hutch, a bow, a ball, their coats. Seven
// stages in teaching order: two primaries make a secondary; more of one colour
// than the other; tints and shades (white and black); guinea pig coats (brown
// from all three); warm and cool; opposite colours; and mixing light, which
// works the other way round from paint. Hints say which way the colour is off
// ("it needs to be bluer"), never the recipe; after three tries "Show me the
// recipe" fills the bowl. Loaded BEFORE app.js and uses its helpers
// (showScreen, chimes, guineaPigSvg, shuffle, addStars) only when called.

// ---- How paint really mixes ----
// Not RGB averaging, which turns blue + yellow into grey. Each paint is a
// reflectance curve across the rainbow (400-700 nm, every 10 nm), and paints
// mix by Kubelka-Munk: each paint's absorption (K/S) is averaged by how much of
// it is in the bowl times how strong a tint it is, turned back into a curve,
// and seen through the CIE colour-matching functions (Wyman's 2013 fit) as
// sRGB. Blue paint reflects blue and some green, yellow reflects green to red,
// so the only light both let through is green. The curve shapes and strengths
// were fitted so the mixes look like children's poster paint (29.10.26).
const PT_NM = []; for (let w = 400; w <= 700; w += 10) PT_NM.push(w);
const ptG = (x, m, s1, s2) => { const t = (x - m) / (x < m ? s1 : s2); return Math.exp(-0.5 * t * t); };
const ptSig = x => 1 / (1 + Math.exp(-x));
const PT_CMF = PT_NM.map(w => [
  1.056 * ptG(w, 599.8, 37.9, 31.0) + 0.362 * ptG(w, 442.0, 16.0, 26.7) - 0.065 * ptG(w, 501.1, 20.4, 26.2),
  0.821 * ptG(w, 568.8, 46.9, 40.5) + 0.286 * ptG(w, 530.9, 16.3, 31.1),
  1.217 * ptG(w, 437.0, 11.8, 36.0) + 0.681 * ptG(w, 459.0, 26.0, 13.8),
]);
const PAINTS = {
  r: { name: 'red',    strength: 0.458, curve: w => 0.03 + 0.6 * ptSig((w - 580) / 5) + 0.3 * ptG(w, 410, 18, 22) },
  y: { name: 'yellow', strength: 0.727, curve: w => 0.04 + 0.86 * ptSig((w - 500) / 4) },
  b: { name: 'blue',   strength: 0.196, curve: w => 0.03 + 0.613 * ptG(w, 458.6, 80, 40.3) },
  w: { name: 'white',  strength: 1,     curve: () => 0.93 },
  k: { name: 'black',  strength: 0.083, curve: () => 0.012 },
};
const PT_ORDER = ['r', 'y', 'b', 'w', 'k'];
const ptKS = r => (1 - r) * (1 - r) / (2 * r);
for (const p of PT_ORDER) PAINTS[p].ks = PT_NM.map(w => ptKS(PAINTS[p].curve(w)));

function ptLinear(refl) {
  let X = 0, Y = 0, Z = 0;
  refl.forEach((r, i) => { X += r * PT_CMF[i][0]; Y += r * PT_CMF[i][1]; Z += r * PT_CMF[i][2]; });
  return [3.2406 * X - 1.5372 * Y - 0.4986 * Z, -0.9689 * X + 1.8758 * Y + 0.0415 * Z, 0.0557 * X - 0.2040 * Y + 1.0570 * Z];
}
const PT_WHITE = ptLinear(PT_NM.map(() => 1));   // a perfect white comes out as (1, 1, 1)

// A recipe is { r: 2, y: 1 }: blobs of each paint. Returns sRGB 0-255, or null for an empty bowl.
function mixPaint(recipe) {
  let tot = 0;
  for (const p in recipe) tot += (recipe[p] || 0) * PAINTS[p].strength;
  if (!tot) return null;
  const refl = PT_NM.map((_, i) => {
    let ks = 0;
    for (const p in recipe) if (recipe[p]) ks += recipe[p] * PAINTS[p].strength / tot * PAINTS[p].ks[i];
    return 1 + ks - Math.sqrt(ks * ks + 2 * ks);
  });
  return ptLinear(refl).map((c, i) => {
    c = Math.max(0, Math.min(1, c / PT_WHITE[i]));
    return Math.round(255 * (c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055));
  });
}
const ptHex = c => '#' + c.map(v => v.toString(16).padStart(2, '0')).join('');

// How different two colours look (CIE Lab distance). Under PT_MATCH counts as a match.
function ptLab(c) {
  const [r, g, b] = c.map(v => { v /= 255; return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); });
  const f = t => t > 0.008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116;
  const X = f((0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.9505), Y = f(0.2126 * r + 0.7152 * g + 0.0722 * b),
    Z = f((0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.089);
  return [116 * Y - 16, 500 * (X - Y), 200 * (Y - Z)];
}
function ptDelta(a, b) { const A = ptLab(a), B = ptLab(b); return Math.hypot(A[0] - B[0], A[1] - B[1], A[2] - B[2]); }
const PT_MATCH = 6;
const PT_MAX_BLOBS = 10;

// ---- What to mix ----
// Every target is a recipe, but any mix that looks the same counts (two blue
// and two yellow is the same green as one and one).
const PT_TARGETS = {
  mix2: [
    { name: 'Green',  recipe: { b: 1, y: 1 }, fact: 'Blue and yellow make green!' },
    { name: 'Orange', recipe: { r: 1, y: 1 }, fact: 'Red and yellow make orange!' },
    { name: 'Purple', recipe: { r: 1, b: 1 }, fact: 'Red and blue make purple!' },
  ],
  more: [
    { name: 'Lime green', recipe: { y: 3, b: 1 }, fact: 'Lots of yellow and a little blue make a yellowy green: lime!' },
    { name: 'Sea green',  recipe: { b: 3, y: 1 }, fact: 'Lots of blue and a little yellow make a bluey green, like the sea.' },
    { name: 'Mango',      recipe: { y: 3, r: 1 }, fact: 'Lots of yellow and a little red make a sunny yellowy orange.' },
    { name: 'Tomato red', recipe: { r: 3, y: 1 }, fact: 'Lots of red and a little yellow make a reddy orange, like a tomato.' },
  ],
  tints: [
    { name: 'Pink',         recipe: { r: 1, w: 2 },       fact: 'Red and white make pink. Adding white makes a tint: a lighter colour.' },
    { name: 'Sky blue',     recipe: { b: 1, w: 2 },       fact: 'Blue and white make sky blue: a tint of blue.' },
    { name: 'Grey',         recipe: { k: 1, w: 3 },       fact: 'Black and white make grey.' },
    { name: 'Maroon',       recipe: { r: 3, k: 1 },       fact: 'Red and a little black make maroon. Adding black makes a shade: a darker colour.' },
    { name: 'Lilac',        recipe: { r: 1, b: 1, w: 3 }, fact: 'Purple and white make lilac: a tint of purple.' },
    { name: 'Forest green', recipe: { b: 2, y: 2, k: 1 }, fact: 'Green and a little black make dark forest green: a shade of green.' },
  ],
  // The farm pigs' invented colours. Evie (cream) is left out: no mix of these
  // five paints makes a true cream, it comes out lemon or peach.
  coats: [
    { name: 'Silver',    pig: 'Marshmallow',  recipe: { k: 1, w: 6 },             fact: 'A little black and lots of white make a light silvery grey.' },
    { name: 'Ginger',    pig: 'Butterscotch', recipe: { r: 1, y: 2, w: 1 },       fact: 'Orange and a little white make ginger.' },
    { name: 'Grey',      pig: 'Smokey',       recipe: { k: 1, w: 2 },             fact: 'Black and white make grey, like smoke.' },
    { name: 'Chocolate', pig: 'Biscuit',      recipe: { r: 1, y: 1, b: 1 },       fact: 'Red, yellow and blue all mixed together make brown!' },
    { name: 'Caramel',   pig: 'Pip',          recipe: { r: 1, y: 1, b: 1, w: 2 }, fact: 'Brown and white make caramel, a light brown.' },
  ],
};

// Warm and cool: shown as plain colours (not paint mixes) so each one is clear-cut.
const PT_WARM_COOL = [
  { name: 'Red', hex: '#e0322b', warm: true }, { name: 'Orange', hex: '#f28a1c', warm: true },
  { name: 'Yellow', hex: '#f6cf1d', warm: true }, { name: 'Golden', hex: '#e9a21a', warm: true },
  { name: 'Pinky red', hex: '#f2556f', warm: true },
  { name: 'Blue', hex: '#2a5bd7', warm: false }, { name: 'Sky blue', hex: '#6ec1f5', warm: false },
  { name: 'Turquoise', hex: '#19b3a6', warm: false }, { name: 'Green', hex: '#33a34a', warm: false },
  { name: 'Violet', hex: '#6a4bd0', warm: false },
];

// The colour wheel, clockwise from the top: opposites are three apart.
const PT_WHEEL = [
  { name: 'red', recipe: { r: 1 } }, { name: 'orange', recipe: { r: 1, y: 1 } },
  { name: 'yellow', recipe: { y: 1 } }, { name: 'green', recipe: { b: 1, y: 1 } },
  { name: 'blue', recipe: { b: 1 } }, { name: 'purple', recipe: { r: 1, b: 1 } },
];

// Mixing light: red, green and blue torches. paint is the same colours mixed as paint, for comparison.
const PT_LIGHTS = [
  { name: 'Yellow', hex: '#ffff00', on: 'rg', paint: { r: 2, b: 1, y: 1 },
    fact: 'Red and green light make yellow! Red and green paint would make brown.' },
  { name: 'Cyan', hex: '#00ffff', on: 'gb', paint: { b: 3, y: 1 },
    fact: 'Green and blue light make cyan, a bright sky blue.' },
  { name: 'Magenta', hex: '#ff00ff', on: 'rb', paint: { r: 1, b: 1 },
    fact: 'Red and blue light make magenta, a bright pink.' },
  { name: 'White', hex: '#ffffff', on: 'rgb', paint: { r: 1, y: 1, b: 1 },
    fact: 'All three lights together make white! All three paints together make brown.' },
];
const PT_TORCH = { r: { name: 'red', hex: '#ff0000' }, g: { name: 'green', hex: '#00ff00' }, b: { name: 'blue', hex: '#0000ff' } };

// ---- Stages ----
// Ids are what is saved (ttg_colours: cleared stages, last stage), so new
// stages get new ids. Clara sees each stage's position in this list.
const PT_STAGES = [
  { id: 1, kind: 'mix', pots: 'ryb', targets: 'mix2', label: 'Mixing two colours',
    intro: 'Red, yellow and blue are the primary colours: you can\'t mix them from other paints. Mix two of them to make a new colour!' },
  { id: 2, kind: 'mix', pots: 'ryb', targets: 'more', label: 'More of one colour',
    intro: 'Use more of one colour than the other. Count your blobs!' },
  { id: 3, kind: 'mix', pots: 'rybwk', targets: 'tints', label: 'Lighter and darker',
    intro: 'White makes a colour lighter: that\'s a tint. Black makes it darker: that\'s a shade. Black is strong, so use a little!' },
  { id: 4, kind: 'mix', pots: 'rybwk', targets: 'coats', label: 'Guinea pig coats',
    intro: 'Paint the guinea pigs\' coats! Here\'s a secret: red, yellow and blue all together make brown.' },
  { id: 5, kind: 'sort', label: 'Warm and cool',
    intro: 'Warm colours remind us of the sun and fire. Cool colours remind us of the sea and ice.' },
  { id: 6, kind: 'wheel', label: 'Opposite colours',
    intro: 'This is a colour wheel. Colours straight across from each other are opposites (complementary colours).' },
  { id: 7, kind: 'light', label: 'Mixing light',
    intro: 'Light mixes differently from paint! The primary colours of light are red, green and blue.' },
];
const ptStageIndex = id => Math.max(0, PT_STAGES.findIndex(s => s.id === id));
const ptStageDef = id => PT_STAGES[ptStageIndex(id)];
const PT_KEY = 'ttg_colours';
const PT_THINGS = ['hutch', 'bow', 'ball', 'cushion', 'tunnel'];
const PT_THING_WORD = { hutch: 'hutch', bow: 'bow', ball: 'ball', cushion: 'cushion', tunnel: 'tunnel' };
const PT_MORE = { r: 'redder', y: 'more yellow', b: 'bluer', w: 'lighter', k: 'darker' };
const PT_TOO = { r: 'too red', y: 'too yellow', b: 'too blue', w: 'too pale', k: 'too dark' };

function loadPaint() {
  try { return Object.assign({ cleared: [], last: 1 }, JSON.parse(localStorage.getItem(PT_KEY))); }
  catch { return { cleared: [], last: 1 }; }
}
function savePaint(s) { try { localStorage.setItem(PT_KEY, JSON.stringify(s)); } catch {} }

// ---- Game state ----
let ptStage = loadPaint().last;
let ptRounds = [], ptRoundNo = 0, ptStars = 0, ptHelped = 0;
let ptTries = 0, ptDone = false, ptRoundHelped = false;
let ptBowl = {}, ptAdded = [];   // the paint in the bowl, and the order it went in (for Undo)
let ptLit = {};                  // light stage: which torches are on
let ptSorted = [];               // warm and cool: what has been sorted this session

const ptRound = () => ptRounds[ptRoundNo - 1];
const aOrAn = w => (/^[aeiou]/i.test(w) ? 'an ' : 'a ') + w;
const ptPig = name => (typeof FARM_PIGS !== 'undefined' && FARM_PIGS.find(p => p.name === name)) || null;   // Pip has no filter

function ptBuildRounds(stage) {
  const pigs = ['Dreamy', 'Evie', 'Pip'];
  if (stage.kind === 'mix') {
    const pool = PT_TARGETS[stage.targets];
    let list = shuffle(pool);
    while (list.length < 5) {
      const t = pool[Math.floor(Math.random() * pool.length)];
      if (t !== list[list.length - 1]) list.push(t);
    }
    const things = shuffle(PT_THINGS);
    return list.slice(0, 5).map((t, i) => ({
      target: t,
      thing: stage.targets === 'coats' ? 'coat' : things[i % things.length],
      pig: t.pig || pigs[i % pigs.length],
    }));
  }
  if (stage.kind === 'sort') {
    const warm = shuffle(PT_WARM_COOL.filter(s => s.warm)).slice(0, 3);
    const cool = shuffle(PT_WARM_COOL.filter(s => !s.warm)).slice(0, 3);
    return shuffle([...warm, ...cool]).map((s, i) => ({ swatch: s, pig: pigs[i % pigs.length] }));
  }
  if (stage.kind === 'wheel') return shuffle(PT_WHEEL.map((_, i) => i)).slice(0, 5).map(i => ({ ask: i }));
  return shuffle(PT_LIGHTS).map(l => ({ light: l }));
}

function startColoursGame() {
  if (actx.state === 'suspended') actx.resume();
  ptRoundNo = 0; ptStars = 0; ptHelped = 0; ptSorted = [];
  ptRounds = ptBuildRounds(ptStageDef(ptStage));
  renderPtStages();
  showScreen('screen-colours');
  nextPtRound();
}

function renderPtStages() {
  const row = document.getElementById('colours-stages');
  const cleared = loadPaint().cleared;
  row.innerHTML = '';
  PT_STAGES.forEach((s, i) => {
    const b = document.createElement('button');
    b.className = 'stage-btn' + (s.id === ptStage ? ' active' : '') + (cleared.includes(s.id) ? ' cleared' : '');
    b.innerHTML = `<span class="stage-num">${i + 1}</span>${cleared.includes(s.id) ? '<span class="tick">✓</span>' : ''}`;
    b.addEventListener('click', () => {
      ptStage = s.id;
      const st = loadPaint(); st.last = s.id; savePaint(st);
      startColoursGame();
    });
    row.appendChild(b);
  });
  document.getElementById('colours-stages-caption').textContent =
    `Stage ${ptStageIndex(ptStage) + 1}: ${ptStageDef(ptStage).label}`;
}

function renderPtDots() {
  const d = document.getElementById('colours-dots');
  d.innerHTML = '';
  for (let i = 1; i <= ptRounds.length; i++) {
    const s = document.createElement('span');
    s.className = 'dot' + (i < ptRoundNo ? ' done' : '');
    d.appendChild(s);
  }
}

function setPtMsg(t, kind) {
  const m = document.getElementById('pt-msg');
  m.textContent = t;
  m.className = 'pt-msg' + (kind ? ' ' + kind : '');
}

// The buttons under the game: [label, onclick, class] each.
function setPtActions(list) {
  const box = document.getElementById('pt-actions');
  box.innerHTML = '';
  list.forEach(([label, f, cls]) => {
    const b = document.createElement('button');
    b.className = cls || 'big-btn';
    b.textContent = label;
    b.addEventListener('click', f);
    box.appendChild(b);
  });
}

function nextPtRound() {
  if (ptRoundNo >= ptRounds.length) return finishColours();
  ptRoundNo++;
  ptTries = 0; ptDone = false; ptRoundHelped = false;
  ptBowl = {}; ptAdded = []; ptLit = {};
  document.getElementById('pt-show').classList.add('hidden');
  renderPtDots();
  const stage = ptStageDef(ptStage);
  const intro = ptRoundNo === 1 ? stage.intro + ' ' : '';
  if (stage.kind === 'mix') renderPtMix(intro);
  else if (stage.kind === 'sort') renderPtSort(intro);
  else if (stage.kind === 'wheel') renderPtWheel(intro);
  else renderPtLight(intro);
}

// Stars for a round: 3 / 2 / 1 by tries for mixing (paint or light), 2 / 1 for
// the two-way warm-or-cool and the wheel. A "show me" round is always 1.
function ptRoundWon(msg) {
  ptDone = true;
  const kind = ptStageDef(ptStage).kind;
  const stars = ptRoundHelped ? 1
    : (kind === 'mix' || kind === 'light') ? Math.max(1, 4 - ptTries)
    : ptTries <= 1 ? 2 : 1;
  ptStars += stars;
  addStars(stars);
  if (ptRoundHelped) ptHelped++;
  document.getElementById('pt-show').classList.add('hidden');
  const pig = document.getElementById('pt-pig');
  if (pig) { pig.classList.remove('idle', 'happy'); void pig.offsetWidth; pig.classList.add('happy'); }
  playSuccessChime();
  setPtMsg(`${msg}  ${'⭐'.repeat(stars)}`, 'ok');
  setPtActions([[ptRoundNo >= ptRounds.length ? 'Finish!' : 'Next', nextPtRound]]);
}

function ptOfferShow(label, f) {
  const btn = document.getElementById('pt-show');
  btn.textContent = label;
  btn.classList.remove('hidden');
  btn.onclick = () => { ptRoundHelped = true; btn.classList.add('hidden'); f(); };
}

// ---- Pictures to paint ----
// The parts with class pt-fill take the paint; unpainted, they are pale with a dashed edge.
const PT_BLANK = '#f3efe6';
function ptThingSvg(kind) {
  const f = `class="pt-fill" fill="${PT_BLANK}" stroke="#6b4c2a" stroke-width="3" stroke-linejoin="round"`;
  const svg = body => `<svg viewBox="0 0 120 100" xmlns="http://www.w3.org/2000/svg">${body}</svg>`;
  if (kind === 'hutch') return svg(
    `<polygon points="6,42 60,6 114,42" fill="#9a6a3a" stroke="#6b4c2a" stroke-width="3" stroke-linejoin="round"/>
     <rect x="16" y="40" width="88" height="54" rx="4" ${f}/>
     <rect x="26" y="50" width="26" height="22" rx="3" fill="#dff1ff" stroke="#6b4c2a" stroke-width="2.5"/>
     <path d="M34.7 50v22M43.3 50v22M26 61h26" stroke="#6b4c2a" stroke-width="1.5"/>
     <path d="M66 94V68a13 13 0 0 1 26 0v26z" fill="#5a3d22"/>`);
  if (kind === 'bow') return svg(
    `<path d="M55 58 L46 96 L56 89 L62 97 L64 58z" ${f}/>
     <path d="M60 50 L14 20 Q2 50 14 80 Z" ${f}/>
     <path d="M60 50 L106 20 Q118 50 106 80 Z" ${f}/>
     <circle cx="60" cy="50" r="11" ${f}/>`);
  if (kind === 'ball') return svg(
    `<circle cx="60" cy="52" r="42" ${f}/>
     <path d="M24 34 Q60 58 96 34 M24 70 Q60 46 96 70" fill="none" stroke="rgba(255,255,255,0.55)" stroke-width="6"/>
     <ellipse cx="44" cy="28" rx="10" ry="6" fill="rgba(255,255,255,0.6)"/>`);
  if (kind === 'cushion') return svg(
    `<rect x="6" y="34" width="108" height="56" rx="26" ${f}/>
     <rect x="18" y="44" width="84" height="36" rx="16" fill="none" stroke="rgba(0,0,0,0.2)" stroke-width="2.5" stroke-dasharray="4 4"/>`);
  return svg(   // tunnel
    `<path d="M6 94V58a54 48 0 0 1 108 0v36H88V62a28 26 0 0 0-56 0v32z" ${f}/>
     <path d="M20 94V60M100 94V60" stroke="rgba(0,0,0,0.18)" stroke-width="3"/>
     <path d="M34 94V64a26 24 0 0 1 52 0v30z" fill="#4a3728"/>`);
}
// Her guinea pig drawing with the ginger patches made paintable (the coats stage).
function ptCoatSvg() {
  return '<div class="pig-tint">' + GUINEA_PIG_SVG.replace(/style="fill:#(FFA54B|FF8C46);"/g, `class="pt-fill" style="fill:${PT_BLANK};"`) + '</div>';
}
function ptApplyPaint(hex) {
  document.querySelectorAll('#pt-play .pt-fill').forEach(el => { el.style.fill = hex; el.classList.add('painted'); });
}

// ---- Mixing paint ----
function renderPtMix(intro) {
  const stage = ptStageDef(ptStage), r = ptRound(), t = r.target;
  const coat = r.thing === 'coat';
  const play = document.getElementById('pt-play');
  play.innerHTML = `
    <div class="pt-top">
      <div class="pt-card">
        <div class="pt-swatch" style="background:${ptHex(mixPaint(t.recipe))}"></div>
        <div class="pt-card-name">${t.name}</div>
      </div>
      <div class="pt-scene${coat ? ' coat' : ''}">
        <div class="pt-pig idle" id="pt-pig">${coat ? ptCoatSvg() : guineaPigSvg(ptPig(r.pig))}</div>
        ${coat ? '' : `<div class="pt-thing">${ptThingSvg(r.thing)}</div>`}
      </div>
    </div>
    <div class="pt-mixer">
      <div class="pt-bowl" id="pt-bowl"><div class="pt-paint" id="pt-paint"></div><span class="pt-bowl-word" id="pt-bowl-word">bowl</span></div>
      <div class="pt-drops" id="pt-drops"></div>
    </div>
    <div class="pt-pots" id="pt-pots"></div>`;
  const pots = document.getElementById('pt-pots');
  stage.pots.split('').forEach(p => {
    const b = document.createElement('button');
    b.className = 'pt-pot';
    b.setAttribute('aria-label', `Add a blob of ${PAINTS[p].name}`);
    b.innerHTML = `<span class="pt-jar" style="background:${ptHex(mixPaint({ [p]: 1 }))}"></span><span class="pt-pot-name">${PAINTS[p].name}</span>`;
    b.addEventListener('click', () => ptAddPaint(p));
    pots.appendChild(b);
  });
  renderPtBowl();
  setPtMsg(intro + (coat
    ? `Paint ${r.pig}'s coat ${t.name.toLowerCase()}. Mix paint to match the card!`
    : `${r.pig} would like ${aOrAn(t.name.toLowerCase())} ${PT_THING_WORD[r.thing]}. Mix paint to match the card!`));
  setPtActions([
    ['↶ Undo', ptUndo, 'pt-small-btn'],
    ['Empty', ptEmpty, 'pt-small-btn'],
    ['Paint it! 🖌️', ptPaint],
  ]);
}

const ptBlobs = () => ptAdded.length;
function renderPtBowl() {
  const c = mixPaint(ptBowl);
  const paint = document.getElementById('pt-paint');
  paint.style.background = c ? ptHex(c) : 'transparent';
  document.getElementById('pt-bowl').classList.toggle('empty', !c);
  document.getElementById('pt-bowl-word').textContent = c ? '' : 'bowl';
  const drops = document.getElementById('pt-drops');
  drops.innerHTML = '';
  ptAdded.forEach(p => {
    const d = document.createElement('span');
    d.className = 'pt-drop';
    d.style.background = ptHex(mixPaint({ [p]: 1 }));
    drops.appendChild(d);
  });
}
function ptStir() {
  const bowl = document.getElementById('pt-bowl');
  bowl.classList.remove('stir'); void bowl.offsetWidth; bowl.classList.add('stir');
}

function ptAddPaint(p) {
  if (ptDone) return;
  if (ptBlobs() >= PT_MAX_BLOBS) return setPtMsg('The bowl is full! Tap Undo to take some out, or Empty to start again.', 'warn');
  ptBowl[p] = (ptBowl[p] || 0) + 1;
  ptAdded.push(p);
  playTone(520 + 40 * PT_ORDER.indexOf(p), actx.currentTime, 0.12, 0.12);
  ptStir();
  renderPtBowl();
}
function ptUndo() {
  if (ptDone || !ptAdded.length) return;
  const p = ptAdded.pop();
  if (--ptBowl[p] === 0) delete ptBowl[p];
  playGentleBlip();
  renderPtBowl();
}
function ptEmpty() {
  if (ptDone) return;
  ptBowl = {}; ptAdded = [];
  playGentleBlip();
  renderPtBowl();
}

function ptPaint() {
  if (ptDone) return;
  if (!ptBlobs()) return setPtMsg('Put some paint in the bowl first: tap the paint pots.', 'warn');
  ptTries++;
  const t = ptRound().target, mine = mixPaint(ptBowl);
  ptApplyPaint(ptHex(mine));
  const d = ptDelta(mine, mixPaint(t.recipe));
  if (d <= PT_MATCH) return ptRoundWon(t.fact);
  playGentleBlip();
  setPtMsg(ptMixHint(d), 'warn');
  if (ptTries >= 3) ptOfferShow('Show me the recipe', () => {
    ptBowl = { ...t.recipe };
    ptAdded = [];
    PT_ORDER.forEach(p => { for (let i = 0; i < (t.recipe[p] || 0); i++) ptAdded.push(p); });
    renderPtBowl(); ptStir();
    setPtMsg(`Here's the recipe: ${ptRecipeWords(t.recipe)}. Now tap Paint it!`);
  });
}

function ptRecipeWords(rec) {
  const parts = PT_ORDER.filter(p => rec[p]).map(p => `${rec[p]} ${PAINTS[p].name}`);
  return parts.length > 1 ? parts.slice(0, -1).join(', ') + ' and ' + parts[parts.length - 1] : parts[0];
}

// Which way the colour is off, never the recipe. A paint the target doesn't use
// at all is named, since no amount of anything else will take it back out.
// Otherwise: try one blob more or one less of each paint in the recipe, and
// describe whichever change would bring it closest ("it needs to be bluer").
function ptMixHint(d) {
  const t = ptRound().target, want = mixPaint(t.recipe);
  const lead = d < 14 ? 'So close! ' : 'Not quite. ';
  const extra = PT_ORDER.find(p => ptBowl[p] && !t.recipe[p]);
  if (extra) return `${lead}This colour doesn't need any ${PAINTS[extra].name}. Tap Empty and try again.`;
  let best = null;
  const tryBowl = (move, p, bowl) => {
    const e = ptDelta(mixPaint(bowl), want);
    if (!best || e < best.e) best = { move, p, e };
  };
  PT_ORDER.filter(p => t.recipe[p]).forEach(p => {
    tryBowl('more', p, { ...ptBowl, [p]: (ptBowl[p] || 0) + 1 });
    if (ptBowl[p]) tryBowl('less', p, { ...ptBowl, [p]: ptBowl[p] - 1 });
  });
  if (best.move === 'more') return `${lead}Look at the card: it needs to be ${PT_MORE[best.p]}.`;
  return `${lead}Look at the card: yours is a bit ${PT_TOO[best.p]}.`;
}

// ---- Warm and cool ----
function renderPtSort(intro) {
  const r = ptRound(), s = r.swatch;
  const play = document.getElementById('pt-play');
  play.innerHTML = `
    <div class="pt-sort">
      <button class="pt-side warm" id="pt-warm"><span class="pt-side-head">☀️ Warm</span><span class="pt-basket" id="pt-warm-basket"></span></button>
      <div class="pt-mid">
        <div class="pt-blob" id="pt-blob" style="background:${s.hex}"></div>
        <div class="pt-blob-name">${s.name}</div>
        <div class="pt-pig small idle" id="pt-pig">${guineaPigSvg(ptPig(r.pig))}</div>
      </div>
      <button class="pt-side cool" id="pt-cool"><span class="pt-side-head">❄️ Cool</span><span class="pt-basket" id="pt-cool-basket"></span></button>
    </div>`;
  renderPtBaskets();
  document.getElementById('pt-warm').addEventListener('click', () => ptSortAs(true));
  document.getElementById('pt-cool').addEventListener('click', () => ptSortAs(false));
  setPtMsg(intro + `Is ${s.name.toLowerCase()} a warm colour or a cool colour? Tap its side.`);
  setPtActions([]);
}
function renderPtBaskets() {
  [true, false].forEach(warm => {
    const box = document.getElementById(warm ? 'pt-warm-basket' : 'pt-cool-basket');
    box.innerHTML = '';
    ptSorted.filter(s => s.warm === warm).forEach(s => {
      const c = document.createElement('span');
      c.className = 'pt-chip';
      c.style.background = s.hex;
      box.appendChild(c);
    });
  });
}
function ptSortAs(warm) {
  if (ptDone) return;
  const s = ptRound().swatch;
  ptTries++;
  if (warm !== s.warm) {
    playGentleBlip();
    const side = document.getElementById(warm ? 'pt-warm' : 'pt-cool');
    side.classList.remove('nope'); void side.offsetWidth; side.classList.add('nope');
    return setPtMsg(`Hmm, think again. Does ${s.name.toLowerCase()} remind you of sunshine and fire, or the sea and ice?`, 'warn');
  }
  ptSorted.push(s);
  document.getElementById('pt-blob').classList.add(warm ? 'fly-warm' : 'fly-cool');
  setTimeout(renderPtBaskets, 350);
  ptRoundWon(s.warm ? `Yes! ${s.name} is a warm colour, like the sun and fire.` : `Yes! ${s.name} is a cool colour, like the sea and ice.`);
}

// ---- Opposite colours (the colour wheel) ----
function ptArc(r0, r1, a0, a1) {
  const pt = (r, a) => { const t = a * Math.PI / 180; return `${(110 + r * Math.sin(t)).toFixed(1)} ${(110 - r * Math.cos(t)).toFixed(1)}`; };
  return `M${pt(r1, a0)} A${r1} ${r1} 0 0 1 ${pt(r1, a1)} L${pt(r0, a1)} A${r0} ${r0} 0 0 0 ${pt(r0, a0)}Z`;
}
function renderPtWheel(intro) {
  const ask = ptRound().ask;
  const play = document.getElementById('pt-play');
  const segs = PT_WHEEL.map((c, i) =>
    `<path class="pt-seg${i === ask ? ' ask' : ''}" data-i="${i}" d="${ptArc(34, 100, i * 60 - 30, i * 60 + 30)}" fill="${ptHex(mixPaint(c.recipe))}"/>`).join('');
  play.innerHTML = `
    <div class="pt-wheel-wrap">
      <svg class="pt-wheel" id="pt-wheel" viewBox="0 0 220 220" xmlns="http://www.w3.org/2000/svg">
        ${segs}
        <line id="pt-wheel-line" class="pt-wheel-line hidden" x1="110" y1="110" x2="110" y2="110"/>
        <circle cx="110" cy="110" r="24" fill="#fffdf7"/>
        <text x="110" y="120" text-anchor="middle" class="pt-wheel-q" id="pt-wheel-q">?</text>
      </svg>
      <div class="pt-pair hidden" id="pt-pair"></div>
    </div>`;
  play.querySelectorAll('.pt-seg').forEach(seg => seg.addEventListener('click', () => ptWheelTap(+seg.dataset.i, seg)));
  setPtMsg(intro + `Which colour is opposite ${PT_WHEEL[ask].name}? Tap it.`);
  setPtActions([]);
}
// A line from the asked colour, through the middle, to the far side.
function ptWheelLine(from, dashed) {
  const a = from * 60 * Math.PI / 180, l = document.getElementById('pt-wheel-line');
  l.setAttribute('x1', 110 + 72 * Math.sin(a)); l.setAttribute('y1', 110 - 72 * Math.cos(a));
  l.setAttribute('x2', 110 - 72 * Math.sin(a)); l.setAttribute('y2', 110 + 72 * Math.cos(a));
  l.classList.toggle('dashed', !!dashed);
  l.classList.remove('hidden');
}
function ptWheelTap(i, seg) {
  if (ptDone) return;
  const ask = ptRound().ask, opp = (ask + 3) % 6;
  if (i === ask) return setPtMsg(`That's ${PT_WHEEL[ask].name} itself! Find the colour on the other side of the wheel.`, 'warn');
  ptTries++;
  if (i !== opp) {
    playGentleBlip();
    seg.classList.remove('nope'); void seg.getBoundingClientRect(); seg.classList.add('nope');
    if (ptTries >= 2) {
      ptRoundHelped = true;
      ptWheelLine(ask, true);
      return setPtMsg(`Follow the dotted line from ${PT_WHEEL[ask].name}, through the middle, to the other side.`, 'warn');
    }
    return setPtMsg(`Not that one. Opposites sit straight across the wheel, on the other side of the middle.`, 'warn');
  }
  seg.classList.add('ask');
  ptWheelLine(ask, false);
  document.getElementById('pt-wheel-q').textContent = '✓';
  // The two mixed in equal amounts, as paint: opposites always make a muddy brown or grey.
  const A = PT_WHEEL[ask], B = PT_WHEEL[opp], both = {};
  const nA = Object.values(A.recipe).reduce((s, v) => s + v, 0), nB = Object.values(B.recipe).reduce((s, v) => s + v, 0);
  for (const p in A.recipe) both[p] = (both[p] || 0) + A.recipe[p] * nB;
  for (const p in B.recipe) both[p] = (both[p] || 0) + B.recipe[p] * nA;
  const chip = rec => `<span class="pt-chip big" style="background:${ptHex(mixPaint(rec))}"></span>`;
  const pair = document.getElementById('pt-pair');
  pair.innerHTML = `${chip(A.recipe)}<span>+</span>${chip(B.recipe)}<span>=</span>${chip(both)}<em>mixed as paint</em>`;
  pair.classList.remove('hidden');
  const cap = s => s[0].toUpperCase() + s.slice(1);
  ptRoundWon(`${cap(A.name)} and ${B.name} are opposites! Side by side, each makes the other look brighter. Mixed together, they make a muddy brown.`);
}

// ---- Mixing light ----
// Three torches shine on a dark wall. The beams add up (CSS mix-blend-mode:
// screen, which is how light really adds): red and green overlap as yellow,
// and all three make white in the middle.
function renderPtLight(intro) {
  const l = ptRound().light;
  const play = document.getElementById('pt-play');
  play.innerHTML = `
    <div class="pt-top">
      <div class="pt-card dark">
        <div class="pt-swatch" style="background:${l.hex};box-shadow:0 0 18px ${l.hex}"></div>
        <div class="pt-card-name">${l.name}</div>
      </div>
      <div class="pt-wall" id="pt-wall">
        <div class="pt-beam r"></div><div class="pt-beam g"></div><div class="pt-beam b"></div>
        <div class="pt-pig small idle" id="pt-pig">${guineaPigSvg(ptPig('Evie'))}</div>
      </div>
    </div>
    <div class="pt-torches" id="pt-torches"></div>
    <div class="pt-pair hidden" id="pt-pair"></div>`;
  const box = document.getElementById('pt-torches');
  'rgb'.split('').forEach(c => {
    const b = document.createElement('button');
    b.className = 'pt-torch';
    b.dataset.c = c;
    b.setAttribute('aria-pressed', 'false');
    b.innerHTML = `<span class="pt-lens" style="background:${PT_TORCH[c].hex}"></span>${PT_TORCH[c].name}`;
    b.addEventListener('click', () => ptToggleTorch(c));
    box.appendChild(b);
  });
  setPtMsg(intro + `Switch on torches to make ${l.name.toLowerCase()} light where they meet.`);
  setPtActions([["That's it! ✓", ptCheckLight]]);
}
function renderPtTorches() {
  document.querySelectorAll('.pt-torch').forEach(b => b.setAttribute('aria-pressed', ptLit[b.dataset.c] ? 'true' : 'false'));
  'rgb'.split('').forEach(c => document.querySelector('.pt-beam.' + c).classList.toggle('on', !!ptLit[c]));
}
function ptToggleTorch(c) {
  if (ptDone) return;
  ptLit[c] = !ptLit[c];
  playTone(ptLit[c] ? 880 : 440, actx.currentTime, 0.1, 0.1);
  renderPtTorches();
}
function ptCheckLight() {
  if (ptDone) return;
  const l = ptRound().light;
  const on = 'rgb'.split('').filter(c => ptLit[c]);
  if (!on.length) return setPtMsg('Tap a torch to switch it on.', 'warn');
  ptTries++;
  const extra = on.filter(c => !l.on.includes(c)).length, missing = l.on.split('').filter(c => !ptLit[c]).length;
  if (!extra && !missing) {
    const pair = document.getElementById('pt-pair');
    pair.innerHTML = `<em>The same colours mixed as paint:</em><span class="pt-chip big" style="background:${ptHex(mixPaint(l.paint))}"></span>`;
    pair.classList.remove('hidden');
    return ptRoundWon(l.fact);
  }
  playGentleBlip();
  setPtMsg(extra && !missing ? 'Lovely glow! But one torch is too many. Which could you switch off?'
    : missing && !extra ? 'Nearly! Switch on another torch too.'
    : 'Look at the card, then try a different pair of torches.', 'warn');
  if (ptTries >= 3) ptOfferShow('Show me', () => {
    ptLit = {}; l.on.split('').forEach(c => { ptLit[c] = true; });
    renderPtTorches();
    setPtMsg(`It's the ${l.on.split('').map(c => PT_TORCH[c].name).join(' and ')} torches. Now tap That's it!`);
  });
}

// ---- Finish ----
function finishColours() {
  lastCompletedGame = 'colours';
  playCompleteFanfare();
  const st = loadPaint();
  const fresh = ptHelped <= 1 && !st.cleared.includes(ptStage);
  document.getElementById('complete-emoji').textContent = '🎨🐹⭐';
  document.getElementById('complete-title').textContent = ptStageDef(ptStage).kind === 'light' ? 'What a light show!' : 'Beautiful colours!';
  document.getElementById('complete-message').textContent =
    `You earned ${ptStars} star${ptStars === 1 ? '' : 's'} for the garden.` +
    (fresh ? ` Stage ${ptStageIndex(ptStage) + 1} cleared!` : '');
  document.getElementById('new-pig-reveal').classList.add('hidden');
  if (fresh) {
    st.cleared.push(ptStage);
    const i = ptStageIndex(ptStage);
    if (i < PT_STAGES.length - 1) { ptStage = PT_STAGES[i + 1].id; st.last = ptStage; }
    savePaint(st);
  }
  document.getElementById('complete-message').textContent += newWorldMessage();
  showScreen('screen-complete');
}
