extends SceneTree
## Isolated source/scene fixtures. No native driving or production-service claim.
const Traffic = preload("res://game/road_traffic.gd")
const Drive = preload("res://game/road_drive.gd")
const State = preload("res://game/road_state.gd")
const World = preload("res://game/road_world_3d.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func vehicle(id: int, at: float, heading: int, cruise: float, lane: float = NAN) -> Dictionary:
	var x := lane if is_finite(lane) else (58.0 if heading > 0 else -58.0)
	return {"id":id,"x":x,"y":660.0-at*9.0,"kind":"sedan","rare":false,"passed":false,
		"direction":heading,"target_x":x,"speed_mps":cruise,"cruise_speed_mps":cruise}

func separated(cars: Array) -> bool:
	for a_index in range(cars.size()):
		for b_index in range(a_index+1,cars.size()):
			var a: Dictionary = cars[a_index]
			var b: Dictionary = cars[b_index]
			if absf(float(a.x)-float(b.x)) < Traffic.LATERAL_BODY:
				if absf(Traffic.position(a)-Traffic.position(b)) < Traffic.MIN_GAP-0.00001: return false
	return true

func run() -> void:
	if OS.get_name()=="Android":
		push_error("Synthetic Road fixtures must not run on the owner's Android profile")
		quit(1)
		return
	var isolated := OS.get_environment("ROUND_FIVE_TEST_ROOT").replace("\\","/").trim_suffix("/")
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").begins_with(isolated+"/"):
		push_error("Road Round5 tests require process-isolated user data and ROUND_FIVE_TEST_ROOT")
		quit(1)
		return
	_test_speed_and_save()
	_test_passing()
	_test_blocked_following()
	_test_dense_fleet()
	await _test_world_clearance()
	print("ROAD_ROUND_FIVE checks=%d failures=%d (isolated source and scene fixtures; no native acceptance)" % [checks,failures])
	quit(1 if failures else 0)

func _test_speed_and_save() -> void:
	var speed := 0.0
	var monotonic := true
	var capped := true
	var profile := State.new()
	var crossed := {}
	for frame in range(1400):
		var previous := speed
		speed=Drive.forward_speed(speed,0.05,false,false)
		monotonic=monotonic and speed>=previous
		capped=capped and speed<=Drive.MAX_SPEED_MPS
		profile.note_speed(speed*3.6)
		for threshold in [70,90,100,120]:
			if profile.stat("top_speed_kmh")>=float(threshold):crossed[threshold]=true
	check(monotonic and capped,"uninterrupted forward driving accelerates monotonically and never exceeds120km/h")
	check(is_equal_approx(speed*3.6,120.0) and crossed.size()==4,"a sufficiently long drive reaches every requested speed milestone")
	check(Drive.forward_speed(speed,1.0,true,false)<speed,"manual braking still slows a120km/h car")
	check(Drive.forward_speed(speed,5.0,false,true)==18.0,"leaving the highway slows safely for the station approach")
	check(Drive.forward_speed(21.0,0.0,false,false)==21.0,"zero covered/pause delta cannot accelerate")
	check(not profile.note_speed(70.0) and profile.stat("top_speed_kmh")==120.0,"slower drives never erase a saved speed record or repeatedly cross a milestone")
	var old := State.new().fresh()
	old.erase("top_speed_kmh")
	old.coins=731
	old.level=5
	old.xp=77
	old.distance=8842.25
	old.earned=["first_mile","level_5"]
	var loaded := State.new()
	loaded.load_data(JSON.parse_string(JSON.stringify(old)))
	var intact := true
	for key in old:
		intact=intact and loaded.data[key]==old[key]
	check(intact and loaded.stat("top_speed_kmh")==0.0,"existing version2progress survives additive peak-speed migration without fabricated old speed")
	loaded.note_speed(100.0)
	var saved := loaded.data.duplicate(true)
	var restored := State.new()
	restored.load_data(JSON.parse_string(JSON.stringify(saved)))
	check(restored.data==saved,"actual JSON round-trip preserves peak speed and every existing banked field")
	check(restored.data.coins==731 and restored.data.xp==77,"recording a speed grants no synthetic currency or XP")
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/catalog.json"))
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://platform/config.json"))
	var keys:=[]
	for achievement: Dictionary in catalog.achievements:
		if str(achievement.metric)=="top_speed_kmh":
			keys.append(int(achievement.threshold))
			check(config.play_games.achievements.has(str(achievement.key)),"new speed achievement has an explicit backend-ID mapping key")
	keys.sort()
	check(keys==[70,90,100,120] and catalog.achievements.size()==20,"four requested speed achievements are additive to the original16")

func _test_passing() -> void:
	var cars: Array=[vehicle(1,45,1,8),vehicle(2,25,1,28)]
	var moved_left:=false
	var safe:=true
	for frame in range(400):
		Traffic.step(cars,0.0,0.05,0.0)
		moved_left=moved_left or float(cars[1].x)<-40.0
		safe=safe and separated(cars)
	check(moved_left,"faster following NPC visibly chooses the left lane to pass a slower driver")
	check(Traffic.position(cars[1])>Traffic.position(cars[0])+Traffic.RETURN_GAP,"the lane change results in a completed longitudinal overtake")
	check(is_equal_approx(float(cars[1].x),58.0),"successful overtaker returns to the right-hand travel lane")
	check(safe,"overtaking and both lane transitions preserve body clearance")
	var passing := vehicle(3,30,1,25,-58)
	check(Drive.traffic_motion(20,passing)<0.0,"forward NPC keeps its heading after crossing into the left lane")
	check(Drive.patrol_observes_pass(2000,2000,passing),"patrol logic uses travel direction rather than temporarily occupied lane")
	check(not Traffic.spawn_clear([passing],-58.0,-1150.0),"new oncoming traffic cannot spawn into an active passing corridor")
	check(not Traffic.spawn_clear([vehicle(4,90,1,10)],58.0,660.0-91.0*9.0),"new traffic never spawns overlapping an existing vehicle")

func _test_blocked_following() -> void:
	var cars: Array=[vehicle(1,45,1,8),vehicle(2,25,1,30),vehicle(3,110,-1,30)]
	Traffic.step(cars,0.0,0.05,0.0)
	check(float(cars[1].target_x)==58.0,"approaching oncoming traffic prevents a dangerous left-lane pass")
	var safe:=true
	for frame in range(30):
		Traffic.step(cars,0.0,0.05,0.0)
		safe=safe and separated(cars)
	check(safe and Traffic.position(cars[1])<Traffic.position(cars[0]),"blocked faster NPC brakes behind the slower car instead of driving through it")
	var queued: Array=[vehicle(1,120,-1,9),vehicle(2,128,-1,33)]
	for frame in range(250):
		Traffic.step(queued,20.0,0.08,0.0)
		safe=safe and separated(queued)
	check(safe,"opposing-direction lane also preserves following separation across extreme speed differences")
	var closing: Array=[vehicle(1,100,1,34,-58),vehicle(2,106,-1,34)]
	for frame in range(40):
		Traffic.step(closing,20.0,0.08,200.0)
		safe=safe and separated(closing)
	check(safe,"swept final guard prevents head-on longitudinal tunnelling during a lane transition")

func _test_dense_fleet() -> void:
	var fleet: Array=[]
	var safe:=true
	var minimum:=INF
	for frame in range(1500):
		if frame%31==0:
			var heading:=1 if frame%3 else -1
			var at:=180.0 if heading<0 else 90.0
			var candidate:=vehicle(100+frame,at,heading,5.0+float(frame%27))
			if Traffic.spawn_clear(fleet,float(candidate.x),float(candidate.y)):fleet.append(candidate)
		Traffic.step(fleet,25.0,0.05,0.0)
		safe=safe and separated(fleet)
		for a: Dictionary in fleet:
			for b: Dictionary in fleet:
				if a!=b and absf(float(a.x)-float(b.x))<Traffic.LATERAL_BODY:
					minimum=minf(minimum,absf(Traffic.position(a)-Traffic.position(b)))
		fleet=fleet.filter(func(car:Dictionary):return float(car.y)<1000.0 and float(car.y)>-1600.0)
	check(safe and minimum>=Traffic.MIN_GAP-0.00001,"75-second generated mixed-speed stream has no same-corridor body overlap")

func _test_world_clearance() -> void:
	var world:=World.new()
	root.add_child(world)
	await process_frame
	world.sync(700,850,200,[],"hatchback",2,"drive",0)
	var cleared:=0
	var bad:=0
	var left_visible:=0
	for item: Node3D in world.scenery:
		var landmark:=item.has_meta("landmark")
		var at:=700.0-item.position.z
		var right:=item.position.x>0.0 if landmark else item.position.x-world.road_x(at,700.0)>0.0
		if right and World.station_access_reserved(at,850,landmark):
			cleared+=1
			if item.visible:bad+=1
		if not right and item.visible:left_visible+=1
	check(cleared>8 and bad==0,"actual scaled scenery nodes are absent throughout the right-hand slip lane and forecourt corridor")
	check(left_visible>8,"clearing the station approach preserves scenery on the opposite side")
	check(world.forecourt.visible and world.exit_lane.visible,"the visible station and its marked access lane remain intact")
	var passing: Array=[vehicle(51,20,1,25,-58)]
	world.sync(700,850,0,passing,"hatchback",0,"drive",0)
	check(is_equal_approx(float(world.traffic_models[51].rotation.y),PI),"actual car mesh faces forward while occupying the left passing lane")
	world.queue_free()
	await process_frame
	await process_frame
