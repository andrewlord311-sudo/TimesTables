# Dino Ten — Felix's dinosaur number bonds (Godot 4)

Bonds to **5** and **10** for Felix (age 5, Reception), played with Dad reading
the screen. Plan and reasoning: vault
`Claude Projects/Kids learning/Number games/Dino number bonds — ideas.md`.

**Play:** double-click `Play Dino Ten.command` (uses `~/Projects/godot-games/tools/Godot.app`).
Choose **Make 5** or **Make 10**, then a place. 🏠 goes back to the valley.
On the valley screen, click the ground to walk the T. rex; space makes it roar.

| Place | What it teaches |
|---|---|
| 🥚 Nest | a nest laid out as a five/ten frame: tap hollows to fill it, then "how many more?" |
| 🌿 Hide | some of a herd hide behind giant ferns: "6 can see. How many hide?" (the missing part) |
| 🌊 River | stepping stones 0–10 as a number line: "Rex is on 4. How many hops to 10?" |
| 🦴 Dig | match bone pieces that make 10 — every way, 1+9 … 5+5 — and the fossil comes alive |
| 🍓 Feed | red and blue berries in Rex's bowl to make exactly 10, a new way each time |
| 🦕 My park | every dinosaur hatched so far wanders here; tap one for its fact card |

Each place is 5 rounds. Every right answer is an egg; every 3 eggs hatch a baby
dinosaur into the park, and Felix's T. rex grows as eggs add up. Questions are
weighted towards the bonds he misses or is slow on (`scripts/progress.gd`); a
wrong answer shows the ten frame and says the bond — it never says "wrong".
Progress is saved in `~/Library/Application Support/Godot/app_userdata/Dino Ten/dino_ten.json`
(delete it to start again).

## Layout
- `scripts/main.gd` — the game: menu, camera, walking, tapping, eggs and hatching, test bot
- `scripts/activity.gd` + `scripts/activities/*.gd` — one file per place
- `scripts/world.gd` — the valley (spots and camera views in `SPOTS`)
- `scripts/dino.gd` — friendlier Quaternius dinosaurs: smooth toon shading, outline, big eyes,
  colourways, fossil mode. Sizes and eyes are worked out in skeleton space (each vertex
  through its bind pose and bone rest): the raw meshes aren't oriented alike.
- `scripts/ui.gd` — big text, number buttons with dots, ten-frame hint, cards, menu
- `scripts/sfx.gd` — every sound synthesised in code (no audio files)
- `scripts/progress.gd` — save file, adaptive question choice
- `shaders/`, `assets/` (Quaternius, CC0 — licences inside), `tools/` (close-up renderer)

## Testing
`Godot --headless --path . -- --bot --fast` plays every place at 5 and 10 (it never
touches the save). `--only=nest,dig`, `--target=10`, and `--shots` (windowed; saves
screenshots to `look-test/shots/`) narrow it down.
