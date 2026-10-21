extends "res://game/drive_kit.gd"
## Perspective world driven by travelled metres. Physical traffic shapes are
## queried in 3D; world scrolling never earns distance or passes by itself.
const CAR_MODELS := {"hatchback":"hatchback-sports", "sedan":"sedan", "suv":"suv", "tourer":"sedan-sports", "camper":"van"}
const BIOME_COLORS := [Color("83a46f"), Color("9cbb9d"), Color("cfbd87"), Color("9bb7aa")]
var player: CollisionObject3D
var camera: Camera3D
var ground: MeshInstance3D
var ocean: MeshInstance3D
var ground_material: StandardMaterial3D
var world_environment: WorldEnvironment
var forecourt: Node3D
var road_tiles: Array[Node3D] = []
var scenery: Array[Node3D] = []
var traffic_models: Dictionary = {}
var selected_car := ""
var biome := -1
var last_player_x := 0.0
var last_distance := 0.0
var build_complete := false
var collision_flash := 0.0

func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_2X
	world_environment = sky_and_sun()
	ground = box(self, Vector3(0, -0.14, -110), Vector3(150, 0.15, 440), BIOME_COLORS[0])
	ground_material = ground.material_override
	ocean = box(self,Vector3(-42,0.01,-110),Vector3(68,0.06,440),Color("318c9b"))
	for i in range(47):
		var road := model("roads", "road-straight", self, Vector3.ZERO, Vector3(8.25, 1.0, 10.0))
		road_tiles.append(road)
	forecourt = station(self)
	camera = Camera3D.new()
	camera.name = "FollowingCamera"
	camera.fov = 57.0
	camera.near = 0.15
	camera.far = 360.0
	camera.position = Vector3(0, 5.2, 10.0)
	add_child(camera)
	camera.current = true
	build_complete = true
	sync(0.0, 850.0, 0.0, [], "hatchback", 0, "home", 0.0)

func _curvature(distance: float) -> float:
	return sin(distance / 180.0) * 12.0 + sin(distance / 420.0) * 6.0

func road_x(at_distance: float, origin_distance: float) -> float:
	return _curvature(at_distance) - _curvature(origin_distance)

func _populate_scenery(next_biome: int) -> void:
	for item in scenery: item.queue_free()
	scenery.clear()
	var types := ["tree_oak", "tree_palm", "rock_largeA", "tree_pineRoundA"]
	for i in range(66):
		var kind: String = types[next_biome] if i % 5 != 0 else "plant_bush"
		if next_biome == 1 and i % 2 == 0: kind = "rock_largeA"
		var item := model("nature", kind, self, Vector3.ZERO, Vector3.ONE * (2.0 + float(i % 4) * 0.30))
		for mesh in item.find_children("*", "GeometryInstance3D", true, false):
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		scenery.append(item)
	# Real settlement silhouettes give the road destinations and a human scale.
	for i in range(8):
		var group := "suburban" if i % 2 == 0 else "commercial"
		var key := "building-type-a" if group == "suburban" else "building-b"
		scenery.append(model(group, key, self, Vector3.ZERO, Vector3.ONE * 4.5))
	for i in range(6):
		var hill := model("nature","rock_largeA",self,Vector3.ZERO,Vector3(32.0,24.0,24.0))
		hill.set_meta("landmark",true)
		scenery.append(hill)
	ocean.visible = next_biome == 1
	ground_material.albedo_color = BIOME_COLORS[next_biome]
	biome = next_biome

func sync(distance: float, station_distance: float, offset: float, traffic: Array, car_key: String, next_biome: int, mode: String, delta: float) -> void:
	if not build_complete: return
	if selected_car != car_key:
		if is_instance_valid(player):
			remove_child(player)
			player.free()
		player = car(CAR_MODELS.get(car_key, "hatchback-sports"), self, -1, true)
		selected_car = car_key
	if biome != next_biome: _populate_scenery(next_biome)
	var driving := mode in ["drive", "pause", "help", "repair"]
	var origin_distance := distance if driving or mode == "station" else 0.0
	for i in range(road_tiles.size()):
		var z := 24.0 - float(i) * 8.0 + fmod(origin_distance, 8.0)
		var at_distance := origin_distance - z
		road_tiles[i].position = Vector3(road_x(at_distance, origin_distance), -0.01, z)
		road_tiles[i].rotation.y = PI * 0.5 - atan2(_curvature(at_distance + 1) - _curvature(at_distance - 1), 2.0)
	for i in range(scenery.size()):
		if scenery[i].has_meta("landmark"):
			scenery[i].position = Vector3((-1.0 if i%2==0 else 1.0)*45.0, -5.0, -90.0-float(i%3)*75.0)
			continue
		var z := 20.0 - fposmod(float(i) * 21.7 + origin_distance, 320.0)
		var side := -1.0 if i % 2 == 0 else 1.0
		if next_biome == 1 and i >= 66: side = 1.0
		var x := road_x(origin_distance - z, origin_distance) + side * (9.0 + float(i % 7) * 3.0)
		scenery[i].position = Vector3(x, 0, z)
		scenery[i].rotation.y = float(i) * 2.4
	var station_z := -(station_distance - origin_distance)
	forecourt.visible = station_z > -180.0 and station_z < 35.0 or mode == "station"
	forecourt.position = Vector3(road_x(station_distance, origin_distance) + 14.5, 0, station_z)
	if mode == "station": forecourt.position = Vector3(11.5, 0, -8.0)
	var x := offset * 0.032 if driving else 0.0
	player.position = Vector3(x, 0.035, 0)
	player.rotation.y = PI - clampf((x - last_player_x) * 0.7, -0.18, 0.18)
	if mode == "station":
		player.position = Vector3(7.2, 0.035, -4.0)
		player.rotation.y = -PI * 0.5
	spin_wheels(player, maxf(0.0, distance - last_distance), (x - last_player_x) * 2.0)
	last_player_x = x
	last_distance = distance
	var present: Dictionary = {}
	for data in traffic:
		var id := int(data.get("id", -1))
		present[id] = true
		if not traffic_models.has(id): traffic_models[id] = car(str(data["kind"]), self, id)
		var body: Node3D = traffic_models[id]
		var z := (float(data["y"]) - 660.0) / 9.0
		body.position = Vector3(road_x(origin_distance - z, origin_distance) + float(data["x"]) * 0.032, 0.035, z)
		body.rotation.y = 0.0 if float(data["x"]) < 0 else PI
		body.visible = driving
		spin_wheels(body, delta * (15.0 if float(data["x"]) < 0 else 8.0))
	for id in traffic_models.keys():
		if not present.has(id):
			traffic_models[id].free()
			traffic_models.erase(id)
	collision_flash = maxf(0.0, collision_flash - delta)
	camera.v_offset = 0.0
	var desired := Vector3(x * 0.72, 5.2, 10.0)
	var focus := Vector3(x * 0.2, 0.5, -14.0)
	if not driving and mode != "station":
		desired = Vector3(4.0, 3.4, 5.5)
		focus = Vector3(0, 0.7, 0)
		camera.v_offset = -1.6
	if mode == "station":
		desired = Vector3(-3.0, 7.0, 12.0)
		focus = Vector3(8.0, 1.2, -5.0)
		camera.v_offset = -1.8
	if collision_flash > 0.0: desired.x += sin(collision_flash * 75.0) * collision_flash * 0.45
	camera.position = desired if delta <= 0 else camera.position.lerp(desired, minf(delta * 5.0, 1.0))
	camera.look_at(focus, Vector3.UP)

func contacts() -> Array[int]:
	var result: Array[int] = []
	if not is_instance_valid(player) or not is_inside_tree(): return result
	var shape: CollisionShape3D = player.get_node("CollisionShape3D")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape.shape
	query.transform = player.global_transform * shape.transform
	query.collision_mask = 2
	query.exclude = [player.get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 8):
		var id := int(hit["collider"].get_meta("traffic_id", -1))
		if id >= 0: result.append(id)
	return result
