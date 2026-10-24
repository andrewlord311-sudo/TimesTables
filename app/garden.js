// ---- Guinea Pig Garden: the 3D reward world (Three.js) ----
// Stars earned in every game (see addStars in columns.js) are spent here on
// things for the garden. Her guinea pigs (the ones she has unlocked on the
// farm) wander about in it; tap one and it squeaks. Everything is built from
// simple shapes in code, so there are no model files to load. Placed items are
// saved in localStorage ('ttg_garden').
//
// Three.js r128 (global build) is loaded from a CDN on first visit.

const GARDEN_KEY = 'ttg_garden';
const THREE_URL = 'https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js';
const GARDEN_ITEMS = [
  { id: 'flowers',  name: 'Flowers',   emoji: '🌸', cost: 2 },
  { id: 'sunflower',name: 'Sunflower', emoji: '🌻', cost: 3 },
  { id: 'bush',     name: 'Bush',      emoji: '🌿', cost: 3 },
  { id: 'carrots',  name: 'Carrots',   emoji: '🥕', cost: 4 },
  { id: 'hay',      name: 'Hay bale',  emoji: '🌾', cost: 3 },
  { id: 'ball',     name: 'Ball',      emoji: '🔴', cost: 4 },
  { id: 'tree',     name: 'Tree',      emoji: '🌳', cost: 5 },
  { id: 'tunnel',   name: 'Tunnel',    emoji: '🕳️', cost: 6 },
  { id: 'pond',     name: 'Pond',      emoji: '💧', cost: 10 },
  { id: 'hutch',    name: 'Hutch',     emoji: '🏠', cost: 12 },
  { id: 'rainbow',  name: 'Rainbow',   emoji: '🌈', cost: 15 },
];
const PIG_COLOURS = { // body, belly/patch
  1: [0x6b5b4e, 0xf0e6d6], 2: [0xf3e2b3, 0xffffff], 3: [0xc98a4b, 0xf6e3c4], 4: [0x7d7d80, 0xe9e9e9],
  5: [0xe0792a, 0xffe2c0], 6: [0xf4f4f0, 0xffffff], 7: [0xa8794e, 0xf1dfc0], 0: [0xd9a15f, 0xfff0d8],
};

let gardenState = null;    // everything three.js; null until first visit
let gardenSel = null;      // selected shop item id, or 'remove'

function loadGarden() {
  try { return JSON.parse(localStorage.getItem(GARDEN_KEY)) || { items: [], spent: 0 }; }
  catch { return { items: [], spent: 0 }; }
}
function saveGarden(g) { try { localStorage.setItem(GARDEN_KEY, JSON.stringify(g)); } catch {} }
function starBalance() {
  let earned = 0;
  try { earned = (JSON.parse(localStorage.getItem(REWARDS_KEY)) || {}).stars || 0; } catch {}
  return earned - loadGarden().spent;
}

function startGardenGame() {
  if (actx.state === 'suspended') actx.resume();
  showScreen('screen-garden');
  renderGardenShop();
  if (gardenState) { gardenState.running = true; syncGardenPigs(); gardenState.loop(); return; }
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
  GARDEN_ITEMS.forEach(it => {
    const b = document.createElement('button');
    b.className = 'shop-item' + (gardenSel === it.id ? ' sel' : '') + (bal < it.cost ? ' poor' : '');
    b.innerHTML = `<span class="si-e">${it.emoji}</span><span class="si-n">${it.name}</span><span class="si-c">⭐ ${it.cost}</span>`;
    b.addEventListener('click', () => { gardenSel = gardenSel === it.id ? null : it.id; renderGardenShop(); gardenHint(); });
    shop.appendChild(b);
  });
  const r = document.createElement('button');
  r.className = 'shop-item' + (gardenSel === 'remove' ? ' sel' : '');
  r.innerHTML = '<span class="si-e">🧺</span><span class="si-n">Tidy up</span><span class="si-c">get ⭐ back</span>';
  r.addEventListener('click', () => { gardenSel = gardenSel === 'remove' ? null : 'remove'; renderGardenShop(); gardenHint(); });
  shop.appendChild(r);
}
function gardenHint() {
  const m = document.getElementById('garden-msg');
  if (gardenSel === 'remove') m.textContent = 'Tap something in the garden to put it away.';
  else if (gardenSel) m.textContent = 'Now tap the grass to put it there!';
  else m.textContent = 'Drag to look around. Tap a guinea pig!';
}

function buildGarden() {
  const T = THREE;
  const canvas = document.getElementById('garden-canvas');
  const renderer = new T.WebGLRenderer({ canvas, antialias: true });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = T.PCFSoftShadowMap;
  const scene = new T.Scene();
  const sky = new T.Color(0xbfe6ff);
  scene.background = sky;
  scene.fog = new T.Fog(sky, 30, 70);
  const camera = new T.PerspectiveCamera(45, 1, 0.1, 200);
  scene.add(new T.HemisphereLight(0xffffff, 0x88aa66, 0.85));
  const sun = new T.DirectionalLight(0xfff2d0, 0.9);
  sun.position.set(8, 14, 6);
  sun.castShadow = true;
  sun.shadow.mapSize.set(1024, 1024);
  Object.assign(sun.shadow.camera, { left: -14, right: 14, top: 14, bottom: -14, near: 1, far: 40 });
  scene.add(sun);

  const R = 11;                                    // garden radius
  const mat = (c, o) => new T.MeshStandardMaterial(Object.assign({ color: c, roughness: 0.85, flatShading: true }, o || {}));
  const ground = new T.Mesh(new T.CylinderGeometry(R, R + 0.4, 0.6, 48), mat(0x7ccf5a));
  ground.position.y = -0.3; ground.receiveShadow = true; scene.add(ground);
  const rim = new T.Mesh(new T.TorusGeometry(R + 0.2, 0.25, 8, 64), mat(0x8a6a3d));
  rim.rotation.x = Math.PI / 2; scene.add(rim);
  // grass tufts and distant hills, fixed seed so it looks the same each visit
  let seed = 7; const rand = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const tuftG = new T.ConeGeometry(0.07, 0.35, 4), tuftM = mat(0x5fb847);
  for (let i = 0; i < 260; i++) {
    const a = rand() * Math.PI * 2, d = Math.sqrt(rand()) * (R - 0.5);
    const t = new T.Mesh(tuftG, tuftM); t.position.set(Math.cos(a) * d, 0.15, Math.sin(a) * d); scene.add(t);
  }
  [[-40, -30, 9], [22, -42, 12], [46, -10, 8], [-46, 8, 10]].forEach(([x, z, r]) => {
    const h = new T.Mesh(new T.SphereGeometry(r, 16, 10), mat(0x8ed36a)); h.position.set(x, -r * 0.45, z); scene.add(h);
  });
  const clouds = [];
  for (let i = 0; i < 6; i++) {
    const c = new T.Group();
    for (let k = 0; k < 4; k++) { const p = new T.Mesh(new T.SphereGeometry(1 + rand() * 0.8, 10, 8), mat(0xffffff, { flatShading: false, roughness: 1 })); p.position.set(k * 1.3 - 2, rand() * 0.4, rand()); c.add(p); }
    c.position.set(-30 + i * 12, 12 + rand() * 5, -14 - rand() * 14); scene.add(c); clouds.push(c);
  }

  // ---- items ----
  const itemGroup = new T.Group(); scene.add(itemGroup);
  const G = loadGarden();
  const cast = o => { o.traverse(m => { if (m.isMesh) { m.castShadow = true; m.receiveShadow = true; } }); return o; };
  function sphere(r, c, x, y, z, sx, sy, sz) { const m = new T.Mesh(new T.SphereGeometry(r, 12, 9), mat(c)); m.position.set(x, y, z); m.scale.set(sx || 1, sy || 1, sz || 1); return m; }
  function box(w, h, d, c, x, y, z) { const m = new T.Mesh(new T.BoxGeometry(w, h, d), mat(c)); m.position.set(x, y, z); return m; }
  function cyl(rt, rb, h, c, x, y, z) { const m = new T.Mesh(new T.CylinderGeometry(rt, rb, h, 10), mat(c)); m.position.set(x, y, z); return m; }
  function makeItem(id) {
    const g = new T.Group();
    if (id === 'flowers') {
      const cols = [0xff6fa5, 0xffd23f, 0xb07cff, 0xff8a3d, 0xffffff];
      for (let i = 0; i < 6; i++) { const x = (rand() - 0.5) * 1.1, z = (rand() - 0.5) * 1.1;
        g.add(cyl(0.025, 0.025, 0.4, 0x3a9a3a, x, 0.2, z)); g.add(sphere(0.12, cols[i % 5], x, 0.45, z)); g.add(sphere(0.05, 0xffe066, x, 0.5, z)); }
    } else if (id === 'sunflower') {
      g.add(cyl(0.04, 0.05, 1.2, 0x3a9a3a, 0, 0.6, 0)); const f = sphere(0.32, 0xffc619, 0, 1.25, 0.05, 1, 1, 0.3); g.add(f); g.add(sphere(0.16, 0x6b3f1d, 0, 1.25, 0.12, 1, 1, 0.4));
    } else if (id === 'bush') {
      g.add(sphere(0.6, 0x3f9d44, 0, 0.5, 0)); g.add(sphere(0.45, 0x4fb355, 0.4, 0.4, 0.2)); g.add(sphere(0.4, 0x3a8f3f, -0.4, 0.35, -0.2));
    } else if (id === 'carrots') {
      for (let i = 0; i < 5; i++) { const x = (i - 2) * 0.28, z = (i % 2) * 0.2 - 0.1;
        g.add(sphere(0.12, 0x3fa143, x, 0.2, z, 1, 1.3, 1)); const c = new T.Mesh(new T.ConeGeometry(0.08, 0.3, 8), mat(0xff8c1a)); c.position.set(x, 0.1, z); c.rotation.x = Math.PI; g.add(c); }
    } else if (id === 'hay') {
      const h = cyl(0.5, 0.5, 0.8, 0xe6c15a, 0, 0.5, 0); h.rotation.z = Math.PI / 2; g.add(h);
    } else if (id === 'ball') {
      g.add(sphere(0.35, 0xe84a4a, 0, 0.35, 0)); const s = sphere(0.355, 0xffffff, 0, 0.35, 0, 1, 0.18, 1); g.add(s);
    } else if (id === 'tree') {
      g.add(cyl(0.2, 0.28, 1.6, 0x8a5a2b, 0, 0.8, 0)); g.add(sphere(1.1, 0x3fa143, 0, 2.1, 0)); g.add(sphere(0.8, 0x4cb351, 0.7, 1.8, 0.2)); g.add(sphere(0.75, 0x37953c, -0.6, 1.7, -0.3));
      g.add(sphere(0.09, 0xff4040, 0.5, 2.3, 0.9)); g.add(sphere(0.09, 0xff4040, -0.4, 2.0, 0.95)); g.add(sphere(0.09, 0xff4040, 0.9, 1.6, 0.6));
    } else if (id === 'tunnel') {
      const arch = new T.Mesh(new T.CylinderGeometry(0.6, 0.6, 1.8, 16, 1, true, Math.PI / 2, Math.PI), mat(0xe0903c, { side: T.DoubleSide }));
      arch.rotation.x = Math.PI / 2; g.add(arch);   // a half-pipe lying along z, open at both ends
    } else if (id === 'pond') {
      const w = new T.Mesh(new T.CylinderGeometry(1.5, 1.5, 0.08, 28), mat(0x4aa8e8, { flatShading: false, roughness: 0.2, metalness: 0.1 })); w.position.y = 0.05; g.add(w);
      const r = new T.Mesh(new T.TorusGeometry(1.5, 0.16, 8, 28), mat(0x9a9a9a)); r.rotation.x = Math.PI / 2; r.position.y = 0.08; g.add(r);
      g.add(sphere(0.3, 0x3fa143, 0.5, 0.1, 0.3, 1, 0.1, 1));
    } else if (id === 'hutch') {
      g.add(box(2.2, 1.0, 1.4, 0xc58a4a, 0, 0.5, 0)); const roof = new T.Mesh(new T.ConeGeometry(1.5, 0.8, 4), mat(0xb03a2e)); roof.rotation.y = Math.PI / 4; roof.scale.set(1.1, 1, 0.75); roof.position.y = 1.4; g.add(roof);
      g.add(box(0.5, 0.6, 0.05, 0x3b2a1a, 0, 0.35, 0.72)); g.add(box(0.5, 0.35, 0.05, 0xfff4cf, -0.7, 0.62, 0.72));
      g.add(box(0.12, 0.05, 0.9, 0x8a5a2b, -0.5, 0.02, 1.0));
    } else if (id === 'rainbow') {
      ['e03b3b', 'ff9a2e', 'ffd93d', '4cc15a', '3fa0e8', '8a5cd6'].forEach((hex, i) => {
        const a = new T.Mesh(new T.TorusGeometry(2.6 - i * 0.22, 0.11, 8, 28, Math.PI), mat(parseInt(hex, 16))); a.position.y = 0; g.add(a); });
    }
    return cast(g);
  }
  const placed = [];
  function addItem(rec) {
    const m = makeItem(rec.id); m.position.set(rec.x, 0, rec.z); m.rotation.y = rec.rot || 0;
    m.userData.rec = rec; itemGroup.add(m); placed.push(m); return m;
  }
  G.items.forEach(addItem);

  // ---- guinea pigs ----
  function makePig(id) {
    const [bodyC, patchC] = PIG_COLOURS[id] || PIG_COLOURS[0];
    const g = new T.Group();
    const body = sphere(0.5, bodyC, 0, 0.42, 0, 1.0, 0.8, 1.35); g.add(body);
    g.add(sphere(0.38, patchC, 0, 0.3, 0.1, 0.9, 0.55, 1.1));
    const head = new T.Group(); head.position.set(0, 0.5, 0.62);
    head.add(sphere(0.36, bodyC, 0, 0, 0, 1, 0.95, 1.05)); head.add(sphere(0.2, patchC, 0, -0.06, 0.27, 1, 0.8, 0.9));
    head.add(sphere(0.06, 0xff9fb0, 0, 0.0, 0.42)); head.add(sphere(0.055, 0x111111, 0.15, 0.1, 0.3)); head.add(sphere(0.055, 0x111111, -0.15, 0.1, 0.3));
    head.add(sphere(0.02, 0xffffff, 0.16, 0.12, 0.34)); head.add(sphere(0.02, 0xffffff, -0.14, 0.12, 0.34));
    head.add(sphere(0.13, 0xe9a1a8, 0.3, 0.22, -0.05, 0.4, 1, 1)); head.add(sphere(0.13, 0xe9a1a8, -0.3, 0.22, -0.05, 0.4, 1, 1));
    g.add(head);
    [[0.25, 0.4], [-0.25, 0.4], [0.25, -0.4], [-0.25, -0.4]].forEach(([x, z]) => g.add(sphere(0.1, patchC, x, 0.08, z, 1, 0.7, 1.3)));
    g.userData = { head, body };
    return cast(g);
  }
  const pigs = [];
  function syncGardenPigs() {
    const cleared = loadProgress().clearedStages;
    const want = [0].concat(cleared);   // 0 = Pip, the garden's own pig
    want.forEach(id => {
      if (pigs.find(p => p.id === id)) return;
      const mesh = makePig(id); scene.add(mesh);
      const a = rand() * 6.28, d = 2 + rand() * 4;
      mesh.position.set(Math.cos(a) * d, 0, Math.sin(a) * d);
      const name = id === 0 ? 'Pip' : (FARM_PIGS.find(f => f.id === id) || {}).name;
      pigs.push({ id, name, mesh, tx: mesh.position.x, tz: mesh.position.z, wait: rand() * 2, hop: 0, squeak: 0 });
    });
  }
  syncGardenPigs();

  // ---- camera orbit, pointer handling ----
  let az = 0.6, pol = 0.95, dist = 22, drag = null;
  function placeCamera() {
    camera.position.set(Math.sin(az) * Math.sin(pol) * dist, Math.cos(pol) * dist, Math.cos(az) * Math.sin(pol) * dist);
    camera.lookAt(0, 0.5, 0);
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
  canvas.addEventListener('wheel', e => { e.preventDefault(); dist = Math.min(30, Math.max(10, dist + e.deltaY * 0.02)); }, { passive: false });

  const ray = new T.Raycaster(), ndc = new T.Vector2(), plane = new T.Plane(new T.Vector3(0, 1, 0), 0);
  function tapAt(e) {
    const r = canvas.getBoundingClientRect();
    ndc.set(((e.clientX - r.left) / r.width) * 2 - 1, -((e.clientY - r.top) / r.height) * 2 + 1);
    ray.setFromCamera(ndc, camera);
    if (gardenSel === 'remove') {
      const hit = ray.intersectObjects(itemGroup.children, true)[0];
      if (hit) {
        let o = hit.object; while (o.parent !== itemGroup) o = o.parent;
        const rec = o.userData.rec, it = GARDEN_ITEMS.find(i => i.id === rec.id);
        itemGroup.remove(o); placed.splice(placed.indexOf(o), 1);
        G.items.splice(G.items.indexOf(rec), 1); G.spent -= it.cost; saveGarden(G);
        playGentleBlip(); renderGardenShop();
      }
      return;
    }
    if (gardenSel) {
      const it = GARDEN_ITEMS.find(i => i.id === gardenSel);
      const p = new T.Vector3();
      if (!ray.ray.intersectPlane(plane, p) || p.length() > R - 1) { document.getElementById('garden-msg').textContent = 'Tap on the grass!'; return; }
      if (starBalance() < it.cost) { document.getElementById('garden-msg').textContent = `You need ⭐ ${it.cost}. Play a game to earn more!`; return; }
      const rec = { id: it.id, x: Math.round(p.x * 2) / 2, z: Math.round(p.z * 2) / 2, rot: (Math.random() - 0.5) * 0.8 };
      G.items.push(rec); G.spent += it.cost; saveGarden(G);
      const m = addItem(rec); m.scale.setScalar(0.05); m.userData.grow = 0;
      playSuccessChime(); renderGardenShop();
      return;
    }
    const meshes = pigs.map(p => p.mesh);
    const hit = ray.intersectObjects(meshes, true)[0];
    if (hit) {
      let o = hit.object; while (!meshes.includes(o)) o = o.parent;
      const pig = pigs.find(p => p.mesh === o);
      pig.hop = 1; pig.squeak = 1;
      playTone(900, actx.currentTime, 0.08, 0.15); playTone(1250, actx.currentTime + 0.08, 0.1, 0.15);
      document.getElementById('garden-msg').textContent = `${pig.name} says wheek! 💕`;
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
    clouds.forEach((c, i) => { c.position.x += dt * (0.4 + i * 0.05); if (c.position.x > 40) c.position.x = -40; });
    placed.forEach(m => { if (m.userData.grow !== undefined) { m.userData.grow = Math.min(1, m.userData.grow + dt * 3); const s = 1 + Math.sin(m.userData.grow * Math.PI) * 0.15; m.scale.setScalar(Math.max(0.05, m.userData.grow * s)); if (m.userData.grow >= 1) { m.scale.setScalar(1); delete m.userData.grow; } } });
    pigs.forEach(p => {
      const m = p.mesh;
      const dx = p.tx - m.position.x, dz = p.tz - m.position.z, d = Math.hypot(dx, dz);
      let moving = false;
      if (p.wait > 0) p.wait -= dt;
      else if (d < 0.2) { p.wait = 1 + Math.random() * 3; const a = Math.random() * 6.28, r = Math.random() * (R - 2); p.tx = Math.cos(a) * r; p.tz = Math.sin(a) * r; }
      else {
        moving = true;
        const want = Math.atan2(dx, dz); let diff = want - m.rotation.y; diff = Math.atan2(Math.sin(diff), Math.cos(diff));
        m.rotation.y += diff * Math.min(1, dt * 6);
        const step = Math.min(d, dt * 1.3); m.position.x += dx / d * step; m.position.z += dz / d * step;
      }
      p.hop = Math.max(0, p.hop - dt * 2.2);
      m.position.y = (moving ? Math.abs(Math.sin(t * 9 + p.id)) * 0.08 : 0) + Math.sin(p.hop * Math.PI) * 0.5;
      m.userData.head.rotation.x = moving ? Math.sin(t * 9) * 0.05 : Math.sin(t * 1.5 + p.id) * 0.08;
    });
    placeCamera();
    renderer.render(scene, camera);
  }
  state.loop = () => { state.running = true; clock.getDelta(); frame(); };
  gardenState = Object.assign(state, { syncPigs: syncGardenPigs });
  // syncGardenPigs above is the closure over THIS scene; expose it for revisits
  window.syncGardenPigs = syncGardenPigs;
  gardenHint();
  frame();
}
