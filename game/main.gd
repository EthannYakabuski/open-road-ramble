extends Node2D
const State = preload("res://game/road_state.gd")
const RoadWorldScene = preload("res://game/road_world_3d.gd")
const Drive = preload("res://game/road_drive.gd")
const W := 540.0
const H := 960.0
const INK := Color("183a3f")
const CREAM := Color("f5f0df")
const MINT := Color("94d3b0")
const ORANGE := Color("df794d")
const GOLD := Color("e9c86b")
const CAR_NAMES := {"hatchback":"Sunday Hatch", "sedan":"Little Sedan", "suv":"Trail Buddy", "tourer":"Golden Tourer", "camper":"Wandering Van"}
const PORTRAITS := {"hatchback":"hatchback-sports", "sedan":"sedan", "suv":"suv", "tourer":"sedan-sports", "camper":"van"}
const CAR_COLORS := {"hatchback":Color("df794d"), "sedan":Color("8abbd1"), "suv":Color("94d3b0"), "tourer":Color("e9c86b"), "camper":Color("bd9bc8")}
const VEHICLES := ["sedan", "suv", "van", "truck", "hatchback-sports", "sedan-sports", "taxi", "police", "ambulance", "race"]
const RARE := ["taxi", "police", "ambulance", "race"]
const MOVING_RARE := ["taxi", "ambulance", "race"]
const BIOMES := ["Meadow miles", "Coastal breeze", "Desert postcards", "Alpine air"]
const SAVE_PATH := "user://open_road_ramble_v1.json"
var state = State.new()
var catalog: Dictionary = {}
var screen := "home"
var ui: Control
var menu_scroll: ScrollContainer
var hud_distance: Label
var hud_speed: Label
var hud_fuel: ProgressBar
var hud_station: Button
var hud_biome: Label
var reward_button: Button
var toast_label: Label
var toast_left := 0.0
var trip_distance := 0.0
var route_distance := 0.0
var route_station := 850.0
var fuel := 100.0
var speed := 0.0
var player_x := 0.0
var target_x := 0.0
var brake_held := false
var pointer_down := false
var pointer_x_position := 270.0
var scenery_scroll := 0.0
var traffic: Array[Dictionary] = []
var spawn_timer := 0.0
var save_timer := 0.0
var elapsed := 0.0
var bumper_cooldown := 0.0
var service: Node
var portraits: Dictionary = {}
var sound_click: AudioStreamPlayer
var sound_chime: AudioStreamPlayer
var engine: AudioStreamPlayer
var muted := false
var _audio_shutting_down := false
var _audio_drained := false
var _quit_pending := false
var capture_screen := ""
var capture_path := ""
var capture_frames := 0
var smoke := false
var world3d: Node3D
var drive = Drive.new()
var heart_icons: Array[TextureRect] = []
var traffic_serial := 0
var application_suspended := false
var _was_external_blocked := false
var _discard_next_frame := false
var last_pitstop: Dictionary = {}
var patrol: Dictionary = {}
var patrol_serial := 0

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	randomize()
	service = get_node_or_null("/root/Services")
	if is_instance_valid(service) and service.has_signal("menu_bottom_reserve_changed"):
		service.connect("menu_bottom_reserve_changed", _apply_banner_layout)
	get_viewport().size_changed.connect(_apply_banner_layout)
	if FileAccess.file_exists(SAVE_PATH):
		state.load_data(JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH)))
	state.roll_day(Time.get_date_string_from_system(true))
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://game/catalog.json"))
	fuel = state.fuel_capacity()
	for car: String in VEHICLES:
		portraits[car] = load("res://assets/cars/" + car + ".png")
	sound_click = _audio("res://assets/audio/click.ogg", -13.0)
	sound_chime = _audio("res://assets/audio/chime.ogg", -13.0)
	engine = _audio("res://assets/audio/engine.wav", -25.0)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--smoke-test": smoke = true
		if arg.begins_with("--capture="): capture_screen = arg.trim_prefix("--capture=")
		if arg.begins_with("--capture-path="): capture_path = arg.trim_prefix("--capture-path=")
	world3d = RoadWorldScene.new()
	world3d.name = "RoadWorld3D"
	add_child(world3d)
	_build_theme()
	_show_home()
	if capture_screen != "":
		state.data["coins"] = 620
		state.data["level"] = 4
		state.data["distance"] = 4620.0
		state.data["discoveries"] = ["sedan", "suv", "van", "police"]
		match capture_screen:
			"drive":
				_start_drive()
				trip_distance = 462.0
				route_distance = 462.0
				fuel = 68.0
				_spawn_traffic(0.22, -1)
				_spawn_traffic(0.65, 1)
			"station":
				_start_drive()
				route_distance = route_station-5.0
				player_x = 350.0
				_request_stop()
			"help": _show_help()
			"achievements": _show_achievements()
			"settings": _show_settings()
			"garage": _show_garage()
			"journal": _show_journal()
			"quests": _show_quests()
			_: _show_home()
	if smoke: call_deferred("_run_smoke")
	_save()

func _audio(path: String, volume: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.volume_db = volume
	add_child(p)
	return p

func _build_theme() -> void:
	var theme := Theme.new()
	theme.default_font_size = 19
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color("72827a"))
	for style: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = MINT if style != "disabled" else Color("d3d9cb")
		if style == "hover": box.bg_color = MINT.lightened(0.12)
		if style == "pressed": box.bg_color = MINT.darkened(0.12)
		box.set_corner_radius_all(15)
		box.content_margin_left = 15
		box.content_margin_right = 15
		box.border_color = INK if style == "focus" else Color.TRANSPARENT
		box.set_border_width_all(2 if style == "focus" else 0)
		theme.set_stylebox(style, "Button", box)
	ui = Control.new()
	ui.name = "UI"
	ui.theme = theme
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_scroll = ScrollContainer.new()
	menu_scroll.size = Vector2(540, 960)
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.follow_focus = true
	menu_scroll.get_v_scroll_bar().value_changed.connect(func(_value: float): queue_redraw())
	add_child(menu_scroll)
	ui.custom_minimum_size = Vector2(540, 960)
	menu_scroll.add_child(ui)

func _apply_banner_layout(reserve_override: float = -1.0) -> void:
	if not is_instance_valid(menu_scroll): return
	var reserve := reserve_override
	if reserve < 0.0:
		reserve = float(service.call("menu_bottom_reserve", self)) if is_instance_valid(service) and service.has_method("menu_bottom_reserve") else 0.0
	if screen in ["drive", "station"]: reserve = 0.0
	reserve = clampf(reserve, 0.0, 400.0)
	menu_scroll.size = Vector2(540.0, 960.0 - reserve)
	menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if reserve > 0.0 else ScrollContainer.SCROLL_MODE_SHOW_NEVER
	menu_scroll.mouse_filter = Control.MOUSE_FILTER_PASS if reserve > 0.0 else Control.MOUSE_FILTER_IGNORE
	if reserve <= 0.0: menu_scroll.scroll_vertical = 0
	queue_redraw()

func _menu_draw_offset() -> Vector2:
	return Vector2(0, -float(menu_scroll.scroll_vertical)) if is_instance_valid(menu_scroll) else Vector2.ZERO


func _clear_ui() -> void:
	for child: Node in ui.get_children():
		# Keep controls in the tree until the current input dispatch completes.
		if child is CanvasItem: child.hide()
		child.queue_free()
	heart_icons.clear()
	hud_distance = null
	hud_speed = null
	hud_fuel = null
	hud_station = null
	hud_biome = null
	reward_button = null
	toast_label = null
	brake_held = false
	pointer_down = false
	if service: service.call("set_menu_visible", screen not in ["drive", "station"])
	menu_scroll.scroll_vertical = 0
	_apply_banner_layout()
	if engine:
		if screen != "drive" or muted or _audio_shutting_down:
			engine.stop()
		elif not engine.playing:
			engine.play()

func _label(text: String, rect: Rect2, size: int = 20, color: Color = INK, parent: Node = null) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else ui).add_child(label)
	return label

func _button(text: String, rect: Rect2, action: Callable, accent: bool = false) -> Button:
	var button := Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_PASS if screen != "drive" else Control.MOUSE_FILTER_STOP
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 19)
	if accent:
		var box := StyleBoxFlat.new()
		box.bg_color = ORANGE
		box.set_corner_radius_all(16)
		button.add_theme_stylebox_override("normal", box)
		button.add_theme_color_override("font_color", CREAM)
	button.pressed.connect(func():
		if not muted and not _audio_shutting_down and not sound_click.playing: sound_click.play()
		action.call())
	ui.add_child(button)
	return button

func _panel(rect: Rect2, color: Color = CREAM) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(22)
	box.shadow_color = Color(0,0,0,0.12)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0,4)
	panel.add_theme_stylebox_override("panel", box)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(panel)
	return panel

func _center_label(text: String, rect: Rect2, size: int = 20, color: Color = INK) -> Label:
	var label := _label(text, rect, size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _title(title: String, subtitle: String) -> void:
	_panel(Rect2(18,18,504,104))
	_label(title, Rect2(38,29,430,45), 29)
	_label(subtitle, Rect2(38,77,440,28), 16, Color("5c786e"))

func _portrait(key: String, rect: Rect2) -> void:
	var texture := TextureRect.new()
	texture.texture = portraits.get(key)
	texture.position = rect.position
	texture.size = rect.size
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(texture)

func _footer() -> void:
	_center_label("A little road. A big sky. Nowhere you need to be.", Rect2(20,875,500,35), 15, CREAM)
	_center_label("Ads optional on Android · Your journey saves locally", Rect2(20,912,500,28), 12, Color("c9ddd0"))

func _show_home() -> void:
	screen = "home"
	_clear_ui()
	_panel(Rect2(22,32,496,192))
	_label("TAKE THE LONG WAY", Rect2(46,50,440,29), 14, Color("6c887b"))
	_label("OPEN ROAD", Rect2(43,86,455,59), 43)
	_label("RAMBLE", Rect2(43,137,380,57), 43)
	_panel(Rect2(24,408,492,142))
	_portrait(str(PORTRAITS[state.data["car"]]), Rect2(35,416,110,110))
	_label(str(CAR_NAMES[state.data["car"]]), Rect2(155,424,340,34), 24)
	_label("Level %d · %d travel coins" % [state.data["level"],state.data["coins"]], Rect2(155,466,335,28), 18)
	_label("%s explored · %d cars spotted" % [_km(float(state.data["distance"])), state.data["discoveries"].size()], Rect2(155,500,335,25), 15, Color("5c786e"))
	_button("Let's ramble  →", Rect2(24,574,492,68), _start_drive, true)
	_button("Garage", Rect2(24,659,238,58), _show_garage)
	_button("Field journal", Rect2(278,659,238,58), _show_journal)
	_button("Today's detours", Rect2(24,731,238,58), _show_quests)
	_button("Settings & services", Rect2(278,731,238,58), _show_settings)
	_center_label("Drag to steer · Hold BRAKE for a slower view", Rect2(20,811,500,30), 16, CREAM)
	_footer()
	_sync_stats()

func _start_drive() -> void:
	screen = "drive"
	_clear_ui()
	traffic.clear()
	drive.reset()
	spawn_timer = 0.6
	trip_distance = 0.0
	route_distance = 0.0
	route_station = 850.0
	fuel = state.fuel_capacity()
	speed = 0.0
	player_x = 0.0
	target_x = 0.0
	_checkpoint_pitstop()
	_schedule_patrol()
	_make_hud()
	if not muted and not _audio_shutting_down and not engine.playing: engine.play()

func _make_hud() -> void:
	_panel(Rect2(18,18,504,138))
	hud_biome = _label("MEADOW MILES", Rect2(36,29,355,27), 14, Color("5c786e"))
	_button("Ⅱ", Rect2(452,32,52,44), _show_pause)
	hud_distance = _label("0.00 km", Rect2(36,60,260,42), 31)
	hud_speed = _label("0 km/h", Rect2(320,69,117,29), 19)
	hud_fuel = ProgressBar.new()
	for i in range(3):
		var icon := TextureRect.new()
		icon.position = Vector2(36 + i * 31, 112)
		icon.size = Vector2(24, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(icon)
		heart_icons.append(icon)
	_update_hearts()
	hud_fuel.position = Vector2(153,120)
	hud_fuel.size = Vector2(283,8)
	hud_fuel.show_percentage = false
	hud_fuel.max_value = state.fuel_capacity()
	var fuel_box := StyleBoxFlat.new()
	fuel_box.bg_color = ORANGE
	fuel_box.set_corner_radius_all(4)
	hud_fuel.add_theme_stylebox_override("fill", fuel_box)
	ui.add_child(hud_fuel)
	_panel(Rect2(18,786,504,150))
	_center_label("DRAG LEFT / RIGHT TO STEER", Rect2(30,798,480,28), 14, Color("5c786e"))
	var brake := _button("HOLD BRAKE", Rect2(34,844,210,67), func(): pass)
	brake.button_down.connect(func(): brake_held = true)
	brake.button_up.connect(func(): brake_held = false)
	hud_station = _button("STATION 850m", Rect2(261,844,245,67), _station_guidance, true)
	toast_label = _center_label("Keep a little fuel for the journey", Rect2(24,172,492,44), 17, CREAM)
	var toast_style := StyleBoxFlat.new()
	toast_style.bg_color = Color(INK,0.88)
	toast_style.set_corner_radius_all(14)
	toast_label.add_theme_stylebox_override("normal",toast_style)
	toast_left = 4.0

func _show_pause() -> void:
	screen = "pause"
	_clear_ui()
	_title("A moment to breathe", "Your car is parked safely. No hurry.")
	_panel(Rect2(38,330,464,353))
	_center_label(_km(trip_distance) + " this ramble", Rect2(58,356,424,52), 30)
	_center_label("Your progress is already saved.", Rect2(55,416,430,32), 18)
	_button("Back to the road", Rect2(64,477,412,66), _resume, true)
	_button("Finish this ramble", Rect2(64,561,412,66), _end_drive)
	_save()

func _resume() -> void:
	_discard_next_frame = true
	screen = "drive"
	_clear_ui()
	_make_hud()

func _end_drive() -> void:
	if service: service.call("round_finished")
	engine.stop()
	_save()
	_show_home()

func _station_guidance() -> void:
	_toast("Steer to the far RIGHT along the exit lane" if Drive.exit_open(route_station - route_distance) else "Follow the right-hand exit near the station")

func _request_stop() -> void:
	# No button can teleport a highway car into the station.
	if screen != "station" and not Drive.entered_forecourt(route_station - route_distance, player_x):
		_station_guidance()
		return
	_enter_station()

func _enter_station() -> void:
	screen = "station"
	speed = 0.0
	_clear_ui()
	_title("Little Pine Gas & Coffee", "A full tank, a friendly wave, and a fresh horizon.")
	_panel(Rect2(18,600,504,338))
	_center_label("PIT STOP", Rect2(55,610,430,38), 33)
	_center_label("Fuel is free here. Take your time.", Rect2(55,653,430,32), 19)
	_center_label("+15 coins and 20 XP for the road", Rect2(55,690,430,28), 17, Color("5c786e"))
	_button("Fill the tank & continue", Rect2(40,733,460,61), _refuel, true)
	reward_button = _button("Rewarded ad · +200 travel coins", Rect2(40,810,460,55), _request_reward)
	reward_button.disabled = service == null or not bool(service.call("can_reward"))
	_center_label("Rewarded ads are optional and may be unavailable.", Rect2(40,883,460,28), 13)
	_save()

func _refuel() -> void:
	state.note_refuel()
	drive.repair()
	fuel = state.fuel_capacity()
	route_station += 850.0
	player_x = 58.0
	target_x = 58.0
	_checkpoint_pitstop()
	if not muted and not _audio_shutting_down and not sound_chime.playing: sound_chime.play()
	_check_achievements()
	_sync_stats()
	_save()
	if service: service.call("round_finished")
	_resume()
	_toast("A full tank. A fresh horizon. +15 coins")

func _show_help() -> void:
	screen = "help"
	_clear_ui()
	_title("A kindness on the highway", "You ran out of fuel. Someone always stops to help.")
	_panel(Rect2(32,295,476,435))
	_portrait("van", Rect2(190,325,160,135))
	_center_label("Milo has a tow rope and a spare coffee.", Rect2(50,469,440,38), 18)
	_center_label("He'll take you to the nearest gas station.", Rect2(45,511,450,38), 17, Color("5c786e"))
	_center_label("No coins lost. No journey erased.", Rect2(50,552,440,31), 17)
	_button("Thanks, Milo!", Rect2(60,617,420,67), _accept_help, true)

func _accept_help() -> void:
	state.note_rescue()
	# This moves route scenery only: no distance, coins or XP awarded for teleporting.
	route_distance = route_station - 20.0
	fuel = 5.0
	_check_achievements()
	_save()
	_enter_station()

func _show_garage() -> void:
	screen = "garage"
	_clear_ui()
	_title("The little garage", "%d travel coins · Choose your favourite kind of slow." % state.data["coins"])
	var y := 140.0
	var prices := [0,150,450,900,1600]
	for i: int in range(State.CARS.size()):
		var key: String = State.CARS[i]
		_panel(Rect2(22,y,496,88))
		_portrait(str(PORTRAITS[key]), Rect2(32,y+4,85,78))
		_label(str(CAR_NAMES[key]), Rect2(126,y+8,218,32), 19)
		_label("Just a different way to ramble", Rect2(126,y+43,228,25), 12, Color("5c786e"))
		var owned: bool = state.data["owned"].has(key)
		var selected: bool = state.data["car"] == key
		var text := "Driving" if selected else ("Select" if owned else "%d coins" % prices[i])
		var button := _button(text, Rect2(362,y+18,140,51), _choose_car.bind(key))
		button.disabled = selected or (not owned and int(state.data["coins"]) < prices[i])
		y += 98.0
	for key: String in ["tank", "comfort"]:
		var level: int = int(state.data[key])
		var text := ("Fuel tank" if key == "tank" else "Cosy cabin") + "  %d / 4" % level
		_panel(Rect2(22,y,496,81))
		_label(text, Rect2(36,y+6,302,32), 19)
		_label("+25 fuel capacity" if key == "tank" else "+4 coins / 100m", Rect2(36,y+42,300,25), 14, Color("5c786e"))
		var cost: int = state.upgrade_cost(key)
		var button := _button("Maxed" if level >= 4 else "%d coins" % cost, Rect2(362,y+15,140,51), _buy_upgrade.bind(key))
		button.disabled = level >= 4 or int(state.data["coins"]) < cost
		y += 92.0
	_button("← Home", Rect2(22,841,496,61), _show_home)

func _choose_car(key: String) -> void:
	if state.buy_car(key):
		_save()
		_show_garage()

func _buy_upgrade(key: String) -> void:
	if state.buy_upgrade(key):
		_check_achievements()
		_save()
		_show_garage()

func _show_quests() -> void:
	screen = "quests"
	_clear_ui()
	state.roll_day(Time.get_date_string_from_system(true))
	_title("Today's little detours", "Three gentle reasons to take the long way. Resets daily.")
	var names := {"distance":"A little further", "passes":"Friendly waves", "refuels":"Coffee for the road"}
	var descriptions := {"distance":"Travel 800 metres", "passes":"Pass 12 travellers", "refuels":"Refuel at 2 gas stations"}
	var y := 150.0
	for key: String in State.QUESTS:
		_panel(Rect2(24,y,492,175))
		_label(str(names[key]), Rect2(44,y+14,440,33), 24)
		_label(str(descriptions[key]), Rect2(44,y+53,440,28), 17, Color("5c786e"))
		var amount: int = mini(int(state.data["daily"][key]), int(State.QUEST_TARGETS[key]))
		_label("%d / %d" % [amount, State.QUEST_TARGETS[key]], Rect2(44,y+105,175,30), 19)
		var claimed: bool = state.data["claimed"].has(key)
		var button := _button("Collected" if claimed else "Claim +100", Rect2(287,y+104,207,48), _claim_quest.bind(key))
		button.disabled = claimed or state.quest_progress(key) < 1.0
		y += 197.0
	_center_label("Every detour also grants 50 player XP.", Rect2(28,754,484,35), 18, CREAM)
	_button("← Home", Rect2(24,824,492,65), _show_home)

func _claim_quest(key: String) -> void:
	if state.claim_quest(key):
		if not muted and not _audio_shutting_down and not sound_chime.playing: sound_chime.play()
		_check_achievements()
		_save()
		_show_quests()

func _show_journal() -> void:
	screen = "journal"
	_clear_ui()
	_title("The roadside field journal", "%d / 10 vehicles spotted · Rare finds wear a gold star." % state.data["discoveries"].size())
	for i: int in range(VEHICLES.size()):
		var key: String = VEHICLES[i]
		var x := 23.0 + float(i % 2) * 254.0
		var y := 142.0 + float(i / 2) * 129.0
		_panel(Rect2(x,y,240,116))
		var found: bool = state.data["discoveries"].has(key)
		if found: _portrait(key,Rect2(x+12,y+5,90,85))
		else: _center_label("?",Rect2(x+17,y+9,80,75),42,Color("b5c4b4"))
		_label(key.replace("-"," ").capitalize() if found else "Not spotted yet",Rect2(x+103,y+22,129,50),15)
		_label("★ Rare" if RARE.has(key) else "Everyday friend",Rect2(x+15,y+85,217,24),13,ORANGE if RARE.has(key) else Color("5c786e"))
	_button("Milestones",Rect2(23,810,240,61),_show_achievements)
	_button("← Home",Rect2(277,810,240,61),_show_home)

func _show_achievements() -> void:
	screen = "achievements"
	_clear_ui()
	_title("Little milestones", "%d / 16 earned · Your offline progress always counts." % state.data["earned"].size())
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24,141)
	scroll.size = Vector2(492,655)
	ui.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",12)
	scroll.add_child(list)
	for ach: Dictionary in catalog["achievements"]:
		var row := PanelContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.custom_minimum_size = Vector2(470,76)
		var box := StyleBoxFlat.new()
		box.bg_color = CREAM
		box.set_corner_radius_all(12)
		box.content_margin_left = 15
		box.content_margin_right = 15
		row.add_theme_stylebox_override("panel",box)
		var text := Label.new()
		text.text = ("✓ " if state.data["earned"].has(ach["key"]) else "○ ") + str(ach["name"]) + "\n" + str(ach["description"])
		text.add_theme_font_size_override("font_size",16)
		row.add_child(text)
		list.add_child(row)
	_button("← Home",Rect2(24,823,492,64),_show_home)

func _show_settings() -> void:
	screen = "settings"
	_clear_ui()
	_title("Your travel bag", "Offline first. Quiet by choice.")
	_panel(Rect2(24,150,492,171))
	_label("Rambler level %d" % state.data["level"],Rect2(44,165,440,39),27)
	_label("%d / %d XP to the next level" % [state.data["xp"],int(state.data["level"])*120],Rect2(44,212,440,32),19)
	_label("Level-ups grant 50 travel coins.",Rect2(44,260,440,28),16,Color("5c786e"))
	_button("Sound: off" if muted else "Sound: on",Rect2(24,347,492,57),func():
		muted = not muted
		if muted: engine.stop()
		_show_settings())
	_button("Sign in to Play Games",Rect2(24,421,492,57),func(): _call_service("sign_in"))
	_button("Distance leaderboard",Rect2(24,495,492,57),func(): _call_service("open_leaderboards",["distance_total"]))
	_button("Play Games achievements",Rect2(24,569,492,57),func(): _call_service("open_achievements"))
	_button("Ad privacy options",Rect2(24,643,492,57),func(): _call_service("privacy_options"))
	var status := str(service.call("status")) if service else "Offline play · native services not configured"
	var line := Label.new()
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.position = Vector2(27,721)
	line.size = Vector2(486,65)
	line.add_theme_font_size_override("font_size",14)
	line.add_theme_color_override("font_color",CREAM)
	line.text = status
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(line)
	_button("← Home",Rect2(24,824,492,64),_show_home)

func _call_service(method: String, arguments: Array = []) -> void:
	if service and service.has_method(method): service.callv(method,arguments)

func _request_reward() -> void:
	if not service or not bool(service.call("can_reward")): return
	service.call("reward_requested","travel_fund",func(granted: bool):
		if granted:
			state.data["coins"] = int(state.data["coins"]) + 200
			state.grant_xp(25)
			_save()
			if screen == "station":
				_request_stop()
				_panel(Rect2(32,543,476,44), INK)
				_center_label("Travel fund received: +200 coins",Rect2(40,548,460,32),18,CREAM))

func _process(delta: float) -> void:
	var blocked := _external_gameplay_blocked()
	if _was_external_blocked and not blocked and screen == "drive": _show_pause()
	_was_external_blocked = blocked
	if blocked or _discard_next_frame:
		delta = 0.0
		_discard_next_frame = blocked
	delta = clampf(delta, 0.0, 0.08)
	elapsed += delta
	if screen == "station" and is_instance_valid(reward_button):
		reward_button.disabled = service == null or not bool(service.call("can_reward"))
	if screen == "drive" and not blocked:
		var steering := 0.0
		if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A): steering -= 1.0
		if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D): steering += 1.0
		var ahead := route_station - route_distance
		var lateral_limit := Drive.steering_limit(ahead)
		if pointer_down: _steer_to_pointer(pointer_x_position)
		if steering != 0: target_x = clampf(target_x + steering*delta*170.0, -Drive.ROAD_EDGE, lateral_limit)
		target_x = clampf(target_x, -Drive.ROAD_EDGE, lateral_limit)
		var braking := brake_held or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_DOWN)
		var desired := 5.0 if braking else 20.0
		if absf(player_x) > 99.0: desired *= 0.65
		speed = move_toward(speed,desired,delta*10.0)
		player_x = lerpf(player_x,target_x,minf(1.0,delta*7.0))
		var distance := speed * delta
		trip_distance += distance
		route_distance += distance
		state.add_distance(distance)
		fuel = maxf(0.0,fuel - distance/31.0)
		scenery_scroll += speed*11.0*delta
		if route_distance > route_station + 24.0:
			route_station += 850.0
			target_x = minf(target_x, Drive.ROAD_EDGE)
			_toast("Exit passed — next station in 850m")
		drive.tick(delta)
		spawn_timer -= delta
		bumper_cooldown -= delta
		if spawn_timer <= 0:
			_spawn_traffic()
			spawn_timer = randf_range(1.5,3.0)
		if not patrol.is_empty():
			if route_distance > float(patrol["distance"]) + 110.0: _schedule_patrol()
			elif absf(route_distance - float(patrol["distance"])) < 180.0 and not bool(patrol.get("spotted", false)):
				patrol["spotted"] = true
				state.note_discovery("police", true)
				_toast("Roadside patrol — wait behind traffic; do not overtake")
		for car: Dictionary in traffic:
			car["y"] = float(car["y"]) + Drive.traffic_motion(speed, car)*delta
			if float(car["y"]) > 680.0 and not bool(car["passed"]):
				car["passed"] = true
				if not patrol.is_empty() and Drive.patrol_observes_pass(route_distance, float(patrol["distance"]), car):
					_capture_by_patrol()
					break
				var found: bool = state.note_pass(str(car["kind"]), bool(car["rare"]))
				if found:
					_toast(("Rare find! " if bool(car["rare"]) else "Journal entry: ") + str(car["kind"]).capitalize())
					if not muted and not _audio_shutting_down and not sound_chime.playing: sound_chime.play()
		traffic = traffic.filter(func(car: Dictionary): return float(car["y"]) < 1000.0 and float(car["y"]) > -1600.0)
		if screen == "drive" and Drive.entered_forecourt(route_station - route_distance, player_x): _enter_station()
		if screen == "drive" and fuel <= 0:
			engine.stop()
			_show_help()
		if screen == "drive" and hud_distance:
			hud_distance.text = _km(trip_distance)
			hud_speed.text = "%d km/h" % int(speed*3.6)
			hud_fuel.value = fuel
			hud_biome.text = BIOMES[int(float(state.data["distance"])/2500.0)%4].to_upper()
			hud_station.text = "EXIT RIGHT →" if Drive.exit_open(route_station-route_distance) else "STATION %dm" % int(route_station-route_distance)
		if engine.playing: engine.pitch_scale = 0.75 + speed/35.0
		save_timer += delta
		if save_timer >= 4.0:
			state.roll_day(Time.get_date_string_from_system(true))
			save_timer = 0.0
			_check_achievements()
			_save()
	else:
		scenery_scroll += delta*12.0
	if toast_label:
		toast_left -= delta
		toast_label.modulate.a = clampf(toast_left,0,1)
	world3d.sync(route_distance, route_station, player_x, traffic, str(state.data["car"]), int(float(state.data["distance"])/2500.0)%4, screen, delta, float(state.data["distance"]), patrol)
	queue_redraw()
	if capture_screen != "":
		capture_frames += 1
		if capture_frames == 24: _capture.call_deferred()

func _spawn_traffic(fraction: float = -1.0, forced_lane: int = 0) -> void:
	var rare := randf() < 0.10
	var kind: String = MOVING_RARE.pick_random() if rare else VEHICLES[randi_range(0,5)]
	var lane := forced_lane if forced_lane != 0 else (1 if randf() > 0.35 else -1)
	traffic_serial += 1
	traffic.append({"id":traffic_serial, "x":float(lane)*58.0,"y":fraction*650.0 if fraction >= 0 else -70.0,
		"kind":kind,"rare":rare,"passed":false,"speed_mps":randf_range(12.0,25.0) if lane < 0 else randf_range(7.0,16.0)})

func _checkpoint_pitstop() -> void:
	last_pitstop = {"route":route_distance, "trip":trip_distance, "next_station":route_station,
		"fuel":fuel, "hearts":drive.hearts}

func _schedule_patrol() -> void:
	patrol_serial += 1
	patrol = {"id":patrol_serial, "distance":route_distance + randf_range(2600.0,4300.0), "spotted":false}

func _capture_by_patrol() -> void:
	# A patrol resets this ramble to its completed stop, never the banked profile.
	route_distance = float(last_pitstop.get("route",0.0))
	trip_distance = float(last_pitstop.get("trip",0.0))
	route_station = float(last_pitstop.get("next_station",850.0))
	fuel = float(last_pitstop.get("fuel",state.fuel_capacity()))
	drive.hearts = int(last_pitstop.get("hearts",3))
	drive.grace = 1.8
	traffic.clear()
	spawn_timer = 1.2
	player_x = 58.0
	target_x = 58.0
	speed = 0.0
	_schedule_patrol()
	screen = "patrol"
	_clear_ui()
	_title("Back to the last pit stop", "A roadside patrol caught that overtake.")
	_panel(Rect2(32,350,476,336))
	_center_label("Wait behind traffic near a patrol.", Rect2(48,372,444,48), 22)
	_center_label("This ramble returns to its last fuel stop.\nYour banked coins and journal stay safe.", Rect2(48,438,444,80), 18)
	_button("Back on the road", Rect2(58,560,424,72), _resume, true)
	_save()

func _steer_to_pointer(pointer_x: float) -> void:
	pointer_x_position = pointer_x
	var limit := Drive.steering_limit(route_station-route_distance)
	if limit > Drive.ROAD_EDGE and pointer_x > 350.0:
		target_x = lerpf(Drive.ROAD_EDGE, limit, clampf((pointer_x-350.0)/170.0,0.0,1.0))
	else:
		target_x = clampf((pointer_x-W/2.0)*0.62,-Drive.ROAD_EDGE,Drive.ROAD_EDGE)

func _back() -> void:
	if _external_gameplay_blocked(): return
	if screen == "drive": _show_pause()
	elif screen in ["pause", "patrol"]: _resume()
	else: _show_home()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_back()
		return
	if screen != "drive": return
	if event is InputEventScreenTouch:
		pointer_down = event.pressed
		if pointer_down and event.position.y > 140.0 and event.position.y < 836.0:
			_steer_to_pointer(event.position.x)
	if event is InputEventScreenDrag and event.position.y > 140 and event.position.y < 836:
		_steer_to_pointer(event.position.x)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_down = event.pressed
		if pointer_down and event.position.y > 140.0 and event.position.y < 836.0:
			_steer_to_pointer(event.position.x)
	if event is InputEventMouseMotion and pointer_down:
		_steer_to_pointer(event.position.x)

func _draw() -> void:
	if screen != "drive": draw_rect(Rect2(0,0,W,H),Color(0.025,0.09,0.10,0.23))
	elif drive.grace > 1.15: draw_rect(Rect2(0,0,W,H),Color(0.9,0.2,0.12,(drive.grace - 1.15) * 0.14))

func _update_hearts() -> void:
	for i in range(heart_icons.size()):
		heart_icons[i].texture = load("res://assets/ui/heart-full.svg" if i < drive.hearts else "res://assets/ui/heart-empty.svg")

func _external_gameplay_blocked() -> bool:
	return application_suspended or (is_instance_valid(service) and service.has_method("is_gameplay_blocked") and bool(service.call("is_gameplay_blocked")))

func _physics_process(_delta: float) -> void:
	if screen != "drive" or _external_gameplay_blocked() or drive.grace > 0.0: return
	for id in world3d.contacts():
		if not drive.collide(id): continue
		for car_data in traffic:
			if int(car_data.id) == id:
				car_data.passed = true # A collision is never a clean passing reward.
		speed *= 0.28
		state.note_collision()
		world3d.collision_flash = 0.65
		_update_hearts()
		_toast("A bump! %d hearts. Give traffic a little room." % drive.hearts)
		_save()
		if drive.hearts <= 0: _show_repair()
		break

func _show_repair() -> void:
	screen = "repair"
	_clear_ui()
	_title("Time for a little repair", "Three bumps. Your saved progress stays safe.")
	_panel(Rect2(32,350,476,340))
	_center_label("Milo can get you to the forecourt.",Rect2(48,382,444,60),21)
	_center_label("No coins or progress lost. Repair is free.",Rect2(48,450,444,55),17)
	_button("Free roadside help",Rect2(55,533,430,65),_accept_help,true)
	_button("Finish this ramble",Rect2(55,611,430,55),_end_drive)

func _toast(text: String) -> void:
	if toast_label:
		toast_label.text = text
		toast_left = 3.5

func _km(metres: float) -> String:
	return "%.2f km" % (metres/1000.0)

func _check_achievements() -> void:
	for ach: Dictionary in catalog.get("achievements",[]):
		var key := str(ach["key"])
		if state.stat(str(ach["metric"])) >= float(ach["threshold"]) and not state.data["earned"].has(key):
			state.data["earned"].append(key)
			if service: service.call("unlock",key)
			_toast("Milestone: " + str(ach["name"]))

func _sync_stats() -> void:
	if not service: return
	for key: String in state.data["earned"]: service.call("unlock",key)
	for board: Dictionary in catalog.get("leaderboards",[]):
		service.call("submit",str(board["key"]),int(state.stat(str(board["metric"]))))

func _save() -> void:
	if smoke or capture_screen != "": return
	var file := FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state.data))
		file.close()
		DirAccess.rename_absolute(SAVE_PATH+".tmp",SAVE_PATH)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()
		return
	if what == NOTIFICATION_APPLICATION_PAUSED: application_suspended = true
	if what == NOTIFICATION_APPLICATION_RESUMED:
		application_suspended = false
		_discard_next_frame = true
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save()
		if what == NOTIFICATION_WM_CLOSE_REQUEST: _quit_cleanly()
		if what == NOTIFICATION_APPLICATION_PAUSED and screen == "drive": _show_pause()

func _capture() -> void:
	if capture_path != "":
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png(capture_path)
		print("CAPTURE_RESULT=",error," PATH=",capture_path)
	await shutdown_audio()
	get_tree().quit()

func _run_smoke() -> void:
	var retained: Dictionary = state.data.duplicate(true)
	_start_drive()
	for i: int in range(200):
		_process(0.1)
		# Exercise real server frames; do not enqueue an entire journey of SFX in one frame.
		if i % 8 == 7: await get_tree().create_timer(0.02,true,false,true).timeout
	assert(trip_distance > 100.0)
	assert(fuel < state.fuel_capacity())
	var touch := InputEventScreenTouch.new()
	touch.position = Vector2(400,810)
	touch.pressed = true
	_unhandled_input(touch)
	assert(target_x > 0.0)
	var drag := InputEventScreenDrag.new()
	drag.position = Vector2(100,810)
	_unhandled_input(drag)
	assert(target_x < 0.0)
	var before_brake := speed
	brake_held = true
	_process(0.1)
	assert(speed < before_brake)
	brake_held = false
	route_distance = route_station-5.0
	player_x = 350.0
	_request_stop()
	assert(screen == "station")
	_refuel()
	assert(screen == "drive")
	assert(fuel == state.fuel_capacity())
	fuel = 0.0
	_process(0.1)
	assert(screen == "help")
	var before_rescue_distance: float = float(state.data["distance"])
	_accept_help()
	assert(screen == "station")
	assert(float(state.data["distance"]) == before_rescue_distance)
	_show_garage()
	_show_quests()
	_show_journal()
	_show_achievements()
	_show_settings()
	_show_home()
	state.data = retained
	await shutdown_audio()
	print("OPEN_ROAD_SMOKE_PASS gameplay, touch/drag/brake, fuel, refuel, rescue, six screens")
	get_tree().quit()

func _stop_audio() -> void:
	_audio_shutting_down = true
	for player in [engine,sound_click,sound_chime]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null

func shutdown_audio() -> void:
	if _audio_drained: return
	_audio_shutting_down = true
	# A same-frame sound/quit can precede its first mixer tick. Let queued
	# playback register before submitting its stop, with new sounds blocked.
	await get_tree().create_timer(clampf(AudioServer.get_time_to_next_mix() * 2.0 + 0.03, 0.12, 0.24), true, false, true).timeout
	_stop_audio()
	# AudioServer removes stopped playback voices on a later mixer tick.
	# Drain in real time while the scene is alive; suppress any new playback.
	await get_tree().create_timer(clampf(AudioServer.get_time_to_next_mix() * 3.0, 0.25, 0.4), true, false, true).timeout
	await get_tree().process_frame
	_audio_drained = true

func _quit_cleanly() -> void:
	if _quit_pending: return
	_quit_pending = true
	await shutdown_audio()
	get_tree().quit()

func _exit_tree() -> void:
	_stop_audio()
