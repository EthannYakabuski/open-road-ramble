extends SceneTree
## Synthetic notification/layout regression in an isolated user-data process.
## Direct callback fixtures below are not native SDK or player-save evidence.

class RewardFixture extends Node:
	var visible := false
	var callback := Callable()
	func set_menu_visible(value: bool) -> void: visible = value
	func menu_bottom_reserve(_reference: CanvasItem = null) -> float: return 161.0 if visible else 0.0
	func can_reward() -> bool: return true
	func reward_requested(_context: String, accepted: Callable) -> void: callback = accepted
	func is_gameplay_blocked() -> bool: return false

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func visible_control(game: Node, text: String) -> Control:
	for child in game.ui.get_children():
		if child is Control and child.visible and not child.is_queued_for_deletion() and "text" in child and child.text == text:
			return child
	return null

func resume_during_audio_shutdown(game: Node) -> void:
	check(game._audio_shutting_down, "The deferred navigation probe runs during the real shutdown drain")
	game._resume()
	check(not game.engine.has_stream_playback(), "UI rebuild cannot start an engine voice after audio shutdown begins")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.muted = true
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	check(not quit_on_go_back, "Android Back must not trigger the SceneTree's automatic quit")
	var rounds_before: int = game.service.get("_round_count")
	game._start_drive()
	for index in range(12): game._process(0.05)
	var before: Dictionary = game.state.data.duplicate(true)
	var before_trip: float = game.trip_distance
	var before_fuel: float = game.fuel
	game.brake_held = true
	game.pointer_down = true
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.screen == "pause", "Android Back from live driving opens the safe pause")
	check(not game.brake_held and not game.pointer_down, "Back retires held touch/brake input with the driving controls")
	game._process(10.0)
	check(game.trip_distance == before_trip and game.fuel == before_fuel, "Paused Back cannot consume trip distance or fuel")
	check(game.state.data == before, "Pausing cannot lose or duplicate banked progression")
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.screen == "drive", "Back from pause follows the existing Resume navigation")
	game._process(10.0)
	check(game.trip_distance == before_trip, "Resume discards the covered frame delta")
	game._process(0.05)
	check(game.trip_distance > before_trip, "Ordinary driving advances after the discarded return frame")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	game._unhandled_input(escape)
	check(game.screen == "pause", "Desktop Escape shares the live-driving Back route")
	escape.pressed = false
	game._unhandled_input(escape)
	check(game.screen == "pause", "Key release cannot resume or navigate")
	escape.pressed = true
	game._unhandled_input(escape)
	check(game.screen == "drive", "Desktop Escape also follows the existing Resume route")
	game._show_pause()
	game.application_suspended = true
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.screen == "pause", "Back cannot resume underneath external application coverage")
	game.application_suspended = false
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.screen == "drive", "Back resumes normally after application coverage ends")
	before = game.state.data.duplicate(true)
	for menu in ["garage", "quests", "journal", "achievements", "settings"]:
		game.call("_show_" + menu)
		game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		check(game.screen == "home", "Android Back returns %s to Home" % menu)
		check(game.state.data == before, "Returning from %s cannot bank another trip" % menu)
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.screen == "home" and not game._quit_pending, "Home Back retains the existing stay-at-Home behavior")
	check(game.service.get("_round_count") == rounds_before, "Back navigation is not a completed round or ad opportunity")
	check(bool(game.service.get("_menu_visible")), "Ordinary Home retains its menu banner")

	game._start_drive()
	game.route_distance = game.route_station - 5.0
	game.player_x = 350.0
	game._request_stop()
	await process_frame
	check(not bool(game.service.get("_menu_visible")), "A parked station hides the banner covering sponsor controls")
	var fill := visible_control(game, "Fill the tank & continue")
	var sponsor: Button = game.reward_button
	var note := visible_control(game, "Rewarded ads are optional and may be unavailable.")
	check(fill != null and sponsor != null and note != null, "Free refuel, optional sponsor and explanation remain present")
	for reserve in [161.0, 289.0]:
		# Late Android geometry notifications cannot shrink an active pit stop.
		game._apply_banner_layout(reserve)
		var usable := Rect2(Vector2.ZERO, game.menu_scroll.size)
		check(game.menu_scroll.size.y == 960.0, "Station ignores hidden-banner reserve %s" % reserve)
		check(usable.encloses(fill.get_rect()) and usable.encloses(sponsor.get_rect()) and usable.encloses(note.get_rect()), "Station actions fit above the viewport bottom")
	before = game.state.data.duplicate(true)
	var real_service: Node = game.service
	var fixture := RewardFixture.new()
	root.add_child(fixture)
	game.service = fixture
	game._request_reward()
	check(fixture.callback.is_valid(), "Synthetic sponsor callback is connected through the actual game request")
	fixture.callback.call(true)
	await process_frame
	check(game.state.data.coins == before.coins + 200 and game.state.data.xp == before.xp + 25, "The existing sponsor benefit remains 200 coins and 25 XP")
	check(not fixture.visible and game.screen == "station", "Earned callback rebuild retains the parked no-banner station")
	var notice := visible_control(game, "Travel fund received: +200 coins")
	fill = visible_control(game, "Fill the tank & continue")
	sponsor = game.reward_button
	check(notice != null and notice.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Grant feedback is readable noninteractive text")
	check(not notice.get_rect().intersects(fill.get_rect()) and not notice.get_rect().intersects(sponsor.get_rect()), "Grant feedback cannot cover either station action")
	game.service = real_service
	fixture.queue_free()
	game._show_garage()
	check(bool(real_service.get("_menu_visible")), "Garage restores its normal menu banner after leaving the station")
	game.muted = false
	game._show_pause()
	call_deferred("resume_during_audio_shutdown", game)
	await game.shutdown_audio()
	game.queue_free()
	await process_frame
	await process_frame
	print("ROAD_ANDROID_BACK_STATION checks=%d failures=%d (synthetic notification/layout/callback fixture)" % [checks, failures])
	quit(1 if failures else 0)
