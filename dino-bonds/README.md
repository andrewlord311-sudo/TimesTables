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
| 🌿 Hide | some of a herd hide behind giant ferns: "I can see 6. How many hide?" (the missing part) |
| 🌊 River | stepping stones 0–10 as a number line: "Rex is on 4. How many hops to 10?" |
| 🦴 Dig | match bone pieces that make 10 — every way, 1+9 … 5+5 — and the fossil comes alive |
| 🍓 Feed | red and blue berries in Rex's bowl to make exactly 10, a new way each time |
| ☁️ Catch | the speed round: "7 and ? make 10" — pterosaurs fly over carrying numbers; tap the partner. 8 catches, a little faster each time, timed quietly |
| ➕ Add | **Dino Sums** — two herds walk in: "3 and 2. How many altogether?", then every dinosaur is counted with a number over it. **Make 5** uses numbers 1–5, **Make 10** uses 1–10. Starts with just +1, then +1 or +2, +3, up to the full range; moves up a step after a visit with 4 of 5 right (saved per range as `add_levels`) |
| 🌋 Dino World | the park grown into an island to explore: steer Rex (tap the ground, or arrow keys / WASD) round the Meadow, Tall trees, Lake, Rocky hills and Volcano. Every kind of dinosaur lives there (26, see below) plus all his hatched babies; tap one for its card, and the first meeting puts it in his **dino book** (`seen` in the save) |

Each place is 5 rounds. Every right answer is an egg; every 3 eggs hatch a baby
dinosaur into the park, and Felix's T. rex grows as eggs add up. Questions are
weighted towards the bonds he misses or is slow on (`scripts/progress.gd`); a
wrong answer shows the ten frame and says the bond — it never says "wrong".
Progress is saved in `~/Library/Application Support/Godot/app_userdata/Dino Ten/dino_ten.json`
(delete it to start again).

## Layout
- `scripts/main.gd` — the game: menu, camera, walking, tapping, eggs and hatching, test bot
- `scripts/activity.gd` + `scripts/activities/*.gd` — one file per place
- `scripts/activities/sums.gd` — Dino Sums (addition); levels in `MAX_ADDEND`, reuses the nest's spot
- `scripts/world.gd` — the valley (spots and camera views in `SPOTS`)
- `scripts/species.gd` — every dinosaur: name, fact, size, home in Dino World, and the hatching order (new kinds first, then new colours)
- `scripts/kit_dino.gd` — the 18 extra dinosaurs (and Mosasaurus) built in code from a shape in `species.gd`: lofted body/neck/head/tail, walking legs, and per-species parts (sail, frill, horns, plates, club, crests, claws). Same calls as `dino.gd`. No free animated models exist for these. Look at them all with `Godot --path . res://tools/kit_lineup.tscn` (saves `look-test/kit_*.png`)
- `scripts/activities/jurassic.gd` — Dino World, built far from the valley only while he's in it
- `scripts/pterosaur.gd` — the pterosaur, built in code (no free animated one exists): lofted body and beak, crest, flapping two-part wings, eyes
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
screenshots to `look-test/shots/`) narrow it down. `--fullpark` gives the bot one baby of every kind and `--tour` walks Rex round Dino World without tapping.
