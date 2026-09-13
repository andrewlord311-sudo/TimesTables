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

// ---- Guinea pig farm - 7 collectible pigs, one per stage ----
// All share the same base artwork (GUINEA_PIG_SVG below); each pig gets a
// distinct look via a CSS filter rather than separate hand-colored art.
// Stages 1 and 2 are Clara's OWN guinea pigs, so the first thing she unlocks
// is something she actually knows. The remaining five stay invented friends
// she collects. Evie is cream/pale yellow (see the 6.9.26 photo); Dreamy's
// filter is a guess from the same photo's background and is one line to
// change. Squeaky is deliberately not here.
const FARM_PIGS = [
  { id: 1, name: 'Dreamy', real: true, filter: 'grayscale(0.55) brightness(0.78)' },
  { id: 2, name: 'Evie', real: true, filter: 'brightness(1.32) saturate(0.55)' },
  { id: 3, name: 'Butterscotch', filter: 'none' },
  { id: 4, name: 'Smokey', filter: 'grayscale(1) brightness(0.85)' },
  { id: 5, name: 'Marmalade', filter: 'hue-rotate(-20deg) saturate(1.4)' },
  { id: 6, name: 'Marshmallow', filter: 'grayscale(0.5) brightness(1.25)' },
  { id: 7, name: 'Biscuit', filter: 'sepia(0.4) hue-rotate(-10deg)' },
];

// ---- Guinea pig artwork ----
// Real illustration Andrew provided (images/guinea-pig-svgrepo-com.svg),
// inlined so CSS filters/animations can be applied to it directly. One
// fixed drawing - "mood" is expressed through animation classes on the
// wrapper (see .pip.happy / .pip.sad / .idle in style.css), not by
// swapping to a different static drawing the way the old hand-drawn
// version did.
const GUINEA_PIG_SVG = `<svg viewBox="0 0 512 512" class="pig-svg" xmlns="http://www.w3.org/2000/svg">
<path style="fill:#FFEBD2;" d="M376.006,288c0,0-72-2-72-90V96c0-26.51-21.49-48-48-48s-48,21.49-48,48v102c0,88-72,90-72,90H28.343
	C21.625,303.251,8,337.018,8,360l24-8v72h40l-8,32h40l-8,24c0,0,53,24,160,24l-0.004-0.008c0.002,0,0.005,0,0.007,0L256,503.998
	c0.177,0,0.35-0.001,0.527-0.002c0.197,0,0.394-0.001,0.591-0.002C363.364,503.826,416,479.998,416,479.998l-8-24h40l-8-32h40v-72
	l24,8c0-22.981-13.624-56.745-20.342-71.998H376.006z"/>
<path style="fill:#FFA54B;" d="M208.006,198V96c0-26.51,21.49-48,48-48s48,21.49,48,48v102c0,88,72,90,72,90h107.652
	c-2.198-4.99-3.658-8.002-3.658-8.002l24,8c0-20-40-88-40-88h1.147c-0.723-1.285-1.129-1.998-1.129-1.998h14.837
	c-4.061-6.965-18.207-30.202-30.402-37.716c1.2-0.606,2.381-1.261,3.553-1.938C436.831,137.08,417.972,111.005,402,90
	c-16.741-22.016-31.952-41.029-51.023-55.283C321.556,17.834,289.421,8,256,8c-36.871,0-72.177,11.969-104.001,32.168l-5.706,4.328
	c-1.852-1.781-3.729-3.395-5.626-4.859c-46.895,30.58-75.362,76.628-91.324,111.202c4.425,3.771,9.199,6.917,14.206,9.446
	c-12.194,7.511-26.34,30.747-30.402,37.715h14.848c0,0-0.408,0.714-1.131,2H48c0,0-34.315,58.338-39.375,82.835
	c-0.398,1.956-0.618,3.697-0.619,5.163L32,280c0,0-1.459,3.011-3.657,8h107.664C136.006,288,208.006,286,208.006,198z
	 M446.667,161.147c0.313-0.147,0.627-0.289,0.938-0.441l-0.938,1.68V161.147z"/>
<circle style="fill:#D7A091;" cx="256.01" cy="416" r="32"/>
<path style="fill:#EBB4A0;" d="M256.019,328c-0.004,0-0.009,0-0.009,0s-0.012,0-0.016,0c-30.935,0-59.54,12.83-56.013,48
	c8.024,80,40.024,56,56.013,56c0.004,0,0.008-0.001,0.008-0.001s0.013,0.001,0.017,0.001c15.987,0,47.987,24,56.012-56
	C315.559,340.83,286.953,328,256.019,328z"/>
<g>
	<path style="fill:#FF8C46;" d="M165.175,87.705c-1.743-15.675-8.529-30.984-20.645-42.908
		c-30.911-30.422-68.911-15.088-90.911,10.912C27.934,86.064,14.59,118.502,42.707,146.62C60.207,164.12,95.333,175,128,164
		c8.178-2.753-6.333-26.333-14-42l35,11c0,0-9.116-41.194-24-66L165.175,87.705z"/>
	<path style="fill:#FF8C46;" d="M345,85.705c1.743-15.675,8.529-30.984,20.645-42.908c30.912-30.422,68.912-15.088,90.912,10.912
		C482.242,84.064,497.118,116.883,469,145c-16.506,16.506-35,31.333-83,19c-10.245-2.632,6.333-37.667,10-43l-36,15
		c0,0,12.213-43.688,28-70L345,85.705z"/>
</g>
<path d="M176,192c-11.797,0-16,16.53-16,32s4.203,32,16,32s16-16.53,16-32S187.797,192,176,192z"/>
<path d="M336,192c-11.797,0-16,16.53-16,32s4.203,32,16,32s16-16.53,16-32S347.797,192,336,192z"/>
<path d="M234.343,381.657c1.562,1.562,3.609,2.343,5.657,2.343s4.095-0.781,5.657-2.343c3.125-3.124,3.125-8.19,0-11.314l-16-16
	c-3.124-3.124-8.189-3.124-11.313,0c-3.125,3.124-3.125,8.19,0,11.314L234.343,381.657z"/>
<path d="M272,384c2.047,0,4.095-0.781,5.657-2.343l16-16c3.125-3.124,3.125-8.19,0-11.314c-3.124-3.124-8.189-3.124-11.313,0l-16,16
	c-3.125,3.124-3.125,8.19,0,11.314C267.905,383.219,269.953,384,272,384z"/>
<path d="M300.313,424.9c-16.255,8.44-30.724-0.332-36.313-4.608V400c0-4.418-3.582-8-8-8s-8,3.582-8,8v20.295
	c-5.598,4.279-20.068,13.04-36.313,4.605c-3.922-2.037-8.751-0.508-10.787,3.413s-0.508,8.75,3.414,10.787
	c7.576,3.934,14.823,5.425,21.467,5.425c13.228,0,24.044-5.92,30.219-10.281c6.175,4.361,16.99,10.281,30.22,10.281
	c6.642,0,13.893-1.492,21.467-5.425c3.921-2.036,5.449-6.865,3.414-10.787C309.064,424.393,304.236,422.864,300.313,424.9z"/>
<path d="M264,448h-16c-4.418,0-8,3.582-8,8s3.582,8,8,8h16c4.418,0,8-3.582,8-8S268.418,448,264,448z"/>
<path d="M501.47,295.587c2.439,0.813,5.122,0.404,7.208-1.1c2.086-1.503,3.322-3.918,3.322-6.49c0-16.88-21.896-58.168-34.178-80
	H480c2.834,0,5.458-1.5,6.895-3.943c1.438-2.443,1.475-5.464,0.098-7.942c-1.499-2.698-12.477-22.102-24.864-34.757
	c3.669-2.602,7.171-5.519,10.439-8.787c27.181-27.181,23.661-61.409-10.461-101.736c-15.615-18.454-36.092-29.564-56.182-30.48
	c-14.556-0.662-28.454,4.113-40.601,13.849c-0.313-0.276-0.645-0.539-1.008-0.77C329.375,11.248,292.933,0,256,0
	c-36.922,0-73.355,11.242-108.288,33.414c-0.373,0.237-0.713,0.506-1.032,0.791c-12.147-9.736-26.044-14.51-40.605-13.852
	c-20.089,0.916-40.567,12.026-56.182,30.48C15.77,91.16,12.251,125.388,39.432,152.569c3.269,3.269,6.771,6.187,10.44,8.789
	c-12.388,12.655-23.366,32.06-24.865,34.758c-1.376,2.478-1.339,5.499,0.098,7.943C26.542,206.5,29.166,208,32,208h2.178
	C21.896,229.832,0,271.119,0,288c0,2.572,1.236,4.986,3.322,6.49s4.769,1.913,7.208,1.1l6.84-2.28C10.056,311.047,0,339.215,0,360
	c0,2.572,1.236,4.986,3.322,6.49s4.769,1.913,7.208,1.1L24,363.1V424c0,4.418,3.582,8,8,8h29.754l-5.515,22.06
	c-0.597,2.39-0.061,4.922,1.456,6.864S61.537,464,64,464h28.9l-4.49,13.47c-1.296,3.888,0.556,8.127,4.289,9.817
	C94.928,488.297,148.509,512,256,512c0.018,0,0.034-0.002,0.052-0.003c107.457-0.007,161.021-23.703,163.249-24.712
	c3.733-1.69,5.585-5.929,4.289-9.817l-4.49-13.47H448c2.463,0,4.79-1.135,6.306-3.077s2.053-4.474,1.456-6.863l-5.515-22.06H480
	c4.418,0,8-3.582,8-8v-60.9l13.47,4.49c2.439,0.813,5.122,0.404,7.208-1.1c2.086-1.503,3.322-3.918,3.322-6.49
	c0-20.785-10.056-48.953-17.37-66.69L501.47,295.587z M370.7,50.79c10.327-10.163,21.932-15.031,34.497-14.454
	c15.426,0.704,32.135,9.986,44.696,24.832c37.569,44.399,24.478,66.971,11.362,80.087c-4.346,4.346-9.184,7.961-14.351,10.824
	c-1.718,0.239-3.34,1.033-4.594,2.306c-16.305,7.386-35.23,7.675-52.17,0.168c2.13-7.78,6.813-17.646,16.167-29.63
	c2.224-2.85,2.261-6.837,0.089-9.728c-2.171-2.89-6.01-3.966-9.367-2.623l-25.204,10.082c4.606-15.253,13.242-38.666,26.181-53.369
	c2.328-2.646,2.651-6.504,0.794-9.5s-5.456-4.424-8.861-3.515c-1.107,0.295-16.25,4.455-32.937,14.86
	C360.194,63.507,364.831,56.565,370.7,50.79z M62.107,61.168c12.562-14.846,29.27-24.128,44.696-24.832
	c12.57-0.58,24.17,4.291,34.497,14.454c5.869,5.776,10.505,12.717,13.698,20.339c-16.688-10.405-31.83-14.564-32.937-14.86
	c-3.407-0.908-7.004,0.52-8.861,3.515c-1.857,2.996-1.534,6.854,0.794,9.5c12.909,14.669,21.555,38.1,26.171,53.365l-25.194-10.078
	c-3.357-1.342-7.196-0.268-9.367,2.623s-2.135,6.877,0.089,9.728c9.354,11.985,14.037,21.85,16.167,29.63
	c-16.942,7.508-35.87,7.218-52.176-0.17c-1.252-1.269-2.869-2.061-4.582-2.301c-5.169-2.863-10.01-6.479-14.357-10.827
	C37.629,128.139,24.538,105.567,62.107,61.168z M495.008,348.568l-12.479-4.16c-2.439-0.813-5.122-0.404-7.208,1.1
	c-2.086,1.503-3.322,3.918-3.322,6.49v64h-32c-2.463,0-4.79,1.135-6.306,3.077s-2.053,4.474-1.456,6.864l5.515,22.06H408
	c-2.572,0-4.986,1.237-6.49,3.322c-1.504,2.086-1.913,4.768-1.1,7.208l5.583,16.749c-17.203,6.06-67.373,20.721-149.993,20.721
	c-0.015,0-0.029,0.002-0.043,0.002c-82.607-0.005-132.764-14.666-149.95-20.721l5.583-16.749c0.813-2.439,0.404-5.122-1.1-7.208
	c-1.503-2.086-3.918-3.322-6.49-3.322H74.246l5.515-22.06c0.597-2.39,0.061-4.922-1.456-6.863C76.79,417.135,74.463,416,72,416H40
	v-64c0-2.572-1.236-4.986-3.322-6.489c-2.086-1.504-4.768-1.913-7.208-1.1l-12.477,4.159c4.41-28.092,22.002-64.662,22.206-65.081
	c1.402-2.896,0.935-6.35-1.189-8.768c-2.123-2.417-5.487-3.329-8.54-2.311l-10.588,3.53c6.798-19.199,24.15-51.714,36.014-71.884
	c1.455-2.474,1.474-5.538,0.049-8.028S50.87,192,48,192h-1.751c5.554-8.423,12.361-17.419,18.2-22.449
	c9.978,4.301,20.694,6.524,31.501,6.524c9.003,0,18.063-1.538,26.798-4.654c-0.247,1.076-0.534,1.982-0.813,2.715
	c-2.049,5.397-6.199,9.041-11.385,9.997c-4.345,0.8-7.219,4.971-6.418,9.316c0.71,3.855,4.074,6.553,7.858,6.553
	c0.481,0,0.969-0.044,1.458-0.134c10.658-1.963,19.422-9.458,23.444-20.051c2.965-7.808,5.279-22.423-4.845-43.181l16.98,6.792
	c2.741,1.097,5.865,0.594,8.125-1.309c2.259-1.902,3.286-4.895,2.671-7.784c-0.318-1.497-6.135-28.31-18.702-52.731
	c12.573,6.94,27.248,17.922,35.802,34.131c2.063,3.907,6.902,5.403,10.809,3.341c3.908-2.063,5.403-6.902,3.341-10.809
	c-4.256-8.065-9.657-15-15.555-20.939c-0.006-0.072-0.005-0.143-0.013-0.215c-1.701-15.298-7.766-29.714-17.269-41.409
	C189.965,25.996,222.843,16,256,16s66.036,9.996,97.76,29.703c-9.503,11.696-15.567,26.111-17.268,41.41
	c-0.008,0.072-0.007,0.142-0.013,0.213c-5.897,5.938-11.298,12.875-15.555,20.94c-2.062,3.907-0.566,8.747,3.341,10.809
	c3.907,2.061,8.747,0.566,10.809-3.341c8.556-16.211,23.229-27.192,35.802-34.132c-12.566,24.422-18.383,51.236-18.702,52.732
	c-0.615,2.889,0.412,5.882,2.671,7.784s5.382,2.405,8.125,1.309l16.98-6.792c-10.124,20.758-7.81,35.374-4.845,43.181
	c4.022,10.592,12.787,18.087,23.444,20.051c0.49,0.09,0.977,0.134,1.458,0.134c3.784,0,7.148-2.698,7.858-6.553
	c0.8-4.346-2.073-8.517-6.418-9.316c-5.186-0.956-9.335-4.599-11.385-9.997c-0.278-0.732-0.565-1.639-0.813-2.715
	c8.735,3.117,17.794,4.654,26.798,4.654c10.812,0,21.534-2.226,31.517-6.531c6.108,5.215,12.928,14.459,18.178,22.454H464
	c-2.87,0-5.52,1.538-6.944,4.028c-1.425,2.491-1.406,5.555,0.049,8.028c11.863,20.17,29.216,52.685,36.014,71.884l-10.588-3.529
	c-3.052-1.018-6.418-0.107-8.542,2.311c-2.123,2.418-2.591,5.874-1.187,8.769C473.004,283.906,490.602,320.454,495.008,348.568z"/>
</svg>`;

function guineaPigSvg(pig) {
  const filter = (pig && pig.filter) || 'none';
  return `<div class="pig-tint" style="filter: ${filter};">${GUINEA_PIG_SVG}</div>`;
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
    slot.innerHTML = unlocked ? guineaPigSvg(pig) : '<span class="lock-icon">🔒</span>';
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

// ---- What Clara actually finds hard ----
// Every fact (7x8, 3x4, ...) gets its own little record, so questions can be
// weighted towards the ones she misses instead of drawn uniformly at random.
// Without this, 2x1 comes up exactly as often as 7x8 forever.
//
// The mastery signal is HOW LONG a correct answer took, not just whether it
// was right: answering 7x8 correctly after six seconds means she counted it
// up, and it should keep coming back; answering in one second means she knows
// it. The timer is never shown -- visible clocks mostly just make children
// anxious, and the information is just as good collected quietly.
const FACTS_KEY = 'ttg_facts';
const factKey = (t, m) => `${t}x${m}`;

function loadFacts() {
  try { return JSON.parse(localStorage.getItem(FACTS_KEY)) || {}; }
  catch { return {}; }
}
function saveFacts(f) { localStorage.setItem(FACTS_KEY, JSON.stringify(f)); }

function recordAttempt(table, multiplier, correct, ms, helped) {
  const facts = loadFacts();
  const k = factKey(table, multiplier);
  const rec = facts[k] || { attempts: 0, correct: 0, avgMs: 0, lastWrong: false, helped: 0 };
  rec.attempts++;
  if (helped) rec.helped++;
  if (correct) {
    rec.correct++;
    // Weighted running average, so recent attempts matter more than the
    // first nervous one.
    rec.avgMs = rec.avgMs ? Math.round(rec.avgMs * 0.6 + ms * 0.4) : ms;
    // Needing the choices counts as not knowing it, even though the answer
    // she then tapped was right.
    rec.lastWrong = !!helped;
  } else {
    rec.lastWrong = true;
  }
  facts[k] = rec;
  saveFacts(facts);
}

// How badly a fact needs practice. Deliberately coarse -- this only has to
// put the shaky ones in front of her more often, not model her memory.
//
// The ORDER matters and was got wrong first time: struggling has to outrank
// novelty. With "unseen" above "slow", a fact she could only reach by
// counting on her fingers came up LESS often than one she had never been
// asked (measured: 0.9% against 2.1%), which is precisely backwards. Never
// seen still ranks above comfortably known, so new facts keep being
// introduced -- it just no longer outranks a fact she is visibly struggling
// with.
function factWeight(rec) {
  if (!rec || !rec.attempts) return 4;     // never asked - keep introducing these
  if (rec.lastWrong) return 14;            // missed it, or needed help, last time
  if (rec.avgMs > 6000) return 8;          // right, but she clearly worked it out
  if (rec.avgMs > 3500) return 5;          // getting there
  return 1;                                 // fast and right - basically known
}

let lastFactKey = null;
function pickFact(tables) {
  const facts = loadFacts();
  const pool = [];
  tables.forEach(t => {
    for (let m = 1; m <= MAX_MULTIPLIER; m++) {
      const k = factKey(t, m);
      pool.push({ table: t, multiplier: m, key: k, weight: factWeight(facts[k]) });
    }
  });
  // Never ask the same fact twice running - a weighted pick would otherwise
  // hammer one hard fact over and over, which feels like punishment.
  const usable = pool.filter(p => p.key !== lastFactKey);
  const list = usable.length ? usable : pool;

  const total = list.reduce((s, p) => s + p.weight, 0);
  let r = Math.random() * total;
  for (const p of list) {
    r -= p.weight;
    if (r <= 0) { lastFactKey = p.key; return p; }
  }
  const last = list[list.length - 1];
  lastFactKey = last.key;
  return last;
}

// ---- Question generation ----
function generateQuestion(tables) {
  const { table, multiplier } = pickFact(tables);
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

// ---- Answer input (shared by both games) ----
// Typed entry, not multiple choice, is the default. The skill being built is
// RECALL: with three buttons she can succeed by elimination, and there is a
// 33% floor from guessing alone. The three choices are still there behind a
// "Stuck?" button, so a new stage never becomes a wall -- but taking that
// help is recorded, so the fact keeps coming back.
const pads = {};

function buildPad(prefix, onAnswer) {
  const pad = { value: '', askedAt: 0, helped: false, onAnswer, locked: false };
  pads[prefix] = pad;

  const wrap = document.getElementById(prefix + '-keypad');
  wrap.innerHTML = '';
  ['1', '2', '3', '4', '5', '6', '7', '8', '9', '⌫', '0', '✓'].forEach(k => {
    const b = document.createElement('button');
    b.className = 'key' + (k === '✓' ? ' key-go' : (k === '⌫' ? ' key-del' : ''));
    b.textContent = k;
    b.addEventListener('click', () => pressKey(prefix, k));
    wrap.appendChild(b);
  });

  document.getElementById(prefix + '-stuck').addEventListener('click', () => {
    showChoices(prefix);
  });
}

function pressKey(prefix, k) {
  const pad = pads[prefix];
  if (pad.locked) return;
  if (k === '⌫') pad.value = pad.value.slice(0, -1);
  else if (k === '✓') { submitTyped(prefix); return; }
  else if (pad.value.length < 3) pad.value += k;       // 12x12=144, 3 digits is plenty
  drawTyped(prefix);
}

function drawTyped(prefix) {
  const el = document.getElementById(prefix + '-typed');
  const pad = pads[prefix];
  el.textContent = pad.value || '?';
  el.classList.toggle('empty', !pad.value);
}

function submitTyped(prefix) {
  const pad = pads[prefix];
  if (!pad.value || pad.locked) return;
  pad.onAnswer(parseInt(pad.value, 10), null);
}

// Called by each game when a wrong answer needs clearing so she can retry.
function clearTyped(prefix) {
  pads[prefix].value = '';
  drawTyped(prefix);
}

function showChoices(prefix) {
  const pad = pads[prefix];
  pad.helped = true;
  document.getElementById(prefix + '-choices').classList.remove('hidden');
  document.getElementById(prefix + '-stuck').classList.add('hidden');
}

// Fresh question: clear the input, hide the choices again, start the clock.
function resetPad(prefix, question, onChoice) {
  const pad = pads[prefix];
  pad.value = '';
  pad.helped = false;
  pad.locked = false;
  pad.askedAt = Date.now();
  drawTyped(prefix);

  document.getElementById(prefix + '-stuck').classList.remove('hidden');
  const choices = document.getElementById(prefix + '-choices');
  choices.classList.add('hidden');
  choices.innerHTML = '';
  question.options.forEach(n => {
    const btn = document.createElement('button');
    btn.className = 'choice-btn';
    btn.textContent = n;
    btn.addEventListener('click', () => onChoice(n, btn));
    choices.appendChild(btn);
  });
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
// Clearing a stage used to need 8 correct IN A ROW. That was a fair bar when
// the answer was one of three buttons; asking for a flawless run of eight
// from memory is a different thing entirely, and a stage she can never clear
// is a stage she stops visiting. So the session is still 8 correct answers,
// but up to this many slips still count as a clear.
const MISTAKES_ALLOWED = 2;

let feedRound = 0;
let feedMistakes = 0;
let feedQuestion = null;

function startFeedGame() {
  feedRound = 0;
  feedMistakes = 0;
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
  resetPad('feed', feedQuestion, handleFeedAnswer);
  const pip = document.getElementById('feed-pip');
  if (!pip.hasChildNodes()) pip.innerHTML = guineaPigSvg(FARM_PIGS[0]);
  pip.classList.remove('happy', 'sad');
  pip.classList.add('idle');
}

function handleFeedAnswer(n, btn) {
  const pad = pads['feed'];
  const pip = document.getElementById('feed-pip');
  const correct = n === feedQuestion.product;
  recordAttempt(feedQuestion.table, feedQuestion.multiplier, correct,
                Date.now() - pad.askedAt, pad.helped);

  if (correct) {
    pad.locked = true;                       // no double-submits during the bounce
    if (btn) btn.classList.add('correct-flash');
    pip.classList.remove('idle');
    pip.classList.add('happy');
    playSuccessChime();
    document.querySelectorAll('#feed-dots .dot')[feedRound].classList.add('done');
    feedRound++;
    setTimeout(() => {
      pip.classList.remove('happy');
      nextFeedRound();
    }, 700);
  } else {
    if (btn) btn.classList.add('wrong-flash');
    clearTyped('feed');                      // wipe it so she can try again
    feedMistakes++;
    pip.classList.remove('idle');
    pip.classList.add('sad');
    playGentleBlip();
    if (btn) setTimeout(() => btn.classList.remove('wrong-flash'), 400);
    setTimeout(() => {
      pip.classList.remove('sad');
      pip.classList.add('idle');
    }, 500);
  }
}

// ---- Guinea Pig Jigsaw ----
// Real photos, not drawn SVGs - one dedicated picture per stage, so each
// stage has its own distinct picture to reveal rather than a random draw.
// To swap or add pictures: drop the file in images/ and update the entry
// for that stage number below.
const JIGSAW_IMAGES = {
  // Stage 1 is a real photo of Clara and Evie (6.9.26), deliberately first
  // rather than saved for stage 7 -- it is the hook, and it should be the
  // thing she uncovers on day one. One line to move it later if that's wrong.
  1: { file: 'images/clara-and-evie.jpg', name: 'you and Evie!', portrait: true },
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
  document.getElementById('jigsaw-stage-box')
    .classList.toggle('portrait', !!currentJigsawImage.portrait);
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
  resetPad('jigsaw', jigsawQuestion, handleJigsawAnswer);
}

function handleJigsawAnswer(n, btn) {
  const pad = pads['jigsaw'];
  const correct = n === jigsawQuestion.product;
  recordAttempt(jigsawQuestion.table, jigsawQuestion.multiplier, correct,
                Date.now() - pad.askedAt, pad.helped);

  if (correct) {
    pad.locked = true;
    if (btn) btn.classList.add('correct-flash');
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
    if (btn) btn.classList.add('wrong-flash');
    clearTyped('jigsaw');
    playGentleBlip();
    if (btn) setTimeout(() => btn.classList.remove('wrong-flash'), 400);
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
    ? feedMistakes <= MISTAKES_ALLOWED
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
      document.getElementById('new-pig-avatar').innerHTML = guineaPigSvg(pig);
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

// ---- For grown-ups: which facts still need work ----
// Deliberately plain and a bit boring. It exists so Andrew and Laura can see
// where she actually is, without any of it leaking into Clara's view of the
// game as a scoreboard.
function renderGrownups() {
  const panel = document.getElementById('grownups-panel');
  const facts = loadFacts();
  const keys = Object.keys(facts);

  if (!keys.length) {
    panel.innerHTML = '<p class="grownups-empty">Nothing practised yet.</p>';
    return;
  }

  const rows = keys.map(k => ({ k, ...facts[k] }));
  const attempts = rows.reduce((s, r) => s + r.attempts, 0);
  const known = rows.filter(r => !r.lastWrong && r.avgMs && r.avgMs <= 3500).length;

  // Worst first: missed last time, then slowest.
  const shaky = rows
    .filter(r => r.lastWrong || (r.avgMs && r.avgMs > 3500))
    .sort((a, b) => (b.lastWrong - a.lastWrong) || ((b.avgMs || 0) - (a.avgMs || 0)))
    .slice(0, 12);

  panel.innerHTML =
    `<p class="grownups-summary">${attempts} questions answered · ` +
    `${known} fact${known === 1 ? '' : 's'} fast and correct · ` +
    `${rows.length} seen</p>` +
    (shaky.length
      ? '<div class="grownups-facts">' + shaky.map(r => {
          const secs = r.avgMs ? (r.avgMs / 1000).toFixed(1) + 's' : '—';
          const cls = r.lastWrong ? 'shaky wrong' : 'shaky slow';
          const why = r.lastWrong ? 'missed last time' : secs;
          return `<span class="${cls}">${r.k.replace('x', ' × ')}<em>${why}</em></span>`;
        }).join('') + '</div>'
      : '<p class="grownups-empty">Nothing shaky right now.</p>');
}

document.getElementById('grownups-btn').addEventListener('click', () => {
  const panel = document.getElementById('grownups-panel');
  const hidden = panel.classList.contains('hidden');
  if (hidden) renderGrownups();
  panel.classList.toggle('hidden');
  document.getElementById('grownups-btn').textContent =
    hidden ? 'Hide' : 'For grown-ups';
});

// ---- Init ----
buildPad('feed', (n, btn) => handleFeedAnswer(n, btn));
buildPad('jigsaw', (n, btn) => handleJigsawAnswer(n, btn));
renderFarm();
