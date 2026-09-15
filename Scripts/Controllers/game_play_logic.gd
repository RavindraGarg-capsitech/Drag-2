extends UIController

## Main Gameplay Controller.
## Coordinates the active level and gameplay result.

@onready var level_root: LevelRoot = $LevelRoot

var initial_level_data: Resource = null
var _level_completed: bool = false
var _hint_used: bool = false


func _ready() -> void:
	super._ready()

	GameBus.home_requested.connect(_on_home_requested)
	GameBus.level_restarted.connect(_on_level_restarted)
	GameBus.level_completed.connect(_on_level_completed)
	GameBus.level_requested.connect(_on_level_requested)
	GameBus.hint_requested.connect(_on_hint_requested)

	if initial_level_data != null and initial_level_data is LevelData:
		_load_level(initial_level_data)


# ============================================================
# LEVEL LOADING
# ============================================================

func _load_level(level_data: Resource) -> void:
	if not level_data is LevelData:
		push_error("[GamePlay] Invalid LevelData.")
		return

	initial_level_data = level_data
	_level_completed = false

	print(
		"[GamePlay] Loading level: ",
		level_data.level_name,
		" | ID: ",
		level_data.level_id
	)

	LevelLoader.load_level(level_data, level_root)

	for obj in level_root.get_level_objects():
		obj.set_editor_mode(false)

		if obj is Basket:
			_connect_basket(obj)

	_apply_initial_hint_state()


# ============================================================
# HINT SYSTEM
# ============================================================

func _apply_initial_hint_state() -> void:
	_hint_used = false
	for obj in level_root.get_level_objects():
		if _is_hint_object(obj):
			obj.visible = false


func _on_hint_requested() -> void:
	if _hint_used:
		return

	_hint_used = true

	for obj in level_root.get_level_objects():
		if _is_hint_object(obj):
			obj.visible = true


func _is_hint_object(obj: LevelObject) -> bool:
	if obj == null:
		return false
	var info: Dictionary = ObjectRegistry.get_object_info(obj.object_id)
	return info.get("category", "") == "Hint"


# ============================================================
# BASKET
# ============================================================

func _connect_basket(basket: Basket) -> void:
	if basket.goal_reached.is_connected(_on_basket_goal_reached):
		return

	basket.goal_reached.connect(_on_basket_goal_reached)

	print("[GamePlay] Basket connected.")


func _on_basket_goal_reached(_ball: Node2D) -> void:
	if _level_completed:
		return

	_level_completed = true

	if not initial_level_data is LevelData:
		push_error("[GamePlay] No valid active LevelData.")
		return

	var level_data := initial_level_data as LevelData

	var level_index: int = level_data.level_id.to_int()

	# Temporary value.
	# Replace this later with your actual star calculation.
	var stars: int = _calculate_stars()

	print(
		"[GamePlay] Level completed | Level: ",
		level_index,
		" | Stars: ",
		stars
	)

	GameBus.level_completed.emit(level_index, stars)


# ============================================================
# STAR CALCULATION
# ============================================================

func _calculate_stars() -> int:
	# Future star system goes here.
	return 3


# ============================================================
# WIN PANEL
# ============================================================

func _on_level_completed(level_index: int, stars: int) -> void:
	print(
		"[GamePlay] Opening WinPanel | Level: ",
		level_index,
		" | Stars: ",
		stars
	)

	var win_panel: Control = GameService.ui.push_packed(
		GameConfig.WIN_PANEL_SCENE
	)

	if win_panel == null:
		push_error("[GamePlay] Failed to spawn WinPanel.")
		return

	# Pass result data to the dynamically created panel.
	if win_panel.has_method("setup"):
		win_panel.call("setup", level_index, stars)
	else:
		push_error("[GamePlay] WinPanel does not contain setup().")


# ============================================================
# RESTART
# ============================================================

func _on_level_restarted(_level_index: int) -> void:
	print("[GamePlay] Restarting level.")

	if initial_level_data != null and initial_level_data is LevelData:
		_load_level(initial_level_data)


# ============================================================
# HOME
# ============================================================

func _on_home_requested() -> void:
	GameService.scenes.go_to(GameConfig.MENU_CANVAS_SCENE)
	queue_free()
	
	
func _on_level_requested(level_index: int) -> void:
	print("[GamePlay] Level requested: ", level_index)

	var level_path: String = GameConfig.LEVEL_FILE_FORMAT % (
		str(level_index).pad_zeros(3)
	)

	# No next level → return to Home
	if not ResourceLoader.exists(level_path):
		print(
			"[GamePlay] Next level does not exist: ",
			level_path,
			" | Returning to Home."
		)

		GameBus.home_requested.emit()
		return

	var next_level: LevelData = ResourceLoader.load(
		level_path
	) as LevelData

	# Failed to load next level → return to Home
	if next_level == null:
		push_error(
			"[GamePlay] Failed to load LevelData: " + level_path
		)

		GameBus.home_requested.emit()
		return

	# Load succeeded, so update last played level
	GameService.save.set_value(
		GameConfig.SAVE_KEY_LAST_LEVEL,
		level_index
	)
	GameService.save.save()

	_load_level(next_level)
