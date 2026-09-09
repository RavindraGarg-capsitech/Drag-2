@tool
class_name Box
extends LevelObject

## Movable physics box / crate in "Drag to Goal".

@export_group("Box Dimensions")
@export var box_size: Vector2 = Vector2(80, 80):
	set(val):
		box_size = Vector2(maxf(20.0, val.x), maxf(20.0, val.y))
		_update_box_dimensions()

@export_group("Physics Properties")
@export var box_mass: float = 2.0:
	set(val):
		box_mass = maxf(0.1, val)
		_update_physics_settings()

@export var box_gravity_scale: float = 1.0:
	set(val):
		box_gravity_scale = val
		_update_physics_settings()

@export var box_bounce: float = 0.2:
	set(val):
		box_bounce = clampf(val, 0.0, 1.0)
		_update_physics_settings()

@export var box_friction: float = 0.6:
	set(val):
		box_friction = clampf(val, 0.0, 1.0)
		_update_physics_settings()

func _init() -> void:
	object_id = "box"
	display_name = "Physics Box"

func _ready() -> void:
	super._ready()
	_update_box_dimensions()
	_update_physics_settings()

func _update_box_dimensions() -> void:
	var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape != null and col_shape.shape is RectangleShape2D:
		var rect := col_shape.shape as RectangleShape2D
		rect.size = box_size
		
	var visual: NinePatchRect = get_node_or_null("Visual/NinePatchRect") as NinePatchRect
	if visual != null:
		visual.size = box_size
		visual.position = -box_size / 2.0

func _update_physics_settings() -> void:
	set("mass", box_mass)
	set("gravity_scale", box_gravity_scale)
	var mat: PhysicsMaterial = get("physics_material_override")
	if mat != null and not mat.resource_path.is_empty():
		mat = mat.duplicate()
		set("physics_material_override", mat)
	elif mat == null:
		mat = PhysicsMaterial.new()
		set("physics_material_override", mat)
	mat.bounce = box_bounce
	mat.friction = box_friction


func reset_to_initial_state() -> void:
	super.reset_to_initial_state()
	set("linear_velocity", Vector2.ZERO)
	set("angular_velocity", 0.0)
	set("freeze", false)

func get_selection_bounds() -> Rect2:
	return Rect2(-box_size / 2.0, box_size)
