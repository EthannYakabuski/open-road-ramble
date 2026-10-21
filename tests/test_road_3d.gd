extends SceneTree
## Synthetic source/physics regression; not native gameplay evidence.
const State = preload("res://game/road_state.gd")
const Drive = preload("res://game/road_drive.gd")
const World = preload("res://game/road_world_3d.gd")
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
	var old = State.new().fresh()
	old.erase("collisions")
	old.version = 1
	old.coins = 731
	old.xp = 77
	old.level = 5
	old.distance = 8842.25
	old.owned = ["hatchback", "sedan", "suv"]
	old.car = "sedan"
	old.tank = 2
	old.comfort = 1
	old.discoveries = ["taxi", "suv", "police"]
	old.earned = ["road_first_mile"]
	old.biomes = ["meadow", "coast"]
	old.day = "2026-10-21"
	old.daily = {"distance":654.5,"passes":9,"refuels":1}
	old.claimed = ["passes"]
	var migrated = State.new()
	migrated.load_data(JSON.parse_string(JSON.stringify(old)))
	for key in old:
		if key != "version": check(migrated.data[key] == old[key], "v1 save preserves " + key)
	check(migrated.data.version == 2 and migrated.data.collisions == 0, "additive v2 collision migration")
	var before: Dictionary = migrated.data.duplicate(true)
	migrated.note_collision()
	check(migrated.data.coins == before.coins and migrated.data.xp == before.xp and migrated.data.distance == before.distance, "collision never erases banked progression")
	check(migrated.data.collisions == 1, "lifetime collision records once")
	var drive = Drive.new()
	check(drive.hearts == 3, "three hearts at departure")
	check(drive.collide(5) and drive.hearts == 2, "first collision costs a heart")
	check(not drive.collide(6) and drive.hearts == 2, "grace protects one contact from rapid multiple hits")
	drive.tick(2.0)
	check(not drive.collide(5), "same overlapping vehicle never costs another heart")
	check(drive.collide(6), "distinct later collision has a consequence")
	drive.tick(2.0)
	check(drive.collide(7) and drive.hearts == 0, "third hit ends the safe drive")
	check(not drive.collide(8), "terminated drive cannot keep losing hearts")
	drive.repair()
	check(drive.hearts == 3, "free forecourt repair restores hearts")
	var world = World.new()
	root.add_child(world)
	await physics_frame
	await physics_frame
	check(world.player is CharacterBody3D and world.camera is Camera3D, "actual 3D player body and following camera")
	check(world.player.get_node("KenneyCar").get_child_count() > 0, "actual imported Kenney player mesh")
	check(world.forecourt.get_node("building-a") != null and world.road_tiles.size() >= 40, "modeled forecourt and supplied road tiles")
	var traffic := [{"id":31,"x":0.0,"y":660.0,"kind":"sedan","rare":false,"passed":false}]
	world.sync(100.0, 850.0, 0.0, traffic, "hatchback", 0, "drive", 0.016)
	await physics_frame
	await physics_frame
	check(world.contacts().has(31), "native 3D physics detects overlapping traffic collider")
	world.sync(100.0, 850.0, 100.0, traffic, "hatchback", 0, "drive", 0.016)
	await physics_frame
	await physics_frame
	check(not world.contacts().has(31), "steering away clears physical collision")
	world.sync(100.0, 850.0, 0.0, [], "hatchback", 0, "drive", 0.016)
	await physics_frame
	check(world.traffic_models.is_empty(), "traffic physics and meshes cleaned together")
	check(absf(world.road_x(400.0, 100.0)) > 0.2, "world road curves ahead of the following camera")
	world.sync(100.0,850.0,0.0,[],"hatchback",0,"drive",0,5500.0)
	check(world.is_night and world.headlight.visible,"legacy lifetime-distance night cycle enables actual headlights")
	check(world.forecourt_light.visible and world.get_node("TouringSun").light_energy < 0.3,"night has readable moonlight and warm forecourt lighting")
	world.sync(0.0,850.0,0.0,[],"sedan",0,"home",0,5500.0)
	check(world.is_night and world.headlight.visible,"trip restart and selected-car change preserve night from lifetime progress")
	world.sync(0.0,850.0,0.0,[],"sedan",0,"home",0,8000.0)
	check(not world.is_night and not world.headlight.visible,"distance cycle returns to daylight without changing progression")
	world.queue_free()
	await process_frame
	await process_frame
	print("ROAD_3D_REGRESSION checks=%d failures=%d (synthetic source and actual engine physics)" % [checks,failures])
	quit(1 if failures else 0)
