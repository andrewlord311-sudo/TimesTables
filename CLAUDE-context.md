# Context for Claude -- TimesTables

_Copied from Claude's memory on Andrew's Mac, 26 September 2026, by `vault-tools/sync-claude-context.py`. Don't edit by hand -- it's regenerated._

## About Andrew

Andrew Lord builds a portfolio of small personal projects, one GitHub repo each
(on his Mac they live in `~/Projects/<repo>`). He is technically fluent: give
concrete detail (file:line, what the code actually does), not just summaries.
His Obsidian vault "Andrew Second Brain" is the durable home for plans; the
private repo `andrew-second-brain` mirrors it (see "Working in the cloud").

**Commit and push without asking** -- he has authorised it durably. Stop only
for a genuine content problem (a secret or someone's personal data about to be
committed), and report that as a finding.

Friendly, not too verbose. Laura (wife), Clara (7) and Felix (4): anything
built for Laura must work as a plain phone link, no accounts or apps.

## Working in the cloud (Claude Code on the web)

This file is copied from the memory Claude keeps on Andrew's Mac, so a cloud
session starts with the same context. The Mac copy may be newer -- the date
is above. In the cloud, as opposed to on the Mac:

- **No Mac-only things:** no launchd jobs, no iCloud Drive, no `~/.secrets`,
  no local Telegram pollers, no Homebrew tools that aren't installed by the
  environment's setup script. Code that runs on the Mac on a schedule can be
  *edited* here, but it won't run until the Mac pulls the change.
- **The vault:** `andrew-second-brain` (a separate private repo) is the Second
  Brain vault. Edits pushed there reach iCloud and Obsidian when the Mac next
  syncs (vault-tools/sync-second-brain.py pulls before it pushes). The Lord
  Family vault is the private repo `the-lord-family/obsidian-vault`.
- **Always commit and push** before the session ends: the Mac and the other
  sessions only see what's on GitHub.

## Memory: project-times-tables-game

"Pip's Times Tables" — a times-table practice game, another sibling to [[project-nuggets-music-apps]] and [[project-phonics-app]] in style/conventions (plain HTML/JS, no build step, self-contained). Built 2026-08-01, MVP working and verified end-to-end in browser.

**Code:** `~/Projects/TimesTables/app/` — `index.html`, `app.js`, `style.css`, no separate docs folder yet (unlike the other two siblings, nothing written to the vault for this one so far).

**Public on GitHub Pages (2026-08-01):** repo `andrewlord311-sudo/TimesTables` (public - needed for free Pages), live at https://andrewlord311-sudo.github.io/TimesTables/app/index.html - built for his daughter to play on her tablet. No personal data in this app (unlike the Nuggets/Phonics login systems), so no privacy tradeoff to flag the way the Music Arcade's pupil-picker had. Deploys automatically on push to `main`, same as the other GitHub Pages projects - remember to actually push after any future edit, not just commit locally.

**Two games**, both multiple-choice (question + 3 answer buttons, one correct + 2 plausible distractors generated from nearby products/off-by-one multipliers, not random noise):
- **Feed Pip** — correct answers feed a guinea pig avatar
- **Guinea Pig Jigsaw** — correct answers reveal pieces of a guinea pig picture (3 pig variants cycle through, avoiding immediate repeats)

**Stage progression — exact spec from Andrew, verified programmatically correct across all 7 stages:** cumulative, not isolated — each stage's pool is every table introduced so far. Stage 1: {1,2,5,10} (the "easy, main focus" starting set). Then one harder table added per stage: +3, +4, +9, +8, +6, +7 (stage 7 = full {1,2,3,4,5,6,7,8,9,10}). Multiplier range is 1-12 (assumed standard UK convention, not explicitly specified by Andrew - worth confirming if it ever comes up). `STAGES` array in `app.js` is the source of truth.

**Reward system — Guinea Pig Farm collection:** 7 collectible guinea pigs (`FARM_PIGS` in `app.js`, each a distinct colour/breed - Butterscotch, Domino, Smokey, Panda, Marmalade, Marshmallow, Biscuit), one unlocked per stage cleared. "Cleared" = 8 correct answers in a single session (`ROUNDS_TO_CLEAR_STAGE`), matching the same "8 in a row" convention used in the sibling Nuggets/Phonics apps. Progress persists in `localStorage` (`ttg_progress`). Farm display is on the home screen, locked slots show a 🔒, unlocked ones show the actual guinea pig SVG + name.

**Guinea pig art (updated 2026-08-01):** Farm collection + Feed Pip now use a real SVG Andrew uploaded (`images/guinea-pig-svgrepo-com.svg`, from svgrepo.com), inlined as a JS template literal (`GUINEA_PIG_SVG` in `app.js`) rather than an `<img src>` — inlining as real DOM was the deciding factor, since it lets CSS `filter` (grayscale/brightness/contrast/hue-rotate/sepia) recolor one shared asset into all 7 distinct `FARM_PIGS` variants instead of needing hand-colored art per pig (`guineaPigSvg(pig)` wraps it in a `.pig-tint` div with the filter applied). Verified live: all 7 filters (Butterscotch/Domino/Smokey/Panda/Marmalade/Marshmallow/Biscuit) render as clearly distinct, pleasant variants on this artwork. Pip also now animates via whole-body CSS transforms on the wrapping `.pip` element: `.idle` (gentle translateY bob, loops at rest), `.happy` (scale+rotate+translateY bounce on correct answers), `.sad` (translateX+rotate wobble on wrong answers — previously Pip had zero reaction to mistakes, now fixed). Old hand-drawn ellipse-based `guineaPigSvg(pig, opts)` generator fully removed. **The Jigsaw game still uses real photos, unrelated asset** - Andrew pasted `images/gpig8.webp` (two long-haired guinea pigs, 900x607) plus 6 more, directly into the project; `JIGSAW_IMAGES` in `app.js` lists them keyed by stage, `.jigsaw-pic img` uses `object-fit: cover`. Add more real photos later by dropping a file in `images/` and adding an entry to `JIGSAW_IMAGES` - there's no auto-discovery (static file:// app, no directory listing available), so new images need that one-line registration.

**7 real photos, one per stage (2026-08-01):** Andrew uploaded 6 more guinea pig photos alongside the original `gpig8.webp`. `JIGSAW_IMAGES` in `app.js` is now keyed by stage number (1-7), not a random-draw array - each stage has its own dedicated picture (roughly simplest single-pig shots for early stages, building up to a 3-pig group photo for stage 7), so completing harder stages reveals a different, more elaborate picture rather than a random repeat. To change/add a picture for a stage, just edit that stage's entry.

**Bug fixed 2026-08-01: jigsaw never recognized completion.** The puzzle grid only has 6 tiles, but the session-end check was `jigsawRound >= ROUNDS_PER_SESSION` (8) - a leftover copy from Feed Pip that never matched the jigsaw's own tile count. Once all 6 tiles were revealed, the next correct answer tried to splice a tile out of an empty `jigsawTilesLeft` array and silently broke, so the completion screen (and the stage-clear/guinea-pig-unlock logic gated behind it) never fired. Fixed by ending the jigsaw session exactly when `jigsawTilesLeft.length === 0`, marking that stage cleared unconditionally (finishing the picture *is* the achievement, no streak threshold needed the way Feed Pip needs one), and auto-advancing `jigsawStage` to the next stage on completion - same auto-advance pattern used elsewhere in the sibling apps. Feed Pip's own completion logic (8-correct-streak) was deliberately left unchanged - only the jigsaw was reported broken.

**No audio** in this game (deliberate scope decision) - unlike phonics, multiplication questions are a visual/numeric concept, not fundamentally audio-first, so v1 ships as on-screen text only ("3 × 4 = ?"). Could add read-aloud later via TTS if wanted (no isolated-phoneme problem here, ordinary sentences work fine with any TTS).

**Other football/guinea-pig reward brainstorm context:** the football-reward-ideas backlog from the same session is for [[project-phonics-app]] (Felix's Phonics), a *different* app - don't conflate the two when either comes up again. This game's guinea-pig theme was specified fresh for times tables, not carried over from phonics.

**How to apply:** when Andrew wants to extend this (more stages, different reward mechanics, audio, art polish), read `app.js` directly - it's a single file, straightforward to extend.

**Major revision 2026-09-13 — and note it was STILL unplayed by Clara at that point** (built 1.8, untouched since 11.8; Andrew: "She hasn't played it yet - let's make it better first"). Three changes:

1. **Typed answers replaced multiple choice as the default.** The reasoning is the transferable bit: times tables are a *recall* skill, and 3 buttons only test *recognition*, with a 33% floor from guessing. A number pad is now default; the 3 choices sit behind a "Stuck?" button so a new stage is never a wall, and taking that help is recorded (`helped`) and makes the fact come back as if missed. **Same argument applies to [[project-phonics-app]] and [[project-nuggets-music-apps]] where the skill is recall rather than discrimination.**
2. **Weighted practice + silent timing.** Per-fact records in `localStorage` (`ttg_facts`: attempts/correct/avgMs/lastWrong/helped); `pickFact()` draws weighted, never repeating the same fact twice running. **How long a CORRECT answer took is the mastery signal** — slow = she counted it up. Deliberately **no visible timer** (clocks make children anxious). **Lesson worth keeping: the weight ORDER was wrong first time and only measurement caught it** — with "never seen" above "slow", a fact she could only reach by counting came up *less* often than one never asked (0.9% vs 2.1% measured over 6000 draws). Now missed 6.8% / very slow 3.8% / slow 2.6% / unseen 2.0% / known 0.6%.
3. **Real pets.** Stages 1-2 unlock **Dreamy** and **Evie** (Clara's actual guinea pigs) before the invented five; stage 1's jigsaw is the real photo of Clara holding Evie, copied from the vault to `images/clara-and-evie.jpg`. **Squeaky (died 6.9.26) deliberately left out — Andrew's explicit call.** Portrait photos get a portrait frame + 2x3 tile grid (`portrait: true` on the JIGSAW_IMAGES entry); the old fixed landscape box centre-cropped Clara's head off.

Also: stage-clear was 8 correct **in a row**, which is fair with 3 buttons and punishing from memory — now 8 correct with up to `MISTAKES_ALLOWED` (2) slips. And a **"For grown-ups"** panel on the home screen lists shaky facts, hidden behind a tap so it never becomes a scoreboard for Clara.

**Third game added 2026-09-13 — "Guinea Pig Run"** (`startRunGame` etc. in `app.js`). Andrew's spec, followed exactly: **ONLY the 2, 5 and 10 tables, multipliers 1-12** (max question 10×12=120) — i.e. Clara's real Year 3 target, unlike the other two games which use the 7-stage ladder. Ten questions, no repeats, split **4/3/3** across the three tables with the extra one shuffled; products kept distinct too so one run never asks both 5×2 and 2×5. Evie hops an obstacle per correct answer along a track to a finish flag; wrong = stumble + retry. **Timed, but the clock is NEVER on screen** — the completion text deliberately says nothing about time, not even "new best", since that would reveal she's being timed. Best/last/recent + slip count go in the grown-ups panel only; times ≥60s render as `1:24`. Verified over **3000 generated runs** (zero spec violations) plus best-never-regresses.

**Arcade hub updated the same day:** `Andrew_Game_Apps/index.html` ("Tiny Games Arcade", live at andrewlord311-sudo.github.io/Andrew_Game_Apps/) now has **four tabs — Music / Games / Phonics / Times Tables**, with the chosen tab remembered in `localStorage`. Phonics and TimesTables are separate repos with their own Pages sites so they link by **absolute URL** (a relative path 404s); one card each because neither app supports deep-linking to a sub-game. **If you add deep-linking to TimesTables (`?game=run` etc.), the arcade can list the three games separately** — discussed, not built.

**Still open:** Dreamy's colour filter is a guess from the background of the Evie photo — Andrew was asked for photos of both pigs and for confirmation. Division, and tables beyond 10 (the Y4 Multiplication Tables Check leans on 6,7,8,9,12), were discussed and not built.
