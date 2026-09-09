# 🛠️ Portable Level Editor Setup Guide

This document provides a complete, step-by-step guide to installing and using the Level Editor in **any Godot 4.x project**.

The Level Editor is **100% self-contained and modular**. It dynamically registers input actions, dynamically builds inspector UIs based on your object's `@export` variables, and can be configured without modifying a single line of editor code.

---

## 📂 1. What Files Need to Be Copied?

To migrate the editor to a new project, you only need to copy **one single folder**:

✅ **Copy this entire directory into your new project:**
`res://Editor/`

**DO NOT** copy any of your game-specific scenes, objects, or autoloads inside the `Editor` folder. Keep the editor completely separate from your gameplay logic.

---

## ⚙️ 2. Required Project Settings & Configuration

There are **zero required Project Settings** to change.

However, the editor relies on a configuration resource to know where to save levels and what objects are available.

1. In your new project, navigate to `res://Editor/Config/DefaultEditorConfig.tres`.
2. Double click the `.tres` file to open it in the Inspector.
3. Configure the following:
   - **Design Width / Height**: The base resolution of your levels (e.g. 1920x1080).
   - **Levels Directory**: Where `.res` level files should be saved (defaults to `res://Resources/Levels/`). *Note: The editor will automatically create this directory if it doesn't exist.*
   - **Registered Objects**: You can add your game's objects here by clicking `Add Element`, supplying an ID, Display Name, and the path to your `.tscn` file.

---

## ⌨️ 3. Required Input Map Actions

You do **not** need to manually configure the Input Map. 

The editor includes `EditorInputManager.gd` which automatically injects the necessary input actions into memory on startup. 
If your project already uses actions with the same names (e.g., `cancel`, `select`), the editor will seamlessly share them. 

The default auto-registered inputs are:
- **`E`** - Toggle Editor Panel
- **`Left Click`** - Select / Move Object
- **`Right Click` / `Escape`** - Deselect
- **`Delete` / `Backspace`** - Delete Selected Object
- **`Ctrl + D`** - Duplicate Selected Object
- **`R`** - Rotate Selected Object
- **`Spacebar` / `F5`** - Start/Stop Play Test

---

## 🏗️ 4. Required Dependencies & Autoloads

- **Autoloads**: The editor requires **zero** autoloads. It manages its own state internally.
- **Dependencies**: The editor requires **zero** external scripts or plugins. Everything it needs is inside `res://Editor/`.

---

## 🧱 5. How to Create and Register a New Object

For an object to appear in the Editor Palette and be saved into levels, it must meet two requirements:

### Step 1: Extend `LevelObject`
Create a new Node2D scene for your game object anywhere in your project (outside the Editor folder). Its root script must extend `LevelObject`:

```gdscript
class_name MyCustomBox
extends LevelObject

@export var bounciness: float = 0.5
@export var health: int = 100

func _init() -> void:
    object_id = "my_custom_box" # Must match registry ID
    display_name = "Bouncy Box"
```

### Step 2: Register the Object
You can register objects in two ways:

**Option A (No-Code):** Add it to `res://Editor/Config/DefaultEditorConfig.tres` under `Registered Objects`.

**Option B (Dynamic Code):** The editor automatically looks for a script at `res://Scripts/Core/ObjectRegistry.gd`. If you create this script in your host project, you can dynamically feed objects to the editor:

```gdscript
# res://Scripts/Core/ObjectRegistry.gd
class_name ObjectRegistry
extends RefCounted

static func get_all_registered_objects() -> Array:
    return [
        {
            "id": "my_custom_box",
            "display_name": "Bouncy Box",
            "scene_path": "res://Scenes/Objects/MyCustomBox.tscn",
            "category": "Obstacles"
        }
    ]
```

---

## 🛠️ 6. Adding Editable Properties

You do **not** need to write any UI code to add new properties to the Editor Inspector!

The editor uses Godot's reflection system (`get_property_list()`). Any variable in your object script marked with `@export` will automatically generate a slider, checkbox, or text field in the editor panel.

When a developer changes a value in the UI, the editor immediately calls `set("your_variable", new_value)` on the live object, allowing you to trigger `set()` callbacks for immediate visual feedback.

---

## 💾 7. Saving and Loading Levels

### Saving Levels
1. Run `res://Editor/Scenes/LevelEditor.tscn`.
2. Create your level using the object palette.
3. In the "Level Management" section, enter a Level ID (e.g., `001`) and a Name.
4. Click **Save Level**. The level will be serialized to `res://Resources/Levels/Level001.res`.

### Loading Levels in Your Game
The Editor exports levels as native Godot `.res` files containing a `LevelData` resource. 

To load a level in your actual game:
```gdscript
var level_data: LevelData = load("res://Resources/Levels/Level001.res")
LevelLoader.load_level(level_data, $MyGameplayNodeContainer)
```

---

## 🎮 8. Play Testing

Clicking **Play Test** in the editor does the following:
1. Temporarily saves the exact positions, rotations, and properties of all objects in memory.
2. Calls `set_editor_mode(false)` on all objects (allowing them to unfreeze, enable physics, and act normally).
3. Hides the editor UI.

When you press **Escape** to stop Play Testing:
1. The editor destroys the modified test objects.
2. It restores the exact memory snapshot, putting everything back exactly where it was before the test started.
3. Calls `set_editor_mode(true)` to re-freeze objects.
