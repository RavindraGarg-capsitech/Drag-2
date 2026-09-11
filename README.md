# Drag-2-Goal


## Figma Design

[Drag-2-Goal Figma Link](https://www.figma.com/design/6YvkKiQZikXZ6zegEffyNd/DRAG-2-GOAL?node-id=93-62&t=mkAJDtTOyJdWZwBB-0)


---

## Tech Stack

* **Game Engine:** Godot
* **Language:** GDScript (primary)
* **Version Control:** Git & GitHub

---

## Project Structure

```
game/
├─ autoloads/                  GameService, BackendService, GameBus, GameConfig, Logger
├─ scripts/
│  ├─ managers/                game_manager, sound_manager, haptics_handler,
│  │                           save_manager, scene_manager, ui_manager, ...
│  ├─ controllers/             nodes/ui equivalent
│  └─ utils/
├─ scenes/
│  ├─ boot/                    initial entry point (e.g. splash screen)
│  ├─ home/
│  ├─ gameplay/                main_scenes equivalent
│  ├─ loading/
│  └─ ui/
│     ├─ mfw/                  placeholder panels — build here first
│     └─ hfw/                  polished panels — same UIManager call, new scene
└─ assets/
   ├─ audio/
   ├─ fonts/
   └─ sprites/
      ├─ atlases/              PDF §1: scene-local & animation only
      │  ├─ animations/
      │  └─ node_specific/
      ├─ single/                PDF §1: anything reused across scenes
      │  ├─ ui/
      │  └─ shared/
      └─ backgrounds/
  └── project.godot  # Godot project file
```



## Branching Guidelines

After cloning the repository, create your own development branch using the following naming convention:

```bash
git checkout -b Dev-<YourInitials>
```

### Example:

```bash
git checkout -b Dev-RG
```



