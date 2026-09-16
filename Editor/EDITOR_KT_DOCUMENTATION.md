# 📘 Developer Level Editor: Complete Architecture & Knowledge Transfer (KT) Guide

**Version**: 2.0 (Godot Engine 4.x Compatible)  
**Project**: Drag to Goal / Portable Modular Tooling  
**Author**: Antigravity Engineering Team  

---

## 📑 Table of Contents
1. [Executive Summary & Folder Responsibility](#1-executive-summary--folder-responsibility)
2. [Architectural Philosophy & Dependency Direction](#2-architectural-philosophy--dependency-direction)
3. [Folder & Module Structure](#3-folder--module-structure)
4. [File-by-File Technical Breakdown](#4-file-by-file-technical-breakdown)
5. [Data Model & .res Level Serialization](#5-data-model--res-level-serialization)
6. [The `LevelObject` Contract Interface](#6-the-levelobject-contract-interface)
7. [Object Registry & Dynamic Discovery (ObjectRegistry vs EditorObjectRegistry)](#7-object-registry--dynamic-discovery)
8. [LevelLoader & LevelRoot Flow](#8-levelloader--levelroot-flow)
9. [Editor UI & Interaction Subsystems](#9-editor-ui--interaction-subsystems)
10. [Play-Testing Runtime Flow](#10-play-testing-runtime-flow)
11. [Step-by-Step Extension Guide](#11-step-by-step-extension-guide)
12. [Troubleshooting & Gotchas](#12-troubleshooting--gotchas)

---

## 1. Executive Summary & Folder Responsibility

The **Developer Level Editor** is an internal 2D level-building tool designed for Godot 4.x. It enables developers and level designers to visually place, move, rotate, duplicate, inspect, configure, play-test, and save physics-based levels as native Godot `.res` resources.

### Folder Responsibility
- **`res://Editor/`**:
  Contains **only** the tools and systems used to create, edit, inspect, preview, and manage levels. It must **never** contain gameplay runtime dependencies.
- **`res://Scripts/Core/`**:
  Contains **shared runtime systems** required by both gameplay and the editor (`LevelData`, `LevelObjectData`, `LevelObject`, `LevelRoot`, `LevelLoader`, and `ObjectRegistry`).
- **`Runtime Gameplay`**:
  Must **never** depend on `Editor/` scripts, scenes, or tools.

### Key Capabilities
- **Unidirectional Decoupling**: Runtime gameplay never imports or depends on editor scripts.
- **Data-Driven & Dynamic**: Objects are discovered from the host project's registry; zero UI buttons are hardcoded.
- **Clean Coordinate Separation**: Level objects exist in a standard **1920 × 1080 Landscape World Space**, while UI elements reside on a separate `CanvasLayer` (Layer 10).
- **Live In-Editor Play-Testing**: One-key instant simulation unfreezes physics to test ball drops and bounces in real-time, restoring the exact edit state upon stopping.
- **Zero Configuration Setup**: Auto-registers required InputMap shortcuts in memory on boot if missing from `project.godot`.

---

## 2. Architectural Philosophy & Dependency Direction

```text
             ┌────────────────────────────────────────┐
             │            GAMEPLAY RUNTIME            │
             │   (Scripts/Controllers/, Scenes/game)  │
             └───────────────────┬────────────────────┘
                                 │
                                 ▼
             ┌────────────────────────────────────────┐
             │          CORE / SHARED SYSTEMS         │
             │             (Scripts/Core/)            │
             │  • ObjectRegistry.gd  • LevelLoader.gd │
             │  • LevelRoot.gd       • LevelObject.gd │
             │  • LevelData.gd       • LevelObjDat.gd │
             └───────────────────▲────────────────────┘
                                 │
                                 │ (Allowed Tool Dependency)
             ┌───────────────────┴────────────────────┐
             │               EDITOR TOOLS             │
             │              (res://Editor/)           │
             │  • LevelEditor        • EditorUI       │
             │  • EditorObjRegistry  • EditorObjMgr   │
             │  • EditorPropMgr      • EditorSaveMgr  │
             │  • EditorSelectMgr    • EditorInputMgr │
             └────────────────────────────────────────┘
```

### Dependency Rules:
- `Gameplay → Core`: **ALLOWED** (Runtime consumes core data models and loader).
- `Editor → Core`: **ALLOWED** (Editor consumes shared schemas, objects, and root container).
- `Core → Editor`: **STRICTLY FORBIDDEN** (Core must remain completely independent).
- `Gameplay → Editor`: **STRICTLY FORBIDDEN** (Runtime must never touch editor tools).

---

## 3. Folder & Module Structure

```text
res://Editor/
├── Config/
│   ├── EditorConfig.gd               # Configuration resource definition
│   └── DefaultEditorConfig.tres      # Default instance (1920x1080, save paths)
├── Core/                             # Shared level abstractions & schemas
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
│   ├── EditorObjectRegistry.gd       # Editor-only dynamic registry bridge & palette factory
│   ├── EditorObjectManager.gd        # Spawning, dragging, duplicating, and deleting
│   ├── EditorSelectionManager.gd     # Selection box rendering & raycast hit testing
│   ├── EditorPropertyManager.gd      # Reflection-based inspector UI generator with UndoRedo
│   ├── EditorSaveManager.gd          # .res level serialization & file loading
│   └── EditorUI.gd                   # Sidebar UI, animations, palette & dialogs
├── UI/
│   ├── EditorPanel.tscn              # Sidebar container scene
│   ├── ObjectButton.tscn             # Reusable palette button component
│   └── PropertyPanel.tscn            # Property inspector container
├── ADD_OBJECT_GUIDE.md               # Quick guide for adding new placeable objects
├── EDITOR_KT_DOCUMENTATION.md        # This technical & architectural manual
└── README.md                         # Quick-start guide
```

---

## 4. File-by-File Technical Breakdown

### Core Subsystems (`Core/`)
| File | Class | Responsibility |
|---|---|---|
| **`LevelObject.gd`** | `LevelObject` | Base class for all placeable entities (Ball, Basket, Box, Wall, SpringRope). Defines `get_custom_properties()`, `apply_custom_properties()`, `get_selection_bounds()`, and `set_editor_mode()`. |
| **`LevelObjectData.gd`** | `LevelObjectData` | Resource storing individual object state: `object_id`, `position`, `rotation`, `scale`, `is_locked`, and `properties` dictionary. |
| **`LevelData.gd`** | `LevelData` | Complete level resource storing `level_id`, `level_name`, `design_width`, `design_height`, and array of `LevelObjectData`. |
| **`LevelLoader.gd`** | `LevelLoader` | Generic loader instantiating `LevelData` into `LevelRoot` at runtime or in the editor. |
| **`LevelRoot.gd`** | `LevelRoot` | World container node handling responsive viewport scaling (`_fit_level_to_viewport()`), object resets, and clearing. |

### Editor Tools (`Scripts/`)
| File | Class | Responsibility |
|---|---|---|
| **`LevelEditor.gd`** | `LevelEditor` | Top-level coordinator. Dispatches keyboard shortcuts, controls play-test simulation flow, and routes mouse events. |
| **`EditorInputManager.gd`** | `EditorInputManager` | Injects required shortcuts into memory on startup (`toggle_editor_panel` $\rightarrow$ `E`, `play_test` $\rightarrow$ `Space`, etc.). |
| **`EditorObjectRegistry.gd`** | `EditorObjectRegistry` | Editor-only palette bridge. Reads canonical definitions from `ObjectRegistry.gd` and feeds palette buttons to `EditorUI`. |
| **`EditorObjectManager.gd`** | `EditorObjectManager` | Handles mouse drag offsets, object duplication (with 30px offset), object deletion, and spawn placement. |
| **`EditorSelectionManager.gd`** | `EditorSelectionManager` | Point-in-bounds hit-testing, visual selection bounding box, and handle drawing. |
| **`EditorPropertyManager.gd`** | `EditorPropertyManager` | Inspects selected objects via reflection. Dynamically creates widgets (`SpinBox`, `CheckBox`, `LineEdit`) with full `UndoRedo` support. |
| **`EditorSaveManager.gd`** | `EditorSaveManager` | Saves levels via `ResourceSaver.save()` to `res://Resources/Levels/Level{ID}.res` and loads them into the editor. |
| **`EditorUI.gd`** | `EditorUI` | Controls sidebar slide tween animation, palette buttons, and status notifications. |

---

## 5. Data Model & .res Level Serialization

Levels are saved as native Godot Resource files (`.res`):

```text
LevelData (.res)
├── level_id: String           ("001")
├── level_name: String         ("Level 1")
├── design_width: float        (1920.0)
├── design_height: float       (1080.0)
└── objects: Array[LevelObjectData]
    ├── [0] LevelObjectData ("ball")
    │   ├── position, rotation, scale, is_locked
    │   └── properties: { "ball_mass": 1.0, "bounce": 0.75, "friction": 0.3 }
    └── [1] LevelObjectData ("spring_rope")
        ├── position, rotation, scale, is_locked
        └── properties: { "rope_length": 200.0, "bounce_strength": 1.3 }
```

---

## 6. The `LevelObject` Contract Interface

Every placeable game object extends `LevelObject`:

```gdscript
class_name LevelObject
extends Node2D

@export var object_id: String = ""
@export var display_name: String = ""
@export var is_selectable: bool = true
@export var is_locked: bool = false

var design_position: Vector2 = Vector2.ZERO

## 1. Exposes inspectable custom properties to editor & serializer
func get_custom_properties() -> Dictionary:
    return {}

## 2. Restores saved custom properties upon level loading
func apply_custom_properties(props: Dictionary) -> void:
    pass

## 3. Hit-testing selection bounding box
func get_selection_bounds() -> Rect2:
    return Rect2(Vector2(-32, -32), Vector2(64, 64))

## 4. Freezes physics during level editing
func set_editor_mode(enabled: bool) -> void:
    _is_editor_mode = enabled
    if get("freeze") != null: set("freeze", enabled)

## 5. Resets state after play-testing stops
func reset_to_initial_state() -> void:
    transform = _initial_transform
    apply_custom_properties(_initial_properties)
```

---

## 7. Object Registry & Dynamic Discovery

### Canonical Registry vs Editor Adapter
1. **`ObjectRegistry.gd` (`res://Scripts/Core/ObjectRegistry.gd`)**:
   - The **canonical single source of truth** for all game objects.
   - Used by runtime gameplay (`game_play_logic.gd`) to query object metadata and instantiate objects.
   - Maps object IDs to scene paths (`res://Scenes/Objects/Ball.tscn`, etc.).
2. **`EditorObjectRegistry.gd` (`res://Editor/Scripts/EditorObjectRegistry.gd`)**:
   - An **editor-only adapter**.
   - Auto-discovers definitions from `ObjectRegistry.gd` or `EditorConfig.tres` on boot.
   - Provides editor-specific helpers such as `spawn_object()` (which places an object and immediately calls `set_editor_mode(true)`).

---

## 8. LevelLoader & LevelRoot Flow

```text
                    LevelData Resource (.res)
                              │
                              ▼
        LevelLoader.load_level(level_data, target_root)
                              │
  ┌───────────────────────────┴───────────────────────────┐
  │ 1. target_root.clear_level_objects()                 │
  │ 2. target_root.design_width = level_data.design_width │
  │ 3. For each obj_data in level_data.objects:           │
  │    • Instantiate object scene from ObjectRegistry     │
  │    • Set position, rotation, scale, is_locked        │
  │    • target_root.add_child(obj)                       │
  │    • obj.apply_custom_properties(obj_data.properties) │
  │ 4. target_root._fit_level_to_viewport()              │
  └───────────────────────────────────────────────────────┘
```

---

## 9. Editor UI & Interaction Subsystems

### Sidebar Show/Hide (E Key)
- The sidebar is **hidden by default** on startup to provide an uncluttered 1920×1080 canvas.
- Pressing **`E`** (or clicking `[🛠️ Panel (E)]`) triggers a smooth slide animation (0.22s cubic).
- Pressing **`E`** again hides the panel.

### Keyboard Shortcuts
| Shortcut | Action |
|---|---|
| **`E`** | Toggle Editor Sidebar Panel |
| **`Left Click + Drag`** | Move selected object |
| **`R`** | Rotate selected object by +15° |
| **`Ctrl + D`** | Duplicate selected object |
| **`Delete` / `Backspace`** | Delete selected object |
| **`Ctrl + Z` / `Ctrl + Y`** | Undo / Redo property edits |
| **`Escape` / `Right Click`** | Deselect active object |
| **`Space` / `F5`** | Start / Stop Play-Testing |

---

## 10. Play-Testing Runtime Flow

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

## 11. Step-by-Step Extension Guide

### Adding a New Object (e.g. `Fan`)
1. Create `res://Scripts/Objects/Fan.gd` extending `LevelObject`:
   ```gdscript
   class_name Fan extends LevelObject
   
   @export var blow_strength: float = 800.0
   
   func _init() -> void:
       object_id = "fan"
       display_name = "Wind Fan"
       
   func get_custom_properties() -> Dictionary:
       return { "blow_strength": blow_strength }
       
   func apply_custom_properties(props: Dictionary) -> void:
       if props.has("blow_strength"): blow_strength = props["blow_strength"]
   ```
2. Build `res://Scenes/Objects/Fan.tscn` with collision and visuals.
3. Register in `res://Scripts/Core/ObjectRegistry.gd`:
   ```gdscript
   "fan": {
       "id": "fan",
       "display_name": "Wind Fan",
       "scene_path": "res://Scenes/Objects/Fan.tscn",
       "category": "Interactive"
   }
   ```
4. Run `LevelEditor.tscn` $\rightarrow$ `➕ Wind Fan` appears in the palette automatically!

---

## 12. Troubleshooting & Gotchas

| Issue | Cause | Solution |
|---|---|---|
| **Palette is empty on startup** | UI rendered before discovery | `EditorObjectRegistry` auto-discovers host objects immediately upon query, and `EditorUI` refreshes when the panel opens. |
| **Object physics falling while editing** | `set_editor_mode(true)` not called | Ensure the object script extends `LevelObject` and calls `super._ready()`. |
| **Static typing downcast errors in Godot 4** | Doing `self is RigidBody2D` when script extends `LevelObject` | Use `get("freeze") != null` to avoid compile-time analyzer conflicts. |
| **Panel blocking click events when hidden** | UI container consuming mouse events | `EditorUI` sets `panel.visible = false` when slide-out completes to avoid intercepting clicks. |
| **Runtime depends on Editor** | Importing anything from `res://Editor/` | Ensure all runtime code imports only from `res://Scripts/Core/`. |
