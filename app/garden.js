// ---- Guinea Pig Garden: the 3D reward world (Three.js) ----
// Stars earned in every game (see addStars in columns.js) are spent here on
// things for the garden. Her guinea pigs (the ones she has unlocked on the
// farm) wander about in it; tap one and it squeaks. Everything is built from
// simple shapes in code, so there are no model files to load.
//
// Other worlds float in the sky round the garden: Beach Island, Snowy
// Mountain, Candy Land and the Moon. They open as she gets better -- each needs
// a number of stages cleared across all her games (times tables and column
// maths, see skillScore) -- and a rainbow bridge then joins it to the garden.
// Tap an open island to go there; each world has its own shop and keeps its
// own things. Saved in localStorage ('ttg_garden').
//
// Three.js r128 (global build) is loaded from a CDN on first visit.

const GARDEN_KEY = 'ttg_garden';
const THREE_URL = 'https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js';
const ITEM_DEFS = {
  // garden
  flowers: ['Flowers', '🌸', 2], sunflower: ['Sunflower', '🌻', 3], bush: ['Bush', '🌿', 3], carrots: ['Carrots', '🥕', 4],
  hay: ['Hay bale', '🌾', 3], ball: ['Ball', '🔴', 4], tree: ['Tree', '🌳', 5], tunnel: ['Tunnel', '🕳️', 6],
  pond: ['Pond', '💧', 10], hutch: ['Hutch', '🏠', 12], rainbow: ['Rainbow', '🌈', 15],
  // beach
  shell: ['Shell', '🐚', 2], starfish: ['Starfish', '⭐', 2], beachball: ['Beach ball', '🏐', 3], umbrella: ['Umbrella', '⛱️', 5],
  palm: ['Palm tree', '🌴', 5], rockpool: ['Rock pool', '🦀', 7], castle: ['Sandcastle', '🏰', 8], boat: ['Boat', '⛵', 12],
  // snow
  snowpile: ['Snowballs', '❄️', 2], icecrystal: ['Ice crystal', '💎', 3], sledge: ['Sledge', '🛷', 4], snowpine: ['Snowy pine', '🌲', 5],
  penguin: ['Penguin', '🐧', 6], snowman: ['Snowman', '⛄', 8], igloo: ['Igloo', '🛖', 12],
  // candy
  gumdrop: ['Gumdrops', '🍬', 2], lollipop: ['Lollipop', '🍭', 3], candycane: ['Candy cane', '🦯', 4], donut: ['Doughnut', '🍩', 4],
  icecream: ['Ice cream', '🍦', 5], cupcake: ['Cupcake', '🧁', 6], cake: ['Big cake', '🎂', 12],
  // moon
  moonrock: ['Moon rock', '🪨', 2], starlamp: ['Star', '🌟', 3], flag: ['Flag', '🚩', 4], alienplant: ['Alien plant', '🌱', 5],
  dish: ['Space dish', '📡', 7], ufo: ['UFO', '🛸', 10], rocket: ['Rocket', '🚀', 15],
};
const WORLDS = [
  { id: 'garden', name: 'the Garden', need: 0, ground: 0x7ccf5a, rim: 0x8a6a3d, sky: 0xbfe6ff, tuft: 0x5fb847, rock: 0x8a6a3d,
    items: ['flowers', 'sunflower', 'bush', 'carrots', 'hay', 'ball', 'tree', 'tunnel', 'pond', 'hutch', 'rainbow'] },
  { id: 'beach', name: 'Beach Island', need: 7, ground: 0xf2d98b, rim: 0xe8c56a, sky: 0x9fe0ff, tuft: 0xd9b866, rock: 0xa98a5a,
    items: ['shell', 'starfish', 'beachball', 'umbrella', 'palm', 'rockpool', 'castle', 'boat'] },
  { id: 'snow', name: 'Snowy Mountain', need: 9, ground: 0xf4f8ff, rim: 0xbcd6ec, sky: 0xd5e5f4, tuft: 0xdfe9f5, rock: 0x8d9fb3,
    items: ['snowpile', 'icecrystal', 'sledge', 'snowpine', 'penguin', 'snowman', 'igloo'] },
  { id: 'candy', name: 'Candy Land', need: 11, ground: 0xff9fc8, rim: 0xff7fb3, sky: 0xffe9f6, tuft: 0xff9ccc, rock: 0xb07a5a,
    items: ['gumdrop', 'lollipop', 'candycane', 'donut', 'icecream', 'cupcake', 'cake'] },
  { id: 'moon', name: 'the Moon', need: 14, ground: 0xc3c3cc, rim: 0x8b8b99, sky: 0x141a33, tuft: 0xa9a9b5, rock: 0x6d6d78,
    items: ['moonrock', 'starlamp', 'flag', 'alienplant', 'dish', 'ufo', 'rocket'] },
];
const PIG_COLOURS = { // body, belly/patch
  1: [0x6b5b4e, 0xf0e6d6], 2: [0xf3e2b3, 0xffffff], 3: [0xc98a4b, 0xf6e3c4], 4: [0x7d7d80, 0xe9e9e9],
  5: [0xe0792a, 0xffe2c0], 6: [0xf4f4f0, 0xffffff], 7: [0xa8794e, 0xf1dfc0], 0: [0xd9a15f, 0xfff0d8],
};

let gardenState = null;    // everything three.js; null until first visit
let gardenSel = null;      // selected shop item id, or 'remove'

function loadGarden() {
  let g;
  try { g = JSON.parse(localStorage.getItem(GARDEN_KEY)); } catch {}
  g = g || {};
  if (!g.worlds) g.worlds = { garden: g.items || [] };     // the first version had just one garden
  delete g.items;
  g.spent = g.spent || 0;
  g.at = g.at || 'garden';
  g.opened = g.opened || ['garden'];   // bridges already built (and celebrated)
  g.told = g.told || ['garden'];       // new worlds already announced on a finish screen
  return g;
}
function saveGarden(g) { try { localStorage.setItem(GARDEN_KEY, JSON.stringify(g)); } catch {} }
function starBalance() {
  let earned = 0;
  try { earned = (JSON.parse(localStorage.getItem(REWARDS_KEY)) || {}).stars || 0; } catch {}
  return earned - loadGarden().spent;
}

// How good she has got: stages cleared across all her games (14 in all).
function skillScore() {
  const tables = new Set(loadProgress().clearedStages || []).size;
  const cols = new Set(loadCols().cleared || []).size;
  return tables + cols;
}
function worldOpen(w) { return skillScore() >= w.need; }

// For the finish screens: a sentence if a world has just opened, else ''.
function newWorldMessage() {
  const g = loadGarden();
  const fresh = WORLDS.filter(w => worldOpen(w) && !g.told.includes(w.id));
  if (!fresh.length) return '';
  fresh.forEach(w => g.told.push(w.id));
  saveGarden(g);
  return ` 🌈 You opened ${fresh.map(w => w.name).join(' and ')}! Go to My Garden to visit.`;
}

function currentWorld() { return WORLDS.find(w => w.id === loadGarden().at) || WORLDS[0]; }

function startGardenGame() {
  if (actx.state === 'suspended') actx.resume();
  showScreen('screen-garden');
  renderGardenShop();
  if (gardenState) { gardenState.running = true; gardenState.enter(); gardenState.loop(); return; }
  const msg = document.getElementById('garden-msg');
  msg.textContent = 'Loading the garden…';
  const s = document.createElement('script');
  s.src = THREE_URL;
  s.onload = () => { msg.textContent = ''; buildGarden(); };
  s.onerror = () => { msg.textContent = 'The garden needs the internet to load the first time.'; };
  document.head.appendChild(s);
}
function stopGarden() { if (gardenState) gardenState.running = false; }

function renderGardenShop() {
  document.getElementById('garden-stars').textContent = '⭐ ' + starBalance();
  const shop = document.getElementById('garden-shop');
  shop.innerHTML = '';
  const bal = starBalance();
  currentWorld().items.forEach(id => {
    const [name, emoji, cost] = ITEM_DEFS[id];
    const b = document.createElement('button');
    b.className = 'shop-item' + (gardenSel === id ? ' sel' : '') + (bal < cost ? ' poor' : '');
    b.innerHTML = `<span class="si-e">${emoji}</span><span class="si-n">${name}</span><span class="si-c">⭐ ${cost}</span>`;
    b.addEventListener('click', () => { gardenSel = gardenSel === id ? null : id; renderGardenShop(); gardenHint(); });
    shop.appendChild(b);
  });
  const r = document.createElement('button');
  r.className = 'shop-item' + (gardenSel === 'remove' ? ' sel' : '');
  r.innerHTML = '<span class="si-e">🧺</span><span class="si-n">Tidy up</span><span class="si-c">get ⭐ back</span>';
  r.addEventListener('click', () => { gardenSel = gardenSel === 'remove' ? null : 'remove'; renderGardenShop(); gardenHint(); });
  shop.appendChild(r);
}
function gardenHint(text) {
  const m = document.getElementById('garden-msg');
  if (text) m.textContent = text;
  else if (gardenSel === 'remove') m.textContent = 'Tap something to put it away.';
  else if (gardenSel) m.textContent = 'Now tap the ground to put it there!';
  else m.textContent = 'Drag to look around. Tap a guinea pig, or an island in the sky!';
}

function buildGarden() {
  const T = THREE;
  const canvas = document.getElementById('garden-canvas');
  const renderer = new T.WebGLRenderer({ canvas, antialias: true });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = T.PCFSoftShadowMap;
  const scene = new T.Scene();
  const fog = new T.Fog(0xbfe6ff, 45, 90);
  const camera = new T.PerspectiveCamera(45, 1, 0.1, 300);
  const hemi = new T.HemisphereLight(0xffffff, 0x88aa66, 0.85);
  scene.add(hemi);
  const sun = new T.DirectionalLight(0xfff2d0, 0.9);
  sun.position.set(8, 14, 6);
  sun.castShadow = true;
  sun.shadow.mapSize.set(1024, 1024);
  Object.assign(sun.shadow.camera, { left: -14, right: 14, top: 14, bottom: -14, near: 1, far: 40 });
  scene.add(sun);

  const R = 11;                                    // world radius
  const mat = (c, o) => new T.MeshStandardMaterial(Object.assign({ color: c, roughness: 0.85, flatShading: true }, o || {}));
  const glow = (c) => new T.MeshStandardMaterial({ color: c, emissive: c, emissiveIntensity: 0.8, roughness: 0.4 });
  let seed = 7; const rand = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const cast = o => { o.traverse(m => { if (m.isMesh) { m.castShadow = true; m.receiveShadow = true; } }); return o; };
  function sphere(r, c, x, y, z, sx, sy, sz) { const m = new T.Mesh(new T.SphereGeometry(r, 12, 9), typeof c === 'number' ? mat(c) : c); m.position.set(x, y, z); m.scale.set(sx || 1, sy || 1, sz || 1); return m; }
  function box(w, h, d, c, x, y, z) { const m = new T.Mesh(new T.BoxGeometry(w, h, d), typeof c === 'number' ? mat(c) : c); m.position.set(x, y, z); return m; }
  function cyl(rt, rb, h, c, x, y, z, seg) { const m = new T.Mesh(new T.CylinderGeometry(rt, rb, h, seg || 10), typeof c === 'number' ? mat(c) : c); m.position.set(x, y, z); return m; }
  function cone(r, h, c, x, y, z, seg) { const m = new T.Mesh(new T.ConeGeometry(r, h, seg || 8), typeof c === 'number' ? mat(c) : c); m.position.set(x, y, z); return m; }

  // ---- things to buy ----
  function makeItem(id) {
    const g = new T.Group();
    const add = (...ms) => ms.forEach(m => g.add(m));
    switch (id) {
      case 'flowers': {
        const cols = [0xff6fa5, 0xffd23f, 0xb07cff, 0xff8a3d, 0xffffff];
        for (let i = 0; i < 6; i++) { const x = (rand() - 0.5) * 1.1, z = (rand() - 0.5) * 1.1;
          add(cyl(0.025, 0.025, 0.4, 0x3a9a3a, x, 0.2, z), sphere(0.12, cols[i % 5], x, 0.45, z), sphere(0.05, 0xffe066, x, 0.5, z)); }
        break; }
      case 'sunflower': add(cyl(0.04, 0.05, 1.2, 0x3a9a3a, 0, 0.6, 0), sphere(0.32, 0xffc619, 0, 1.25, 0.05, 1, 1, 0.3), sphere(0.16, 0x6b3f1d, 0, 1.25, 0.12, 1, 1, 0.4)); break;
      case 'bush': add(sphere(0.6, 0x3f9d44, 0, 0.5, 0), sphere(0.45, 0x4fb355, 0.4, 0.4, 0.2), sphere(0.4, 0x3a8f3f, -0.4, 0.35, -0.2)); break;
      case 'carrots':
        for (let i = 0; i < 5; i++) { const x = (i - 2) * 0.28, z = (i % 2) * 0.2 - 0.1;
          const c = cone(0.08, 0.3, 0xff8c1a, x, 0.1, z); c.rotation.x = Math.PI; add(sphere(0.12, 0x3fa143, x, 0.2, z, 1, 1.3, 1), c); }
        break;
      case 'hay': { const h = cyl(0.5, 0.5, 0.8, 0xe6c15a, 0, 0.5, 0); h.rotation.z = Math.PI / 2; add(h); break; }
      case 'ball': add(sphere(0.35, 0xe84a4a, 0, 0.35, 0), sphere(0.355, 0xffffff, 0, 0.35, 0, 1, 0.18, 1)); break;
      case 'tree':
        add(cyl(0.2, 0.28, 1.6, 0x8a5a2b, 0, 0.8, 0), sphere(1.1, 0x3fa143, 0, 2.1, 0), sphere(0.8, 0x4cb351, 0.7, 1.8, 0.2), sphere(0.75, 0x37953c, -0.6, 1.7, -0.3),
          sphere(0.09, 0xff4040, 0.5, 2.3, 0.9), sphere(0.09, 0xff4040, -0.4, 2.0, 0.95), sphere(0.09, 0xff4040, 0.9, 1.6, 0.6));
        break;
      case 'tunnel': {
        const arch = new T.Mesh(new T.CylinderGeometry(0.6, 0.6, 1.8, 16, 1, true, Math.PI / 2, Math.PI), mat(0xe0903c, { side: T.DoubleSide }));
        arch.rotation.x = Math.PI / 2; add(arch); break; }   // a half-pipe lying along z, open at both ends
      case 'pond': {
        const w = cyl(1.5, 1.5, 0.08, mat(0x4aa8e8, { flatShading: false, roughness: 0.2, metalness: 0.1 }), 0, 0.05, 0, 28);
        const r = new T.Mesh(new T.TorusGeometry(1.5, 0.16, 8, 28), mat(0x9a9a9a)); r.rotation.x = Math.PI / 2; r.position.y = 0.08;
        add(w, r, sphere(0.3, 0x3fa143, 0.5, 0.1, 0.3, 1, 0.1, 1)); break; }
      case 'hutch': {
        const roof = cone(1.5, 0.8, 0xb03a2e, 0, 1.4, 0, 4); roof.rotation.y = Math.PI / 4; roof.scale.set(1.1, 1, 0.75);
        add(box(2.2, 1.0, 1.4, 0xc58a4a, 0, 0.5, 0), roof, box(0.5, 0.6, 0.05, 0x3b2a1a, 0, 0.35, 0.72), box(0.5, 0.35, 0.05, 0xfff4cf, -0.7, 0.62, 0.72), box(0.12, 0.05, 0.9, 0x8a5a2b, -0.5, 0.02, 1.0));
        break; }
      case 'rainbow':
        ['e03b3b', 'ff9a2e', 'ffd93d', '4cc15a', '3fa0e8', '8a5cd6'].forEach((hex, i) => add(new T.Mesh(new T.TorusGeometry(2.6 - i * 0.22, 0.11, 8, 28, Math.PI), mat(parseInt(hex, 16)))));
        break;
      // -- beach --
      case 'shell': add(sphere(0.3, 0xffb6b9, 0, 0.12, 0, 1, 0.5, 0.8), sphere(0.31, 0xff9aa2, 0, 0.13, 0, 0.6, 0.45, 0.85), cone(0.12, 0.2, 0xffd1d4, 0, 0.12, -0.28)); break;
      case 'starfish':
        for (let i = 0; i < 5; i++) { const a = i * Math.PI * 2 / 5; const c = cone(0.1, 0.42, 0xff8a3d, Math.sin(a) * 0.2, 0.06, Math.cos(a) * 0.2, 6);
          c.rotation.order = 'YXZ'; c.rotation.set(Math.PI / 2, a, 0); c.scale.set(1, 1, 0.4); add(c); }
        add(sphere(0.12, 0xff8a3d, 0, 0.06, 0, 1, 0.5, 1)); break;
      case 'beachball': add(sphere(0.4, 0xffffff, 0, 0.4, 0), sphere(0.405, 0xe84a4a, 0, 0.4, 0, 0.35, 1, 1), sphere(0.405, 0x3fa0e8, 0, 0.4, 0, 1, 1, 0.35)); break;
      case 'umbrella': {
        add(cyl(0.04, 0.04, 2.0, 0xffffff, 0, 1.0, 0), cone(1.2, 0.5, 0xff5c7a, 0, 2.05, 0, 8), cone(1.21, 0.5, 0xffffff, 0, 2.05, 0, 4), box(0.9, 0.04, 1.6, 0x3fa0e8, 0.9, 0.02, 0.2));
        break; }
      case 'palm': {
        for (let i = 0; i < 6; i++) add(cyl(0.17 - i * 0.015, 0.19 - i * 0.015, 0.45, 0x9b6b3d, i * i * 0.025, 0.22 + i * 0.42, 0));
        const top = new T.Vector3(25 * 0.025, 2.6, 0);
        for (let i = 0; i < 6; i++) { const a = i * Math.PI / 3; const l = sphere(0.6, 0x3fae49, top.x + Math.cos(a) * 0.6, top.y - 0.1, Math.sin(a) * 0.6, 1.4, 0.12, 0.35);
          l.rotation.y = -a; l.rotation.z = -0.35; add(l); }
        add(sphere(0.12, 0x6b4a2a, top.x + 0.15, top.y - 0.25, 0.1), sphere(0.12, 0x6b4a2a, top.x - 0.1, top.y - 0.25, -0.12)); break; }
      case 'rockpool': {
        for (let i = 0; i < 8; i++) { const a = i * Math.PI / 4; add(sphere(0.32, 0x8c8c8c, Math.cos(a) * 1.0, 0.12, Math.sin(a) * 1.0, 1.1, 0.6, 1)); }
        add(cyl(0.95, 0.95, 0.06, mat(0x3fb4e8, { flatShading: false, roughness: 0.15 }), 0, 0.06, 0, 24));
        add(sphere(0.14, 0xe0432f, 0.2, 0.2, 0.1, 1.3, 0.6, 1), sphere(0.05, 0x111111, 0.27, 0.3, 0.2), sphere(0.05, 0x111111, 0.13, 0.3, 0.2)); break; }
      case 'castle': {
        add(box(1.4, 0.6, 1.4, 0xe9cf86, 0, 0.3, 0));
        [[-0.6, -0.6], [0.6, -0.6], [-0.6, 0.6], [0.6, 0.6]].forEach(([x, z]) => add(cyl(0.25, 0.3, 1.0, 0xe9cf86, x, 0.5, z), cone(0.3, 0.35, 0xdcbf72, x, 1.17, z)));
        add(box(0.35, 0.4, 0.05, 0x8a6a3d, 0, 0.2, 0.72), cyl(0.015, 0.015, 0.6, 0x555555, 0.6, 1.6, 0.6), box(0.3, 0.18, 0.02, 0xff5c7a, 0.75, 1.8, 0.6)); break; }
      case 'boat': {
        add(box(1.8, 0.4, 0.7, 0x3fa0e8, 0, 0.25, 0), box(1.9, 0.12, 0.8, 0xffffff, 0, 0.5, 0), cyl(0.04, 0.04, 2.0, 0x8a5a2b, 0, 1.4, 0));
        const sail = new T.Mesh(new T.ShapeGeometry(new T.Shape([new T.Vector2(0, 0), new T.Vector2(0, 1.6), new T.Vector2(1.0, 0)])), mat(0xffffff, { side: T.DoubleSide }));
        sail.position.set(0.05, 0.6, 0); add(sail); break; }
      // -- snow --
      case 'snowpile': add(sphere(0.45, 0xffffff, 0, 0.2, 0, 1, 0.5, 1), sphere(0.15, 0xffffff, 0.5, 0.15, 0.2), sphere(0.15, 0xffffff, 0.6, 0.15, -0.15), sphere(0.15, 0xffffff, 0.55, 0.4, 0.03)); break;
      case 'icecrystal': { const c = new T.Mesh(new T.OctahedronGeometry(0.45), new T.MeshStandardMaterial({ color: 0x9fe3ff, emissive: 0x4fb8ff, emissiveIntensity: 0.5, roughness: 0.1, transparent: true, opacity: 0.85 }));
        c.position.y = 0.9; c.scale.set(0.8, 1.4, 0.8); c.userData.spin = 1; add(c); break; }
      case 'sledge': add(box(1.4, 0.06, 0.08, 0x777777, 0, 0.05, 0.3), box(1.4, 0.06, 0.08, 0x777777, 0, 0.05, -0.3), box(1.0, 0.12, 0.7, 0xd9342b, 0, 0.3, 0), box(0.06, 0.25, 0.06, 0x777777, 0.4, 0.15, 0.3), box(0.06, 0.25, 0.06, 0x777777, -0.4, 0.15, 0.3), box(0.06, 0.25, 0.06, 0x777777, 0.4, 0.15, -0.3), box(0.06, 0.25, 0.06, 0x777777, -0.4, 0.15, -0.3)); break;
      case 'snowpine':
        add(cyl(0.12, 0.16, 0.6, 0x6b4a2a, 0, 0.3, 0));
        for (let i = 0; i < 3; i++) add(cone(1.0 - i * 0.25, 0.9, 0x2f6b4a, 0, 0.9 + i * 0.55, 0), cone(0.55 - i * 0.14, 0.4, 0xffffff, 0, 1.25 + i * 0.55, 0));
        break;
      case 'penguin':
        add(sphere(0.35, 0x1f2430, 0, 0.5, 0, 1, 1.4, 0.9), sphere(0.27, 0xffffff, 0, 0.45, 0.1, 1, 1.3, 0.8), sphere(0.24, 0x1f2430, 0, 1.0, 0),
          cone(0.06, 0.18, 0xffa630, 0, 0.98, 0.25), sphere(0.045, 0xffffff, 0.09, 1.07, 0.18), sphere(0.045, 0xffffff, -0.09, 1.07, 0.18),
          sphere(0.025, 0x000000, 0.1, 1.07, 0.22), sphere(0.025, 0x000000, -0.08, 1.07, 0.22), sphere(0.1, 0xffa630, 0.12, 0.03, 0.1, 1, 0.3, 1.5), sphere(0.1, 0xffa630, -0.12, 0.03, 0.1, 1, 0.3, 1.5));
        g.userData.waddle = 1; break;
      case 'snowman': {
        const nose = cone(0.07, 0.35, 0xff8c1a, 0, 1.6, 0.4); nose.rotation.x = Math.PI / 2;
        const scarf = new T.Mesh(new T.TorusGeometry(0.33, 0.08, 6, 16), mat(0xd9342b)); scarf.rotation.x = Math.PI / 2; scarf.position.y = 1.28;
        add(sphere(0.6, 0xffffff, 0, 0.55, 0), sphere(0.42, 0xffffff, 0, 1.15, 0), sphere(0.32, 0xffffff, 0, 1.6, 0), nose, scarf,
          sphere(0.05, 0x111111, 0.12, 1.7, 0.27), sphere(0.05, 0x111111, -0.12, 1.7, 0.27), cyl(0.3, 0.3, 0.05, 0x222222, 0, 1.88, 0), cyl(0.2, 0.2, 0.35, 0x222222, 0, 2.05, 0),
          sphere(0.05, 0x111111, 0, 1.2, 0.41), sphere(0.05, 0x111111, 0, 1.0, 0.4));
        break; }
      case 'igloo': {
        const dome = new T.Mesh(new T.SphereGeometry(1.2, 16, 10, 0, Math.PI * 2, 0, Math.PI / 2), mat(0xf4f8ff));
        const door = new T.Mesh(new T.CylinderGeometry(0.45, 0.45, 0.8, 12, 1, false, Math.PI / 2, Math.PI), mat(0xe8f0fa)); door.rotation.x = Math.PI / 2; door.position.set(0, 0, 1.2);
        add(dome, door, cyl(0.35, 0.35, 0.05, 0x333a44, 0, 0.2, 1.61)); break; }
      // -- candy --
      case 'gumdrop': [0xff5c7a, 0x6fd16f, 0xffd23f, 0x7ab8ff].forEach((c, i) => add(sphere(0.2, c, (i % 2) * 0.45 - 0.2, 0.15, Math.floor(i / 2) * 0.45 - 0.2, 1, 0.9, 1))); break;
      case 'lollipop': {
        add(cyl(0.04, 0.04, 1.4, 0xffffff, 0, 0.7, 0));
        for (let i = 0; i < 4; i++) { const t = new T.Mesh(new T.TorusGeometry(0.08 + i * 0.1, 0.06, 8, 20), mat(i % 2 ? 0xffffff : 0xff4fa0)); t.position.y = 1.65; add(t); }
        add(cyl(0.45, 0.45, 0.1, 0xff7fbf, 0, 1.65, -0.02)); g.children[g.children.length - 1].rotation.x = Math.PI / 2; break; }
      case 'candycane': {
        for (let i = 0; i < 8; i++) add(cyl(0.09, 0.09, 0.2, i % 2 ? 0xffffff : 0xe8333a, 0, 0.1 + i * 0.2, 0));
        for (let i = 0; i < 6; i++) { const a = i / 5 * Math.PI; const s = cyl(0.09, 0.09, 0.15, i % 2 ? 0xe8333a : 0xffffff, 0.25 - Math.cos(a) * 0.25, 1.65 + Math.sin(a) * 0.25, 0); s.rotation.z = a - Math.PI / 2; add(s); }
        break; }
      case 'donut': {
        const d = new T.Mesh(new T.TorusGeometry(0.4, 0.2, 10, 20), mat(0xd9a066)); d.rotation.x = Math.PI / 2; d.position.y = 0.2;
        const ic = new T.Mesh(new T.TorusGeometry(0.4, 0.17, 10, 20), mat(0xff8fc6)); ic.rotation.x = Math.PI / 2; ic.position.y = 0.27;
        add(d, ic); [0xffffff, 0x6fd16f, 0xffd23f, 0x7ab8ff].forEach((c, i) => { for (let k = 0; k < 3; k++) { const a = (i * 3 + k) * 0.52; add(box(0.1, 0.03, 0.03, c, Math.cos(a) * 0.4, 0.43, Math.sin(a) * 0.4)); } });
        break; }
      case 'icecream': {
        const c = cone(0.28, 0.8, 0xe0b06a, 0, 0.4, 0); c.rotation.x = Math.PI;
        add(c, sphere(0.3, 0xff9ccc, 0, 0.9, 0), sphere(0.27, 0xfff5d6, 0, 1.25, 0), sphere(0.08, 0xe8333a, 0, 1.52, 0)); break; }
      case 'cupcake':
        add(cyl(0.45, 0.33, 0.5, 0x7ab8ff, 0, 0.25, 0, 12), sphere(0.45, 0xfff0f6, 0, 0.6, 0, 1, 0.6, 1), sphere(0.3, 0xffd6e8, 0, 0.82, 0, 1, 0.7, 1), sphere(0.1, 0xe8333a, 0, 1.0, 0));
        break;
      case 'cake':
        add(cyl(1.1, 1.1, 0.6, 0xffe3ef, 0, 0.3, 0, 20), cyl(1.12, 1.12, 0.1, 0xff7fbf, 0, 0.6, 0, 20), cyl(0.7, 0.7, 0.5, 0xfff5d6, 0, 0.9, 0, 20), cyl(0.72, 0.72, 0.08, 0x8a5a2b, 0, 1.15, 0, 20));
        for (let i = 0; i < 5; i++) { const a = i * Math.PI * 2 / 5; add(cyl(0.04, 0.04, 0.3, 0x7ab8ff, Math.cos(a) * 0.4, 1.35, Math.sin(a) * 0.4), sphere(0.05, glow(0xffb020), Math.cos(a) * 0.4, 1.55, Math.sin(a) * 0.4)); }
        break;
      // -- moon --
      case 'moonrock': add(sphere(0.4, 0x8d8d99, 0, 0.25, 0, 1.2, 0.7, 1), sphere(0.25, 0x9a9aa6, 0.4, 0.2, 0.2), cone(0.1, 0.4, glow(0xb57cff), -0.2, 0.55, 0.1, 5)); break;
      case 'starlamp': { const s = new T.Mesh(new T.OctahedronGeometry(0.4), glow(0xffd84a)); s.position.y = 1.4; s.userData.spin = 1; add(s, cyl(0.03, 0.03, 1.2, 0xaaaaaa, 0, 0.6, 0)); break; }
      case 'flag': add(cyl(0.03, 0.03, 1.8, 0xdddddd, 0, 0.9, 0), box(0.8, 0.5, 0.02, 0xff7fbf, 0.42, 1.5, 0), sphere(0.12, 0xffffff, 0.42, 1.5, 0.02, 1, 1, 0.2)); break;
      case 'alienplant':
        add(cyl(0.05, 0.08, 1.0, 0x5fb847, 0, 0.5, 0), sphere(0.18, glow(0x7dff8a), 0, 1.05, 0), cyl(0.04, 0.05, 0.7, 0x5fb847, 0.3, 0.35, 0.1), sphere(0.13, glow(0xd57cff), 0.3, 0.75, 0.1), cyl(0.04, 0.05, 0.6, 0x5fb847, -0.25, 0.3, -0.1), sphere(0.12, glow(0x7ce0ff), -0.25, 0.65, -0.1));
        break;
      case 'dish': {
        const d = new T.Mesh(new T.SphereGeometry(0.8, 16, 8, 0, Math.PI * 2, 0, 1.0), mat(0xeeeeee, { side: T.DoubleSide }));
        d.rotation.x = Math.PI * 0.75; d.position.set(0, 1.3, 0);
        add(cyl(0.08, 0.15, 1.1, 0x999999, 0, 0.55, 0), d, cyl(0.02, 0.02, 0.6, 0x999999, 0, 1.45, 0.35), sphere(0.06, glow(0xff4040), 0, 1.75, 0.45)); break; }
      case 'ufo': {
        const u = new T.Group(); u.position.y = 1.6; u.userData.hover = 1;
        u.add(sphere(1.0, 0xb8c2cc, 0, 0, 0, 1, 0.25, 1), sphere(0.45, mat(0x9fe3ff, { transparent: true, opacity: 0.8 }), 0, 0.2, 0, 1, 0.8, 1));
        for (let i = 0; i < 6; i++) { const a = i * Math.PI / 3; u.add(sphere(0.07, glow([0xff4040, 0xffd84a, 0x7dff8a][i % 3]), Math.cos(a) * 0.85, -0.05, Math.sin(a) * 0.85)); }
        add(u); break; }
      case 'rocket': {
        add(cyl(0.45, 0.5, 2.2, 0xf4f4f4, 0, 1.4, 0, 14), cone(0.45, 0.9, 0xe8333a, 0, 2.95, 0, 14), sphere(0.2, glow(0x7ce0ff), 0, 1.9, 0.43, 1, 1, 0.4));
        for (let i = 0; i < 3; i++) { const a = i * Math.PI * 2 / 3; const f = box(0.08, 0.7, 0.6, 0xe8333a, Math.cos(a) * 0.55, 0.45, Math.sin(a) * 0.55); f.rotation.y = -a; add(f); }
        add(cone(0.3, 0.5, glow(0xffa630), 0, 0.1, 0, 10)); g.children[g.children.length - 1].rotation.x = Math.PI; break; }
    }
    return cast(g);
  }

  // ---- the world you're standing in ----
  let worldRoot = null, itemGroup = null, placed = [], weather = null, world = null, G = loadGarden();
  const pigs = [];
  function buildWorld(w) {
    if (worldRoot) scene.remove(worldRoot);
    world = w; G = loadGarden(); placed = [];
    worldRoot = new T.Group(); scene.add(worldRoot);
    seed = 7 + WORLDS.indexOf(w) * 101;
    const sky = new T.Color(w.sky);
    scene.background = sky; fog.color = sky;
    hemi.groundColor = new T.Color(w.ground).multiplyScalar(0.7);
    const night = w.id === 'moon';
    scene.fog = night ? null : fog;   // no air on the Moon: stars and the Earth stay sharp
    hemi.intensity = night ? 0.55 : 0.85; sun.intensity = night ? 0.75 : 0.9;
    const ground = new T.Mesh(new T.CylinderGeometry(R, R + 0.4, 0.6, 48), mat(w.ground));
    ground.position.y = -0.3; ground.receiveShadow = true; worldRoot.add(ground);
    const under = new T.Mesh(new T.ConeGeometry(R + 0.4, 9, 24), mat(w.rock)); under.rotation.x = Math.PI; under.position.y = -5.1; worldRoot.add(under);
    const rim = new T.Mesh(new T.TorusGeometry(R + 0.2, 0.25, 8, 64), mat(w.rim)); rim.rotation.x = Math.PI / 2; worldRoot.add(rim);
    const tuftG = w.id === 'candy' ? new T.BoxGeometry(0.06, 0.06, 0.25) : new T.ConeGeometry(0.07, 0.35, 4);   // sprinkles in Candy Land
    const tuftMs = w.id === 'candy' ? [0xffffff, 0x6fd16f, 0xffd23f, 0x7ab8ff, 0xff4fa0].map(c => mat(c)) : [mat(w.tuft)];
    const tufts = w.id === 'moon' ? 0 : (w.id === 'snow' ? 60 : 260);
    for (let i = 0; i < tufts; i++) {
      const a = rand() * Math.PI * 2, d = Math.sqrt(rand()) * (R - 0.5);
      const t = new T.Mesh(tuftG, tuftMs[i % tuftMs.length]); t.position.set(Math.cos(a) * d, w.id === 'candy' ? 0.03 : 0.15, Math.sin(a) * d);
      if (w.id === 'candy') t.rotation.y = rand() * 6.3;
      worldRoot.add(t);
    }
    if (w.id === 'beach') {   // the sea all round
      const sea = new T.Mesh(new T.CircleGeometry(80, 48), mat(0x3fb4e8, { flatShading: false, roughness: 0.2 })); sea.rotation.x = -Math.PI / 2; sea.position.y = -0.8; worldRoot.add(sea);
    }
    if (night) {             // craters, stars and the Earth
      for (let i = 0; i < 9; i++) { const a = rand() * 6.3, d = Math.sqrt(rand()) * (R - 2);
        const c = new T.Mesh(new T.TorusGeometry(0.5 + rand() * 0.6, 0.12, 6, 18), mat(0xa9a9b5)); c.rotation.x = Math.PI / 2; c.position.set(Math.cos(a) * d, 0.02, Math.sin(a) * d); c.scale.z = 0.4; worldRoot.add(c); }
      const pts = []; for (let i = 0; i < 1500; i++) { const v = new T.Vector3(rand() - 0.5, rand() * 0.9 - 0.45, rand() - 0.5).normalize().multiplyScalar(150); pts.push(v.x, v.y, v.z); }
      const sg = new T.BufferGeometry(); sg.setAttribute('position', new T.Float32BufferAttribute(pts, 3));
      worldRoot.add(new T.Points(sg, new T.PointsMaterial({ color: 0xffffff, size: 3, sizeAttenuation: false, fog: false })));
      const earth = sphere(4, mat(0x3f8ee8, { flatShading: false, fog: false }), -40, 6, -50); earth.add(sphere(1, mat(0x5fbf5a, { flatShading: false }), 0.3, 0.3, 0.6, 0.6, 0.5, 0.5));
      worldRoot.add(earth);
    }
    weather = null;
    if (w.id === 'snow') {   // gently falling snow
      const pts = []; for (let i = 0; i < 400; i++) pts.push((rand() - 0.5) * 30, rand() * 16, (rand() - 0.5) * 30);
      const sg = new T.BufferGeometry(); sg.setAttribute('position', new T.Float32BufferAttribute(pts, 3));
      weather = new T.Points(sg, new T.PointsMaterial({ color: 0xffffff, size: 0.15 })); worldRoot.add(weather);
    }
    if (!night) {
      for (let i = 0; i < 6; i++) {
        const c = new T.Group(); c.userData.cloud = 0.4 + i * 0.05;
        for (let k = 0; k < 4; k++) c.add(sphere(1 + rand() * 0.8, mat(0xffffff, { flatShading: false, roughness: 1 }), k * 1.3 - 2, rand() * 0.4, rand()));
        c.position.set(-30 + i * 12, 14 + rand() * 5, -20 - rand() * 14); worldRoot.add(c);
      }
    }
    itemGroup = new T.Group(); worldRoot.add(itemGroup);
    (G.worlds[w.id] || []).forEach(addItem);
    buildIslands();
    pigs.forEach(p => { const a = rand() * 6.28, d = 2 + rand() * 4; p.mesh.position.set(Math.cos(a) * d, 0, Math.sin(a) * d); p.tx = p.mesh.position.x; p.tz = p.mesh.position.z; });
    renderGardenShop();
  }
  function addItem(rec) {
    const m = makeItem(rec.id); m.position.set(rec.x, 0, rec.z); m.rotation.y = rec.rot || 0;
    m.userData.rec = rec; itemGroup.add(m); placed.push(m); return m;
  }

  // ---- islands in the sky: the other worlds ----
  let islands = [];
  function label(text, sub) {
    const c = document.createElement('canvas'); c.width = 512; c.height = 160;
    const x = c.getContext('2d');
    x.fillStyle = 'rgba(255,255,255,0.92)'; x.beginPath(); x.roundRect ? x.roundRect(8, 8, 496, 144, 40) : x.rect(8, 8, 496, 144); x.fill();
    x.fillStyle = '#4a3a22'; x.textAlign = 'center'; x.font = 'bold 56px Trebuchet MS, sans-serif'; x.fillText(text, 256, sub ? 72 : 100);
    if (sub) { x.font = 'bold 36px Trebuchet MS, sans-serif'; x.fillStyle = '#8a6d00'; x.fillText(sub, 256, 124); }
    const s = new T.Sprite(new T.SpriteMaterial({ map: new T.CanvasTexture(c), depthTest: false, fog: false }));
    s.scale.set(6.4, 2, 1); s.renderOrder = 10; return s;
  }
  function miniFor(id) {   // a tiny taste of each world on its island
    const pick = { garden: ['tree', 'hutch'], beach: ['palm', 'umbrella'], snow: ['snowpine', 'snowman'], candy: ['lollipop', 'cupcake'], moon: ['rocket', 'alienplant'] }[id];
    return pick.map(makeItem);
  }
  function buildIslands() {
    islands = [];
    const others = WORLDS.filter(w => w.id !== world.id);
    const score = skillScore();
    others.forEach((w, i) => {
      const open = score >= w.need;
      const g = new T.Group();
      const a = -0.6 + (i - (others.length - 1) / 2) * 0.62;   // spread across the sky beyond the far edge
      const pos = new T.Vector3(Math.sin(a) * 22, 2 + (i % 2) * 2.2, -Math.cos(a) * 22);
      g.position.copy(pos);
      const grey = c => open ? c : new T.Color(c).lerp(new T.Color(0xb8b8c0), 0.75).getHex();
      const top = new T.Mesh(new T.CylinderGeometry(3.2, 3.4, 0.5, 24), mat(grey(w.ground))); g.add(top);
      const rock = new T.Mesh(new T.ConeGeometry(3.4, 4.5, 12), mat(grey(w.rock))); rock.rotation.x = Math.PI; rock.position.y = -2.5; g.add(rock);
      miniFor(w.id).forEach((m, k) => { m.position.set(k ? 1.1 : -1.0, 0.25, k ? 0.6 : -0.5); m.scale.setScalar(0.6);
        if (!open) m.traverse(o => { if (o.isMesh) { o.material = o.material.clone(); o.material.color.lerp(new T.Color(0xb8b8c0), 0.75); if (o.material.emissive) o.material.emissiveIntensity = 0; } });
        g.add(m); });
      if (!open) for (let k = 0; k < 7; k++) { const p = sphere(1.3, mat(0xffffff, { flatShading: false, transparent: true, opacity: 0.85 }), Math.cos(k) * 3, 0.4 + (k % 3) * 0.5, Math.sin(k * 1.7) * 3); g.add(p); }
      const lab = open ? label(w.name.replace(/^the /, 'The ')) : label('🔒 ' + w.name.replace(/^the /, 'The '), `Clear ${w.need - score} more stage${w.need - score === 1 ? '' : 's'}`);
      lab.position.set(0, 3.4, 0); g.add(lab);
      g.userData = { world: w, open, base: pos.y, phase: i * 1.3 };
      worldRoot.add(g);
      islands.push(g);
      if (open) {
        const fresh = !G.opened.includes(w.id);
        g.userData.bridge = bridge(pos, fresh);
        if (fresh) { G.opened.push(w.id); saveGarden(G); setTimeout(() => { playCompleteFanfare(); gardenHint(`🌈 A rainbow bridge to ${w.name} appeared! Tap the island to visit.`); }, 600); }
      }
    });
  }
  // A rainbow bridge from the edge of this world up to an island. A new one grows.
  function bridge(to, grow) {
    const from = new T.Vector3(to.x, 0, to.z).normalize().multiplyScalar(R - 0.5);
    const mid = from.clone().lerp(to, 0.5); mid.y = Math.max(from.y, to.y) + 4;
    const curve = new T.QuadraticBezierCurve3(from, mid, to.clone().add(new T.Vector3(0, 0.3, 0)));
    const side = new T.Vector3().crossVectors(to.clone().sub(from).setY(0).normalize(), new T.Vector3(0, 1, 0));
    const g = new T.Group();
    ['e03b3b', 'ff9a2e', 'ffd93d', '4cc15a', '3fa0e8', '8a5cd6'].forEach((hex, i) => {
      const off = side.clone().multiplyScalar((i - 2.5) * 0.18);
      const c = new T.QuadraticBezierCurve3(curve.v0.clone().add(off), curve.v1.clone().add(off), curve.v2.clone().add(off));
      const geo = new T.TubeGeometry(c, 60, 0.1, 6, false);
      if (grow) geo.setDrawRange(0, 0);
      g.add(new T.Mesh(geo, mat(parseInt(hex, 16), { flatShading: false })));
    });
    g.userData.grow = grow ? 0 : 1;
    worldRoot.add(g);
    return g;
  }

  // ---- going to another world: fade out, rebuild, fade in ----
  const fade = document.getElementById('garden-fade');
  let travelling = false;
  function travel(w) {
    if (travelling) return;
    travelling = true; gardenSel = null;
    fade.classList.add('on'); playSuccessChime();
    setTimeout(() => {
      const g = loadGarden(); g.at = w.id; saveGarden(g);
      buildWorld(w); az = 0.6; pol = 1.08; dist = 25;
      fade.classList.remove('on');
      gardenHint(w.id === 'garden' ? 'Home to the garden!' : `Welcome to ${w.name}! ${w.id === 'moon' ? 'The guinea pigs can jump really high here!' : ''}`);
      travelling = false;
    }, 600);
  }

  // ---- guinea pigs ----
  function makePig(id) {
    const [bodyC, patchC] = PIG_COLOURS[id] || PIG_COLOURS[0];
    const g = new T.Group();
    g.add(sphere(0.5, bodyC, 0, 0.42, 0, 1.0, 0.8, 1.35), sphere(0.38, patchC, 0, 0.3, 0.1, 0.9, 0.55, 1.1));
    const head = new T.Group(); head.position.set(0, 0.5, 0.62);
    head.add(sphere(0.36, bodyC, 0, 0, 0, 1, 0.95, 1.05), sphere(0.2, patchC, 0, -0.06, 0.27, 1, 0.8, 0.9),
      sphere(0.06, 0xff9fb0, 0, 0.0, 0.42), sphere(0.055, 0x111111, 0.15, 0.1, 0.3), sphere(0.055, 0x111111, -0.15, 0.1, 0.3),
      sphere(0.02, 0xffffff, 0.16, 0.12, 0.34), sphere(0.02, 0xffffff, -0.14, 0.12, 0.34),
      sphere(0.13, 0xe9a1a8, 0.3, 0.22, -0.05, 0.4, 1, 1), sphere(0.13, 0xe9a1a8, -0.3, 0.22, -0.05, 0.4, 1, 1));
    g.add(head);
    [[0.25, 0.4], [-0.25, 0.4], [0.25, -0.4], [-0.25, -0.4]].forEach(([x, z]) => g.add(sphere(0.1, patchC, x, 0.08, z, 1, 0.7, 1.3)));
    g.userData = { head };
    return cast(g);
  }
  function syncPigs() {
    const want = [0].concat(loadProgress().clearedStages);   // 0 = Pip, the garden's own pig
    want.forEach(id => {
      if (pigs.find(p => p.id === id)) return;
      const mesh = makePig(id); scene.add(mesh);
      const a = rand() * 6.28, d = 2 + rand() * 4;
      mesh.position.set(Math.cos(a) * d, 0, Math.sin(a) * d);
      const name = id === 0 ? 'Pip' : (FARM_PIGS.find(f => f.id === id) || {}).name;
      pigs.push({ id, name, mesh, tx: mesh.position.x, tz: mesh.position.z, wait: rand() * 2, hop: 0 });
    });
  }

  // ---- camera orbit, pointer handling ----
  let az = 0.6, pol = 1.08, dist = 25, drag = null;
  function placeCamera() {
    camera.position.set(Math.sin(az) * Math.sin(pol) * dist, Math.cos(pol) * dist, Math.cos(az) * Math.sin(pol) * dist);
    camera.lookAt(0, 2.2, 0);
  }
  function resize() {
    const w = canvas.clientWidth, h = canvas.clientHeight;
    if (!w || !h) return;
    renderer.setSize(w, h, false); camera.aspect = w / h; camera.updateProjectionMatrix();
  }
  addEventListener('resize', resize);
  canvas.addEventListener('pointerdown', e => { drag = { x: e.clientX, y: e.clientY, moved: 0 }; canvas.setPointerCapture(e.pointerId); });
  canvas.addEventListener('pointermove', e => {
    if (!drag) return;
    const dx = e.clientX - drag.x, dy = e.clientY - drag.y;
    drag.moved += Math.abs(dx) + Math.abs(dy); drag.x = e.clientX; drag.y = e.clientY;
    az -= dx * 0.008; pol = Math.min(1.35, Math.max(0.35, pol - dy * 0.006));
  });
  canvas.addEventListener('pointerup', e => { const d = drag; drag = null; if (d && d.moved < 8) tapAt(e); });
  canvas.addEventListener('wheel', e => { e.preventDefault(); dist = Math.min(34, Math.max(10, dist + e.deltaY * 0.02)); }, { passive: false });

  const ray = new T.Raycaster(), ndc = new T.Vector2(), plane = new T.Plane(new T.Vector3(0, 1, 0), 0);
  const islandOf = o => { while (o && !islands.includes(o) && !islands.some(i => i.userData.bridge === o)) o = o.parent; return islands.find(i => i === o || i.userData.bridge === o); };
  function tapAt(e) {
    if (travelling) return;
    const r = canvas.getBoundingClientRect();
    ndc.set(((e.clientX - r.left) / r.width) * 2 - 1, -((e.clientY - r.top) / r.height) * 2 + 1);
    ray.setFromCamera(ndc, camera);
    // An island (or its bridge) in the sky?
    const targets = islands.concat(islands.map(i => i.userData.bridge).filter(Boolean));
    const ih = ray.intersectObjects(targets, true)[0];
    if (ih && !gardenSel) {
      const isl = islandOf(ih.object);
      if (isl) {
        const w = isl.userData.world;
        if (isl.userData.open) travel(w);
        else { playGentleBlip(); const n = w.need - skillScore(); gardenHint(`🔒 ${w.name.replace(/^the /, 'The ')} opens when you clear ${n} more stage${n === 1 ? '' : 's'}. Try Column Maths or Feed Pip!`); }
        return;
      }
    }
    if (gardenSel === 'remove') {
      const hit = ray.intersectObjects(itemGroup.children, true)[0];
      if (hit) {
        let o = hit.object; while (o.parent !== itemGroup) o = o.parent;
        const rec = o.userData.rec;
        G = loadGarden();
        const list = G.worlds[world.id] || [];
        const k = list.findIndex(x => x.x === rec.x && x.z === rec.z && x.id === rec.id);
        if (k >= 0) list.splice(k, 1);
        G.spent -= ITEM_DEFS[rec.id][2]; saveGarden(G);
        itemGroup.remove(o); placed.splice(placed.indexOf(o), 1);
        playGentleBlip(); renderGardenShop();
      }
      return;
    }
    if (gardenSel) {
      const cost = ITEM_DEFS[gardenSel][2];
      const p = new T.Vector3();
      if (!ray.ray.intersectPlane(plane, p) || p.length() > R - 1) { gardenHint('Tap on the ground!'); return; }
      if (starBalance() < cost) { gardenHint(`You need ⭐ ${cost}. Play a game to earn more!`); return; }
      const rec = { id: gardenSel, x: Math.round(p.x * 2) / 2, z: Math.round(p.z * 2) / 2, rot: (Math.random() - 0.5) * 0.8 };
      G = loadGarden();
      (G.worlds[world.id] = G.worlds[world.id] || []).push(rec); G.spent += cost; saveGarden(G);
      const m = addItem(rec); m.scale.setScalar(0.05); m.userData.grow = 0;
      playSuccessChime(); renderGardenShop();
      return;
    }
    const meshes = pigs.map(p => p.mesh);
    const hit = ray.intersectObjects(meshes, true)[0];
    if (hit) {
      let o = hit.object; while (!meshes.includes(o)) o = o.parent;
      const pig = pigs.find(p => p.mesh === o);
      pig.hop = 1;
      playTone(900, actx.currentTime, 0.08, 0.15); playTone(1250, actx.currentTime + 0.08, 0.1, 0.15);
      gardenHint(`${pig.name} says wheek! 💕`);
    }
  }

  // ---- loop ----
  const clock = new T.Clock();
  const state = { running: true, loop: null };
  function frame() {
    if (!state.running) return;
    requestAnimationFrame(frame);
    resize();
    const dt = Math.min(clock.getDelta(), 0.05), t = clock.elapsedTime;
    const lowG = world.id === 'moon';
    worldRoot.children.forEach(c => { if (c.userData.cloud) { c.position.x += dt * c.userData.cloud; if (c.position.x > 40) c.position.x = -40; } });
    if (weather) { const a = weather.geometry.attributes.position; for (let i = 0; i < a.count; i++) { let y = a.getY(i) - dt * 1.2; if (y < 0) y = 16; a.setY(i, y); a.setX(i, a.getX(i) + Math.sin(t + i) * dt * 0.2); } a.needsUpdate = true; }
    islands.forEach(isl => {
      isl.position.y = isl.userData.base + Math.sin(t * 0.6 + isl.userData.phase) * 0.35;
      const b = isl.userData.bridge;
      if (b && b.userData.grow < 1) { b.userData.grow = Math.min(1, b.userData.grow + dt * 0.4); b.children.forEach(m => m.geometry.setDrawRange(0, Math.floor(m.geometry.index.count * b.userData.grow / 3) * 3)); }
    });
    placed.forEach(m => {
      if (m.userData.grow !== undefined) { m.userData.grow = Math.min(1, m.userData.grow + dt * 3); const s = 1 + Math.sin(m.userData.grow * Math.PI) * 0.15; m.scale.setScalar(Math.max(0.05, m.userData.grow * s)); if (m.userData.grow >= 1) { m.scale.setScalar(1); delete m.userData.grow; } }
      m.traverse(o => { if (o.userData.spin) o.rotation.y += dt * 1.2; if (o.userData.hover) { o.position.y = 1.6 + Math.sin(t * 2) * 0.15; o.rotation.y += dt * 0.8; } if (o.userData.waddle) o.rotation.z = Math.sin(t * 4) * 0.08; });
    });
    pigs.forEach(p => {
      const m = p.mesh;
      const dx = p.tx - m.position.x, dz = p.tz - m.position.z, d = Math.hypot(dx, dz);
      let moving = false;
      if (p.wait > 0) p.wait -= dt;
      else if (d < 0.2) { p.wait = 1 + Math.random() * 3; const a = Math.random() * 6.28, r = Math.random() * (R - 2); p.tx = Math.cos(a) * r; p.tz = Math.sin(a) * r; if (lowG && Math.random() < 0.5) p.hop = 1; }
      else {
        moving = true;
        const want = Math.atan2(dx, dz); let diff = want - m.rotation.y; diff = Math.atan2(Math.sin(diff), Math.cos(diff));
        m.rotation.y += diff * Math.min(1, dt * 6);
        const step = Math.min(d, dt * 1.3); m.position.x += dx / d * step; m.position.z += dz / d * step;
      }
      p.hop = Math.max(0, p.hop - dt * (lowG ? 0.8 : 2.2));
      m.position.y = (moving ? Math.abs(Math.sin(t * 9 + p.id)) * 0.08 : 0) + Math.sin(p.hop * Math.PI) * (lowG ? 2.2 : 0.5);
      m.userData.head.rotation.x = moving ? Math.sin(t * 9) * 0.05 : Math.sin(t * 1.5 + p.id) * 0.08;
    });
    placeCamera();
    renderer.render(scene, camera);
  }
  state.loop = () => { state.running = true; clock.getDelta(); frame(); };
  // Coming back from a game: new pigs, and maybe a newly opened world.
  state.enter = () => { syncPigs(); buildWorld(currentWorld()); };
  gardenState = state;
  syncPigs();
  buildWorld(currentWorld());
  gardenHint();
  frame();
}
