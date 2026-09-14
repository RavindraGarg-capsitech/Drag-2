
extends Node

## BackendService
##
## PDF §2:
## Owns third-party/backend integrations:
## - Firebase
## - Ads
## - GameAnalytics
## - Meta
##
## BackendService must remain separate from GameService.
## Communication with game systems happens through GameBus.


func _ready() -> void:
	_init_firebase()
	_init_ads()
	_init_game_analytics()
	_init_meta()

	_connect_game_bus()


# ============================================================
# THIRD-PARTY INITIALIZATION
# ============================================================

func _init_firebase() -> void:
	# TODO:
	# Firebase SDK initialization.
	pass


func _init_ads() -> void:
	# TODO:
	# Advertisement SDK initialization.
	pass


func _init_game_analytics() -> void:
	# TODO:
	# GameAnalytics initialization.
	pass


func _init_meta() -> void:
	# TODO:
	# Meta SDK initialization.
	pass


# ============================================================
# GAME BUS
# ============================================================

func _connect_game_bus() -> void:
	if not GameBus.level_completed.is_connected(
		_on_level_completed
	):
		GameBus.level_completed.connect(
			_on_level_completed
		)

	if not GameBus.level_failed.is_connected(
		_on_level_failed
	):
		GameBus.level_failed.connect(
			_on_level_failed
		)

	if not GameBus.gameplay_started.is_connected(
		_on_gameplay_started
	):
		GameBus.gameplay_started.connect(
			_on_gameplay_started
		)


# ============================================================
# EVENTS
# ============================================================

func _on_level_completed(
	level_index: int,
	stars: int
) -> void:
	# TODO:
	# Send analytics event.
	# Evaluate ad display policy.
	print(
		"[BackendService] level_completed: ",
		level_index,
		" stars=",
		stars
	)


func _on_level_failed(level_index: int) -> void:
	# TODO:
	# Send analytics event.
	print(
		"[BackendService] level_failed: ",
		level_index
	)


func _on_gameplay_started(_level_data: Resource) -> void:
	# TODO:
	# Send gameplay_started analytics event.
	print("[BackendService] gameplay_started")
