# Dino Ten — Felix's dinosaur number bonds (Godot 4)

Look test only (10.10.26): one jungle clearing, a friendly T. rex walking round a
ten-frame nest of eggs, a Parasaurolophus and a Stegosaurus grazing. Ideas and
plan: vault `Claude Projects/Kids learning/Number games/Dino number bonds — ideas.md`.

- Play: double-click `Play Dino Look Test.command` (uses `~/Projects/godot-games/tools/Godot.app`).
  Click the ground to walk, arrow keys, space to roar. `-- --demo` walks itself.
- `dino.gd` makes the Quaternius models friendlier: smoothed normals, toon
  materials in brighter colours, an outline, and big eyes on the head bone.
  The pack's skins carry a scale in their bind poses — sizes and eye radii
  account for it. The Triceratops is built differently and isn't right yet.
- `closeup.tscn -- <Species>` renders one dinosaur to `look-test/closeup_<Species>.png`.
- Assets: Quaternius *Animated LowPoly Dinosaurs* and *Stylized Nature MegaKit*
  (Standard), both CC0 — licences in `assets/*/`.
