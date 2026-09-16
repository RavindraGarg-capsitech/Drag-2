# 🛠️ Portable Level Editor Setup Guide

This document provides a complete guide to understanding, configuring, and using the Level Editor in Godot 4.x.

The Level Editor is **data-driven and modular**. It dynamically registers input actions, dynamically builds inspector UIs based on your object's `@export` variables, and can be configured without modifying a single line of editor code.

---

## 🏗️ Architectural Responsibility & Boundaries

To keep projects clean, the architecture separates the **Editor Tooling** from the **Shared Runtime Systems**:

```text
Editor/
    Contains only tools used for creating, editing, previewing, and managing levels.
    It must NEVER contain gameplay runtime dependencies.

Scripts/Core/
    Contains shared runtime systems required by both gameplay and the editor:
    - ObjectRegistry.gd   (canonical object catalog)
    - LevelLoader.gd      (generic level builder)
    - LevelRoot.gd        (responsive viewport container)
    - LevelObject.gd      (base class for all game props)
    - LevelData.gd        (complete level resource schema)
    - LevelObjectData.gd  (serialized object schema)

Runtime Gameplay
    Must NEVER depend on Editor/.
```

### Golden Rule:
> **Editor tools may depend on Core/Runtime definitions, but Core and Runtime gameplay must never depend on Editor systems.**

---

## 📂 1. Editor Module Structure

The editor toolset lives under:
`res://Editor/`

- **Config/**: Configuration schema (`EditorConfig.gd`) and default values (`DefaultEditorConfig.tres`).
- **Scripts/**: Coordinator (`LevelEditor.gd`), Selection manager, Property inspector, Save manager, UI controller, and Palette adapter (`EditorObjectRegistry.gd`).
- **Scenes/**: The standalone editor tool scene (`LevelEditor.tscn`).
- **UI/**: Editor panel, palette buttons, and property inspector widgets.

---

## ⚙️ 2. Configuration (`DefaultEditorConfig.tres`)

The editor relies on a configuration resource to know where to save levels and what objects are available:

1. Navigate to `res://Editor/Config/DefaultEditorConfig.tres`.
2. Open it in the Inspector to configure:
   - **Design Width / Height**: The base coordinate space (defaults to 1920x1080).
   - **Levels Directory**: Where `.res` level files should be saved (defaults to `res://Resources/Levels/`).
   - **Registered Objects**: Optional explicit object definitions.

---

## ⌨️ 3. Input Map Actions

The editor includes `EditorInputManager.gd` which automatically injects necessary input actions into memory on startup if missing from `project.godot`:

- **`E`** - Toggle Editor Panel
- **`Left Click`** - Select / Move Object
- **`Right Click` / `Escape`** - Deselect
- **`Delete` / `Backspace`** - Delete Selected Object
- **`Ctrl + D`** - Duplicate Selected Object
- **`R`** - Rotate Selected Object (+15°)
- **`Ctrl + Z` / `Ctrl + Y`** - Undo / Redo property changes
- **`Spacebar` / `F5`** - Start/Stop Play Test

---

## 🧱 4. How to Create and Register a New Object

For an object to appear in the Editor Palette and be saved into levels:

### Step 1: Extend `LevelObject`
Create a new Node2D scene for your game object anywhere outside the Editor folder (e.g., `res://Scenes/Objects/BouncyBox.tscn`). Its root script must extend `LevelObject`:

```gdscript
class_name BouncyBox
extends LevelObject

@export var bounciness: float = 0.8
@export var health: int = 100

func _init() -> void:
    object_id = "bouncy_box"
    display_name = "Bouncy Box"

func get_custom_properties() -> Dictionary:
    return {
        "bounciness": bounciness,
        "health": health
    }

func apply_custom_properties(props: Dictionary) -> void:
    if props.has("bounciness"): bounciness = props["bounciness"]
    if props.has("health"): health = props["health"]
```

### Step 2: Register in `ObjectRegistry.gd`
Open `res://Scripts/Core/ObjectRegistry.gd` (the single source of truth) and add the object:

```gdscript
"bouncy_box": {
    "id": "bouncy_box",
    "display_name": "Bouncy Box",
    "scene_path": "res://Scenes/Objects/BouncyBox.tscn",
    "category": "Physics"
}
```

---

## 🛠️ 5. Dynamic Property Inspector

The editor uses Godot's reflection system (`get_property_list()`). Any variable in your object script returned by `get_custom_properties()` will automatically generate interactive widgets (sliders, check boxes, text inputs) in the editor panel with full `UndoRedo` support.

---

## 💾 6. Saving and Loading Levels

### Saving Levels
1. Open and run `res://Editor/Scenes/LevelEditor.tscn` (Press **F6**).
2. Create your level using the object palette.
3. In the "Level Management" section, enter a Level ID (e.g. `001`) and a Name.
4. Click **Save Level**. The level is serialized to `res://Resources/Levels/Level001.res`.

### Loading Levels in Gameplay
The editor saves levels as native Godot `.res` resources containing a `LevelData` resource.

To load a level in runtime gameplay:
```gdscript
var level_data: LevelData = load("res://Resources/Levels/Level001.res")
LevelLoader.load_level(level_data, my_level_root)
```

---

## 🎮 7. Play-Testing Flow

Clicking **Play Test** (or pressing Space):
1. Captures an in-memory snapshot of the current level.
2. Calls `set_editor_mode(false)` on all placed objects, unfreezing physics bodies.
3. Allows live simulation of collisions, ball launches, and bounces.

Pressing **Escape** or **Space** stops Play Testing:
1. Reloads the snapshot using `LevelLoader.load_level(snapshot, level_root)`.
2. Calls `set_editor_mode(true)` to re-freeze physics bodies.
3. Restores exact editing state and positions.
