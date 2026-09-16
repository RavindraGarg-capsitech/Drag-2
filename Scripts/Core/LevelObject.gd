class_name LevelObject
extends Node2D

## Base class and contract for any placeable, inspectable object in the Level Editor.

signal state_changed

@export var object_id: String = ""
@export var display_name: String = ""
@export var is_selectable: bool = true
@export var is_locked: bool = false

var design_position: Vector2 = Vector2.ZERO   # original/base position from the Resource, used to recompute the responsive runtime position

var _initial_transform: Transform2D
var _initial_properties: Dictionary = {}
var _is_editor_mode: bool = false

func _ready() -> void:
	_capture_initial_state()

## Sets editor mode (e.g. freeze physics bodies during level editing).
func set_editor_mode(enabled: bool) -> void:
	_is_editor_mode = enabled
	if get("freeze") != null:
		set("freeze", enabled)
	for child in get_children():
		if child.get("freeze") != null:
			child.set("freeze", enabled)

func is_editor_mode() -> bool:
	return _is_editor_mode

## Captures transform and custom properties for state resetting.
func _capture_initial_state() -> void:
	_initial_transform = transform
	_initial_properties = get_custom_properties().duplicate(true)

## Resets object back to initial state.
func reset_to_initial_state() -> void:
	transform = _initial_transform
	apply_custom_properties(_initial_properties)
	if get("linear_velocity") != null:
		set("linear_velocity", Vector2.ZERO)
		set("angular_velocity", 0.0)

## Virtual method: returns dictionary of inspectable / savable custom properties.
func get_custom_properties() -> Dictionary:
	var props := {}
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var prop_name = p.name
			if prop_name in ["object_id", "display_name", "is_selectable", "is_locked", "design_position"] or prop_name.begins_with("_"):   # CHANGED: added "design_position"
				continue
			props[prop_name] = get(prop_name)
	return props

func apply_custom_properties(_props: Dictionary) -> void:
	for prop_name in _props:
		if prop_name == "design_position":   # ADDED
			continue                          # ADDED
		set(prop_name, _props[prop_name])

## Virtual method: returns approximate local bounding box for selection rendering and hit-testing.
func get_selection_bounds() -> Rect2:
	var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape != null and col_shape.shape != null:
		var s := col_shape.shape
		if s is CircleShape2D:
			var r := (s as CircleShape2D).radius
			return Rect2(Vector2(-r, -r), Vector2(r * 2.0, r * 2.0))
		elif s is RectangleShape2D:
			var sz := (s as RectangleShape2D).size
			return Rect2(-sz / 2.0, sz)
		elif s is SegmentShape2D:
			var seg := s as SegmentShape2D
			var top_left := Vector2(minf(seg.a.x, seg.b.x), minf(seg.a.y, seg.b.y) - 15)
			var size := Vector2(absf(seg.b.x - seg.a.x) + 20, 30)
			return Rect2(top_left - Vector2(10, 0), size)
			
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if spr != null and spr.texture != null:
		var sz := spr.texture.get_size() * spr.scale.abs()
		return Rect2(-sz / 2.0, sz)
		
	return Rect2(Vector2(-32, -32), Vector2(64, 64))

func get_object_id() -> String:
	return object_id
