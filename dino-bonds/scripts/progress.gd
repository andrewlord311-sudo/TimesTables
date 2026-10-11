extends Node
## What Felix knows and what he's earned, saved between sessions.
## Each bond is stored by its target (5 or 10) and the part he's shown; a
## correct but slow answer counts as "not yet known", like Pip's Times Tables.

const SAVE := "user://dino_ten.json"
const SPECIES := ["Triceratops", "Parasaurolophus", "Stegosaurus", "Apatosaurus", "Velociraptor", "Trex"]
const EGGS_PER_HATCH := 3

var target := 10
var eggs := 0                 # eggs earned in total
var park: Array = []          # hatched dinosaurs: {"species": .., "colour": idx}
var stats := {}               # "10:7" -> {"seen": n, "right": n, "slow": n}
var rng := RandomNumberGenerator.new()
var no_save := false   # the test bot plays without touching Felix's save

func _ready() -> void:
	rng.randomize()
	load_game()

func key(t: int, part: int) -> String:
	return "%d:%d" % [t, part]

## Pick the part to show (0..target) weighted towards bonds he misses or is
## slow on. 0 and the target itself come up rarely.
func pick_part(exclude := -1) -> int:
	var weights := []
	var total := 0.0
	for p in range(0, target + 1):
		var st: Dictionary = stats.get(key(target, p), {})
		var seen: int = st.get("seen", 0)
		var wrong: int = seen - int(st.get("right", 0))
		var slow: int = st.get("slow", 0)
		var w := 1.0 + wrong * 2.0 + slow * 1.0
		if seen >= 3 and wrong == 0 and slow == 0:
			w *= 0.35
		if p == 0 or p == target:
			w *= 0.3
		if p == exclude:
			w *= 0.1
		weights.append(w)
		total += w
	var r := rng.randf() * total
	for p in weights.size():
		r -= weights[p]
		if r <= 0.0:
			return p
	return target / 2

func record(part: int, right: bool, seconds: float) -> void:
	var k := key(target, part)
	var st: Dictionary = stats.get(k, {"seen": 0, "right": 0, "slow": 0})
	st["seen"] = int(st["seen"]) + 1
	if right:
		st["right"] = int(st["right"]) + 1
		if seconds > 6.0:
			st["slow"] = int(st["slow"]) + 1
		elif int(st["slow"]) > 0 and seconds < 3.0:
			st["slow"] = int(st["slow"]) - 1
	stats[k] = st
	save_game()

## Add an egg. Returns the new dinosaur if this egg completes a batch, else {}.
func add_egg() -> Dictionary:
	eggs += 1
	var hatched := {}
	if eggs % EGGS_PER_HATCH == 0:
		var n := park.size()
		hatched = {"species": SPECIES[n % SPECIES.size()], "colour": n / SPECIES.size()}
		park.append(hatched)
	save_game()
	return hatched

## How grown-up Felix's T. rex is: 0 (baby) to 1 (full size), from his eggs.
func growth() -> float:
	return clampf(eggs / 30.0, 0.0, 1.0)

func save_game() -> void:
	if no_save:
		return
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"eggs": eggs, "park": park, "stats": stats, "target": target}))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if data is Dictionary:
		eggs = int(data.get("eggs", 0))
		park = data.get("park", [])
		stats = data.get("stats", {})
		target = int(data.get("target", 10))
