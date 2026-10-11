# Dino Ten — Felix's dinosaur number bonds (Godot 4)

Look test only (10.10.26): one jungle clearing, a friendly T. rex walking round a
ten-frame nest of eggs, a Triceratops, a Parasaurolophus and a Stegosaurus grazing. Ideas and
plan: vault `Claude Projects/Kids learning/Number games/Dino number bonds — ideas.md`.

- Play: double-click `Play Dino Look Test.command` (uses `~/Projects/godot-games/tools/Godot.app`).
  Click the ground to walk, arrow keys, space to roar. `-- --demo` walks itself.
- `dino.gd` makes the Quaternius models friendlier: smoothed normals, toon
  materials in brighter colours, an outline, and big eyes on the head bone.
  Sizes and eyes are worked out in skeleton space (each vertex through its bind
  pose and bone rest): the raw meshes aren't oriented alike (the Triceratops
  lies on its side until skinned) and the bind poses carry scales.
- `closeup.tscn -- <Species>` renders one dinosaur to `look-test/closeup_<Species>.png`.
- Assets: Quaternius *Animated LowPoly Dinosaurs* and *Stylized Nature MegaKit*
  (Standard), both CC0 — licences in `assets/*/`.
