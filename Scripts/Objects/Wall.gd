@tool
class_name Wall
extends LevelObject

## Static wall obstacle in "Drag to Goal".

@export_group("Wall Dimensions")
@export var size: Vector2 = Vector2(200, 40):
	set(val):
		size = Vector2(maxf(20.0, val.x), maxf(20.0, val.y))
		_update_dimensions()

@export_group("Physics Properties")
@export var bounce: float = 0.4:
	set(val):
		bounce = clampf(val, 0.0, 1.0)
		_update_physics_material()

@export var friction: float = 0.5:
	set(val):
		friction = clampf(val, 0.0, 1.0)
		_update_physics_material()

func _init() -> void:
	object_id = "wall"
	display_name = "Static Wall"

func _ready() -> void:
	super._ready()
	_update_dimensions()
	_update_physics_material()

func _update_dimensions() -> void:
	var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape != null and col_shape.shape is RectangleShape2D:
		var rect := col_shape.shape as RectangleShape2D
		rect.size = size
		
	var sprite: NinePatchRect = get_node_or_null("Visual/NinePatchRect") as NinePatchRect
	if sprite != null:
		sprite.size = size
		sprite.position = -size / 2.0

func _update_physics_material() -> void:
	var mat: PhysicsMaterial = get("physics_material_override")
	if mat != null and not mat.resource_path.is_empty():
		mat = mat.duplicate()
		set("physics_material_override", mat)
	elif mat == null:
		mat = PhysicsMaterial.new()
		set("physics_material_override", mat)
	mat.bounce = bounce
	mat.friction = friction


func get_selection_bounds() -> Rect2:
	return Rect2(-size / 2.0, size)
