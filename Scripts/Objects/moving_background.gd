extends Parallax2D

@export var speed: float = 80.0
@export var direction_duration: float = 3.0

var directions: Array[Vector2] = [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(-1, -1).normalized(),
	Vector2(1, -1).normalized(),
	Vector2(1, 1).normalized(),
	Vector2(-1, 1).normalized()
]

var current_direction: int = 0
var direction_timer: float = 0.0


func _ready() -> void:
	_set_direction()


func _process(delta: float) -> void:
	direction_timer += delta

	if direction_timer >= direction_duration:
		direction_timer = 0.0
		current_direction += 1

		if current_direction >= directions.size():
			current_direction = 0

		_set_direction()


func _set_direction() -> void:
	autoscroll = directions[current_direction] * speed
