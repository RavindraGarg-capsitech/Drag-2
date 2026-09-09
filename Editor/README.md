# 🛠️ Portable Developer Level Editor Module

A 100% self-contained, data-driven, and completely portable Developer Level Editor for Godot 4.x.

---

## 📂 Folder Structure

```text
res://Editor/
├── Config/
│   ├── EditorConfig.gd           # Configuration resource definition
│   └── DefaultEditorConfig.tres  # Default design size & level directory settings
├── Core/
│   ├── LevelObject.gd            # Base class & contract for placeable objects
│   ├── LevelObjectData.gd        # Resource representation of individual objects
│   ├── LevelData.gd              # Resource representation of a complete level (.res)
│   ├── LevelLoader.gd            # Generic level loader for LevelData
│   └── LevelRoot.gd              # Self-contained world design space container
├── Scenes/
│   └── LevelEditor.tscn          # Main Level Editor scene (0 external dependencies)
├── Scripts/
│   ├── LevelEditor.gd            # Editor coordinator, shortcut handling & play-test
│   ├── EditorInputManager.gd     # Auto-registers required InputMap actions on startup
│   ├── EditorObjectRegistry.gd   # Dynamic object registry & scene factory
│   ├── EditorObjectManager.gd    # Spawning, dragging, duplicate & delete logic
│   ├── EditorSelectionManager.gd # Generic bounds hit testing & visual outline
│   ├── EditorPropertyManager.gd  # Dynamic property inspector for custom properties
│   ├── EditorSaveManager.gd      # Configurable .res level saving & loading
│   └── EditorUI.gd               # Sidebar UI, dynamic palette & slide animations
├── UI/
│   ├── EditorPanel.tscn          # Right-side sidebar panel container
│   ├── ObjectButton.tscn         # Reusable palette button component
│   └── PropertyPanel.tscn        # Property inspector container
└── README.md                     # Documentation & migration guide
```

---

## ➕ How to Add an Object to the Object Palette

> 💡 **For a complete copy-pasteable demo code example, see [ADD_OBJECT_GUIDE.md](file:///c:/Users/deadp/OneDrive/Documents/drag-2-goal/Editor/ADD_OBJECT_GUIDE.md).**

### 1. Locate or Create Your Game Object
Make sure your game object scene exists outside the `Editor/` folder (e.g. `res://Scenes/Objects/Ball.tscn`, `res://Scenes/Objects/SpringRope.tscn`, or `res://Scenes/Objects/Fan.tscn`).

### 2. Make Your Script Extend `LevelObject`
In your object script (e.g. `res://Scripts/Objects/Ball.gd`), extend `LevelObject` and implement property getters/setters:

```gdscript
class_name Ball
extends LevelObject

@export var ball_mass: float = 1.0
@export var bounce: float = 0.75
@export var friction: float = 0.3

func _init() -> void:
	object_id = "ball"
	display_name = "Basketball"

func get_custom_properties() -> Dictionary:
	return {
		"ball_mass": ball_mass,
		"bounce": bounce,
		"friction": friction
	}

func apply_custom_properties(props: Dictionary) -> void:
	if props.has("ball_mass"): ball_mass = props["ball_mass"]
	if props.has("bounce"): bounce = props["bounce"]
	if props.has("friction"): friction = props["friction"]
```

### 3. Register the Object in `ObjectRegistry.gd`
Open `res://Scripts/Core/ObjectRegistry.gd` and add the object definition:

```gdscript
"ball": {
	"id": "ball",
	"display_name": "Basketball",
	"scene_path": "res://Scenes/Objects/Ball.tscn",
	"category": "Core"
},
"spring_rope": {
	"id": "spring_rope",
	"display_name": "Spring Rope",
	"scene_path": "res://Scenes/Objects/SpringRope.tscn",
	"category": "Interactive"
}
```

*(Or register dynamically in code with:*
`EditorObjectRegistry.register_object("ball", "res://Scenes/Objects/Ball.tscn", "Basketball", "Core")`*)*

### 4. Run the Editor
Open and run **`res://Editor/Scenes/LevelEditor.tscn`** (Press **F6**):
- Press **`E`** to open the panel.
- The button **`+ Basketball`** appears automatically!
- Clicking it spawns the real `Ball.tscn` from `res://Scenes/Objects/Ball.tscn` into `LevelRoot`.

---

## 📝 Files to Edit vs Files NOT to Edit

| What You Want to Do | File You NEED to Edit | Files You DO NOT Need to Edit |
|---|---|---|
| **Add a new object** | Your new `MyObject.tscn` / `MyObject.gd` & `ObjectRegistry.gd` | ❌ `LevelEditor.gd`<br>❌ `EditorUI.gd`<br>❌ `EditorPanel.tscn`<br>❌ `EditorObjectManager.gd`<br>❌ `EditorSaveManager.gd` |
| **Add a custom property** | Only your object script (`get_custom_properties()`) | ❌ Any editor script (inspector adapts dynamically) |

---

## 🚀 How to Detach & Use in Any Godot Project

1. **ZIP `res://Editor/`**: Copy or zip the single folder `res://Editor/`.
2. **Paste into New Project**: Paste `res://Editor/` into the destination project root.
3. **Extend `LevelObject`**: Have placeable objects in the new project extend `LevelObject`.
4. **Register Objects**: Call `EditorObjectRegistry.register_object(...)` or configure `EditorConfig.tres`.
5. **Run Editor**: Launch `res://Editor/Scenes/LevelEditor.tscn` (Press **F6**).

---

## ⚙️ Zero Required `project.godot` Setup

The editor includes `EditorInputManager.gd` which **automatically registers all required InputMap actions in memory on startup** if they are missing from your project:

| Action | Default Input / Key |
|---|---|
| **Toggle Editor Panel** | **`E` Key** (or top-right `🛠️ Panel [E]` button) |
| **Select Object** | Left Click on object in level |
| **Move Object** | Left Click + Drag on selected object |
| **Deselect** | Right Click / `Escape` |
| **Rotate Selected (+15°)** | `R` Key (or Inspector input) |
| **Duplicate Selected** | `Ctrl + D` (or Duplicate button) |
| **Delete Selected** | `Delete` / `Backspace` (or Delete button) |
| **Play Test / Stop Test** | `Spacebar` / `F5` (or Play Test button) |

---

## 💾 Level Resource Format (.res)

Levels are saved as native Godot binary/text resources (`.res`) in `res://Resources/Levels/Level{ID}.res`.

To load a level in your runtime game:
```gdscript
var level_data: LevelData = ResourceLoader.load("res://Resources/Levels/Level001.res")
LevelLoader.load_level(level_data, my_level_root)
```
