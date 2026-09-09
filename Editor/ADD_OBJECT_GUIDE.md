# 📖 Complete Guide: Adding New Objects to the Level Editor

This guide provides copy-pasteable demo code and step-by-step instructions for adding custom game objects to the Level Editor.

---

## 🏗️ Architecture Overview

The Level Editor is **100% data-driven**. You never need to touch or modify any code inside `res://Editor/`.

```text
1. Your Game Object Script (extends LevelObject)
		↓
2. Your Game Object Scene (.tscn)
		↓
3. Register in Object Registry
		↓
4. Open Editor (Press E) -> Object appears automatically!
```

---

## 💻 Complete Demo Code Example: `Trampoline`

### Step 1: Create the Script
Create `res://Scripts/Objects/Trampoline.gd`:

```gdscript
class_name Trampoline
extends LevelObject

## Custom properties for this object
@export var bounce_power: float = 600.0
@export var is_active: bool = true
@export var launch_angle_degrees: float = 90.0

func _init() -> void:
	object_id = "trampoline"
	display_name = "Trampoline"

## 1. Expose custom properties to the Editor's Inspector & Save File (.res)
func get_custom_properties() -> Dictionary:
	return {
		"bounce_power": bounce_power,
		"is_active": is_active,
		"launch_angle_degrees": launch_angle_degrees
	}

## 2. Apply saved properties when a level is loaded
func apply_custom_properties(props: Dictionary) -> void:
	if props.has("bounce_power"):
		bounce_power = props["bounce_power"]
	if props.has("is_active"):
		is_active = props["is_active"]
	if props.has("launch_angle_degrees"):
		launch_angle_degrees = props["launch_angle_degrees"]

## 3. (Optional) Custom selection bounding box for clicking and outlines
func get_selection_bounds() -> Rect2:
	# Local bounding rectangle centered on the object: width=120, height=40
	return Rect2(Vector2(-60, -20), Vector2(120, 40))

## 4. (Optional) Reset to initial state after play-testing stops
func reset_to_initial_state() -> void:
	super.reset_to_initial_state()
	# Reset any runtime state here if needed
```

---

### Step 2: Create the Scene
Create `res://Scenes/Objects/Trampoline.tscn`:

```text
Trampoline (Node2D, script: res://Scripts/Objects/Trampoline.gd)
├── Sprite2D (Your texture / sprite)
└── Area2D or CollisionShape2D (RectangleShape2D, size: 120 x 40)
```

---

### Step 3: Register the Object

#### Option A: In `res://Scripts/Core/ObjectRegistry.gd` (Recommended for Drag to Goal)
Add an entry to `DEFAULT_REGISTRY`:

```gdscript
"trampoline": {
	"id": "trampoline",
	"display_name": "Trampoline",
	"scene_path": "res://Scenes/Objects/Trampoline.tscn",
	"category": "Interactive"
}
```

#### Option B: Dynamic Code Registration (For other projects)
You can also register it at runtime in your main startup script or autoload:

```gdscript
EditorObjectRegistry.register_object(
	"trampoline",                              # Unique ID
	"res://Scenes/Objects/Trampoline.tscn",   # Scene path
	"Super Trampoline",                       # Display Name
	"Interactive"                             # Category
)
```

---

## 🎮 How to Test in the Editor

1. Open **`res://Editor/Scenes/LevelEditor.tscn`** and press **F6**.
2. Press **`E`** (or click `[🛠️ Panel (E)]` at the top right).
3. The button **`➕ Trampoline`** appears automatically in the **OBJECT PALETTE**.
4. Click **`➕ Trampoline`** $\rightarrow$ It spawns in the center of the level.
5. Click on the trampoline:
   - The Inspector creates live controls for **Bounce Power**, **Is Active**, and **Launch Angle Degrees**.
6. Move or rotate (**`R`**), duplicate (**`Ctrl + D`**), and click **💾 Save Level**.
7. Press **`Space`** to play-test!

---

## 📌 Checklist of Methods to Implement in `LevelObject`

| Method | Required? | Description |
|---|---|---|
| `_init()` | **Yes** | Sets `object_id` and `display_name`. |
| `get_custom_properties()` | **Yes** | Returns a `Dictionary` of properties to inspect and save. |
| `apply_custom_properties(props)` | **Yes** | Applies property dictionary when loading from `.res`. |
| `get_selection_bounds()` | Optional | Returns `Rect2` local bounds for selection box and clicking. |
| `reset_to_initial_state()` | Optional | Called when stopping play-test mode. |
| `set_editor_mode(enabled)` | Handled | Freezes rigid bodies during edit mode (default handles this). |
