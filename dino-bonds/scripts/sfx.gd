extends Node
## Every sound in the game, synthesised once at start-up (no audio files):
## roar, stomp, pop, chime, crack, squeak, splash, burp, chomp, rustle, hop, cheer.

const RATE := 22050
var _streams := {}
var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_streams["roar"] = _roar()
	_streams["stomp"] = _thump(55.0, 0.45, 0.9)
	_streams["pop"] = _sweep(500.0, 1100.0, 0.09, 0.5)
	_streams["hop"] = _sweep(260.0, 620.0, 0.16, 0.45)
	_streams["chime"] = _chord([1046.5, 1318.5], 0.7, 0.35)
	_streams["crack"] = _crack()
	_streams["squeak"] = _sweep(900.0, 1700.0, 0.22, 0.35, 18.0)
	_streams["splash"] = _noise_burst(0.8, 0.6, 2200.0)
	_streams["rustle"] = _noise_burst(0.55, 0.35, 5200.0, 14.0)
	_streams["burp"] = _burp()
	_streams["chomp"] = _thump(140.0, 0.18, 0.7, true)
	_streams["cheer"] = _arpeggio([523.25, 659.25, 783.99, 1046.5], 0.11, 0.35)
	_streams["soft"] = _sweep(420.0, 330.0, 0.25, 0.3)

func play(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not _streams.has(name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[name]
			p.pitch_scale = pitch
			p.volume_db = volume_db
			p.play()
			return

# --- synthesis -------------------------------------------------------------------

func _make(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w

## A big friendly roar: a growling sawtooth falling in pitch, with a breathy
## noise layer, a fast wobble for the growl, and a swell then fade.
func _roar() -> AudioStreamWAV:
	var dur := 1.7
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	var phase2 := 0.0
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		var t := float(i) / RATE
		var u := t / dur
		var f := lerpf(150.0, 70.0, pow(u, 0.7)) * (1.0 + 0.06 * sin(TAU * 4.0 * t))
		phase = fmod(phase + f / RATE, 1.0)
		phase2 = fmod(phase2 + f * 1.505 / RATE, 1.0)
		var saw := (phase * 2.0 - 1.0) * 0.6 + (phase2 * 2.0 - 1.0) * 0.3
		var growl := 0.65 + 0.35 * sin(TAU * 31.0 * t)
		var noise := randf_range(-1.0, 1.0)
		lp += (noise - lp) * 0.18
		lp2 += (saw * growl - lp2) * 0.35
		var env := smoothstep(0.0, 0.18, t) * (1.0 - smoothstep(0.55, 1.0, u))
		s[i] = (lp2 * 0.85 + lp * 0.55) * env * 0.95
	return _make(s)

func _thump(freq: float, dur: float, vol: float, clicky := false) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := freq * (1.0 + 1.5 * exp(-t * 30.0))
		phase += f / RATE
		var v := sin(TAU * phase) * exp(-t * 9.0)
		if clicky:
			v += randf_range(-1.0, 1.0) * exp(-t * 60.0) * 0.6
		s[i] = v * vol
	return _make(s)

func _sweep(f0: float, f1: float, dur: float, vol: float, vibrato := 0.0) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := lerpf(f0, f1, t / dur) * (1.0 + 0.05 * sin(TAU * vibrato * t))
		phase += f / RATE
		var env := smoothstep(0.0, 0.01, t) * (1.0 - t / dur)
		s[i] = sin(TAU * phase) * env * vol
	return _make(s)

func _chord(freqs: Array, dur: float, vol: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for f in freqs:
			v += sin(TAU * float(f) * t) + 0.3 * sin(TAU * float(f) * 2.0 * t)
		s[i] = v / freqs.size() * exp(-t * 5.0) * vol
	return _make(s)

func _arpeggio(freqs: Array, step: float, vol: float) -> AudioStreamWAV:
	var dur := step * freqs.size() + 0.5
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for k in freqs.size():
		var start := int(k * step * RATE)
		for i in range(start, n):
			var t := float(i - start) / RATE
			s[i] += (sin(TAU * float(freqs[k]) * t) + 0.25 * sin(TAU * float(freqs[k]) * 3.0 * t)) * exp(-t * 6.0) * vol
	return _make(s)

func _crack() -> AudioStreamWAV:
	var n := int(0.25 * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var burst := 1.0 if (int(t * 60.0) % 3 == 0) else 0.3
		s[i] = randf_range(-1.0, 1.0) * exp(-t * 18.0) * burst * 0.6
	return _make(s)

func _noise_burst(dur: float, vol: float, cutoff: float, flutter := 0.0) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var a := clampf(cutoff / RATE * TAU, 0.0, 1.0)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (randf_range(-1.0, 1.0) - lp) * a
		var env := smoothstep(0.0, 0.03, t) * exp(-t * 4.0 / dur)
		if flutter > 0.0:
			env *= 0.6 + 0.4 * sin(TAU * flutter * t)
		s[i] = lp * env * vol * 2.0
	return _make(s)

func _burp() -> AudioStreamWAV:
	var dur := 0.6
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 95.0 + 25.0 * sin(TAU * 7.0 * t) - 30.0 * t
		phase = fmod(phase + f / RATE, 1.0)
		lp += ((phase * 2.0 - 1.0) - lp) * 0.25
		s[i] = lp * smoothstep(0.0, 0.04, t) * (1.0 - t / dur) * 0.9
	return _make(s)
