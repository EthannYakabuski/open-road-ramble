extends SceneTree
const State = preload("res://game/road_state.gd")
var checks := 0
var failures := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error("FAILED: " + message)
		failures += 1

func _initialize() -> void:
	var state = State.new()
	check(state.data["level"] == 1, "new rambler starts at level one")
	check(state.roll_day("2026-10-20"), "first daily initialization")
	state.add_distance(99.0)
	check(state.data["coins"] == 0, "sub-threshold distance does not round up")
	state.add_distance(1.0)
	check(state.data["coins"] == 20, "distance coins paid exactly once at threshold")
	state.add_distance(-1000.0)
	check(state.data["distance"] == 100.0, "negative distance is rejected")
	state.add_distance(700.0)
	check(state.claim_quest("distance"), "completed distance quest can be claimed")
	check(not state.claim_quest("distance"), "daily quest cannot be claimed twice")
	check(not state.roll_day("2026-10-19"), "backwards clock does not reset quests")
	check(state.roll_day("2026-10-21"), "next day resets quest state")
	check(state.data["claimed"].is_empty(), "next day claims cleared")
	check(state.note_pass("police",true), "new rare discovery")
	check(not state.note_pass("police",true), "rare discovery reward cannot repeat")
	check(state.stat("rare") == 1.0, "rare count is unique types")
	state.data["coins"] = 1000
	check(state.buy_upgrade("tank"), "affordable fuel upgrade succeeds")
	check(state.fuel_capacity() == 125.0, "fuel capacity responds to upgrade")
	check(not state.buy_upgrade("invalid"), "unknown upgrades rejected")
	check(state.buy_car("sedan"), "vehicle purchase")
	var remaining: int = int(state.data["coins"])
	check(state.buy_car("sedan"), "owned vehicle selection")
	check(state.data["coins"] == remaining, "owned vehicle never charges twice")
	var copy = State.new()
	copy.load_data(JSON.parse_string(JSON.stringify(state.data)))
	for key: String in state.data:
		if copy.data[key] != state.data[key]: print("ROUNDTRIP_DIFF ",key," before=",state.data[key]," after=",copy.data[key])
	check(copy.data == state.data, "save round trip retains all progress")
	copy.load_data({"coins": -4,"distance": -4,"tank":99,"car":"injected","owned":["injected"]})
	check(copy.data["coins"] == 0 and copy.data["distance"] == 0.0, "negative corrupt save values clamped")
	check(copy.data["tank"] == 4 and copy.data["car"] == "hatchback", "upgrade and vehicle save validation")
	copy.load_data({"level": {}, "tank": [], "comfort": "bad"})
	check(copy.data["level"] == 1 and copy.data["tank"] == 0 and copy.data["comfort"] == 0, "malformed numeric save types safely default")
	copy.load_data(null)
	check(copy.data["level"] == 1, "invalid save safely returns fresh state")
	state.grant_xp(3000)
	check(state.data["level"] > 1, "player progression and level rewards")
	print("OPEN_ROAD_STATE_PASS" if failures == 0 else "OPEN_ROAD_STATE_FAIL", " checks=", checks, " failures=", failures)
	quit(1 if failures > 0 else 0)
