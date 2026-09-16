# 🛠️ Developer Level Editor & Architecture Guide

A data-driven, visual Level Editor toolset for Godot 4.x, designed for creating, inspecting, editing, play-testing, and serializing 2D physics levels.

---

## 🏗️ Architectural Boundary & Folder Responsibility

To ensure clean architecture and prevent game runtime code from depending on editor tools, the project strictly enforces a **unidirectional dependency rule**:

```text
┌────────────────────────────────────────────────────────┐
│               GAMEPLAY RUNTIME SYSTEMS                 │
│         (Scripts/Controllers/, Scenes/gameplay/)       │
└───────────────────────────┬────────────────────────────┘
							│
							▼
┌────────────────────────────────────────────────────────┐
│                SHARED RUNTIME / CORE                   │
│         (Scripts/Core/, Resources/Levels/)             │
│  - ObjectRegistry.gd  : Canonical game object catalog  │
│  - LevelLoader.gd     : Generic level builder/loader   │
│  - LevelRoot.gd       : Responsive viewport container  │
│  - LevelObject.gd     : Base class for all game props  │
│  - LevelData.gd       : Complete level resource schema │
│  - LevelObjectData.gd : Serialized object schema       │
└───────────────────────────▲────────────────────────────┘
							│
							│ (Allowed tool dependency)
┌───────────────────────────┴────────────────────────────┐
│                  EDITOR-ONLY TOOLS                     │
│                     (res://Editor/)                    │
│  - LevelEditor        : Coordinator & shortcut router  │
│  - EditorUI           : Sidebar, status bar, palette   │
│  - EditorObjectRegistry: Editor-only palette adapter   │
│  - EditorObjectManager: Canvas spawn/drag/duplicate    │
│  - EditorPropertyMgr  : Dynamic reflection inspector   │
│  - EditorSaveManager  : Level serializer & disk I/O    │
│  - EditorSelectionMgr : Bounding box & gizmo handles   │
└────────────────────────────────────────────────────────┘
```

### The Golden Rule
> **Runtime gameplay must NEVER depend on `res://Editor/`.**  
> Editor systems may depend on shared Core systems, but runtime gameplay must never import, preload, or call anything under `Editor/`.

---

## 📂 Folder Breakdown

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
│   └── LevelEditor.tscn          # Main Level Editor tool scene
├── Scripts/
│   ├── LevelEditor.gd            # Editor coordinator, shortcut handling & play-test
│   ├── EditorInputManager.gd     # Auto-registers required InputMap actions on startup
│   ├── EditorObjectRegistry.gd   # Dynamic object registry & scene factory for editor palette
│   ├── EditorObjectManager.gd    # Spawning, dragging, duplicate & delete logic
│   ├── EditorSelectionManager.gd # Generic bounds hit testing & visual outline drawing
│   ├── EditorPropertyManager.gd  # Dynamic property inspector for custom properties & UndoRedo
│   ├── EditorSaveManager.gd      # Configurable .res level saving & loading
│   └── EditorUI.gd               # Sidebar UI, dynamic palette & slide animations
├── UI/
│   ├── EditorPanel.tscn          # Right-side sidebar panel container
│   ├── ObjectButton.tscn         # Reusable palette button component
│   └── PropertyPanel.tscn        # Property inspector container
└── README.md                     # Documentation & usage guide
```

---

## 🔄 Runtime Flow: LevelLoader & Object Discovery

### 1. The Object Registry Flow
- **`ObjectRegistry.gd`** (`res://Scripts/Core/ObjectRegistry.gd`):  
  The **canonical single source of truth** for all game objects. Maps stable string IDs (e.g. `"ball"`, `"spring_rope"`) to their `.tscn` packed scenes.
- **`EditorObjectRegistry.gd`** (`res://Editor/Scripts/EditorObjectRegistry.gd`):  
  An **editor-only adapter**. On editor startup, it discovers definitions from `ObjectRegistry.gd` or `EditorConfig.tres` and populates the editor palette with buttons.

### 2. The Level Loading Flow (`LevelLoader.gd`)
Whenever a level is loaded (either at runtime or during in-editor preview):
```text
Level Resource (.res file or LevelData resource)
	│
	▼
LevelLoader.load_level(level_res_or_path, target_root: LevelRoot)
	│
	├── 1. Clear existing level objects from target_root
	├── 2. Apply level design dimensions (1920x1080)
	├── 3. For each object in level_data.objects:
	│      ├── Query ObjectRegistry for scene_path
	│      ├── Instantiate object scene (inherits LevelObject)
	│      ├── Apply position, rotation, scale, is_locked
	│      └── Apply custom properties via obj.apply_custom_properties()
	└── 4. Center and scale target_root to fit current viewport via _fit_level_to_viewport()
```

---

## 🎮 How to Use the Level Editor

### Opening the Editor
1. In the Godot FileSystem dock, open **`res://Editor/Scenes/LevelEditor.tscn`**.
2. Press **F6** (Play Current Scene).

### Keyboard & Mouse Shortcuts
The editor automatically registers all required InputMap actions in memory on startup:

| Action | Default Input / Key |
|---|---|
| **Toggle Editor Panel** | **`E` Key** (or top-right `🛠️ Panel [E]` button) |
| **Select Object** | Left Click on object in level |
| **Move Object** | Left Click + Drag on selected object |
| **Deselect** | Right Click or `Escape` |
| **Rotate Selected (+15°)** | `R` Key (or numeric input in Inspector) |
| **Duplicate Selected** | `Ctrl + D` (or Duplicate button) |
| **Delete Selected** | `Delete` / `Backspace` (or Delete button) |
| **Undo / Redo** | `Ctrl + Z` / `Ctrl + Y` (or `Ctrl + Shift + Z`) |
| **Play Test / Stop Test** | `Spacebar` / `F5` (or Play Test button) |

---

## ➕ How to Add a New Object to the Editor Palette

### 1. Create Your Game Object Scene
Create your scene outside `Editor/` (e.g. `res://Scenes/Objects/MyNewProp.tscn`).

### 2. Make Your Script Extend `LevelObject`
In your object script, extend `LevelObject` and implement `get_custom_properties()` and `apply_custom_properties()`:

```gdscript
class_name MyNewProp
extends LevelObject

@export var bounce_power: float = 500.0
@export var is_active: bool = true

func _init() -> void:
	object_id = "my_new_prop"
	display_name = "My New Prop"

func get_custom_properties() -> Dictionary:
	return {
		"bounce_power": bounce_power,
		"is_active": is_active
	}

func apply_custom_properties(props: Dictionary) -> void:
	if props.has("bounce_power"): bounce_power = props["bounce_power"]
	if props.has("is_active"): is_active = props["is_active"]
```

### 3. Register in `ObjectRegistry.gd`
Add your object to `DEFAULT_REGISTRY` inside `res://Scripts/Core/ObjectRegistry.gd`:

```gdscript
"my_new_prop": {
	"id": "my_new_prop",
	"display_name": "My New Prop",
	"scene_path": "res://Scenes/Objects/MyNewProp.tscn",
	"category": "Interactive"
}
```

### 4. Run the Editor
Open `res://Editor/Scenes/LevelEditor.tscn` (Press **F6**):
- Press **`E`** to open the palette.
- **`+ My New Prop`** appears automatically in the category group.
- Click to spawn and configure its properties in real-time.
