class_name Basket
extends LevelObject

## Basket object representing the goal / destination in "Drag to Goal".

signal goal_reached(ball: Node2D)

@export_group("Goal Settings")
@export var require_downward_motion: bool = false
@export var score_points: int = 100

var _is_goal_triggered: bool = false

func _init() -> void:
	object_id = "basket"
	display_name = "Basket Goal"

func _ready() -> void:
	super._ready()
	_setup_detection()

func _setup_detection() -> void:
	if has_signal("body_entered") and not is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _is_goal_triggered:
		return
		
	if body is Ball or body.is_in_group("Ball"):
		if require_downward_motion:
			var vel: Vector2 = body.get("linear_velocity") if body.get("linear_velocity") != null else Vector2.ZERO
			if vel.y <= 0:
				return
		
		_is_goal_triggered = true
		goal_reached.emit(body)

#func reset_to_initial_state() -> void:
	#super.reset_to_initial_state()
	#_is_goal_triggered = false

func reset_to_initial_state() -> void:
	super.reset_to_initial_state()
	_is_goal_triggered = false
