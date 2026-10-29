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

const ROAD_EDGE := 107.0
const EXIT_EDGE := 430.0
const EXIT_START_METRES := 180.0
const EXIT_END_METRES := -22.0

static func exit_open(metres_to_station: float) -> bool:
	return metres_to_station <= EXIT_START_METRES and metres_to_station >= EXIT_END_METRES

static func steering_limit(metres_to_station: float) -> float:
	if not exit_open(metres_to_station): return ROAD_EDGE
	return lerpf(135.0, EXIT_EDGE, clampf((EXIT_START_METRES - metres_to_station) / 170.0, 0.0, 1.0))

static func entered_forecourt(metres_to_station: float, lateral_position: float) -> bool:
	return metres_to_station <= 10.0 and metres_to_station >= EXIT_END_METRES and lateral_position >= 330.0

static func traffic_motion(player_speed: float, vehicle: Dictionary) -> float:
	# World-space longitudinal speed; oncoming traffic adds closing speed.
	var npc_speed := float(vehicle.get("speed_mps", 12.0))
	var travel_direction := int(vehicle.get("direction", -1 if float(vehicle.get("x", 0)) < 0.0 else 1))
	return (player_speed - float(travel_direction) * npc_speed) * 9.0

static func patrol_observes_pass(route_metres: float, patrol_metres: float, vehicle: Dictionary) -> bool:
	return absf(route_metres - patrol_metres) <= 70.0 and int(vehicle.get("direction", 1 if float(vehicle.get("x", 0)) > 0.0 else -1)) > 0

const MAX_SPEED_MPS := 120.0 / 3.6

static func forward_speed(current: float, delta: float, braking: bool, off_road: bool) -> float:
	if not is_finite(current): current = 0.0
	if not is_finite(delta) or delta <= 0.0: return clampf(current, 0.0, MAX_SPEED_MPS)
	var target := 5.0 if braking else (18.0 if off_road else MAX_SPEED_MPS)
	var acceleration := 10.0 if current > target else (4.0 if current < 12.0 else 1.0)
	return clampf(move_toward(current, target, delta * acceleration), 0.0, MAX_SPEED_MPS)
