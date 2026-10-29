extends RefCounted
## Deterministic two-way traffic. Screen x is a lane position, never a heading.
## Vehicles reserve their swept lane during changes and cannot cross another
## vehicle's longitudinal ordering while their bodies share that corridor.
const RIGHT := 58.0
const LEFT := -58.0
const LATERAL_BODY := 50.0
const MIN_GAP := 4.8
const LANE_CHANGE_RATE := 80.0
const RETURN_GAP := 11.0

static func direction(car: Dictionary) -> int:
	return 1 if int(car.get("direction", 1 if float(car.get("x", RIGHT)) >= 0.0 else -1)) >= 0 else -1

static func position(car: Dictionary) -> float:
	return (660.0 - float(car.get("y", -70.0))) / 9.0

static func _occupies(car: Dictionary, lane: float) -> bool:
	return absf(float(car.x) - lane) < LATERAL_BODY or absf(float(car.get("target_x", car.x)) - lane) < LATERAL_BODY

static func _lane_clear(cars: Array, subject: Dictionary, lane: float, seconds: float, player_speed: float, player_x: float) -> bool:
	var at := position(subject)
	var speed := float(subject.cruise_speed_mps)
	for other: Dictionary in cars:
		if other == subject or not _occupies(other, lane): continue
		var gap := position(other) - at
		var future := gap + (float(direction(other)) * float(other.cruise_speed_mps) - speed) * seconds
		if gap * future <= 0.0 or minf(absf(gap), absf(future)) < MIN_GAP * 2.0:
			return false
	# A lane change must not cut across the player's current physical position.
	if player_x >= minf(float(subject.x), lane) - LATERAL_BODY and player_x <= maxf(float(subject.x), lane) + LATERAL_BODY:
		var gap := -at
		var future := gap + (player_speed - speed) * minf(seconds, 2.0)
		if gap * future <= 0.0 or minf(absf(gap), absf(future)) < MIN_GAP * 2.0: return false
	return true

static func spawn_clear(cars: Array, x: float, y: float) -> bool:
	for other: Dictionary in cars:
		if absf(float(other.get("x", 0.0)) - x) < LATERAL_BODY and absf(float(other.get("y", 0.0)) - y) < MIN_GAP * 9.0 * 2.0:
			return false
		# Never introduce an oncoming car into an occupied passing corridor.
		if x < 0.0 and direction(other) > 0 and _occupies(other, LEFT): return false
	return true

static func _swept_overlap(a0: float, a1: float, b0: float, b1: float) -> bool:
	return minf(a0, a1) - LATERAL_BODY < maxf(b0, b1) and minf(b0, b1) - LATERAL_BODY < maxf(a0, a1)

static func step(cars: Array, player_speed: float, delta: float, player_x: float = 0.0) -> void:
	if not is_finite(delta) or delta <= 0.0: return
	var dt := minf(delta, 0.08)
	var before: Dictionary = {}
	for car: Dictionary in cars:
		car.direction = direction(car)
		car.cruise_speed_mps = clampf(float(car.get("cruise_speed_mps", car.get("speed_mps", 12.0))), 4.0, 34.0)
		car.speed_mps = clampf(float(car.get("speed_mps", car.cruise_speed_mps)), 0.0, float(car.cruise_speed_mps))
		car.target_x = float(car.get("target_x", RIGHT if int(car.direction) > 0 else LEFT))
		before[int(car.id)] = {"position": position(car), "x": float(car.x)}
	# Reserve decisions in ID order, so simultaneous followers cannot merge into
	# the same opening. Passing uses the actual opposing stream, not a free lane.
	var decisions := cars.duplicate()
	decisions.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.id) < int(b.id))
	for car: Dictionary in decisions:
		if int(car.direction) < 0: continue
		if float(car.target_x) == LEFT:
			var lead: Dictionary = {}
			for other: Dictionary in cars:
				if int(other.id) == int(car.get("passing_id", -1)): lead = other
			if (lead.is_empty() or position(car) > position(lead) + RETURN_GAP) and _lane_clear(cars, car, RIGHT, 2.0, player_speed, player_x):
				car.target_x = RIGHT
				car.passing_id = -1
		elif absf(float(car.x) - RIGHT) < 3.0:
			var lead: Dictionary = {}
			var nearest := INF
			for other: Dictionary in cars:
				if other == car or int(other.direction) < 0 or not _occupies(other, RIGHT): continue
				var gap := position(other) - position(car)
				if gap > 0.0 and gap < nearest:
					nearest = gap
					lead = other
			if not lead.is_empty() and nearest < maxf(25.0, float(car.cruise_speed_mps) * 1.6):
				var advantage := float(car.cruise_speed_mps) - float(lead.cruise_speed_mps)
				var time_to_pass := (nearest + RETURN_GAP * 2.0) / maxf(advantage, 1.0) + 3.0
				if advantage >= 2.0 and _lane_clear(cars, car, LEFT, time_to_pass, player_speed, player_x):
					car.target_x = LEFT
					car.passing_id = int(lead.id)
	for car: Dictionary in cars:
		car.x = move_toward(float(car.x), float(car.target_x), LANE_CHANGE_RATE * dt)
	for travel_direction in [1, -1]:
		var ordered: Array = cars.filter(func(car: Dictionary): return int(car.direction) == travel_direction)
		ordered.sort_custom(func(a: Dictionary, b: Dictionary): return float(travel_direction) * position(a) > float(travel_direction) * position(b))
		for car: Dictionary in ordered:
			var target_speed := float(car.cruise_speed_mps)
			var at := float(travel_direction) * float(before[int(car.id)].position)
			var maximum_position := INF
			for other: Dictionary in ordered:
				if other == car: continue
				var other_at := float(travel_direction) * float(before[int(other.id)].position)
				if other_at <= at: continue
				if not _swept_overlap(float(before[int(car.id)].x), float(car.x), float(before[int(other.id)].x), float(other.x)): continue
				var gap := other_at - at
				var headway := maxf(MIN_GAP, float(car.cruise_speed_mps) * 0.7)
				target_speed = minf(target_speed, maxf(0.0, float(other.speed_mps) + (gap - headway) * 1.6))
				maximum_position = minf(maximum_position, float(travel_direction) * position(other) - MIN_GAP)
			car.speed_mps = move_toward(float(car.speed_mps), target_speed, dt * (9.0 if target_speed < float(car.speed_mps) else 3.0))
			var next_position := position(car) + (float(travel_direction) * float(car.speed_mps) - player_speed) * dt
			if maximum_position < INF:
				next_position = float(travel_direction) * minf(float(travel_direction) * next_position, maximum_position)
			car.y = 660.0 - next_position * 9.0
	# Swept checks also protect against opposing traffic and large closing speeds.
	# Decisions avoid these situations in ordinary traffic; this is the final
	# no-tunnelling guard, never a reward or a player-position adjustment.
	for iteration in range(8):
		var corrected := false
		for a_index in range(cars.size()):
			for b_index in range(a_index + 1, cars.size()):
				var a: Dictionary = cars[a_index]
				var b: Dictionary = cars[b_index]
				if not _swept_overlap(float(before[int(a.id)].x), float(a.x), float(before[int(b.id)].x), float(b.x)): continue
				var low: Dictionary = a if float(before[int(a.id)].position) < float(before[int(b.id)].position) else b
				var high: Dictionary = b if low == a else a
				if position(high) - position(low) >= MIN_GAP: continue
				if int(low.direction) == int(high.direction):
					if int(low.direction) > 0: low.y = 660.0 - (position(high) - MIN_GAP) * 9.0
					else: high.y = 660.0 - (position(low) + MIN_GAP) * 9.0
				else:
					var middle := (float(before[int(low.id)].position) + float(before[int(high.id)].position)) * 0.5
					low.y = 660.0 - minf(position(low), middle - MIN_GAP * 0.5) * 9.0
					high.y = 660.0 - maxf(position(high), middle + MIN_GAP * 0.5) * 9.0
				corrected = true
		if not corrected: break
	for car: Dictionary in cars:
		var travelled := (position(car) - float(before[int(car.id)].position)) / dt + player_speed
		car.speed_mps = clampf(float(car.direction) * travelled, 0.0, float(car.cruise_speed_mps))
