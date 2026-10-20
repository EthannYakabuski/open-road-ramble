extends RefCounted
## Pure, deterministic persistent economy. Never grants progress for rescue teleportation.
const SAVE_VERSION := 1
const CARS := ["hatchback", "sedan", "suv", "tourer", "camper"]
const QUESTS := ["distance", "passes", "refuels"]
const QUEST_TARGETS := {"distance": 800, "passes": 12, "refuels": 2}
var data: Dictionary = {}

func _init() -> void:
	data = fresh()

func fresh() -> Dictionary:
	return {"version": SAVE_VERSION, "coins": 0, "xp": 0, "level": 1,
		"distance": 0.0, "passes": 0, "refuels": 0, "rescues": 0,
		"car": "hatchback", "owned": ["hatchback"], "discoveries": [],
		"tank": 0, "comfort": 0, "earned": [], "biomes": [],
		"day": "", "daily": {"distance": 0.0, "passes": 0, "refuels": 0}, "claimed": []}

func load_data(raw: Variant) -> void:
	data = fresh()
	if not raw is Dictionary:
		return
	for key: String in ["coins", "xp", "passes", "refuels", "rescues"]:
		if raw.get(key) is int or raw.get(key) is float:
			data[key] = clampi(int(raw[key]), 0, 2000000000)
	if raw.get("level", 1) is int or raw.get("level", 1) is float:
		data["level"] = clampi(int(raw.get("level", 1)), 1, 200)
	if raw.get("distance") is int or raw.get("distance") is float:
		data["distance"] = clampf(float(raw["distance"]), 0.0, 1.0e10)
	for key: String in ["tank", "comfort"]:
		if raw.get(key, 0) is int or raw.get(key, 0) is float:
			data[key] = clampi(int(raw.get(key, 0)), 0, 4)
	for key: String in ["owned", "discoveries", "earned", "biomes", "claimed"]:
		if raw.get(key) is Array:
			for item: Variant in raw[key]:
				if item is String and not data[key].has(item) and str(item).length() < 80:
					if key != "owned" or CARS.has(item):
						data[key].append(item)
	var selected := str(raw.get("car", "hatchback"))
	data["car"] = selected if data["owned"].has(selected) else "hatchback"
	data["day"] = str(raw.get("day", "")).left(10)
	if raw.get("daily") is Dictionary:
		for key: String in QUESTS:
			var value: Variant = raw["daily"].get(key, 0)
			if value is int or value is float:
				data["daily"][key] = clampf(float(value), 0.0, 1.0e10) if key == "distance" else clampi(int(value), 0, 2000000000)

func roll_day(today: String) -> bool:
	# Backwards local-clock changes do not produce another free reset.
	if today <= str(data["day"]):
		return false
	data["day"] = today
	data["daily"] = {"distance": 0.0, "passes": 0, "refuels": 0}
	data["claimed"] = []
	return true

func add_distance(metres: float) -> void:
	if not is_finite(metres) or metres <= 0:
		return
	var old_steps := int(float(data["distance"]) / 100.0)
	data["distance"] = float(data["distance"]) + metres
	data["daily"]["distance"] = float(data["daily"]["distance"]) + metres
	var new_steps := int(float(data["distance"]) / 100.0) - old_steps
	if new_steps > 0:
		data["coins"] = int(data["coins"]) + new_steps * (20 + int(data["comfort"]) * 4)
		grant_xp(new_steps * 6)
	var biome: String = str(["meadow", "coast", "desert", "alpine"][int(float(data["distance"]) / 2500.0) % 4])
	if not data["biomes"].has(biome):
		data["biomes"].append(biome)

func note_pass(vehicle: String, rare: bool) -> bool:
	data["passes"] = int(data["passes"]) + 1
	data["daily"]["passes"] = int(data["daily"]["passes"]) + 1
	data["coins"] = int(data["coins"]) + 3
	grant_xp(2)
	var is_new: bool = not data["discoveries"].has(vehicle)
	if is_new:
		data["discoveries"].append(vehicle)
		data["coins"] = int(data["coins"]) + (80 if rare else 15)
		grant_xp(30 if rare else 5)
	return is_new

func note_refuel() -> void:
	data["refuels"] = int(data["refuels"]) + 1
	data["daily"]["refuels"] = int(data["daily"]["refuels"]) + 1
	data["coins"] = int(data["coins"]) + 15
	grant_xp(20)

func note_rescue() -> void:
	data["rescues"] = int(data["rescues"]) + 1

func grant_xp(amount: int) -> void:
	data["xp"] = int(data["xp"]) + maxi(0, amount)
	while int(data["xp"]) >= int(data["level"]) * 120 and int(data["level"]) < 200:
		data["xp"] = int(data["xp"]) - int(data["level"]) * 120
		data["level"] = int(data["level"]) + 1
		data["coins"] = int(data["coins"]) + 50

func quest_progress(key: String) -> float:
	return minf(1.0, float(data["daily"].get(key, 0)) / float(QUEST_TARGETS.get(key, 1)))

func claim_quest(key: String) -> bool:
	if not QUESTS.has(key) or data["claimed"].has(key) or quest_progress(key) < 1.0:
		return false
	data["claimed"].append(key)
	data["coins"] = int(data["coins"]) + 100
	grant_xp(50)
	return true

func upgrade_cost(key: String) -> int:
	return (160 if key == "tank" else 180) * (int(data.get(key, 0)) + 1)

func buy_upgrade(key: String) -> bool:
	if not ["tank", "comfort"].has(key) or int(data[key]) >= 4:
		return false
	var cost := upgrade_cost(key)
	if int(data["coins"]) < cost:
		return false
	data["coins"] = int(data["coins"]) - cost
	data[key] = int(data[key]) + 1
	return true

func buy_car(key: String) -> bool:
	if not CARS.has(key):
		return false
	if data["owned"].has(key):
		data["car"] = key
		return true
	var index: int = CARS.find(key)
	var costs := [0, 150, 450, 900, 1600]
	if int(data["coins"]) < costs[index]:
		return false
	data["coins"] = int(data["coins"]) - costs[index]
	data["owned"].append(key)
	data["car"] = key
	return true

func fuel_capacity() -> float:
	return 100.0 + float(data["tank"]) * 25.0

func stat(key: String) -> float:
	if key == "rare":
		var total := 0
		for id: String in ["taxi", "police", "ambulance", "race"]:
			if data["discoveries"].has(id):
				total += 1
		return float(total)
	if key == "quests":
		return float(data["claimed"].size())
	if key == "upgrades":
		return float(int(data["tank"]) + int(data["comfort"]))
	if key == "biomes":
		return float(data["biomes"].size())
	return float(data.get(key, 0))
