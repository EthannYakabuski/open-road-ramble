extends SceneTree
## Isolated source/scene/physics fixtures, never native or genuine-save evidence.
const Drive = preload("res://game/road_drive.gd")
const State = preload("res://game/road_state.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(not Drive.exit_open(181) and Drive.exit_open(180) and not Drive.exit_open(-23), "Exit only opens beside its signed slip lane")
	check(Drive.steering_limit(300)==107 and Drive.steering_limit(10)>420, "Ordinary highway stays bounded while the exit widens to the forecourt")
	check(not Drive.entered_forecourt(5,107) and not Drive.entered_forecourt(100,350), "Highway position and early lateral steering cannot teleport to station")
	check(Drive.entered_forecourt(5,350), "Real forecourt entry requires rightward position and actual arrival")
	check(Drive.traffic_motion(20,{"x":58,"speed_mps":8}) > Drive.traffic_motion(20,{"x":58,"speed_mps":15}), "Same-direction NPC speed varies actual relative movement")
	check(Drive.traffic_motion(5,{"x":58,"speed_mps":8}) < 0, "Faster traffic pulls away when the player brakes")
	check(Drive.traffic_motion(20,{"x":-58,"speed_mps":15}) > Drive.traffic_motion(20,{"x":58,"speed_mps":15}), "Oncoming and same-direction closing speeds differ")
	check(Drive.patrol_observes_pass(2000,2030,{"x":58}) and not Drive.patrol_observes_pass(2000,2030,{"x":-58}), "Patrol penalizes overtaking, not meeting oncoming traffic")
	check(not Drive.patrol_observes_pass(2000,2100,{"x":58}), "A distant patrol cannot catch an overtake")
	var profile=State.new()
	var before=profile.data.duplicate(true)
	check(profile.note_discovery("police",true), "Roadside police remain an obtainable journal discovery")
	check(profile.data.passes==before.passes and profile.data.daily.passes==before.daily.passes, "Spotting parked police never counts as passing them")
	var first=profile.data.duplicate(true)
	check(not profile.note_discovery("police",true) and profile.data==first, "A parked sighting rewards the journal once")
	var game=load("res://main.tscn").instantiate()
	game.muted=true
	root.add_child(game)
	game.smoke=true
	game.set_process(false)
	game.set_physics_process(false)
	await process_frame
	game._start_drive()
	check(game.VEHICLES.has("police") and game.RARE.has("police"), "Existing police journal and rare-achievement membership remain present")
	game.world3d.sync(40,850,0,[],"suv",0,"drive",0)
	var world=game.world3d
	var prop_z: float=world.scenery[1].position.z
	var road_z: float=world.road_tiles[0].position.z
	world.sync(41,850,0,[],"suv",0,"drive",0)
	check(is_equal_approx(world.scenery[1].position.z-prop_z,1), "A roadside prop moves toward the camera as forward distance advances")
	check(is_equal_approx(world.road_tiles[0].position.z-road_z,1), "Prop and road surface travel in the same direction")
	world.sync(750,850,350,[],"suv",0,"drive",0)
	check(world.camera.is_position_in_frustum(world.player.global_position+Vector3(0,0.7,0)), "Following camera keeps the car visible in the right-hand exit")
	var nearest: Node3D = null
	for section in world.exit_lane.get_children():
		if section.has_meta("lane_start") and (nearest==null or absf(section.global_position.z)<absf(nearest.global_position.z)): nearest=section
	check(nearest!=null and nearest.global_position.x>5 and nearest.global_position.x<10, "Curved slip lane remains beside the actual local road instead of inheriting distant station drift")
	var spare=world.player.find_child("wheel-back",true,false)
	var rolling=world.player.find_child("wheel-front-left",true,false)
	check(spare!=null and rolling!=null, "Actual supplied SUV has both spare and rolling front wheel")
	var spare_rotation: Vector3=spare.rotation
	var rolling_rotation: Vector3=rolling.rotation
	world.spin_wheels(world.player,2)
	check(spare.rotation==spare_rotation, "SUV's rear spare stays fixed instead of orbiting")
	check(rolling.rotation!=rolling_rotation, "Actual road wheels still rotate")
	game.route_distance=game.route_station-20
	game.player_x=0
	game._request_stop()
	check(game.screen=="drive", "Station action on the highway only explains the exit")
	game.route_distance=700
	game.player_x=107
	game.target_x=107
	game.speed=13
	game.brake_held=true
	var touch=InputEventScreenTouch.new()
	touch.pressed=true
	touch.position=Vector2(520,600)
	game._unhandled_input(touch)
	for index in range(900):
		if game.screen!="drive":break
		game.spawn_timer=5
		game._process(0.05)
	check(game.screen=="station", "One continuous rightward steering input follows the actual slip lane and enters the station")
	check(not bool(game.service.get("_menu_visible")), "Forecourt station still hides the ad banner")
	var trip: float=game.trip_distance
	game._refuel()
	check(game.last_pitstop.trip==trip and game.last_pitstop.next_station==1700, "A completed fuel stop becomes the next patrol checkpoint")
	game._discard_next_frame=false
	game.state.data.coins=1234
	game.state.data.xp=77
	game.route_distance+=120
	game.trip_distance+=120
	game.fuel-=10
	game.speed=20
	game.patrol={"distance":game.route_distance,"spotted":true}
	game.traffic.clear()
	game.traffic.append({"id":501,"kind":"sedan","x":58.0,"y":679.5,"speed_mps":8.0,"rare":false,"passed":false})
	before=game.state.data.duplicate(true)
	game._process(0.05)
	check(game.screen=="patrol", "A same-direction overtake near an actual roadside patrol triggers capture")
	check(game.route_distance==game.last_pitstop.route and game.trip_distance==trip and game.fuel==game.last_pitstop.fuel, "Capture restores ramble route, trip and fuel to the completed stop")
	check(game.state.data.coins==1234 and game.state.data.xp==77 and game.state.data.passes==before.passes, "Capture preserves banked coins/XP and grants no passing reward")
	check(game.traffic.is_empty() and game.speed==0, "Captured traffic is retired and no motion continues behind the explanation")
	game._resume()
	game._discard_next_frame=false
	game.route_distance=2000
	game.patrol={"distance":2000.0,"spotted":true}
	game.traffic.clear()
	game.traffic.append({"id":502,"kind":"sedan","x":-58.0,"y":679.5,"speed_mps":15.0,"rare":false,"passed":false})
	game.speed=20
	game._process(0.05)
	check(game.screen=="drive", "Meeting an oncoming NPC beside a patrol is not an offence")
	game.application_suspended=true
	game.patrol={"distance":game.route_distance,"spotted":false}
	before=game.state.data.duplicate(true)
	game._process(0.05)
	check(game.state.data==before and not game.patrol.spotted, "Covered gameplay cannot award a parked sighting or advance patrol detection")
	game.application_suspended=false
	seed(20261024)
	game._spawn_traffic()
	for index in range(200):game._spawn_traffic()
	var seen_speeds={}
	var moving_police := 0
	for vehicle in game.traffic:
		if vehicle.kind=="police":moving_police+=1
		seen_speeds[float(vehicle.speed_mps)]=true
	check(moving_police==0, "Police are never generated as moving road traffic")
	check(seen_speeds.size()>20, "Generated NPC fleet has real per-vehicle speed variation")
	world.sync(2000,2550,0,[],"suv",0,"drive",0,-1,{"distance":2050.0})
	check(world.roadside_patrol.visible and world.roadside_patrol.position.x< -4 and world.roadside_patrol.collision_layer==0, "Patrol is visibly parked outside the road and never a traffic collider")
	await game.shutdown_audio()
	game.queue_free()
	await process_frame
	await process_frame
	print("ROAD_ROUND_FOUR checks=%d failures=%d (isolated source/scene fixtures)"%[checks,failures])
	quit(1 if failures else 0)
