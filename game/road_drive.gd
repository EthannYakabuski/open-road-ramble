extends RefCounted
## Per-ramble damage state. It never changes a profile or awards a traffic pass.
const MAX_HEARTS := 3
const HIT_GRACE_SECONDS := 1.8
var hearts := MAX_HEARTS
var hits := 0
var grace := 0.0
var hit_vehicles: Dictionary = {}

func reset() -> void:
	hearts = MAX_HEARTS
	hits = 0
	grace = 0.0
	hit_vehicles.clear()

func tick(delta: float) -> void:
	if is_finite(delta): grace = maxf(0.0, grace - maxf(delta, 0.0))

func collide(vehicle_id: int) -> bool:
	if vehicle_id < 0 or hearts <= 0 or grace > 0.0 or hit_vehicles.has(vehicle_id): return false
	hit_vehicles[vehicle_id] = true
	hearts -= 1
	hits += 1
	grace = HIT_GRACE_SECONDS
	return true

func repair() -> void:
	hearts = MAX_HEARTS
	grace = HIT_GRACE_SECONDS
