extends SceneTree
## Synthetic integrated scene regression. Never native SDK or player-save proof.
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	# Active engine/chime audio is also drained before scene removal.
	game.muted = false
	root.add_child(game)
	game.smoke = true
	game.set_process(false)
	game._start_drive()
	var before_passes: int = game.state.data.passes
	var before_collisions: int = game.state.data.collisions
	for index in range(3):
		game.drive.grace = 0.0
		game.traffic.clear()
		game.traffic.append({"id":90+index,"x":0.0,"y":660.0,"kind":"sedan","rare":false,"passed":false,"drift":0.0})
		game.world3d.sync(0.0,850.0,0.0,game.traffic,"hatchback",0,"drive",0.0)
		await physics_frame
		await physics_frame
		check(game.drive.hearts == 2-index, "physical contact updates integrated hearts %d" % index)
		check(game.state.data.passes == before_passes and game.traffic[0].passed, "collision cannot grant a clean pass")
	check(game.screen == "repair" and game.state.data.collisions == before_collisions+3, "third physical collision opens free-repair decision")
	var before_distance: float = game.state.data.distance
	var before_coins: int = game.state.data.coins
	var before_xp: int = game.state.data.xp
	game._accept_help()
	check(game.screen == "station", "roadside repair reaches modeled station")
	check(game.state.data.distance == before_distance and game.state.data.coins == before_coins and game.state.data.xp == before_xp, "help teleport grants no distance/currency/XP")
	game._refuel()
	check(game.screen == "drive" and game.drive.hearts == 3 and game.fuel == game.state.fuel_capacity(), "free stop repairs and refuels")
	check(game.heart_icons.size() == 3 and game.heart_icons[0].texture != null, "visible heart icons rebuilt after repair")
	before_distance = game.state.data.distance
	game.service.set("_interstitial_showing",true)
	game._process(20.0)
	check(game.state.data.distance == before_distance, "simulated fullscreen service state freezes travel")
	game.service.set("_interstitial_showing",false)
	game._process(20.0)
	check(game.screen == "pause" and game.state.data.distance == before_distance, "fullscreen return requires explicit Resume and drops covered time")
	game._resume()
	game._process(20.0)
	check(game.state.data.distance == before_distance, "first return frame discards stale delta")
	var drag := InputEventScreenDrag.new()
	drag.position = Vector2(460,500)
	game._unhandled_input(drag)
	game._process(0.05)
	check(game.target_x > 0 and game.world3d.player.position.x > 0, "manual touch steering moves actual 3D car")
	check(game.state.data.distance > before_distance, "ordinary resumed drive advances genuine simulated movement")
	game._show_pause()
	before_distance = game.state.data.distance
	game._process(5.0)
	check(game.state.data.distance == before_distance, "ordinary pause freezes progression")
	await game.shutdown_audio()
	game.queue_free()
	await process_frame
	await process_frame
	print("ROAD_3D_FLOW checks=%d failures=%d (synthetic integrated scene/physics/input)" % [checks,failures])
	quit(1 if failures else 0)
