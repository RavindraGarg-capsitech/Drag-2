# 📘 Developer Level Editor: Complete Architecture & Knowledge Transfer (KT) Guide

**Version**: 1.0 (Godot Engine 4.x Compatible)  
**Project**: Drag to Goal / Portable Modular Tooling  
**Author**: Antigravity Engineering Team  

---

## 📑 Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [Architectural Philosophy](#2-architectural-philosophy)
3. [Folder & Module Structure](#3-folder--module-structure)
4. [File-by-File Technical Breakdown](#4-file-by-file-technical-breakdown)
5. [Data Model & .res Level Serialization](#5-data-model--res-level-serialization)
6. [The `LevelObject` Contract Interface](#6-the-levelobject-contract-interface)
7. [Object Registry & Dynamic Discovery](#7-object-registry--dynamic-discovery)
8. [Editor UI & Interaction Subsystems](#8-editor-ui--interaction-subsystems)
9. [Play-Testing Runtime Flow](#9-play-testing-runtime-flow)
10. [Portability & Migration Protocol (ZIP & Detach)](#10-portability--migration-protocol-zip--detach)
11. [Step-by-Step Extension Guide](#11-step-by-step-extension-guide)
12. [Troubleshooting & Gotchas](#12-troubleshooting--gotchas)

---

## 1. Executive Summary

The **Developer Level Editor** is an internal, handcrafted 2D level-building tool designed for Godot 4.x. It enables level designers and developers to visually place, move, rotate, duplicate, inspect, configure, play-test, and save physics-based levels as native Godot `.res` binary/text resources.

### Key Capabilities
- **100% Self-Contained**: The entire editor lives inside `res://Editor/` and has **zero hardcoded dependencies** on external project scenes.
- **Data-Driven & Dynamic**: Objects are discovered from the host project's registry; zero UI buttons are hardcoded.
- **Clean Coordinate Separation**: Level objects exist in a standard **1920 × 1080 Landscape World Space**, while UI elements reside on a separate `CanvasLayer` (Layer 10).
- **Live In-Editor Play-Testing**: One-key instant simulation unfreezes physics to test ball drops and bounces in real-time, restoring the exact edit state upon stopping.
- **Zero Configuration Setup**: Auto-registers required InputMap shortcuts in memory on boot if missing from `project.godot`.

---

## 2. Architectural Philosophy

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                                EDITOR MODULE                                │
│                              (res://Editor/)                                │
│                                                                             │
│  ┌───────────────────────┐   ┌───────────────────────┐   ┌───────────────┐  │
│  │   EditorUI            │   │  SelectionManager     │   │ ObjectManager │  │
│  │   (Sidebar & Palette) │   │  (Hit-Testing & Box)  │   │ (Spawn/Drag)  │  │
│  └───────────┬───────────┘   └───────────┬───────────┘   └───────┬───────┘  │
│              │                           │                       │          │
│              └─────────────────┐         │         ┌─────────────┘          │
│                                ▼         ▼         ▼                        │
│                        ┌───────────────────────────────┐                    │
│                        │       LevelEditor (Coord)     │                    │
│                        └───────────────┬───────────────┘                    │
│                                        ▼                                    │
│                        ┌───────────────────────────────┐                    │
│                        │       LevelRoot Container     │                    │
│                        │    (1920x1080 Design Space)   │                    │
│                        └───────────────┬───────────────┘                    │
│                                        │                                    │
└────────────────────────────────────────┼────────────────────────────────────┘
                                         │
                    Communicates via Contract Interface
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             HOST GAME PROJECT                               │
│                                                                             │
│  ┌───────────────────────────┐           ┌───────────────────────────────┐  │
│  │    ObjectRegistry.gd      │           │      Game Objects (.tscn)     │  │
│  │    (Host Object Map)      │           │  (extends LevelObject)        │  │
│  │    - "ball"               │           │  - Ball.tscn                  │  │
│  │    - "spring_rope"        │           │  - SpringRope.tscn            │  │
│  │    - "wall"               │           │  - Wall.tscn                  │  │
│  │    - "box"                │           │  - Basket.tscn                │  │
│  └───────────────────────────┘           └───────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Folder & Module Structure

```text
res://Editor/
├── Config/
│   ├── EditorConfig.gd               # Configuration resource definition
│   └── DefaultEditorConfig.tres      # Default instance (1920x1080, save paths)
├── Core/
│   ├── LevelObject.gd                # Base class / interface for all placeable objects
│   ├── LevelObjectData.gd            # Resource data model for a single placed object
│   ├── LevelData.gd                  # Resource data model for a complete level (.res)
│   ├── LevelLoader.gd                # Generic loader instantiating LevelData into LevelRoot
│   └── LevelRoot.gd                  # World container defining 1920x1080 design space
├── Scenes/
│   └── LevelEditor.tscn              # Canonical standalone editor scene
├── Scripts/
│   ├── LevelEditor.gd                # Main editor controller, shortcut router & play-test
│   ├── EditorInputManager.gd         # Dynamic in-memory InputMap auto-registration
│   ├── EditorObjectRegistry.gd       # Dynamic registry bridge & scene factory
│   ├── EditorObjectManager.gd        # Spawning, dragging, duplicating, and deleting
│   ├── EditorSelectionManager.gd     # Selection box rendering & raycast hit testing
│   ├── EditorPropertyManager.gd      # Reflection-based inspector UI generator
│   ├── EditorSaveManager.gd          # .res level serialization & file dialog manager
│   └── EditorUI.gd                   # Sidebar UI, animations, palette & dialogs
├── UI/
│   ├── EditorPanel.tscn              # Sidebar container scene
│   ├── ObjectButton.tscn             # Reusable palette button component
│   └── PropertyPanel.tscn            # Property inspector container
├── ADD_OBJECT_GUIDE.md               # Quick copy-pasteable guide for adding objects
├── EDITOR_KT_DOCUMENTATION.md        # Comprehensive technical & architectural manual
└── README.md                         # Quick-start manual
```

---

## 4. File-by-File Technical Breakdown

### `Core/`
| File | Type | Purpose |
|---|---|---|
| **`LevelObject.gd`** | `class_name LevelObject extends Node2D` | Base class for all placeable game objects. Implements `get_custom_properties()`, `apply_custom_properties()`, `get_selection_bounds()`, and physics freezing (`set_editor_mode()`). |
| **`LevelObjectData.gd`** | `class_name LevelObjectData extends Resource` | Serializable container storing `object_id`, `position`, `rotation`, `scale`, `is_locked`, and `properties` dictionary. |
| **`LevelData.gd`** | `class_name LevelData extends Resource` | Complete level resource storing `level_id`, `level_name`, `design_width`, `design_height`, and an array of `LevelObjectData`. |
| **`LevelLoader.gd`** | `class_name LevelLoader extends RefCounted` | Instantiates `LevelData` into any `LevelRoot` container at runtime or in the editor. |
| **`LevelRoot.gd`** | `class_name LevelRoot extends Node2D` | Design space world root. Exposes constants `DESIGN_WIDTH = 1920.0`, `DESIGN_HEIGHT = 1080.0`, and helper methods `get_level_objects()` and `clear_level_objects()`. |

### `Scripts/`
| File | Class | Purpose |
|---|---|---|
| **`LevelEditor.gd`** | `LevelEditor` | Top-level coordinator. Dispatches keyboard shortcuts, manages camera, controls play-test simulation flow, and routes mouse events. |
| **`EditorInputManager.gd`** | `EditorInputManager` | Checks `InputMap` on startup and dynamically creates missing actions in memory (e.g. `toggle_editor_panel` -> `E`, `play_test` -> `Space`, `duplicate` -> `Ctrl+D`). |
| **`EditorObjectRegistry.gd`** | `EditorObjectRegistry` | Static registry bridge. Auto-discovers host objects from `ObjectRegistry.gd` or `EditorConfig.tres`, stores metadata, and acts as the object instantiator. |
| **`EditorObjectManager.gd`** | `EditorObjectManager` | Handles mouse drag offsets, object duplication (with 30px offset), object deletion, and spawn placement. |
| **`EditorSelectionManager.gd`** | `EditorSelectionManager` | Performs point-in-bounds hit-testing and draws selection outlines and resize handles via `_draw()`. |
| **`EditorPropertyManager.gd`** | `EditorPropertyManager` | Inspects selected objects via reflection. Dynamically creates `SpinBox`, `CheckBox`, and `LineEdit` widgets based on property types. |
| **`EditorSaveManager.gd`** | `EditorSaveManager` | Saves levels via `ResourceSaver.save()` to `res://Resources/Levels/Level{ID}.res` and lists available `.res` files for loading. |
| **`EditorUI.gd`** | `EditorUI` | Controls the sidebar panel, slide tween animation (0.22s cubic), dynamic palette button population, status messages, and modal dialogs. |

---

## 5. Data Model & .res Level Serialization

### Serialization Format
Levels are saved as native Godot Resource files (`.res`) containing:

```text
LevelData (.res)
├── level_id: String           ("001")
├── level_name: String         ("Basketball Challenge")
├── design_width: float        (1920.0)
├── design_height: float       (1080.0)
└── objects: Array[LevelObjectData]
    ├── [0] LevelObjectData
    │   ├── object_id: "ball"
    │   ├── position: Vector2(450, 300)
    │   ├── rotation: 0.0
    │   ├── scale: Vector2(1, 1)
    │   └── properties: { "ball_mass": 1.0, "bounce": 0.75, "friction": 0.3 }
    └── [1] LevelObjectData
        ├── object_id: "spring_rope"
        ├── position: Vector2(960, 700)
        ├── rotation: 0.26
        ├── scale: Vector2(1, 1)
        └── properties: { "rope_length": 300.0, "bounce_strength": 1.5 }
```

### Decoupled Coordinates
The Level Editor operates strictly in **1920 × 1080 World Space**. The sidebar panel on `CanvasLayer` does **not** alter world positions or affect saved object coordinates.

---

## 6. The `LevelObject` Contract Interface

Every placeable game object in the host project extends `LevelObject`:

```gdscript
class_name LevelObject
extends Node2D

@export var object_id: String = ""
@export var display_name: String = ""
@export var is_locked: bool = false

## 1. Virtual method: returns dictionary of inspectable & savable properties
func get_custom_properties() -> Dictionary:
    return {}

## 2. Virtual method: applies loaded properties from save file
func apply_custom_properties(props: Dictionary) -> void:
    pass

## 3. Virtual method: returns approximate local bounds for hit-testing
func get_selection_bounds() -> Rect2:
    # Automatically checks CollisionShape2D or Sprite2D if not overridden
    ...

## 4. Freezes physics during level editing
func set_editor_mode(enabled: bool) -> void:
	# Automatically sets 'freeze = true' on RigidBody2D nodes
    ...

## 5. Resets state after play-testing stops
func reset_to_initial_state() -> void:
    ...
```

---

## 7. Object Registry & Dynamic Discovery

1. **Host Definition**: The host project defines available objects in `res://Scripts/Core/ObjectRegistry.gd` (or via `EditorObjectRegistry.register_object(...)`).
2. **Auto-Discovery**: `EditorObjectRegistry` queries the host definitions on boot.
3. **Data-Driven UI**: `EditorUI._setup_palette()` reads the list and instantiates an `ObjectButton.tscn` for every registered object.
4. **Spawning**: When clicked, `EditorObjectRegistry.spawn_object(id, level_root)` instantiates the real `.tscn` from the host project, adds it to `LevelRoot`, freezes its physics, and selects it.

---

## 8. Editor UI & Interaction Subsystems

### Sidebar Show/Hide (E Key)
- The right-side panel is **hidden by default** on startup to give a clean, full-screen 1920×1080 workspace.
- Pressing **`E`** (or clicking `[🛠️ Panel (E)]`) triggers a cubic ease-out slide animation (0.22 seconds).
- Pressing **`E`** again smoothly hides the panel.

### Keyboard Shortcuts
| Shortcut | Action |
|---|---|
| **`E`** | Toggle Editor Sidebar Panel |
| **`Left Click + Drag`** | Move selected object |
| **`R`** | Rotate selected object by +15° |
| **`Ctrl + D`** | Duplicate selected object |
| **`Delete` / `Backspace`** | Delete selected object |
| **`Escape` / `Right Click`** | Deselect active object |
| **`Space` / `F5`** | Start / Stop Play-Testing |

---

## 9. Play-Testing Runtime Flow

```text
[ Developer presses Spacebar / clicks ▶️ PLAY TEST ]
                       │
                       ▼
1. Capture in-memory level snapshot (LevelData)
2. Deselect active selection outline
3. Call obj.set_editor_mode(false) on all objects (Unfreezes RigidBody2D physics)
4. Full 2D physics simulation runs live in landscape
                       │
[ Developer presses Spacebar / Escape to Stop ]
                       │
                       ▼
1. Call LevelLoader.load_level(snapshot, level_root)
2. Call obj.set_editor_mode(true) (Re-freezes physics)
3. Exact layout, positions, and properties are 100% restored
```

---

## 10. Portability & Migration Protocol (ZIP & Detach)

### How to Transfer to Another Project

1. **Copy/ZIP**: Copy `res://Editor/` into the destination Godot project at `res://Editor/`.
2. **Inherit `LevelObject`**: Have placeable objects in the new project extend `LevelObject`.
3. **Register Objects**: In the new project's startup script or `ObjectRegistry.gd`, register the objects:
   ```gdscript
   EditorObjectRegistry.register_object("hero", "res://Scenes/Hero.tscn", "Hero Player", "Actors")
   ```
4. **Launch**: Run `res://Editor/Scenes/LevelEditor.tscn` (Press `F6`).

### Zero Dependencies Guarantee
- **No hardcoded external scene paths**.
- **No required `project.godot` input actions** (handled dynamically in memory).
- **No external plugins or GDExtensions required**.

---

## 11. Step-by-Step Extension Guide

### Adding a New Object (e.g. `LaserGate`)
1. Create `LaserGate.gd` extending `LevelObject`:
   ```gdscript
   class_name LaserGate extends LevelObject
   
   @export var damage: float = 50.0
   
   func _init() -> void:
	   object_id = "laser_gate"
	   display_name = "Laser Gate"
	   
   func get_custom_properties() -> Dictionary:
	   return { "damage": damage }
	   
   func apply_custom_properties(props: Dictionary) -> void:
	   if props.has("damage"): damage = props["damage"]
   ```
2. Build `LaserGate.tscn` with a `Sprite2D` and `Area2D`.
3. Register in `ObjectRegistry.gd`:
   ```gdscript
   "laser_gate": {
	   "id": "laser_gate",
	   "display_name": "Laser Gate",
	   "scene_path": "res://Scenes/Objects/LaserGate.tscn",
	   "category": "Hazards"
   }
   ```
4. Run `LevelEditor.tscn` $\rightarrow$ `➕ Laser Gate` appears in the palette automatically!

---

## 12. Troubleshooting & Gotchas

| Issue | Cause | Solution |
|---|---|---|
| **Palette is empty on startup** | UI rendered before registry discovery | `EditorObjectRegistry` now auto-discovers host objects immediately upon query, and `EditorUI` refreshes on panel open. |
| **Object physics falling while editing** | `set_editor_mode(true)` was not called | Ensure the object script extends `LevelObject` and calls `super._ready()`. |
| **Static typing downcast errors in Godot 4** | Doing `self is RigidBody2D` when script extends `LevelObject` | Use `get("freeze") != null` or `(self as Object) is RigidBody2D` to avoid compile-time analyzer conflicts. |
| **Panel blocking click events when hidden** | UI container consuming mouse events | `EditorUI` sets `panel.visible = false` at the end of the slide-out animation to prevent intercepting clicks. |
