class_name Ball
extends LevelObject

## Ball object representing the player's basketball in "Drag to Goal".

signal ball_reset
signal ball_launched(initial_velocity: Vector2)

@export_group("Ball Physics")
@export var ball_mass: float = 1.0:
	set(val):
		ball_mass = val
		_apply_physics_settings()

@export var gravity_scale_override: float = 1.0:
	set(val):
		gravity_scale_override = val
		_apply_physics_settings()

@export var linear_damp_override: float = 0.0:
	set(val):
		linear_damp_override = val
		_apply_physics_settings()

@export var angular_damp_override: float = 0.0:
	set(val):
		angular_damp_override = val
		_apply_physics_settings()

@export var bounce: float = 0.0:
	set(val):
		bounce = val
		_apply_physics_settings()

@export var friction: float = 0.3:
	set(val):
		friction = val
		_apply_physics_settings()

func _init() -> void:
	object_id = "ball"
	display_name = "Basketball"

func _ready() -> void:
	super._ready()
	_apply_physics_settings()

func _apply_physics_settings() -> void:
	set("mass", ball_mass)
	set("gravity_scale", gravity_scale_override)
	set("linear_damp", linear_damp_override)
	set("angular_damp", angular_damp_override)
	
	var mat: PhysicsMaterial = get("physics_material_override")
	if mat != null and not mat.resource_path.is_empty():
		mat = mat.duplicate()
		set("physics_material_override", mat)
	elif mat == null:
		mat = PhysicsMaterial.new()
		set("physics_material_override", mat)
	mat.bounce = bounce
	mat.friction = friction

var _last_velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not get("freeze"):
		_last_velocity = get("linear_velocity") as Vector2

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		for i in range(state.get_contact_count()):
			var normal = state.get_contact_local_normal(i)
			var approach_speed = _last_velocity.dot(normal)
			
			# If the ball was approaching this surface
			if approach_speed < -5.0:
				var collider_bounce: float = 0.0
				var collider = state.get_contact_collider_object(i)
				
				if collider != null:
					var c_mat = collider.get("physics_material_override")
					if c_mat is PhysicsMaterial:
						collider_bounce = c_mat.bounce
						
				var max_requested_bounce = maxf(bounce, collider_bounce)
				
				# Godot clamps physics restitution natively to 1.0.
				# To support custom extreme bounce values (e.g., 15 or 50),
				# we manually inject the remaining velocity multiplier.
				if max_requested_bounce > 1.0:
					var extra_speed = -approach_speed * (max_requested_bounce - 1.0)
					state.linear_velocity += normal * extra_speed
					
				# Ensure we only process the strongest primary impact per frame
				break
func reset_to_initial_state() -> void:
	super.reset_to_initial_state()
	set("linear_velocity", Vector2.ZERO)
	set("angular_velocity", 0.0)
	set("freeze", false)
	ball_reset.emit()

func launch(velocity: Vector2) -> void:
	set("freeze", false)
	set("linear_velocity", velocity)
	ball_launched.emit(velocity)
