extends RefCounted
## Every dinosaur in Dino Ten: its name, a short fact for Dad to read, and,
## for the ones built in code (kit_dino.gd), the shape to build. The first six
## are the Quaternius models (dino.gd); the rest are kit dinosaurs.
##
## Kit shape keys (units are roughly "hip height = 1"):
##   pose   "biped", "quad" or "swim"
##   hip    hip height; shoulder (quads) shoulder height
##   body   [length, height, width] of the torso
##   neck   [length, angle up in degrees, thickness]
##   head   [length, height, width]; snout "rex", "croc", "beak", "duck", "small"
##   tail   [length, thickness, droop]
##   arms   [length, thickness] (bipeds)
##   legs   [back thickness, front thickness]
##   feat   extra parts, see kit_dino.gd _features()
##   col    [main, belly, accent]
##   size   standing height in Dino World (metres-ish; Rex is 3)
##   home   where it lives in Dino World: meadow, trees, lake, rocks, volcano, water

const QUATERNIUS := ["Trex", "Triceratops", "Parasaurolophus", "Stegosaurus", "Apatosaurus", "Velociraptor"]

const ALL := {
	"Trex": {"name": "T. rex", "fact": "T. rex had big teeth. It ate meat.", "size": 3.0, "home": "volcano"},
	"Triceratops": {"name": "Triceratops", "fact": "Triceratops had three horns. It ate plants.", "size": 2.4, "home": "meadow"},
	"Parasaurolophus": {"name": "Parasaurolophus", "fact": "It had a long crest on its head. It ate plants.", "size": 2.8, "home": "lake"},
	"Stegosaurus": {"name": "Stegosaurus", "fact": "It had big plates on its back and spikes on its tail.", "size": 2.6, "home": "meadow"},
	"Apatosaurus": {"name": "Apatosaurus", "fact": "It had a very long neck. It ate leaves from tall trees.", "size": 4.5, "home": "trees"},
	"Velociraptor": {"name": "Velociraptor", "fact": "It was fast and had feathers. It was as big as a turkey.", "size": 1.2, "home": "rocks"},

	"Ankylosaurus": {"name": "Ankylosaurus", "fact": "It had armour like a tank and a big club on its tail.",
		"pose": "quad", "hip": 0.75, "shoulder": 0.65, "body": [1.9, 0.75, 0.85], "neck": [0.25, 5, 0.32], "head": [0.5, 0.36, 0.42], "snout": "beak",
		"tail": [1.5, 0.22, 0.1], "legs": [0.2, 0.18], "feat": ["armour", "club", "cheek_horns"],
		"col": ["#8a9a5b", "#e8dcb0", "#5d4a33"], "size": 1.8, "home": "rocks"},
	"Brachiosaurus": {"name": "Brachiosaurus", "fact": "It was as tall as a house! Its front legs were longer than its back legs.",
		"pose": "quad", "hip": 1.15, "shoulder": 1.55, "body": [1.8, 0.85, 0.75], "neck": [2.4, 62, 0.27], "head": [0.55, 0.36, 0.32], "snout": "small",
		"tail": [1.6, 0.22, 0.25], "legs": [0.2, 0.2], "feat": ["nose_bump"],
		"col": ["#7fa3b8", "#e6eef0", "#4f7186"], "size": 7.0, "home": "trees"},
	"Diplodocus": {"name": "Diplodocus", "fact": "It had a long neck and a very, very long tail, like a whip.",
		"pose": "quad", "hip": 1.15, "shoulder": 1.0, "body": [1.8, 0.8, 0.7], "neck": [2.2, 18, 0.24], "head": [0.5, 0.3, 0.3], "snout": "small",
		"tail": [3.6, 0.24, 0.35], "legs": [0.2, 0.19], "feat": ["back_bumps"],
		"col": ["#b49a6a", "#f1e6c8", "#7d6544"], "size": 4.0, "home": "trees"},
	"Spinosaurus": {"name": "Spinosaurus", "fact": "It had a big sail on its back. It caught fish in rivers.",
		"pose": "biped", "hip": 1.0, "body": [1.6, 0.6, 0.5], "neck": [0.7, 35, 0.22], "head": [0.95, 0.32, 0.26], "snout": "croc",
		"tail": [2.0, 0.24, 0.15], "arms": [0.55, 0.08], "legs": [0.17, 0.0], "feat": ["sail"],
		"col": ["#6d8f6a", "#e9e2c4", "#d65a3a"], "size": 3.4, "home": "lake"},
	"Pachycephalosaurus": {"name": "Pachycephalosaurus", "fact": "It had a hard, round head. It bumped heads with other dinos.",
		"pose": "biped", "hip": 0.85, "body": [1.0, 0.55, 0.45], "neck": [0.45, 40, 0.17], "head": [0.45, 0.4, 0.34], "snout": "beak",
		"tail": [1.2, 0.18, 0.1], "arms": [0.35, 0.06], "legs": [0.15, 0.0], "feat": ["dome"],
		"col": ["#a3825c", "#f2e3c5", "#5f8fcf"], "size": 1.6, "home": "rocks"},
	"Dilophosaurus": {"name": "Dilophosaurus", "fact": "It had two thin crests on its head. It was quick and ate meat.",
		"pose": "biped", "hip": 0.95, "body": [1.1, 0.5, 0.42], "neck": [0.55, 40, 0.16], "head": [0.6, 0.28, 0.24], "snout": "rex",
		"tail": [1.5, 0.18, 0.12], "arms": [0.45, 0.06], "legs": [0.15, 0.0], "feat": ["crest_double", "stripes"],
		"col": ["#d9b44a", "#fbf0cc", "#c2412f"], "size": 2.0, "home": "volcano"},
	"Allosaurus": {"name": "Allosaurus", "fact": "It had little horns over its eyes. It was a big hunter.",
		"pose": "biped", "hip": 1.05, "body": [1.4, 0.65, 0.55], "neck": [0.5, 35, 0.22], "head": [0.75, 0.42, 0.34], "snout": "rex",
		"tail": [1.8, 0.24, 0.12], "arms": [0.5, 0.08], "legs": [0.2, 0.0], "feat": ["brow_horns", "stripes"],
		"col": ["#9c6b4a", "#f0dcc0", "#5a3a2a"], "size": 2.8, "home": "volcano"},
	"Iguanodon": {"name": "Iguanodon", "fact": "It had a spike on each thumb. It ate plants.",
		"pose": "biped", "hip": 1.05, "body": [1.5, 0.7, 0.55], "neck": [0.45, 30, 0.22], "head": [0.55, 0.32, 0.28], "snout": "beak",
		"tail": [1.7, 0.24, 0.15], "arms": [0.65, 0.1], "legs": [0.2, 0.0], "feat": ["thumb_spike"],
		"col": ["#6e9e5a", "#e8eecf", "#3f6b37"], "size": 2.6, "home": "meadow"},
	"Gallimimus": {"name": "Gallimimus", "fact": "It ran very fast, like an ostrich. It had a beak.",
		"pose": "biped", "hip": 1.15, "body": [0.9, 0.45, 0.38], "neck": [0.9, 55, 0.11], "head": [0.4, 0.2, 0.17], "snout": "beak",
		"tail": [1.3, 0.14, 0.08], "arms": [0.5, 0.05], "legs": [0.13, 0.0], "feat": ["feathers"],
		"col": ["#d9925b", "#fbe9d2", "#8a5b3a"], "size": 2.0, "home": "meadow"},
	"Carnotaurus": {"name": "Carnotaurus", "fact": "It had horns like a bull and very tiny arms.",
		"pose": "biped", "hip": 1.05, "body": [1.3, 0.6, 0.5], "neck": [0.5, 35, 0.22], "head": [0.55, 0.42, 0.34], "snout": "rex",
		"tail": [1.7, 0.22, 0.12], "arms": [0.22, 0.07], "legs": [0.19, 0.0], "feat": ["bull_horns", "bumps"],
		"col": ["#c0503a", "#f3d6c0", "#6a2a22"], "size": 2.6, "home": "volcano"},
	"Therizinosaurus": {"name": "Therizinosaurus", "fact": "It had giant claws, longer than your arm! But it ate plants.",
		"pose": "biped", "hip": 1.0, "body": [1.2, 0.85, 0.65], "neck": [0.9, 55, 0.16], "head": [0.35, 0.22, 0.2], "snout": "beak",
		"tail": [0.9, 0.18, 0.1], "arms": [0.9, 0.09], "legs": [0.22, 0.0], "feat": ["long_claws", "feathers"],
		"col": ["#8c7a9c", "#ece4f0", "#4f3f60"], "size": 3.4, "home": "trees"},
	"Styracosaurus": {"name": "Styracosaurus", "fact": "It had a big horn on its nose and spikes all round its frill.",
		"pose": "quad", "hip": 0.85, "shoulder": 0.75, "body": [1.6, 0.75, 0.72], "neck": [0.2, 10, 0.3], "head": [0.75, 0.42, 0.4], "snout": "beak",
		"tail": [1.0, 0.2, 0.12], "legs": [0.2, 0.19], "feat": ["frill", "frill_spikes", "nose_horn"],
		"col": ["#c99a4a", "#f5e7c8", "#b5452f"], "size": 1.9, "home": "meadow"},
	"Kentrosaurus": {"name": "Kentrosaurus", "fact": "It had spikes on its back and on its tail. Ouch!",
		"pose": "quad", "hip": 0.9, "shoulder": 0.6, "body": [1.4, 0.65, 0.55], "neck": [0.35, 5, 0.2], "head": [0.4, 0.24, 0.22], "snout": "small",
		"tail": [1.5, 0.2, 0.15], "legs": [0.17, 0.15], "feat": ["plates_small", "back_spikes", "tail_spikes", "shoulder_spikes"],
		"col": ["#a2b04f", "#eef0c8", "#c46a2a"], "size": 1.6, "home": "meadow"},
	"Baryonyx": {"name": "Baryonyx", "fact": "It had a long snout like a crocodile and a big claw. It ate fish.",
		"pose": "biped", "hip": 1.0, "body": [1.3, 0.6, 0.5], "neck": [0.65, 30, 0.2], "head": [0.85, 0.3, 0.24], "snout": "croc",
		"tail": [1.8, 0.22, 0.12], "arms": [0.6, 0.09], "legs": [0.18, 0.0], "feat": ["thumb_spike", "small_crest"],
		"col": ["#5f8a8a", "#e3efe8", "#2e5656"], "size": 2.6, "home": "lake"},
	"Giganotosaurus": {"name": "Giganotosaurus", "fact": "It was even longer than T. rex! It was one of the biggest hunters.",
		"pose": "biped", "hip": 1.1, "body": [1.7, 0.75, 0.6], "neck": [0.5, 32, 0.26], "head": [0.9, 0.48, 0.36], "snout": "rex",
		"tail": [2.2, 0.28, 0.14], "arms": [0.45, 0.09], "legs": [0.24, 0.0], "feat": ["bumps", "stripes"],
		"col": ["#7a6a5a", "#efe2cf", "#3a2f27"], "size": 3.6, "home": "volcano"},
	"Protoceratops": {"name": "Protoceratops", "fact": "It was as big as a sheep. It had a frill and a beak.",
		"pose": "quad", "hip": 0.7, "shoulder": 0.6, "body": [1.0, 0.6, 0.55], "neck": [0.15, 15, 0.26], "head": [0.6, 0.4, 0.36], "snout": "beak",
		"tail": [0.8, 0.18, 0.1], "legs": [0.15, 0.14], "feat": ["frill"],
		"col": ["#d8b07a", "#f8ecd3", "#a66b3b"], "size": 1.0, "home": "rocks"},
	"Corythosaurus": {"name": "Corythosaurus", "fact": "It had a crest like a helmet. It could honk loudly.",
		"pose": "biped", "hip": 1.05, "body": [1.4, 0.7, 0.55], "neck": [0.55, 40, 0.2], "head": [0.6, 0.3, 0.26], "snout": "duck",
		"tail": [1.6, 0.24, 0.15], "arms": [0.55, 0.09], "legs": [0.2, 0.0], "feat": ["crest_fan"],
		"col": ["#5f86b5", "#e3ecf6", "#e8b13a"], "size": 2.6, "home": "lake"},
	"Compsognathus": {"name": "Compsognathus", "fact": "It was tiny, as small as a chicken! It ate bugs and lizards.",
		"pose": "biped", "hip": 0.9, "body": [0.7, 0.4, 0.32], "neck": [0.5, 45, 0.1], "head": [0.4, 0.22, 0.18], "snout": "rex",
		"tail": [1.3, 0.12, 0.06], "arms": [0.35, 0.05], "legs": [0.11, 0.0], "feat": ["stripes"],
		"col": ["#7bb052", "#eef5d8", "#3d6b2a"], "size": 0.6, "home": "meadow"},
	"Mosasaurus": {"name": "Mosasaurus", "fact": "It lived in the sea and swam with flippers. It was not a dinosaur, but it lived with them!",
		"pose": "swim", "hip": 0.0, "body": [2.6, 0.7, 0.65], "neck": [0.4, 0, 0.36], "head": [1.0, 0.4, 0.38], "snout": "croc",
		"tail": [2.6, 0.3, 0.0], "legs": [0.0, 0.0], "feat": ["flippers", "tail_fin"],
		"col": ["#4a7aa0", "#e7f0f4", "#24486a"], "size": 1.2, "home": "water"},
	"Pteranodon": {"name": "Pteranodon", "fact": "It flew in the sky on big wings. It was not a dinosaur, but it lived with them!",
		"size": 1.4, "home": "sky"},
}

## Which can hatch from eggs, in the order Felix gets them (the first six are
## the ones he already has). Mosasaurus and Pteranodon are only met in Dino World.
const HATCH_ORDER := ["Triceratops", "Parasaurolophus", "Stegosaurus", "Apatosaurus", "Velociraptor", "Trex",
	"Ankylosaurus", "Brachiosaurus", "Spinosaurus", "Pachycephalosaurus", "Diplodocus", "Dilophosaurus",
	"Iguanodon", "Styracosaurus", "Allosaurus", "Gallimimus", "Corythosaurus", "Kentrosaurus",
	"Carnotaurus", "Protoceratops", "Baryonyx", "Therizinosaurus", "Compsognathus", "Giganotosaurus"]

static func info(sp: String) -> Dictionary:
	return ALL.get(sp, {"name": sp, "fact": "", "size": 2.0, "home": "meadow"})

static func is_kit(sp: String) -> bool:
	return not QUATERNIUS.has(sp) and sp != "Pteranodon"
