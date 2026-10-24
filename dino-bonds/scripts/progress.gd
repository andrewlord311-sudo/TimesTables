extends Node
## What Felix knows and what he's earned, saved between sessions.
## Each bond is stored by its target (5 or 10) and the part he's shown; a
## correct but slow answer counts as "not yet known", like Pip's Times Tables.

const SAVE := "user://dino_ten.json"
const Species := preload("res://scripts/species.gd")
const EGGS_PER_HATCH := 3

var target := 10
var eggs := 0                 # eggs earned in total
var park: Array = []          # hatched dinosaurs: {"species": .., "colour": idx}
var seen: Array = []          # species met in Dino World (the dino book)
var stats := {}               # "10:7" -> {"seen": n, "right": n, "slow": n}
var add_levels := {}          # "5"/"10" -> how far up the Add game he has got (0 = just +1)
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

## Note a species as met in Dino World. Returns true the first time.
func see(sp: String) -> bool:
	if seen.has(sp):
		return false
	seen.append(sp)
	save_game()
	return true

func get_add_level() -> int:
	return clampi(int(add_levels.get(str(target), 0)), 0, 4)

func set_add_level(l: int) -> void:
	add_levels[str(target)] = clampi(l, 0, 4)
	save_game()

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
		# A species he hasn't got yet if there is one, otherwise a new colour of one he has.
		var have := {}
		for p in park:
			have[p["species"]] = int(have.get(p["species"], 0)) + 1
		var sp: String = ""
		for s in Species.HATCH_ORDER:
			if not have.has(s):
				sp = s
				break
		if sp == "":
			sp = Species.HATCH_ORDER[park.size() % Species.HATCH_ORDER.size()]
		hatched = {"species": sp, "colour": int(have.get(sp, 0)) % 5}
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
		f.store_string(JSON.stringify({"eggs": eggs, "park": park, "stats": stats, "target": target, "add_levels": add_levels, "seen": seen}))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if data is Dictionary:
		eggs = int(data.get("eggs", 0))
		park = data.get("park", [])
		stats = data.get("stats", {})
		target = int(data.get("target", 10))
		add_levels = data.get("add_levels", {})
		seen = data.get("seen", [])
