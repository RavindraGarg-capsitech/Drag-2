@tool
class_name SpringRope
extends LevelObject

## Spring Rope / Trampoline object in "Drag to Goal".
## Interacts with the ball by applying elastic spring impulse and can lock its position upon contact.

signal spring_contact(body: Node2D)
signal spring_locked_changed(locked: bool)

@export_group("Spring Properties")
@export var rope_length: float = 200.0:
	set(val):
		rope_length = maxf(40.0, val)
		_update_geometry()

@export var bounce_strength: float = 1.3:
	set(val):
		bounce_strength = maxf(0.1, val)
		_update_physics_material()

@export var spring_stiffness: float = 500.0
@export var spring_damping: float = 10.0

## If true, once the ball makes contact, the rope locks into place.
@export var lock_on_contact: bool = true

func _init() -> void:
	object_id = "spring_rope"
	display_name = "Spring Rope"

func _ready() -> void:
	super._ready()
	_update_geometry()
	_update_physics_material()
	_setup_contact_trigger()

func _update_geometry() -> void:
	var half_len: float = rope_length / 2.0
	
	# Update collision shape
	var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape != null:
		if col_shape.shape is SegmentShape2D:
			var seg := col_shape.shape as SegmentShape2D
			seg.a = Vector2(-half_len, 0)
			seg.b = Vector2(half_len, 0)
		elif col_shape.shape is RectangleShape2D:
			var rect := col_shape.shape as RectangleShape2D
			rect.size = Vector2(rope_length, 20)
			
	# Update visual Line2D or Pegs if present
	var line: Line2D = get_node_or_null("Visual/RopeLine") as Line2D
	if line != null:
		line.clear_points()
		line.add_point(Vector2(-half_len, 0))
		line.add_point(Vector2(half_len, 0))
		
	var left_peg: Node2D = get_node_or_null("Visual/LeftPeg") as Node2D
	if left_peg != null:
		left_peg.position = Vector2(-half_len, 0)
		
	var right_peg: Node2D = get_node_or_null("Visual/RightPeg") as Node2D
	if right_peg != null:
		right_peg.position = Vector2(half_len, 0)

func _update_physics_material() -> void:
	var mat: PhysicsMaterial = get("physics_material_override")
	if mat != null and not mat.resource_path.is_empty():
		mat = mat.duplicate()
		set("physics_material_override", mat)
	elif mat == null:
		mat = PhysicsMaterial.new()
		set("physics_material_override", mat)
	mat.bounce = bounce_strength
	mat.friction = 0.2
	print("[SpringRope] Bounciness Applied: ", bounce_strength)
	print("[SpringRope] PhysicsMaterial Bounce: ", mat.bounce)

func _setup_contact_trigger() -> void:
	var trigger: Area2D = get_node_or_null("ContactTrigger") as Area2D
	if trigger != null and not trigger.body_entered.is_connected(_on_contact_trigger_body_entered):
		trigger.body_entered.connect(_on_contact_trigger_body_entered)

func _on_contact_trigger_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
		
	if body is Ball or body.is_in_group("Ball"):
		spring_contact.emit(body)
		if lock_on_contact and not is_locked:
			is_locked = true
			spring_locked_changed.emit(true)


func get_selection_bounds() -> Rect2:
	return Rect2(Vector2(-rope_length / 2.0 - 15, -20), Vector2(rope_length + 30, 40))
